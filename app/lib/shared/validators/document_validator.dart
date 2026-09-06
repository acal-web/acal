import 'package:acalapp/shared/formatters/digits.dart';
import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:acalapp/shared/validators/required_validator.dart';

String? validateDocument(String? value, DocumentKind documentKind) {
  final digits = value == null ? '' : onlyDigits(value);

  if (digits.isEmpty) return requiredFieldMessage;

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
