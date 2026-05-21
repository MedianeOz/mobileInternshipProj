// lib/app/models/password_check_result.dart
//
// Holds the in-memory result of a Have I Been Pwned password range check.
// The plain password is intentionally not stored in this model.

class PasswordCheckResult {
  final bool isPwned;
  final int breachCount;

  const PasswordCheckResult({
    required this.isPwned,
    required this.breachCount,
  });
}
