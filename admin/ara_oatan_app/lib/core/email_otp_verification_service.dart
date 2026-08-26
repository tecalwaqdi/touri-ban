import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/backend/cloud_functions/cloud_functions.dart';

/// Email verification presentation mode.
///
/// Final gate SoT is always Firebase Auth [User.emailVerified].
/// This flag only selects how verification is requested/presented.
enum EmailVerificationMode {
  emailOtp,
  emailLink,
}

/// Shared Customer/Driver Email OTP client (6-digit).
///
/// Never generates or validates OTP locally. Never writes emailVerified.
abstract final class EmailOtpVerificationService {
  EmailOtpVerificationService._();

  /// Default product mode for Customer release: Firebase email **link**.
  /// 6-digit OTP CF remains in repo as DORMANT / SAFE_TO_REMOVE.
  static EmailVerificationMode mode = EmailVerificationMode.emailLink;

  static String? _challengeId;
  static DateTime? _lastSentAt;
  static const Duration resendCooldown = Duration(seconds: 60);

  static String? get challengeId => _challengeId;

  static Duration? get remainingCooldown {
    final last = _lastSentAt;
    if (last == null) return null;
    final left = resendCooldown - DateTime.now().difference(last);
    if (left.isNegative || left == Duration.zero) return null;
    return left;
  }

  static bool get canResend => remainingCooldown == null;

  static String maskEmail(String? email) {
    final e = (email ?? '').trim();
    final at = e.indexOf('@');
    if (at < 1) return '***';
    final local = e.substring(0, at);
    final domain = e.substring(at + 1);
    final shown = local.substring(0, local.length < 2 ? local.length : 2);
    return '$shown***@$domain';
  }

  static Future<bool> reloadAndCheckVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified == true;
  }

  /// Request a new OTP. Returns challenge metadata (never the code).
  static Future<Map<String, dynamic>> requestOtp({String locale = 'en'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'AUTHENTICATION_REQUIRED',
      );
    }
    if (user.emailVerified) {
      return {'alreadyVerified': true, 'verified': true};
    }
    if (mode == EmailVerificationMode.emailLink) {
      await user.sendEmailVerification();
      _lastSentAt = DateTime.now();
      return {'ok': true, 'mode': 'email_link'};
    }
    if (!canResend) {
      throw FirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'RESEND_COOLDOWN',
      );
    }

    final res = await makeCloudCall('requestEmailVerificationOtp', {
      'locale': locale,
    });
    if (res['error'] != null) {
      throw FirebaseFunctionsException(
        code: (res['code'] as String?) ?? 'internal',
        message: (res['error'] as String?) ?? 'OTP_REQUEST_FAILED',
      );
    }
    if (res['alreadyVerified'] == true) {
      return res;
    }
    final id = res['challengeId'] as String?;
    if (id == null || id.isEmpty) {
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'OTP_REQUEST_FAILED',
      );
    }
    _challengeId = id;
    _lastSentAt = DateTime.now();
    debugPrint('EmailOtpVerificationService: OTP requested challenge=$id');
    return res;
  }

  /// Verify 6-digit code via backend; then reload Auth SoT.
  static Future<bool> verifyOtp(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (user.emailVerified) return true;

    final trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'INVALID_CODE',
      );
    }
    final id = _challengeId;
    if (id == null || id.isEmpty) {
      throw FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'NO_CHALLENGE',
      );
    }

    final res = await makeCloudCall('verifyEmailVerificationOtp', {
      'challengeId': id,
      'code': trimmed,
    });
    if (res['error'] != null) {
      throw FirebaseFunctionsException(
        code: (res['code'] as String?) ?? 'invalid-argument',
        message: (res['error'] as String?) ?? 'INVALID_CODE',
      );
    }
    await user.reload();
    final ok = FirebaseAuth.instance.currentUser?.emailVerified == true;
    if (ok) {
      _challengeId = null;
    }
    return ok;
  }

  @visibleForTesting
  static void debugReset() {
    _challengeId = null;
    _lastSentAt = null;
  }

  @visibleForTesting
  static void debugSetChallenge(String id) {
    _challengeId = id;
  }
}
