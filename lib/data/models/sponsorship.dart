/// A sponsorship (Tài trợ) towards a trip: a fixed amount that reduces the
/// group's total expenses before each member's split is calculated.
///
/// A sponsor can be an existing member of the group ([memberId] set) or an
/// external sponsor / "Mạnh thường quân" ([memberId] is null and the sponsor
/// is identified only by [sponsorName]).
class Sponsorship {
  final String id;
  final String tripId;
  final String sponsorName;
  final String? memberId; // Null when an external sponsor.
  final double amount;
  final String? note;
  final DateTime createdAt;

  const Sponsorship({
    required this.id,
    required this.tripId,
    required this.sponsorName,
    this.memberId,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  bool get isInternal => memberId != null;

  Sponsorship copyWith({
    String? sponsorName,
    String? memberId,
    double? amount,
    String? note,
  }) {
    return Sponsorship(
      id: id,
      tripId: tripId,
      sponsorName: sponsorName ?? this.sponsorName,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'sponsor_name': sponsorName,
      'member_id': memberId,
      'amount': amount,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Sponsorship.fromMap(Map<String, dynamic> map) {
    return Sponsorship(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      sponsorName: map['sponsor_name'] as String,
      memberId: map['member_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}