// lib/app/utils/password_analyzer.dart

import 'package:flutter/material.dart';

enum PasswordStrength { empty, weak, fair, strong, veryStrong }

class PasswordStrengthResult {
  final PasswordStrength level;
  final List<Color> bars;
  final String label;
  final Color labelColor;
  final Color borderColor;

  const PasswordStrengthResult({
    required this.level,
    required this.bars,
    required this.label,
    required this.labelColor,
    required this.borderColor,
  });
}

class PasswordAnalyzer {
  PasswordAnalyzer._();

  static const Color _empty   = Color(0xFF2A2D3A);
  static const Color _red     = Color(0xFFFF4444);
  static const Color _amber   = Color(0xFFE5A000);
  static const Color _teal    = Color(0xFF00E5A0);
  static const Color _green   = Color(0xFF00C853);

  static PasswordStrengthResult evaluate(String value) {
    if (value.isEmpty) {
      return PasswordStrengthResult(
        level: PasswordStrength.empty,
        bars: List.generate(4, (_) => _empty),
        label: '',
        labelColor: Colors.transparent,
        borderColor: _empty,
      );
    }

    int score = 0;
    if (value.length >= 10) score++;
    if (value.contains(RegExp(r'[a-z]')) &&
        value.contains(RegExp(r'[A-Z]'))) score++;
    if (value.split('').where((c) => RegExp(r'\d').hasMatch(c)).length >= 2) score++;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 1) {
      return PasswordStrengthResult(
        level: PasswordStrength.weak,
        bars: [_red, _empty, _empty, _empty],
        label: 'Weak',
        labelColor: _red,
        borderColor: _red,
      );
    }
    if (score == 2) {
      return PasswordStrengthResult(
        level: PasswordStrength.fair,
        bars: [_amber, _amber, _empty, _empty],
        label: 'Fair',
        labelColor: _amber,
        borderColor: _amber,
      );
    }
    if (score == 3) {
      return PasswordStrengthResult(
        level: PasswordStrength.strong,
        bars: [_teal, _teal, _teal, _empty],
        label: 'Strong',
        labelColor: _teal,
        borderColor: _teal,
      );
    }
    return PasswordStrengthResult(
      level: PasswordStrength.veryStrong,
      bars: List.generate(4, (_) => _green),
      label: 'Very Strong',
      labelColor: _green,
      borderColor: _green,
    );
  }
}
