/// Email / password validation for driver Login & Register (no Firestore).
abstract final class DriverAuthValidationService {
  DriverAuthValidationService._();

  static final RegExp _email = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  /// Trim + lowercase; empty → null.
  static String? normalizeEmail(String? raw) {
    final v = (raw ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (v.isEmpty) return null;
    return v;
  }

  /// Returns i18n message key or null if valid.
  static String? validateEmail(String? raw) {
    final email = normalizeEmail(raw);
    if (email == null) {
      return 'Please enter a valid email';
    }
    if (!_email.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Returns i18n message key or null if valid.
  static String? validatePassword(
    String? raw, {
    int minLength = 6,
    bool requireConfirm = false,
    String? confirm,
  }) {
    final password = raw ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < minLength) {
      return 'Password must be at least 6 characters';
    }
    if (requireConfirm && password != (confirm ?? '')) {
      return 'Passwords do not match';
    }
    return null;
  }
}
