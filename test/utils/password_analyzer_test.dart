import 'package:cybershield_app/app/utils/password_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordAnalyzer.evaluate', () {
    test('empty string returns empty result', () {
      final result = PasswordAnalyzer.evaluate('');

      expect(result.level, PasswordStrength.empty);
      expect(result.label, '');
      expect(result.entropyBits, 0);
    });

    test('single char is weak', () {
      expect(PasswordAnalyzer.evaluate('a').level, PasswordStrength.weak);
    });

    test('password detects dictionary word and is not strong', () {
      final result = PasswordAnalyzer.evaluate('password');

      expect(result.hasDictionaryWord, isTrue);
      expect(
        result.level,
        anyOf(PasswordStrength.weak, PasswordStrength.fair),
      );
    });

    test('123456 detects numbers only and is weak', () {
      final result = PasswordAnalyzer.evaluate('123456');

      expect(result.hasNumbers, isTrue);
      expect(result.hasUppercase, isFalse);
      expect(result.level, PasswordStrength.weak);
    });

    test('Hello1! is fair because it is short', () {
      expect(PasswordAnalyzer.evaluate('Hello1!').level, PasswordStrength.fair);
    });

    test('Hello123! is strong', () {
      expect(
        PasswordAnalyzer.evaluate('Hello123!').level,
        PasswordStrength.strong,
      );
    });

    test('complex long password is very strong', () {
      expect(
        PasswordAnalyzer.evaluate('C0mpl3x!Pass#99').level,
        PasswordStrength.veryStrong,
      );
    });

    test('entropyBits is positive for non-empty passwords', () {
      expect(PasswordAnalyzer.evaluate('a').entropyBits, greaterThan(0));
    });

    test('entropyBits increases as charset size grows', () {
      final lower = PasswordAnalyzer.evaluate('aaaaaaaaaaaa');
      final mixed = PasswordAnalyzer.evaluate('Aaaaaaaaaaaa');

      expect(mixed.entropyBits, greaterThan(lower.entropyBits));
    });

    test('bars length is always four', () {
      for (final value in ['', 'a', 'password', 'Hello123!', 'Xk9!mQ7@pL2#']) {
        expect(PasswordAnalyzer.evaluate(value).bars.length, 4);
      }
    });

    test('random-looking password has no dictionary word', () {
      expect(
        PasswordAnalyzer.evaluate('Xk9!mQ7@pL2#').hasDictionaryWord,
        isFalse,
      );
    });

    test('embedded common password is detected', () {
      expect(
        PasswordAnalyzer.evaluate('mypassword123').hasDictionaryWord,
        isTrue,
      );
    });

    test('improvementTip is null for very strong passwords', () {
      expect(PasswordAnalyzer.evaluate('C0mpl3x!Pass#99').improvementTip, null);
    });

    test('improvementTip suggests length when length is under 12', () {
      expect(PasswordAnalyzer.evaluate('Hello123!').improvementTip,
          'Use at least 12 characters');
    });

    test('improvementTip suggests uppercase when missing', () {
      expect(
        PasswordAnalyzer.evaluate('lowercase123!').improvementTip,
        'Add uppercase letters to increase entropy',
      );
    });

    test('hasPassword is false only for empty', () {
      expect(PasswordAnalyzer.evaluate('').hasPassword, isFalse);
      expect(PasswordAnalyzer.evaluate('a').hasPassword, isTrue);
    });

    test('isVeryStrong is true only for very strong', () {
      expect(PasswordAnalyzer.evaluate('C0mpl3x!Pass#99').isVeryStrong, isTrue);
      expect(PasswordAnalyzer.evaluate('Hello123!').isVeryStrong, isFalse);
    });
  });
}
