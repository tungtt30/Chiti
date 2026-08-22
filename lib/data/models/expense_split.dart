/// One participant's portion of an expense (how much they owe).
///
/// In equal mode [weight] is null; in weighted mode [weight] keeps the raw
/// share the user entered so it can be re-edited, and [amount] is the resolved
/// money obligation. [note] is an optional per-person inline note for the
/// expense.
class ExpenseSplit {
  final String id;
  final String expenseId;
  final String participantId;
  final double amount;
  final double? weight;
  final String? note;

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.participantId,
    required this.amount,
    this.weight,
    this.note,
  });

  ExpenseSplit copyWith({
    String? expenseId,
    double? amount,
    double? weight,
    String? note,
  }) {
    return ExpenseSplit(
      id: id,
      expenseId: expenseId ?? this.expenseId,
      participantId: participantId,
      amount: amount ?? this.amount,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'participant_id': participantId,
      'amount': amount,
      'weight': weight,
      'note': note,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      participantId: map['participant_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      note: map['note'] as String?,
    );
  }
}
