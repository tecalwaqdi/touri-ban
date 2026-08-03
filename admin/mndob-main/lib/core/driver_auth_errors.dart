import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/core/driver_i18n.dart';

/// Maps Firebase Auth (and related) error codes to localized user messages.
abstract final class DriverAuthErrors {
  DriverAuthErrors._();

  /// English keys — must exist in `assets/langs/*.json` (except `en`).
  static const Map<String, String> _codeToKey = {
    'user-not-found': 'Account not found.',
    'wrong-password': 'Incorrect email or password.',
    'invalid-credential': 'Incorrect email or password.',
    'INVALID_LOGIN_CREDENTIALS': 'Incorrect email or password.',
    'invalid-email': 'Please enter a valid email',
    'user-disabled': 'This account has been disabled.',
    'too-many-requests': 'Too many attempts. Please try again later.',
    'network-request-failed': 'No internet connection.',
    'operation-not-allowed': 'This sign-in method is not enabled.',
    'invalid-verification-code': 'Invalid verification code.',
    'session-expired': 'Verification code expired. Request a new one.',
    'account-exists-with-different-credential':
        'An account already exists with a different sign-in method.',
    'credential-already-in-use': 'This credential is already in use.',
    'email-already-in-use': 'This email is already registered.',
    'phone-number-already-exists': 'This phone number is already registered.',
    'missing-phone-number': 'Phone number is required.',
    'invalid-phone-number': 'Please enter a valid phone number',
    'quota-exceeded': 'SMS quota exceeded. Try again later.',
    'app-not-authorized': 'App is not authorized for this operation.',
    'captcha-check-failed': 'Security check failed. Try again.',
    'weak-password': 'Password must be at least 6 characters',
    'requires-recent-login': 'Please sign in again to continue.',
  };

  static String messageKeyForCode(String code) {
    final normalized = code.trim();
    return _codeToKey[normalized] ??
        'Something went wrong. Please try again.';
  }

  static String messageForException(Object error) {
    if (error is FirebaseAuthException) {
      return messageKeyForCode(error.code);
    }
    return 'Something went wrong. Please try again.';
  }

  static String localized(BuildContext context, Object error) {
    return driverTr(context, messageForException(error));
  }

  static void logSafely(Object error, [StackTrace? stack]) {
    if (error is FirebaseAuthException) {
      debugPrint(
        'DriverAuthErrors code=${error.code} message=${error.message}',
      );
    } else {
      debugPrint('DriverAuthErrors: $error');
    }
    if (stack != null) {
      debugPrint('$stack');
    }
  }
}
