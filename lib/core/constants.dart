import '../l10n/app_localizations.dart';

class ExpenseCategory {
  static const sports = 'sports'; // 🏸 Thể thao & Sân bãi
  static const dining = 'dining'; // 🍜 Ăn uống & Tiệc tùng
  static const cafe = 'cafe'; // ☕ Cafe & Trà đá
  static const transport = 'transport'; // 🚗 Di chuyển
  static const housing = 'housing'; // 🏠 Sinh hoạt & Tiền phòng
  static const entertainment = 'entertainment'; // 🎟️ Vui chơi & Giải trí
  static const shopping = 'shopping'; // 🛍️ Mua sắm chung
  static const other = 'other'; // 📦 Khác

  static const all = [
    sports,
    dining,
    cafe,
    transport,
    housing,
    entertainment,
    shopping,
    other,
  ];

  static const icons = {
    sports: '🏸',
    dining: '🍜',
    cafe: '☕',
    transport: '🚗',
    housing: '🏠',
    entertainment: '🎟️',
    shopping: '🛍️',
    other: '📦',
  };

  /// Category ids persisted before the multi-purpose overhaul (trip-era
  /// presets). Used to map legacy rows onto the current set.
  static const legacyAliases = {
    'Food': dining,
    'Transport': transport,
    'Lodging': housing,
    'Activities': entertainment,
    'Other': other,
  };

  /// Fallback English labels (used by pure Dart code outside the widget tree).
  static const labels = {
    sports: 'Sports & Court',
    dining: 'Dining & Drinks',
    cafe: 'Coffee & Hangouts',
    transport: 'Transport',
    housing: 'Housing & Utilities',
    entertainment: 'Entertainment',
    shopping: 'Shared Shopping',
    other: 'Other',
  };

  static String label(String category) => labels[category] ?? 'Other';

  /// Maps a stored category id onto the current set: legacy ids are aliased,
  /// anything unknown falls back to [other] so stale/foreign rows never break
  /// the dashboard.
  static String normalize(String category) {
    if (all.contains(category)) return category;
    return legacyAliases[category] ?? other;
  }

  /// Locale-aware label for UI strings.
  static String localizedLabel(String category, AppLocalizations l10n) {
    return switch (category) {
      sports => l10n.categorySports,
      dining => l10n.categoryDining,
      cafe => l10n.categoryCafe,
      transport => l10n.categoryTransport,
      housing => l10n.categoryHousing,
      entertainment => l10n.categoryEntertainment,
      shopping => l10n.categoryShopping,
      _ => l10n.categoryOther,
    };
  }

  static const fallback = other;
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
