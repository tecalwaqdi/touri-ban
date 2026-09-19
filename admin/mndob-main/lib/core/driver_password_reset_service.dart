import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/driver_auth_validation_service.dart';

/// Login-time password reset via 6-digit email OTP (Resend), not Firebase link mail.
abstract final class DriverPasswordResetService {
  DriverPasswordResetService._();

  static String? _challengeId;

  static String localeFromLanguageCode(String? code) {
    final c = (code ?? 'en').trim().toLowerCase();
    if (c.startsWith('ar')) return 'ar';
    return 'en';
  }

  static Future<Map<String, dynamic>> requestOtp({
    required String emailRaw,
    required String locale,
  }) async {
    final email = DriverAuthValidationService.normalizeEmail(emailRaw);
    if (email == null) {
      throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'INVALID_EMAIL',
      );
    }

    final res = await makeCloudCall('requestPasswordResetOtp', {
      'email': email,
      'locale': locale,
    });
    if (res['ok'] != true) {
      throw FirebaseFunctionsException(
        code: (res['code'] as String?) ?? 'internal',
        message: (res['error'] as String?) ?? 'OTP_REQUEST_FAILED',
      );
    }

    final id = res['challengeId'] as String?;
    if (id != null && id.isNotEmpty) {
      _challengeId = id;
    } else {
      _challengeId = null;
    }
    debugPrint(
      'DriverPasswordResetService: OTP requested masked=${res['emailMasked']}',
    );
    return res;
  }

  static Future<void> confirmReset({
    required String code,
    required String newPassword,
  }) async {
    final id = _challengeId;
    if (id == null || id.isEmpty) {
      throw FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'RESET_SESSION_MISSING',
      );
    }
    final trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'OTP_INVALID',
      );
    }
    final pwdError = DriverAuthValidationService.validatePassword(newPassword);
    if (pwdError != null) {
      throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'WEAK_PASSWORD',
      );
    }

    final res = await makeCloudCall('confirmPasswordResetOtp', {
      'challengeId': id,
      'code': trimmed,
      'newPassword': newPassword,
    });
    if (res['ok'] != true) {
      throw FirebaseFunctionsException(
        code: (res['code'] as String?) ?? 'internal',
        message: (res['error'] as String?) ?? 'RESET_FAILED',
      );
    }
    _challengeId = null;
  }

  @visibleForTesting
  static void debugClearChallenge() => _challengeId = null;
}
