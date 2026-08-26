import 'package:firebase_auth/firebase_auth.dart';

import '/core/email_otp_verification_service.dart';

/// Driver email verification facade — Email OTP by default.
///
/// Source of truth is always `user.emailVerified` after `reload()`.
abstract final class DriverEmailVerificationService {
  DriverEmailVerificationService._();

  static const Duration resendCooldown = EmailOtpVerificationService.resendCooldown;

  static Duration? get remainingCooldown =>
      EmailOtpVerificationService.remainingCooldown;

  static bool get canResend => EmailOtpVerificationService.canResend;

  static Future<void> sendVerificationEmail({String locale = 'en'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Sign in required',
      );
    }
    if (user.emailVerified) return;
    await EmailOtpVerificationService.requestOtp(locale: locale);
  }

  static Future<bool> reloadAndCheckVerified() =>
      EmailOtpVerificationService.reloadAndCheckVerified();

  static Future<bool> verifyOtp(String code) =>
      EmailOtpVerificationService.verifyOtp(code);
}
