import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/auth/base_auth_user_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/firebase_auth/firebase_user_provider.dart';
import '/backend/backend.dart';
import '/core/toury_google_auth_errors.dart';
import '/core/toury_google_sign_in.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';

/// يُزامن حالة المستخدم مع التطبيق فور نجاح Firebase Auth (بدون انتقال).
Future<void> tourySyncAuthState(
  BuildContext context,
  BaseAuthUser? user, {
  bool markUserActive = true,
}) async {
  if (user == null || user.uid == null) {
    return;
  }

  currentUser = user;
  final notifier = AppStateNotifier.instance;
  notifier.updateNotifyOnAuthChange(true);
  notifier.update(user);

  if (markUserActive) {
    try {
      final now = getCurrentTimestamp;
      await UserRecord.collection.doc(user.uid).set(
        {
          'actev_user': true,
          'last_login_at': now,
          'updated_time': now,
          if ((user.email ?? '').trim().isNotEmpty) 'email': user.email,
          if ((user.displayName ?? '').trim().isNotEmpty)
            'display_name': user.displayName,
          if ((user.photoUrl ?? '').trim().isNotEmpty) 'photo_url': user.photoUrl,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('tourySyncAuthState: user profile sync skipped: $e');
    }
  }
}

/// إكمال تسجيل الدخول والانتقال للتطبيق (تجاوز تأخير auth stream).
Future<void> touryFinishSignIn(
  BuildContext context,
  BaseAuthUser? user, {
  bool markUserActive = true,
}) async {
  if (user == null || user.uid == null) {
    return;
  }

  await tourySyncAuthState(
    context,
    user,
    markUserActive: markUserActive,
  );

  final navContext = appNavigatorKey.currentContext ?? context;
  if (!navContext.mounted) {
    return;
  }

  GoRouter.of(navContext).clearRedirectLocation();
  GoRouter.of(navContext).go('/');
}

/// تسجيل الدخول عبر Google — يفتح منتقي حسابات الجهاز ثم يُكمل الدخول.
Future<void> tourySignInWithGoogle(BuildContext context) async {
  GoRouter.of(context).prepareAuthEvent();

  try {
    final credential = await touryPickGoogleAccountAndSignIn(context);
    if (credential?.user == null) {
      return;
    }

    try {
      await maybeCreateUser(credential!.user!);
    } catch (e) {
      debugPrint('tourySignInWithGoogle: maybeCreateUser skipped: $e');
    }

    final user = AraOatanAppFirebaseUser.fromUserCredential(credential!);
    if (!context.mounted) return;
    await touryFinishSignIn(context, user);
  } catch (e) {
    debugPrint('tourySignInWithGoogle error: $e');
    if (!context.mounted || touryGoogleAuthWasCancelled(e)) {
      return;
    }
    final errorMsg = touryGoogleAuthErrorMessage(e, context);
    if (errorMsg.isEmpty) {
      return;
    }
    showSnackbar(context, errorMsg, type: TouryMessageType.error);
  }
}
