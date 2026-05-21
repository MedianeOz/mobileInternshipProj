// lib/app/utils/password_analyzer.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PasswordStrength { empty, weak, fair, strong, veryStrong }

class PasswordStrengthResult {
  final PasswordStrength level;
  final List<Color> bars;
  final String label;
  final Color labelColor;
  final Color borderColor;
  final int length;
  final double entropyBits;
  final bool hasUppercase;
  final bool hasNumbers;
  final bool hasSymbols;
  final bool hasDictionaryWord;

  const PasswordStrengthResult({
    required this.level,
    required this.bars,
    required this.label,
    required this.labelColor,
    required this.borderColor,
    required this.length,
    required this.entropyBits,
    required this.hasUppercase,
    required this.hasNumbers,
    required this.hasSymbols,
    required this.hasDictionaryWord,
  });

  bool get hasPassword => level != PasswordStrength.empty;

  bool get isVeryStrong => level == PasswordStrength.veryStrong;

  String get dictionaryLabel => hasDictionaryWord ? 'Detected' : 'Clean';

  String? get improvementTip {
    if (isVeryStrong) {
      return null;
    }
    if (length < 12) {
      return 'Use at least 12 characters';
    }
    if (!hasUppercase) {
      return 'Add uppercase letters to increase entropy';
    }
    if (!hasNumbers) {
      return 'Add numbers to increase entropy';
    }
    if (!hasSymbols) {
      return 'Add a special character (!@#\$) to increase entropy';
    }
    if (hasDictionaryWord) {
      return 'Avoid common words and predictable phrases';
    }
    return 'Use more variety to increase entropy';
  }
}

class PasswordAnalyzer {
  PasswordAnalyzer._();

  static const Color _empty = Color(0xFF2A2D3A);
  static const Color _red = Color(0xFFFF4444);
  static const Color _amber = Color(0xFFE5A000);
  static const Color _teal = Color(0xFF00E5A0);
  static const Color _green = Color(0xFF00C853);

  static const List<String> _commonWords = [
    'password',
    'letmein',
    'welcome',
    'admin',
    'login',
    'qwerty',
    'abc',
    'monkey',
    'dragon',
    'master',
    'hello',
    'shadow',
    'sunshine',
    'princess',
    'football',
    'baseball',
    'soccer',
    'trustno',
    'iloveyou',
    'superman',
  ];

  static PasswordStrengthResult evaluate(String value) {
    final length = value.length;
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasNumbers = value.contains(RegExp(r'\d'));
    final hasSymbols = value.contains(RegExp(r'[^A-Za-z0-9]'));
    final normalized = value.toLowerCase();
    final hasDictionaryWord = _commonWords.any(
      (word) => word.length > 4 && normalized.contains(word),
    );
    final entropyBits = _calculateEntropyBits(
      length: length,
      hasLowercase: hasLowercase,
      hasUppercase: hasUppercase,
      hasNumbers: hasNumbers,
      hasSymbols: hasSymbols,
    );

    if (value.isEmpty) {
      return PasswordStrengthResult(
        level: PasswordStrength.empty,
        bars: List.generate(4, (_) => _empty),
        label: '',
        labelColor: Colors.transparent,
        borderColor: _empty,
        length: 0,
        entropyBits: 0,
        hasUppercase: false,
        hasNumbers: false,
        hasSymbols: false,
        hasDictionaryWord: false,
      );
    }

    int score = 0;
    if (length >= 12) score += 2;
    if (length >= 8 && length < 12) score++;
    if (hasLowercase && hasUppercase) score++;
    if (hasNumbers) score++;
    if (hasSymbols) score++;
    if (!hasDictionaryWord) score++;
    if (entropyBits >= 72) score++;

    if (score <= 2) {
      return PasswordStrengthResult(
        level: PasswordStrength.weak,
        bars: [_red, _empty, _empty, _empty],
        label: 'Weak',
        labelColor: _red,
        borderColor: _red,
        length: length,
        entropyBits: entropyBits,
        hasUppercase: hasUppercase,
        hasNumbers: hasNumbers,
        hasSymbols: hasSymbols,
        hasDictionaryWord: hasDictionaryWord,
      );
    }
    if (score <= 3) {
      return PasswordStrengthResult(
        level: PasswordStrength.fair,
        bars: [_amber, _amber, _empty, _empty],
        label: 'Fair',
        labelColor: _amber,
        borderColor: _amber,
        length: length,
        entropyBits: entropyBits,
        hasUppercase: hasUppercase,
        hasNumbers: hasNumbers,
        hasSymbols: hasSymbols,
        hasDictionaryWord: hasDictionaryWord,
      );
    }
    if (score <= 5) {
      return PasswordStrengthResult(
        level: PasswordStrength.strong,
        bars: [_teal, _teal, _teal, _empty],
        label: 'Strong',
        labelColor: _teal,
        borderColor: _teal,
        length: length,
        entropyBits: entropyBits,
        hasUppercase: hasUppercase,
        hasNumbers: hasNumbers,
        hasSymbols: hasSymbols,
        hasDictionaryWord: hasDictionaryWord,
      );
    }
    return PasswordStrengthResult(
      level: PasswordStrength.veryStrong,
      bars: List.generate(4, (_) => _green),
      label: 'Very Strong',
      labelColor: _green,
      borderColor: _green,
      length: length,
      entropyBits: entropyBits,
      hasUppercase: hasUppercase,
      hasNumbers: hasNumbers,
      hasSymbols: hasSymbols,
      hasDictionaryWord: hasDictionaryWord,
    );
  }

  static double _calculateEntropyBits({
    required int length,
    required bool hasLowercase,
    required bool hasUppercase,
    required bool hasNumbers,
    required bool hasSymbols,
  }) {
    var charsetSize = 0;
    if (hasLowercase) {
      charsetSize += 26;
    }
    if (hasUppercase) {
      charsetSize += 26;
    }
    if (hasNumbers) {
      charsetSize += 10;
    }
    if (hasSymbols) {
      charsetSize += 32;
    }
    if (charsetSize == 0) {
      return 0;
    }
    return length * (math.log(charsetSize) / math.ln2);
  }
}
