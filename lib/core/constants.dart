import '../l10n/app_localizations.dart';

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

  /// Fallback English labels (used by pure Dart code outside the widget tree).
  static const labels = {
    food: 'Food',
    transport: 'Transport',
    lodging: 'Lodging',
    activities: 'Activities',
    others: 'Other',
  };

  static String label(String category) => labels[category] ?? 'Other';

  /// Locale-aware label for UI strings.
  static String localizedLabel(String category, AppLocalizations l10n) {
    return switch (category) {
      food => l10n.categoryFood,
      transport => l10n.categoryTransport,
      lodging => l10n.categoryLodging,
      activities => l10n.categoryActivities,
      _ => l10n.categoryOther,
    };
  }

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
