import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '/auth/firebase_auth/apple_auth.dart' as apple_auth;
import '/auth/firebase_auth/google_auth.dart';

/// Client-side account deletion: re-auth + callable only.
/// Server (`requestAccountDeletion`) is the source of truth.
abstract final class TouryAccountDeletionService {
  TouryAccountDeletionService._();

  static String? primaryProviderId(User user) {
    final providers = user.providerData.map((p) => p.providerId).toList();
    if (providers.contains('password')) return 'password';
    if (providers.contains('google.com')) return 'google.com';
    if (providers.contains('apple.com')) return 'apple.com';
    if (providers.contains('phone')) return 'phone';
    return providers.isEmpty ? null : providers.first;
  }

  /// Returns true if re-auth succeeded or was not required.
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
          final cred = EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          await user.reauthenticateWithCredential(cred);
          return true;
        case 'google.com':
          if (kIsWeb) {
            final cred =
                await user.reauthenticateWithPopup(GoogleAuthProvider());
            return cred.user != null;
          }
          final account = await pickGoogleAccount(forcePicker: true);
          if (account == null) return false;
          final auth = await account.authentication;
          final cred = GoogleAuthProvider.credential(
            idToken: auth.idToken,
            accessToken: auth.accessToken,
          );
          await user.reauthenticateWithCredential(cred);
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
          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
            accessToken: appleCredential.authorizationCode,
          );
          await user.reauthenticateWithCredential(oauthCredential);
          return true;
        case 'phone':
          return false;
        default:
          return false;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('TouryAccountDeletionService reauth: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('TouryAccountDeletionService reauth: $e');
      return false;
    }
  }

  static Future<AccountDeletionResult> requestDeletion() async {
    try {
      final response =
          await FirebaseFunctions.instanceFor(region: 'us-central1')
              .httpsCallable(
                'requestAccountDeletion',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 120),
                ),
              )
              .call({'confirm': true});
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      if (data['ok'] == true) {
        return AccountDeletionResult.success(
          idempotent: data['idempotent'] == true,
        );
      }
      return AccountDeletionResult.failure(
        message: (data['error'] as String?) ?? 'ACCOUNT_DELETION_FAILED',
        typedCode: 'ACCOUNT_DELETION_FAILED',
      );
    } on FirebaseFunctionsException catch (e) {
      String? typed;
      final details = e.details;
      if (details is Map && details['code'] is String) {
        typed = details['code'] as String;
      }
      final message = e.message ?? 'ACCOUNT_DELETION_FAILED';
      typed ??= message.startsWith('ACCOUNT_DELETION_') ? message : null;
      return AccountDeletionResult.failure(
        message: message,
        firebaseCode: e.code,
        typedCode: typed,
      );
    } catch (e) {
      return AccountDeletionResult.failure(
        message: e.toString(),
        typedCode: 'ACCOUNT_DELETION_FAILED',
      );
    }
  }

  static String userFacingMessage(AccountDeletionResult result) {
    final code = result.typedCode ?? result.message;
    switch (code) {
      case 'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP':
        return 'account_deletion_blocked_active_trip';
      case 'ACCOUNT_DELETION_BLOCKED_PENDING_SETTLEMENT':
        return 'account_deletion_blocked_pending_settlement';
      case 'ACCOUNT_DELETION_BLOCKED_PENDING_WALLET_TX':
        return 'account_deletion_blocked_pending_wallet_tx';
      case 'ACCOUNT_DELETION_BLOCKED_WALLET_BALANCE':
        return 'account_deletion_blocked_wallet_balance';
      case 'unauthenticated':
        return 'account_deletion_sign_in_required';
      default:
        if (result.firebaseCode == 'unauthenticated') {
          return 'account_deletion_sign_in_required';
        }
        return 'account_deletion_failed_generic';
    }
  }
}

class AccountDeletionResult {
  AccountDeletionResult._({
    required this.ok,
    this.idempotent = false,
    this.message,
    this.firebaseCode,
    this.typedCode,
  });

  factory AccountDeletionResult.success({bool idempotent = false}) =>
      AccountDeletionResult._(ok: true, idempotent: idempotent);

  factory AccountDeletionResult.failure({
    required String message,
    String? firebaseCode,
    String? typedCode,
  }) =>
      AccountDeletionResult._(
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
