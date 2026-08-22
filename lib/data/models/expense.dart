/// A logged expense: total [amount], the single person who paid ([payerId]),
/// and the subset of participants who joined via [ExpenseParticipant] rows.
class Expense {
  final String id;
  final String tripId;
  final String title;
  final double amount;
  final String payerId;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.payerId,
    required this.createdAt,
  });

  Expense copyWith({
    String? title,
    double? amount,
    String? payerId,
  }) {
    return Expense(
      id: id,
      tripId: tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      payerId: payerId ?? this.payerId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'payer_id': payerId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      payerId: map['payer_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}