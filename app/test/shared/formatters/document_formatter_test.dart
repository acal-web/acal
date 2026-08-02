import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maskDocument', () {
    test('formats a partial and a full CPF', () {
      expect(maskDocument('123', DocumentKind.cpf), '123');
      expect(maskDocument('123456789', DocumentKind.cpf), '123.456.789');
      expect(maskDocument('12345678909', DocumentKind.cpf), '123.456.789-09');
    });

    test('formats a partial and a full CNPJ', () {
      expect(maskDocument('11', DocumentKind.cnpj), '11');
      expect(maskDocument('11222333', DocumentKind.cnpj), '11.222.333');
      expect(maskDocument('11222333000181', DocumentKind.cnpj), '11.222.333/0001-81');
    });
  });

  group('DocumentKind.fromDigits', () {
    test('infers CPF for 11 digits and CNPJ for 14, otherwise null', () {
      expect(DocumentKind.fromDigits('12345678909'), DocumentKind.cpf);
      expect(DocumentKind.fromDigits('11222333000181'), DocumentKind.cnpj);
      expect(DocumentKind.fromDigits('123'), isNull);
    });
  });

  group('isValidCpf', () {
    test('accepts a real CPF check-digit sequence', () {
      expect(isValidCpf('11144477735'), isTrue);
    });

    test('rejects a wrong length, wrong check digit, or repeated digit', () {
      expect(isValidCpf('123'), isFalse);
      expect(isValidCpf('11144477736'), isFalse);
      expect(isValidCpf('11111111111'), isFalse);
    });
  });

  group('isValidCnpj', () {
    test('accepts a real CNPJ check-digit sequence', () {
      expect(isValidCnpj('11222333000181'), isTrue);
    });

    test('rejects a wrong length, wrong check digit, or repeated digit', () {
      expect(isValidCnpj('123'), isFalse);
      expect(isValidCnpj('11222333000180'), isFalse);
      expect(isValidCnpj('00000000000000'), isFalse);
    });
  });

  group('DocumentInputFormatter', () {
    TextEditingValue apply(DocumentKind kind, String text) {
      final formatter = DocumentInputFormatter(kind);
      final value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
      return formatter.formatEditUpdate(TextEditingValue.empty, value);
    }

    test('masks CPF input live and caps it at 11 digits', () {
      expect(apply(DocumentKind.cpf, '12345678909').text, '123.456.789-09');
      expect(apply(DocumentKind.cpf, '123456789099999').text, '123.456.789-09');
    });

    test('masks CNPJ input live and caps it at 14 digits', () {
      expect(apply(DocumentKind.cnpj, '11222333000181').text, '11.222.333/0001-81');
      expect(apply(DocumentKind.cnpj, '1122233300018199999').text, '11.222.333/0001-81');
    });

    test('strips non-digit characters before masking', () {
      expect(apply(DocumentKind.cpf, '123.456.789-09').text, '123.456.789-09');
    });
  });
}
