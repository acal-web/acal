import 'package:flutter/services.dart';

enum DocumentKind {
  cpf(11, [ 3, 6, 9 ], [ '.', '.', '-' ]),
  cnpj(14, [ 2, 5, 8, 12 ], [ '.', '.', '/', '-' ]);

  const DocumentKind(this.maxDigits, this._groupBreaks, this._separators);

  final int maxDigits;
  final List<int> _groupBreaks;
  final List<String> _separators;

  /// Infers CPF/CNPJ from how many digits a raw document has. Returns null
  /// when the length doesn't match either (e.g. still being typed).
  static DocumentKind? fromDigits(String digits) => switch (digits.length) {
        11 => cpf,
        14 => cnpj,
        _ => null,
      };
}

/// Applies the CPF ("000.000.000-00") or CNPJ ("00.000.000/0000-00") mask to
/// a raw digit string, however many digits it currently has.
String maskDocument(String digits, DocumentKind kind) {
  final buffer = StringBuffer();
  var breakIndex = 0;

  for (var i = 0; i < digits.length; i++) {
    if (breakIndex < kind._groupBreaks.length && i == kind._groupBreaks[breakIndex]) {
      buffer.write(kind._separators[breakIndex]);
      breakIndex++;
    }
    buffer.write(digits[i]);
  }

  return buffer.toString();
}

int _checkDigit(String digits, List<int> weights) {
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    sum += int.parse(digits[i]) * weights[i];
  }
  final remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}

bool _allSameDigit(String digits) => digits.split('').toSet().length == 1;

/// Validates a CPF by its check digits (not just its length) — the same
/// algorithm the API uses.
bool isValidCpf(String digits) {
  if (digits.length != 11 || _allSameDigit(digits)) return false;

  final d1 = _checkDigit(digits.substring(0, 9), [ 10, 9, 8, 7, 6, 5, 4, 3, 2 ]);
  final d2 = _checkDigit(digits.substring(0, 9) + d1.toString(), [ 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 ]);
  return d1 == int.parse(digits[9]) && d2 == int.parse(digits[10]);
}

/// Validates a CNPJ by its check digits (not just its length) — the same
/// algorithm the API uses.
bool isValidCnpj(String digits) {
  if (digits.length != 14 || _allSameDigit(digits)) return false;

  final d1 = _checkDigit(digits.substring(0, 12), [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]);
  final d2 = _checkDigit(digits.substring(0, 12) + d1.toString(), [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]);
  return d1 == int.parse(digits[12]) && d2 == int.parse(digits[13]);
}

bool isValidDocument(String digits, DocumentKind kind) =>
    kind == DocumentKind.cpf ? isValidCpf(digits) : isValidCnpj(digits);

/// Live mask for a document [TextField] — reformats as CPF or CNPJ (chosen
/// by [kind]) as the user types, capping input at the kind's digit count.
class DocumentInputFormatter extends TextInputFormatter {
  DocumentInputFormatter(this.kind);

  final DocumentKind kind;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > kind.maxDigits ? digits.substring(0, kind.maxDigits) : digits;
    final formatted = maskDocument(capped, kind);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
