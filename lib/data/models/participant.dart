/// A member of a trip, with optional avatar color, contact info and a
/// per-person note (e.g. "Paid deposit early", "Vegetarian discount").
class Participant {
  final String id;
  final String tripId;
  final String name;
  final int color; // ARGB int, used for the avatar.
  final String? contact; // Optional phone / email / handle.
  final String? note; // Per-person note attached to this trip.
  final DateTime createdAt;

  const Participant({
    required this.id,
    required this.tripId,
    required this.name,
    required this.color,
    this.contact,
    this.note,
    required this.createdAt,
  });

  Participant copyWith({
    String? name,
    int? color,
    String? contact,
    String? note,
  }) {
    return Participant(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      color: color ?? this.color,
      contact: contact ?? this.contact,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'color': color,
      'contact': contact,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      name: map['name'] as String,
      color: (map['color'] as int?) ?? 0xFFE57373,
      contact: map['contact'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
