import 'package:intl/intl.dart';

/// Currency code -> symbol lookup used when the locale-aware formatter would
/// produce an unexpected glyph.
const Map<String, String> _currencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'VND': '₫',
  'THB': '฿',
  'KRW': '₩',
  'CNY': '¥',
  'AUD': 'A\$',
  'CAD': 'C\$',
  'SGD': 'S\$',
  'MYR': 'RM',
  'IDR': 'Rp',
  'KHR': '៛',
  'LAK': '₭',
  'MMK': 'K',
};

String _currencySymbol(String code) => _currencySymbols[code] ?? code;

/// Human friendly money string, e.g. `₫150,000` or `\$25.00`.
String formatCurrency(double amount, String currencyCode) {
  return NumberFormat.currency(
    symbol: _currencySymbol(currencyCode),
    decimalDigits: currencyCode == 'VND' ? 0 : 2,
  ).format(amount);
}

/// Compact money string used inside table cells, e.g. `₫150,000`.
String formatMoney(double amount, String currencyCode) {
  return formatCurrency(amount, currencyCode);
}

/// e.g. `Aug 22, 2026`.
String formatDate(DateTime date) => DateFormat.yMMMd().format(date);

/// e.g. `2026-08-22` for input fields.
String formatDateCompact(DateTime date) =>
    DateFormat('yyyy-MM-dd').format(date);

/// e.g. `08/22/2026`.
String formatDateShort(DateTime date) => DateFormat('MM/dd/yyyy').format(date);
