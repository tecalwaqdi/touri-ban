import '/auth/base_auth_user_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/user_record.dart';
import '/core/toury_phone_util.dart';

/// Single semantic source for profile completeness / booking readiness.
abstract final class TouryProfileCompleteness {
  TouryProfileCompleteness._();

  /// Firestore `user/{uid}` is canonical for phone, name, photo.
  /// Firebase Auth is canonical for [emailVerified] only.
  static bool hasUsablePhone({
    UserRecord? user,
    BaseAuthUser? authUser,
  }) {
    final doc = user ?? currentUserDocument;
    final auth = authUser ?? currentUser;
    return TouryPhoneUtil.hasUsablePhone(
      phoneNumber: doc?.phoneNumber,
      phoneN: doc?.phoneN,
      authPhone: auth?.phoneNumber,
    );
  }

  static bool hasDisplayName({UserRecord? user, BaseAuthUser? authUser}) {
    final doc = user ?? currentUserDocument;
    final auth = authUser ?? currentUser;
    final name = (doc?.displayName ?? auth?.displayName ?? '').trim();
    return name.isNotEmpty;
  }

  static bool hasProfilePhoto({UserRecord? user, BaseAuthUser? authUser}) {
    final doc = user ?? currentUserDocument;
    final auth = authUser ?? currentUser;
    final url = (doc?.photoUrl ?? auth?.photoUrl ?? '').trim();
    return url.isNotEmpty;
  }

  static bool isEmailVerified({BaseAuthUser? authUser}) =>
      authUser?.emailVerified ?? currentUserEmailVerified;

  static bool isBookingProfileReady({
    UserRecord? user,
    BaseAuthUser? authUser,
  }) =>
      hasUsablePhone(user: user, authUser: authUser);

  static List<String> missingRequiredFields({
    UserRecord? user,
    BaseAuthUser? authUser,
  }) {
    final missing = <String>[];
    if (!hasUsablePhone(user: user, authUser: authUser)) {
      missing.add('phone');
    }
    if (!hasDisplayName(user: user, authUser: authUser)) {
      missing.add('displayName');
    }
    return missing;
  }
}
