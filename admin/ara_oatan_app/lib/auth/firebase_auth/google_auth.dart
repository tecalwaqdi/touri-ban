import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web client ID (client_type 3) — مطلوب لـ Firebase Auth على Android
/// ولعرض اختيار حسابات Google على الجهاز.
const kGoogleWebClientId =
    '638010533068-0mrbpin1uol2mbe25fs875p7uvsv6d1g.apps.googleusercontent.com';

final touryGoogleSignIn = GoogleSignIn(
  scopes: const ['profile', 'email'],
  serverClientId: kGoogleWebClientId,
);

/// يفتح منتقي حسابات Google على الجهاز ويُرجع الحساب المختار.
Future<GoogleSignInAccount?> pickGoogleAccount({
  bool forcePicker = false,
}) async {
  if (kIsWeb) {
    return null;
  }

  if (!forcePicker) {
    final silent = await touryGoogleSignIn.signInSilently();
    if (silent != null) {
      return silent;
    }
  }

  // لا نستدعي signOut قبل signIn — يسبب DEVELOPER_ERROR على بعض أجهزة Samsung.
  return touryGoogleSignIn.signIn();
}

/// تسجيل الدخول إلى Firebase باستخدام حساب Google محدد.
Future<UserCredential?> firebaseSignInWithGoogleAccount(
  GoogleSignInAccount account,
) async {
  var auth = await account.authentication;
  if (auth.idToken == null && auth.accessToken == null) {
    throw FirebaseAuthException(
      code: 'invalid-credential',
      message:
          'Google ID token missing. Register Android SHA-1 in Firebase Console.',
    );
  }

  // على Android قد ينتهي idToken — نعيد طلب الاعتماد مرة واحدة عند الحاجة.
  if (auth.idToken == null) {
    final refreshed = await touryGoogleSignIn.signIn();
    if (refreshed == null) {
      return null;
    }
    auth = await refreshed.authentication;
    if (auth.idToken == null && auth.accessToken == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message:
            'Google ID token missing after refresh. Check Firebase SHA-1 setup.',
      );
    }
  }

  final credential = GoogleAuthProvider.credential(
    idToken: auth.idToken,
    accessToken: auth.accessToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}

/// تدفق كامل: منتقي الحسابات ثم Firebase (للويب: نافذة Google مباشرة).
Future<UserCredential?> googleSignInWithAccount({
  bool forceAccountPicker = true,
}) async {
  if (kIsWeb) {
    return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }

  final account = await pickGoogleAccount(forcePicker: forceAccountPicker);
  if (account == null) {
    return null;
  }

  return firebaseSignInWithGoogleAccount(account);
}

/// يُستدعى من FirebaseAuthManager — يعرض منتقي الحسابات دائماً.
Future<UserCredential?> googleSignInFunc() =>
    googleSignInWithAccount(forceAccountPicker: true);

Future<void> signOutWithGoogle() => touryGoogleSignIn.signOut();
