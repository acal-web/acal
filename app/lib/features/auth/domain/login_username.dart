import 'package:acalapp/shared/formatters/document_formatter.dart';

/// Normalizes what the user typed into the single login field, which serves
/// both staff (free-form username, may contain '.'/'-') and sócios (CPF/CNPJ,
/// stored digits-only). Only strips formatting when doing so yields a valid
/// document length (11/14 digits) — otherwise the raw text is returned
/// untouched, so a staff username is never mangled.
String normalizeLoginUsername(String raw) {
  final trimmed = raw.trim();
  final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  return DocumentKind.fromDigits(digitsOnly) != null ? digitsOnly : trimmed;
}
