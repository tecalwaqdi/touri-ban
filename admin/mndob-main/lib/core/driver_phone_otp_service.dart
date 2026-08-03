import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Phone OTP for registration: obtains a [PhoneAuthCredential] without
/// signing in (so email/password account can be created, then linked).
abstract final class DriverPhoneOtpService {
  DriverPhoneOtpService._();

  static Future<DriverPhoneOtpSendResult> sendCode({
    required String e164Phone,
    int? forceResendingToken,
  }) async {
    final completer = Completer<DriverPhoneOtpSendResult>();
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164Phone,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          if (!completer.isCompleted) {
            completer.complete(
              DriverPhoneOtpSendResult.autoVerified(credential),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('DriverPhoneOtpService failed: ${e.code}');
          if (!completer.isCompleted) {
            completer.complete(DriverPhoneOtpSendResult.failed(e));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              DriverPhoneOtpSendResult.codeSent(
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Keep waiting for manual entry; do not fail the send.
          if (!completer.isCompleted) {
            completer.complete(
              DriverPhoneOtpSendResult.codeSent(
                verificationId: verificationId,
                resendToken: null,
              ),
            );
          }
        },
      );
    } catch (e, st) {
      debugPrint('DriverPhoneOtpService.sendCode: $e\n$st');
      if (!completer.isCompleted) {
        completer.complete(
          DriverPhoneOtpSendResult.failed(
            e is FirebaseAuthException
                ? e
                : FirebaseAuthException(
                    code: 'unknown',
                    message: e.toString(),
                  ),
          ),
        );
      }
    }
    return completer.future;
  }

  static PhoneAuthCredential credential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
  }

  /// Link phone to the current email user after account create.
  static Future<void> linkToCurrentUser(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'No current user to link phone',
      );
    }
    await user.linkWithCredential(credential);
  }

  /// True when Firebase Phone Auth provider is disabled / unavailable.
  /// Registration must still proceed via email + password.
  static bool isPhoneProviderUnavailable(FirebaseAuthException? error) {
    if (error == null) return false;
    switch (error.code) {
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
      case 'app-not-authorized':
      case 'ERROR_OPERATION_NOT_ALLOWED':
        return true;
      default:
        return false;
    }
  }
}

class DriverPhoneOtpSendResult {
  const DriverPhoneOtpSendResult._({
    required this.ok,
    this.verificationId,
    this.resendToken,
    this.autoCredential,
    this.error,
  });

  factory DriverPhoneOtpSendResult.codeSent({
    required String verificationId,
    int? resendToken,
  }) =>
      DriverPhoneOtpSendResult._(
        ok: true,
        verificationId: verificationId,
        resendToken: resendToken,
      );

  factory DriverPhoneOtpSendResult.autoVerified(PhoneAuthCredential c) =>
      DriverPhoneOtpSendResult._(ok: true, autoCredential: c);

  factory DriverPhoneOtpSendResult.failed(FirebaseAuthException e) =>
      DriverPhoneOtpSendResult._(ok: false, error: e);

  final bool ok;
  final String? verificationId;
  final int? resendToken;
  final PhoneAuthCredential? autoCredential;
  final FirebaseAuthException? error;
}
