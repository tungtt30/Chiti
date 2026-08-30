import '../../core/settlement_calculator.dart' show SettlementMode;

class Trip {
  final String id;
  final String name;
  final String destination;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  /// Designated Host / Treasurer (Thủ quỹ) for host-mode settlement, or null
  /// when none is assigned (legacy trips / no members yet).
  final String? hostId;

  /// How this trip settles balances: `'host'` or `'peer_to_peer'`.
  final String settlementMode;

  const Trip({
    required this.id,
    required this.name,
    this.destination = '',
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.hostId,
    this.settlementMode = 'host',
  });

  Trip copyWith({
    String? name,
    String? destination,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? hostId,
    String? settlementMode,
    bool clearHost = false,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      hostId: clearHost ? null : (hostId ?? this.hostId),
      settlementMode: settlementMode ?? this.settlementMode,
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
      'host_id': hostId,
      'settlement_mode': settlementMode,
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
      hostId: map['host_id'] as String?,
      settlementMode: (map['settlement_mode'] as String?) ??
          SettlementMode.host.dbValue,
    );
  }
}