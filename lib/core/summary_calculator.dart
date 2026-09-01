import '../core/constants.dart';
import '../data/models/models.dart';

double _round2(double value) => double.parse(value.toStringAsFixed(2));

/// Sponsorship discount factor: `k = max(0, E_total - S_total) / E_total`.
///
/// - No sponsorships (`S = 0`): `k = 1` — members pay their full consumption.
/// - Partial coverage: each member's consumption is reduced proportionally.
/// - Full coverage (`S >= E`): `k = 0` — nothing is split, every member gets
///   their advance refunded.
/// - No expenses (`E = 0`): returns `1` (nothing to discount).
double sponsorshipDiscountFactor({
  required double totalSpent,
  required double totalSponsorship,
}) {
  if (totalSpent <= 0) return 1;
  final net = totalSpent - totalSponsorship;
  if (net <= 0) return 0;
  return net / totalSpent;
}

/// Computes the full analytical snapshot of a trip from raw data.
///
/// Pure Dart — no database or Flutter dependencies, so it can be unit-tested
/// in isolation. Mirrors the same paid/share derivation used by
/// `summaryProvider`:
///   - A member's "paid" = sum of expenses where they are the payer.
///   - A member's "consumed" = sum of their `expense_participants` shares
///     (only bills they joined — excluded members consume nothing), adjusted
///     by the sponsorship discount factor `k = max(0, E-S)/E`.
///
/// [sponsorships] reduce the total split by [totalSponsorship]; every
/// member's consumption is scaled by `k`, so `net = paid - k * consumed`.
/// Internal sponsors' sponsorship funds do NOT count toward their paid
/// advance — only what they actually paid out of pocket does.
TripSummaryStats computeTripSummary({
  required List<Expense> expenses,
  required List<Participant> participants,
  required List<ExpenseParticipant> joined,
  required List<Settlement> settlements,
  List<Sponsorship> sponsorships = const [],
}) {
  final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final totalSponsorship = sponsorships.fold<double>(
    0,
    (sum, s) => sum + s.amount,
  );
  final discountFactor = sponsorshipDiscountFactor(
    totalSpent: totalSpent,
    totalSponsorship: totalSponsorship,
  );
  final netTotal = _round2(totalSpent * discountFactor);
  final memberCount = participants.length;
  final averagePerMember = memberCount > 0 ? totalSpent / memberCount : 0.0;

  // Top single expense.
  TopExpense? topExpense;
  for (final e in expenses) {
    if (topExpense == null || e.amount > topExpense.amount) {
      topExpense = TopExpense(
        id: e.id,
        title: e.title,
        amount: e.amount,
        payerId: e.payerId,
      );
    }
  }

  // Per-member paid / consumed.
  final totalPaid = <String, double>{};
  final totalConsumed = <String, double>{};
  final joinedCount = <String, int>{};
  for (final p in participants) {
    totalPaid[p.id] = 0;
    totalConsumed[p.id] = 0;
    joinedCount[p.id] = 0;
  }
  for (final e in expenses) {
    totalPaid[e.payerId] = (totalPaid[e.payerId] ?? 0) + e.amount;
  }
  for (final j in joined) {
    totalConsumed[j.participantId] =
        (totalConsumed[j.participantId] ?? 0) + j.shareAmount;
    joinedCount[j.participantId] = (joinedCount[j.participantId] ?? 0) + 1;
  }

  final members = participants.map((p) {
    final paid = _round2(totalPaid[p.id] ?? 0);
    final consumed = _round2((totalConsumed[p.id] ?? 0) * discountFactor);
    final net = _round2(paid - consumed);
    final joined = joinedCount[p.id] ?? 0;
    return MemberStat(
      participantId: p.id,
      name: p.name,
      paid: paid,
      consumed: consumed,
      net: net,
      joinedCount: joined,
      totalBillsCount: expenses.length,
      participationRate:
          expenses.isEmpty ? 0 : joined / expenses.length,
    );
  }).toList();

  // Category distribution, ranked descending. Legacy/unknown ids are folded
  // into the current preset set via normalize so stale rows never break the
  // dashboard.
  final categoryTotals = <String, double>{};
  for (final e in expenses) {
    final k = ExpenseCategory.normalize(e.category);
    categoryTotals[k] = (categoryTotals[k] ?? 0) + e.amount;
  }
  final categories = categoryTotals.entries.map((entry) {
    final total = _round2(entry.value);
    return CategoryStat(
      categoryId: entry.key,
      label: ExpenseCategory.label(entry.key),
      emoji: ExpenseCategory.icons[entry.key] ?? '📦',
      total: total,
      percent: totalSpent > 0 ? total / totalSpent : 0,
    );
  }).toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  final paidSettlementsCount = settlements.where((s) => s.isPaid).length;

  return TripSummaryStats(
    totalSpent: _round2(totalSpent),
    averagePerMember: _round2(averagePerMember),
    expenseCount: expenses.length,
    topExpense: topExpense,
    categories: categories,
    members: members,
    settlements: settlements,
    paidSettlementsCount: paidSettlementsCount,
    totalSponsorship: _round2(totalSponsorship),
    netTotal: netTotal,
    discountFactor: discountFactor,
    sponsorships: sponsorships,
  );
}