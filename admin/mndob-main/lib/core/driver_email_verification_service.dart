import 'package:firebase_auth/firebase_auth.dart';

import '/core/email_otp_verification_service.dart';

/// Driver email verification — Firebase Auth email **link** only.
///
/// Policy:
/// - `EMAIL_VERIFICATION = FIREBASE_EMAIL_LINK`
/// - `EMAIL_VERIFIED_SOT = FirebaseAuth.currentUser.emailVerified`
/// - Do NOT use Brevo / 6-digit email OTP for drivers.
abstract final class DriverEmailVerificationService {
  DriverEmailVerificationService._();

  static const Duration resendCooldown = EmailOtpVerificationService.resendCooldown;

  static Duration? get remainingCooldown =>
      EmailOtpVerificationService.remainingCooldown;

  static bool get canResend => EmailOtpVerificationService.canResend;

  static String maskEmail(String? email) =>
      EmailOtpVerificationService.maskEmail(email);

  /// Sends Firebase Auth verification email (`sendEmailVerification`).
  static Future<void> sendVerificationEmail({String locale = 'en'}) async {
    // Force link mode for drivers regardless of shared helper defaults.
    EmailOtpVerificationService.mode = EmailVerificationMode.emailLink;
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

  /// Before submit callables: reload user + refresh ID token.
  static Future<bool> reloadRefreshTokenAndCheckVerified() =>
      EmailOtpVerificationService.reloadRefreshTokenAndCheckVerified();
}
