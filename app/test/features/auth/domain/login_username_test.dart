import 'package:acalapp/features/auth/domain/login_username.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeLoginUsername', () {
    test('strips punctuation from a formatted CPF', () {
      expect(normalizeLoginUsername('123.456.789-09'), '12345678909');
    });

    test('strips punctuation from a formatted CNPJ', () {
      expect(normalizeLoginUsername('12.345.678/0001-95'), '12345678000195');
    });

    test('leaves an already digits-only CPF untouched', () {
      expect(normalizeLoginUsername('12345678909'), '12345678909');
    });

    test('leaves a staff username with dots/dashes untouched', () {
      expect(normalizeLoginUsername('joao.silva'), 'joao.silva');
      expect(normalizeLoginUsername('maria-costa'), 'maria-costa');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeLoginUsername('  administrador  '), 'administrador');
    });

    test('leaves a numeric string of the wrong length untouched', () {
      expect(normalizeLoginUsername('123-456'), '123-456');
    });
  });
}
