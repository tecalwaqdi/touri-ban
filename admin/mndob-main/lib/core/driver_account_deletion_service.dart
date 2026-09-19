import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '/auth/firebase_auth/apple_auth.dart' as apple_auth;
import '/auth/firebase_auth/google_auth.dart';
import '/backend/cloud_functions/cloud_functions.dart';

/// Driver account deletion client — UI + re-auth + callable only.
abstract final class DriverAccountDeletionService {
  DriverAccountDeletionService._();

  static final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: const ['profile', 'email']);

  static String? primaryProviderId(User user) {
    final providers = user.providerData.map((p) => p.providerId).toList();
    if (providers.contains('password')) return 'password';
    if (providers.contains('google.com')) return 'google.com';
    if (providers.contains('apple.com')) return 'apple.com';
    if (providers.contains('phone')) return 'phone';
    return providers.isEmpty ? null : providers.first;
  }

  static Future<bool> reauthenticate(
    BuildContext context, {
    required Future<String?> Function() askPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final provider = primaryProviderId(user);
    try {
      switch (provider) {
        case 'password':
          final email = user.email;
          if (email == null || email.isEmpty) return false;
          final password = await askPassword();
          if (password == null || password.isEmpty) return false;
          await user.reauthenticateWithCredential(
            EmailAuthProvider.credential(email: email, password: password),
          );
          return true;
        case 'google.com':
          if (kIsWeb) {
            await user.reauthenticateWithPopup(GoogleAuthProvider());
            return true;
          }
          await signOutWithGoogle().catchError((_) => null);
          final account = await _googleSignIn.signIn();
          if (account == null) return false;
          final auth = await account.authentication;
          await user.reauthenticateWithCredential(
            GoogleAuthProvider.credential(
              idToken: auth.idToken,
              accessToken: auth.accessToken,
            ),
          );
          return true;
        case 'apple.com':
          if (kIsWeb) {
            final provider = OAuthProvider('apple.com')
              ..addScope('email')
              ..addScope('name');
            await user.reauthenticateWithPopup(provider);
            return true;
          }
          final rawNonce = apple_auth.generateNonce();
          final nonce = apple_auth.sha256ofString(rawNonce);
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );
          await user.reauthenticateWithCredential(
            OAuthProvider('apple.com').credential(
              idToken: appleCredential.identityToken,
              rawNonce: rawNonce,
              accessToken: appleCredential.authorizationCode,
            ),
          );
          return true;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('DriverAccountDeletionService reauth: $e');
      return false;
    }
  }

  static Future<DriverDeletionResult> requestDeletion() async {
    final res = await makeCloudCall(
      'requestAccountDeletion',
      {'confirm': true},
      timeout: const Duration(seconds: 120),
    );

    if (res['ok'] == true) {
      return DriverDeletionResult.success(idempotent: res['idempotent'] == true);
    }

    final details = res['details'];
    String? typed = res['errorCode'] as String?;
    if (details is Map && details['code'] is String) {
      typed = details['code'] as String;
    }
    final message = (res['error'] as String?) ?? 'ACCOUNT_DELETION_FAILED';
    typed ??= message.startsWith('ACCOUNT_DELETION_') ? message : null;

    return DriverDeletionResult.failure(
      message: message,
      firebaseCode: res['code'] as String?,
      typedCode: typed,
    );
  }

  static String userFacingMessage(
    DriverDeletionResult result, {
    required bool arabic,
  }) {
    final code = result.typedCode ?? result.message;
    switch (code) {
      case 'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP':
        return arabic
            ? 'لا يمكن حذف الحساب أثناء وجود رحلة نشطة.'
            : 'You cannot delete the account while a trip is active.';
      case 'ACCOUNT_DELETION_BLOCKED_PENDING_SETTLEMENT':
        return arabic
            ? 'لا يمكن حذف الحساب لوجود تسوية مالية معلقة.'
            : 'You cannot delete the account while a settlement is pending.';
      case 'ACCOUNT_DELETION_BLOCKED_PENDING_WALLET_TX':
        return arabic
            ? 'لا يمكن حذف الحساب لوجود عملية محفظة قيد المعالجة.'
            : 'You cannot delete the account while a wallet transaction is pending.';
      case 'ACCOUNT_DELETION_BLOCKED_WALLET_BALANCE':
        return arabic
            ? 'لا يمكن حذف الحساب بينما توجد مستحقات أو رصيد في المحفظة. تواصل مع الدعم لتسوية الحساب أولاً.'
            : 'You cannot delete the account while the wallet has a balance. Contact support to settle first.';
      default:
        return arabic
            ? 'تعذر حذف الحساب حالياً. حاول مرة أخرى أو تواصل مع الدعم.'
            : 'Account deletion could not be completed. Try again or contact support.';
    }
  }
}

class DriverDeletionResult {
  DriverDeletionResult._({
    required this.ok,
    this.idempotent = false,
    this.message,
    this.firebaseCode,
    this.typedCode,
  });

  factory DriverDeletionResult.success({bool idempotent = false}) =>
      DriverDeletionResult._(ok: true, idempotent: idempotent);

  factory DriverDeletionResult.failure({
    required String message,
    String? firebaseCode,
    String? typedCode,
  }) =>
      DriverDeletionResult._(
        ok: false,
        message: message,
        firebaseCode: firebaseCode,
        typedCode: typedCode,
      );

  final bool ok;
  final bool idempotent;
  final String? message;
  final String? firebaseCode;
  final String? typedCode;
}
