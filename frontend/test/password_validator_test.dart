import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator.analyze (OWASP A07)', () {
    test('Empty password should be critical and invalid', () {
      final result = PasswordValidator.analyze('');
      expect(result.isValid, isFalse);
      expect(result.score, equals(0));
      expect(result.level, equals(PasswordSecurityLevel.critical));
      expect(result.errorMessage, isNotNull);
    });

    test('Password with only lowercase letters and length < 8 should fail multiple criteria', () {
      final result = PasswordValidator.analyze('short');
      expect(result.isValid, isFalse);
      expect(result.requirements.firstWhere((r) => r.label.contains('8')).isMet, isFalse);
      expect(result.requirements.firstWhere((r) => r.label.contains('maiúscula')).isMet, isFalse);
      expect(result.requirements.firstWhere((r) => r.label.contains('minúscula')).isMet, isTrue);
      expect(result.requirements.firstWhere((r) => r.label.contains('Número')).isMet, isFalse);
      expect(result.requirements.firstWhere((r) => r.label.contains('especial')).isMet, isFalse);
    });

    test('Password lacking special characters should be invalid', () {
      final result = PasswordValidator.analyze('Password123');
      expect(result.isValid, isFalse);
      expect(result.requirements.firstWhere((r) => r.label.contains('especial')).isMet, isFalse);
    });

    test('Password lacking numbers should be invalid', () {
      final result = PasswordValidator.analyze('Password!@#');
      expect(result.isValid, isFalse);
      expect(result.requirements.firstWhere((r) => r.label.contains('Número')).isMet, isFalse);
    });

    test('Password lacking uppercase letters should be invalid', () {
      final result = PasswordValidator.analyze('password123!');
      expect(result.isValid, isFalse);
      expect(result.requirements.firstWhere((r) => r.label.contains('maiúscula')).isMet, isFalse);
    });

    test('Strong password meeting all 5 requirements should be valid and armored', () {
      final result = PasswordValidator.analyze('CyberDef!2026');
      expect(result.isValid, isTrue);
      expect(result.score, equals(5));
      expect(result.level, equals(PasswordSecurityLevel.armored));
      expect(result.errorMessage, isNull);
      expect(result.requirements.every((r) => r.isMet), isTrue);

      final userPwdResult = PasswordValidator.analyze('Antonio@2092!');
      expect(userPwdResult.isValid, isTrue);
      expect(userPwdResult.score, equals(5));
      expect(userPwdResult.level, equals(PasswordSecurityLevel.armored));
      expect(userPwdResult.errorMessage, isNull);
      expect(userPwdResult.requirements.every((r) => r.isMet), isTrue);
    });

    test('Password exceeding 128 characters is rejected to mitigate Hash DoS', () {
      final longPassword = 'P@ssword1!${'A' * 125}';
      final result = PasswordValidator.analyze(longPassword);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('128 caracteres'));
    });
  });

  group('PasswordValidator.validateLogin', () {
    test('Rejects empty or whitespace-only password', () {
      final res = PasswordValidator.validateLogin('   ');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, isNotNull);
    });

    test('Rejects passwords shorter than 8 characters', () {
      final res = PasswordValidator.validateLogin('1234567');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('8 caracteres'));
    });

    test('Rejects passwords longer than 128 characters', () {
      final res = PasswordValidator.validateLogin('A' * 129);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('128 caracteres'));
    });

    test('Accepts valid password format of 8+ characters', () {
      final res = PasswordValidator.validateLogin('ValidTacticalPass123!');
      expect(res.isValid, isTrue);
      expect(res.errorMessage, isNull);
    });
  });
}
