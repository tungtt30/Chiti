import 'settlement.dart';

/// Largest single expense, for the KPI card.
class TopExpense {
  final String id;
  final String title;
  final double amount;
  final String payerId;

  const TopExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.payerId,
  });
}

/// Per-member audit row.
class MemberStat {
  final String participantId;
  final String name;
  final double paid; // Đã ứng trước (physically paid out of pocket).
  final double consumed; // Phải chịu (actual consumption / share).
  final double net; // paid - consumed.
  final int joinedCount; // Bills this member participated in.
  final int totalBillsCount; // Total bills (for participation rate).
  final double participationRate; // 0..1

  const MemberStat({
    required this.participantId,
    required this.name,
    required this.paid,
    required this.consumed,
    required this.net,
    required this.joinedCount,
    required this.totalBillsCount,
    required this.participationRate,
  });
}

/// One category row of the breakdown section.
class CategoryStat {
  final String categoryId;
  final String label;
  final String emoji;
  final double total;
  final double percent; // 0..1 of total spent.

  const CategoryStat({
    required this.categoryId,
    required this.label,
    required this.emoji,
    required this.total,
    required this.percent,
  });
}

/// Full analytical snapshot of a trip: aggregate KPIs, member audit, category
/// distribution and the debt-settlement plan.
class TripSummaryStats {
  final double totalSpent;
  final double averagePerMember;
  final int expenseCount;
  final TopExpense? topExpense;
  final List<CategoryStat> categories;
  final List<MemberStat> members;
  final List<Settlement> settlements;
  final int paidSettlementsCount;

  const TripSummaryStats({
    required this.totalSpent,
    required this.averagePerMember,
    required this.expenseCount,
    required this.topExpense,
    required this.categories,
    required this.members,
    required this.settlements,
    required this.paidSettlementsCount,
  });

  TripSummaryStats copyWith({
    double? totalSpent,
    double? averagePerMember,
    int? expenseCount,
    TopExpense? topExpense,
    List<CategoryStat>? categories,
    List<MemberStat>? members,
    List<Settlement>? settlements,
    int? paidSettlementsCount,
  }) {
    return TripSummaryStats(
      totalSpent: totalSpent ?? this.totalSpent,
      averagePerMember: averagePerMember ?? this.averagePerMember,
      expenseCount: expenseCount ?? this.expenseCount,
      topExpense: topExpense ?? this.topExpense,
      categories: categories ?? this.categories,
      members: members ?? this.members,
      settlements: settlements ?? this.settlements,
      paidSettlementsCount: paidSettlementsCount ?? this.paidSettlementsCount,
    );
  }
}