class Trip {
  final String id;
  final String name;
  final String destination;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Trip copyWith({
    String? name,
    String? destination,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'currency': currency,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      name: map['name'] as String,
      destination: map['destination'] as String,
      currency: map['currency'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
