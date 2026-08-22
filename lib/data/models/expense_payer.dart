/// One payer of an expense. An expense can have multiple payers, each with the
/// exact amount they contributed (the sum of payer amounts equals the expense
/// total).
class ExpensePayer {
  final String id;
  final String expenseId;
  final String participantId;
  final double amount;

  const ExpensePayer({
    required this.id,
    required this.expenseId,
    required this.participantId,
    required this.amount,
  });

  ExpensePayer copyWith({String? expenseId, double? amount}) {
    return ExpensePayer(
      id: id,
      expenseId: expenseId ?? this.expenseId,
      participantId: participantId,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'participant_id': participantId,
      'amount': amount,
    };
  }

  factory ExpensePayer.fromMap(Map<String, dynamic> map) {
    return ExpensePayer(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      participantId: map['participant_id'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}
