/// A persisted debt-simplification transaction produced by the settlement
/// engine: [fromParticipantId] pays [amount] to [toParticipantId].
///
/// [isPaid] lets the group mark a transfer as completed.
class Settlement {
  final String id;
  final String tripId;
  final String fromParticipantId;
  final String toParticipantId;
  final double amount;
  final bool isPaid;
  final DateTime createdAt;

  const Settlement({
    required this.id,
    required this.tripId,
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amount,
    required this.isPaid,
    required this.createdAt,
  });

  Settlement copyWith({bool? isPaid}) {
    return Settlement(
      id: id,
      tripId: tripId,
      fromParticipantId: fromParticipantId,
      toParticipantId: toParticipantId,
      amount: amount,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'from_participant_id': fromParticipantId,
      'to_participant_id': toParticipantId,
      'amount': amount,
      'is_paid': isPaid ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      fromParticipantId: map['from_participant_id'] as String,
      toParticipantId: map['to_participant_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      isPaid: ((map['is_paid'] as int?) ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
