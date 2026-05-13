// lib/app/utils/validators.dart

class Validators {
  Validators._(); // static-only class

  static final RegExp _emailRegex =
  RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false);

  static String? email(String value) {
    final t = value.trim();
    if (t.isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(t)) return 'Please enter a valid email address.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? fullName(String value) {
    final t = value.trim();
    if (t.isEmpty) return 'Full name is required.';
    if (t.length < 2) return 'Please enter your full name.';
    return null;
  }
}
