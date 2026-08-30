import 'package:flutter/services.dart';

/// Formats a currency amount field in real time with `,` thousands separators
/// while keeping up to 2 decimal places (e.g. `100000` -> `100,000`,
/// `1000000.5` -> `1,000,000.5`).
///
/// The integer part is grouped manually (not via `intl`) so arbitrarily long
/// inputs never overflow an `int`, and cursor position is preserved when
/// inserting/deleting digits in the middle of the field.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  static final RegExp _clean = RegExp(r'[^0-9.]');

  /// Groups the integer part of [text] with commas, keeping any decimal part
  /// intact. Non-numeric characters are stripped.
  static String formatThousands(String text) {
    final cleaned = _cleanAll(text);
    final dotIndex = cleaned.indexOf('.');
    final intPart = dotIndex == -1 ? cleaned : cleaned.substring(0, dotIndex);
    final decPart = dotIndex == -1 ? '' : cleaned.substring(dotIndex);
    return '${_group(intPart)}$decPart';
  }

  static String _cleanAll(String text) {
    var cleaned = text.replaceAll(_clean, '');
    // Keep only the first dot (already grouped text has exactly one).
    if (cleaned.contains('.')) {
      final firstDot = cleaned.indexOf('.');
      cleaned = cleaned.substring(0, firstDot + 1) +
          cleaned.substring(firstDot + 1).replaceAll('.', '');
    }
    return cleaned;
  }

  static String _group(String digits) {
    if (digits.isEmpty) return '';
    final sb = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) sb.write(',');
      sb.write(digits[i]);
    }
    return sb.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final cleaned = _cleanAll(newValue.text);
    if (cleaned.isEmpty) return const TextEditingValue();

    // Clamp the decimal part to 2 digits.
    final dotIndex = cleaned.indexOf('.');
    final limited = dotIndex != -1 && cleaned.length > dotIndex + 3
        ? cleaned.substring(0, dotIndex + 3)
        : cleaned;

    final formatted = formatThousands(limited);

    // Map the selection back onto the formatted string: count how many
    // digits (and the dot) precede the caret in the new value, then place the
    // caret after that many "content" characters in the formatted result.
    final caretContent = _contentBeforeCaret(newValue, formatted);
    final newOffset = _offsetAfterContent(formatted, caretContent);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  /// Number of digits/dot characters in [value] before its selection start.
  static int _contentBeforeCaret(
    TextEditingValue value,
    String formatted,
  ) {
    final caret = value.selection.isValid
        ? value.selection.baseOffset
        : value.text.length;
    final prefix = value.text.substring(0, caret.clamp(0, value.text.length));
    var count = 0;
    for (final ch in prefix.split('')) {
      if (RegExp(r'[0-9.]').hasMatch(ch)) count++;
    }
    return count;
  }

  /// Offset in [formatted] after [contentCount] digits/dots.
  static int _offsetAfterContent(String formatted, int contentCount) {
    var count = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9.]').hasMatch(formatted[i])) {
        count++;
        if (count == contentCount) return i + 1;
      }
    }
    return formatted.length;
  }
}