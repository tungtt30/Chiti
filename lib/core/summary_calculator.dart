import '../core/constants.dart';
import '../data/models/models.dart';

double _round2(double value) => double.parse(value.toStringAsFixed(2));

/// Computes the full analytical snapshot of a trip from raw data.
///
/// Pure Dart — no database or Flutter dependencies, so it can be unit-tested
/// in isolation. Mirrors the same paid/share derivation used by
/// `summaryProvider`:
///   - A member's "paid" = sum of expenses where they are the payer.
///   - A member's "consumed" = sum of their `expense_participants` shares
///     (only bills they joined — excluded members consume nothing).
TripSummaryStats computeTripSummary({
  required List<Expense> expenses,
  required List<Participant> participants,
  required List<ExpenseParticipant> joined,
  required List<Settlement> settlements,
}) {
  final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
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
    final consumed = _round2(totalConsumed[p.id] ?? 0);
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

  // Category distribution, ranked descending. Unknown categories are folded
  // into 'Other' so stale/legacy rows never break the dashboard.
  final categoryTotals = <String, double>{};
  for (final e in expenses) {
    final k = ExpenseCategory.all.contains(e.category)
        ? e.category
        : ExpenseCategory.fallback;
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
  );
}