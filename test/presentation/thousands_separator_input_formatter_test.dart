import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chiti/presentation/widgets/thousands_separator_input_formatter.dart';

void main() {
  const formatter = ThousandsSeparatorInputFormatter();

  TextEditingValue apply(String text, {int cursor = -1}) {
    final newValue = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: cursor == -1 ? text.length : cursor,
      ),
    );
    return formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      newValue,
    );
  }

  group('formatThousands', () {
    test('groups with commas', () {
      expect(ThousandsSeparatorInputFormatter.formatThousands('100000'), '100,000');
      expect(
        ThousandsSeparatorInputFormatter.formatThousands('1000000'),
        '1,000,000',
      );
      expect(
        ThousandsSeparatorInputFormatter.formatThousands('1234567890'),
        '1,234,567,890',
      );
    });

    test('keeps decimals', () {
      expect(
        ThousandsSeparatorInputFormatter.formatThousands('1000000.5'),
        '1,000,000.5',
      );
      expect(
        ThousandsSeparatorInputFormatter.formatThousands('1000.25'),
        '1,000.25',
      );
    });

    test('handles already-grouped input idempotently', () {
      expect(
        ThousandsSeparatorInputFormatter.formatThousands('100,000'),
        '100,000',
      );
      expect(
        ThousandsSeparatorInputFormatter.formatThousands('1,000,000'),
        '1,000,000',
      );
    });

    test('strips non-numeric characters', () {
      expect(ThousandsSeparatorInputFormatter.formatThousands('ab12cd34'), '1,234');
      expect(ThousandsSeparatorInputFormatter.formatThousands('12a.5'), '12.5');
    });

    test('keeps only the first dot', () {
      expect(ThousandsSeparatorInputFormatter.formatThousands('12.3.4'), '12.34');
    });
  });

  group('formatEditUpdate', () {
    test('formats typed digits in real time', () {
      expect(apply('100000').text, '100,000');
      expect(apply('1000000').text, '1,000,000');
      expect(apply('1000').text, '1,000');
    });

    test('limits decimals to two places', () {
      expect(apply('1.999').text, '1.99');
      expect(apply('1000.505').text, '1,000.50');
    });

    test('empty input stays empty', () {
      expect(apply('').text, '');
    });

    test('only non-digit input yields empty field', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, '');
    });

    test('long digit runs do not overflow', () {
      expect(
        apply('99999999999999999999').text,
        '99,999,999,999,999,999,999',
      );
    });

    test('cursor stays at the end when typing at the end', () {
      final result = apply('1000000');
      expect(result.selection.baseOffset, result.text.length);
      expect(result.text, '1,000,000');
    });

    test('cursor is preserved when inserting in the middle', () {
      // "1,000" -> insert "5" before the last two digits -> "1,0500".
      final newValue = TextEditingValue(
        text: '10005',
        selection: TextSelection.collapsed(offset: 4),
      );
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1000'),
        newValue,
      );
      expect(result.text, '10,005');
      expect(result.selection.baseOffset, 5);
    });

    test('cursor is preserved when deleting in the middle', () {
      // "1,005" -> delete the "0" in the middle -> "105".
      final newValue = TextEditingValue(
        text: '105',
        selection: TextSelection.collapsed(offset: 2),
      );
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1005'),
        newValue,
      );
      expect(result.text, '105');
      expect(result.selection.baseOffset, 2);
    });
  });
}