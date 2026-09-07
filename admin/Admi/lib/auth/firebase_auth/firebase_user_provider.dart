import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../base_auth_user_provider.dart';

export '../base_auth_user_provider.dart';

class AdminArawatanFirebaseUser extends BaseAuthUser {
  AdminArawatanFirebaseUser(this.user);
  User? user;
  bool get loggedIn => user != null;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(
        uid: user?.uid,
        email: user?.email,
        displayName: user?.displayName,
        photoUrl: user?.photoURL,
        phoneNumber: user?.phoneNumber,
      );

  @override
  Future? delete() => user?.delete();

  @override
  Future? updateEmail(String email) async {
    await user?.verifyBeforeUpdateEmail(email);
  }

  @override
  Future? updatePassword(String newPassword) async {
    await user?.updatePassword(newPassword);
  }

  @override
  Future? sendEmailVerification() => user?.sendEmailVerification();

  @override
  bool get emailVerified {
    // Reloads the user when checking in order to get the most up to date
    // email verified status.
    if (loggedIn && !user!.emailVerified) {
      refreshUser();
    }
    return user?.emailVerified ?? false;
  }

  @override
  Future refreshUser() async {
    await FirebaseAuth.instance.currentUser
        ?.reload()
        .then((_) => user = FirebaseAuth.instance.currentUser);
  }

  static BaseAuthUser fromUserCredential(UserCredential userCredential) =>
      fromFirebaseUser(userCredential.user);
  static BaseAuthUser fromFirebaseUser(User? user) =>
      AdminArawatanFirebaseUser(user);
}

/// AUTH-NAV-P0: ignore transient authState nulls while the SDK still has a user,
/// and debounce null emissions when the app currently believes it is logged in.
///
/// Previous debounce used `user == null && !loggedIn`, which *skipped* the hold
/// exactly when a logged-in session saw a blip — causing GoRouter to treat
/// AUTH_LOADING blips as UNAUTHENTICATED and redirect to `/homePage`.
Stream<BaseAuthUser> adminArawatanFirebaseUserStream() =>
    FirebaseAuth.instance.authStateChanges().debounce((user) {
      final believedLoggedIn = currentUser?.loggedIn ?? false;
      if (user == null && believedLoggedIn) {
        return TimerStream(true, const Duration(milliseconds: 800));
      }
      return Stream.value(user);
    }).map<BaseAuthUser>(
      (user) {
        // SDK still has a session — do not publish a synthetic logout.
        if (user == null && FirebaseAuth.instance.currentUser != null) {
          final existing = currentUser;
          if (existing != null && existing.loggedIn) {
            return existing;
          }
          currentUser =
              AdminArawatanFirebaseUser(FirebaseAuth.instance.currentUser);
          return currentUser!;
        }
        currentUser = AdminArawatanFirebaseUser(user);
        return currentUser!;
      },
    );
