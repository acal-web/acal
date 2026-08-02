import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Formats a reais amount the way it should be displayed — "R\$ 1.234,56".
String formatBRL(double value) => _brl.format(value);

/// Parses text produced by [CurrencyInputFormatter] (or [formatBRL]) back
/// into its numeric reais amount.
double parseBRL(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? 0 : int.parse(digits) / 100;
}

/// Live "money mask" for a [TextField] — digits fill in from the right as
/// the user types, like a calculator (e.g. typing "1234" shows "R\$ 12,34").
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final formatted = _brl.format(int.parse(digits) / 100);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
