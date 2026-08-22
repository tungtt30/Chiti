/// One participant who joined an expense (junction between `expenses` and
/// `participants`). [shareAmount] is the exact amount this person owes for the
/// expense. A member with no row did not participate and owes nothing.
class ExpenseParticipant {
  final String id;
  final String expenseId;
  final String participantId;
  final double shareAmount;

  const ExpenseParticipant({
    required this.id,
    required this.expenseId,
    required this.participantId,
    required this.shareAmount,
  });

  ExpenseParticipant copyWith({
    String? expenseId,
    double? shareAmount,
  }) {
    return ExpenseParticipant(
      id: id,
      expenseId: expenseId ?? this.expenseId,
      participantId: participantId,
      shareAmount: shareAmount ?? this.shareAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'participant_id': participantId,
      'share_amount': shareAmount,
    };
  }

  factory ExpenseParticipant.fromMap(Map<String, dynamic> map) {
    return ExpenseParticipant(
      id: map['id'] as String,
      expenseId: map['expense_id'] as String,
      participantId: map['participant_id'] as String,
      shareAmount: (map['share_amount'] as num).toDouble(),
    );
  }
}