import 'package:acalapp/shared/formatters/decimal_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecimalInputFormatter', () {
    final formatter = DecimalInputFormatter();

    TextEditingValue value(String text) => TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

    test('accepts digits and a single decimal point', () {
      expect(formatter.formatEditUpdate(value('123'), value('1234')).text, '1234');
      expect(formatter.formatEditUpdate(value('123'), value('123.')).text, '123.');
      expect(formatter.formatEditUpdate(value('123.'), value('123.5')).text, '123.5');
      expect(formatter.formatEditUpdate(value(''), value('')).text, '');
    });

    test('rejects letters, keeping the previous value', () {
      final old = value('123');
      expect(formatter.formatEditUpdate(old, value('123a')).text, '123');
    });

    test('rejects a second decimal point, keeping the previous value', () {
      final old = value('123.4');
      expect(formatter.formatEditUpdate(old, value('123.4.5')).text, '123.4');
    });

    test('rejects a minus sign, keeping the previous value', () {
      final old = value('');
      expect(formatter.formatEditUpdate(old, value('-1')).text, '');
    });
  });
}
