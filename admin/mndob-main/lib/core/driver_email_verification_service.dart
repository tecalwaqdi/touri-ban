import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth email verification helpers for Registration V2.
///
/// Source of truth is always `user.emailVerified` after `reload()`.
/// Never write a client-owned "email verified" boolean to Firestore.
abstract final class DriverEmailVerificationService {
  DriverEmailVerificationService._();

  static const Duration resendCooldown = Duration(seconds: 60);

  static DateTime? _lastSentAt;

  static Duration? get remainingCooldown {
    final last = _lastSentAt;
    if (last == null) return null;
    final left = resendCooldown - DateTime.now().difference(last);
    if (left.isNegative || left == Duration.zero) return null;
    return left;
  }

  static bool get canResend => remainingCooldown == null;

  static Future<void> sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Sign in required',
      );
    }
    if (user.emailVerified) return;
    if (!canResend) {
      throw FirebaseAuthException(
        code: 'too-many-requests',
        message: 'RESEND_COOLDOWN',
      );
    }
    await user.sendEmailVerification();
    _lastSentAt = DateTime.now();
    debugPrint('DriverEmailVerificationService: verification email sent');
  }

  /// Reload Auth user and return Firebase's emailVerified flag.
  static Future<bool> reloadAndCheckVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    return refreshed?.emailVerified == true;
  }
}
