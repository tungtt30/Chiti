class ExpenseCategory {
  static const food = 'Food';
  static const transport = 'Transport';
  static const lodging = 'Lodging';
  static const activities = 'Activities';
  static const others = 'Other';

  static const all = [food, transport, lodging, activities, others];

  static const icons = {
    food: '🍽️',
    transport: '🚗',
    lodging: '🏨',
    activities: '🎭',
    others: '📦',
  };

  /// Vietnamese labels for reporting (Bảng thống kê).
  static const labels = {
    food: 'Ăn uống',
    transport: 'Di chuyển',
    lodging: 'Lưu trú',
    activities: 'Vui chơi',
    others: 'Khác',
  };

  static String label(String category) => labels[category] ?? 'Khác';

  static const fallback = others;
}

/// How the total of an expense is divided among participants.
class SplitMode {
  static const equal = 'equal';
  static const customAmount = 'custom_amount';
  static const customWeight = 'custom_weight';

  static const all = [equal, customAmount, customWeight];
}

/// Currencies offered when creating a trip.
const kSupportedCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'VND',
  'THB',
  'KRW',
  'CNY',
  'AUD',
  'CAD',
];

/// Default avatar colors for participants (cycled in order).
const kParticipantColors = <int>[
  0xFFE57373, // red 300
  0xFFBA68C8, // purple 300
  0xFF9575CD, // deep purple 300
  0xFF64B5F6, // blue 300
  0xFF4DB6AC, // teal 300
  0xFF81C784, // green 300
  0xFFFFB74D, // orange 300
  0xFFA1887F, // brown 300
];
