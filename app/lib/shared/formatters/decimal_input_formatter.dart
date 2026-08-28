import 'package:flutter/services.dart';

/// Restricts input to a non-negative decimal number — digits with at most
/// one decimal point (e.g. water meter readings: "1234.5"). Rejects any
/// edit that would produce something else (letters, multiple dots, a
/// leading minus, etc.) by reverting to the previous value.
class DecimalInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (_pattern.hasMatch(newValue.text)) return newValue;
    return oldValue;
  }
}
