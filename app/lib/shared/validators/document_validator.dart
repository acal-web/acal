import 'package:acalapp/shared/formatters/document_formatter.dart';

String? validateDocument(String? value, DocumentKind documentKind) {
  final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

  if (digits.isEmpty) return 'Obrigatório';

  if (digits.length != documentKind.maxDigits) {
    return documentKind == DocumentKind.cpf
        ? 'CPF deve ter 11 dígitos'
        : 'CNPJ deve ter 14 dígitos';
  }

  if (!isValidDocument(digits, documentKind)) {
    return documentKind == DocumentKind.cpf ? 'CPF inválido' : 'CNPJ inválido';
  }

  return null;
}
