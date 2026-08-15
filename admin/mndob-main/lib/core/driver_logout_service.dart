import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/driver_live_location_service.dart';
import '/core/driver_registration_draft.dart';
import '/custom_code/actions/index.dart' as actions;

/// Safe logout: stop streams, sign out, clear user-scoped local state.
abstract final class DriverLogoutService {
  DriverLogoutService._();

  static Future<void> logout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      if (currentUserReference != null &&
          !(FirebaseAuth.instance.currentUser?.isAnonymous ?? true)) {
        try {
          await currentUserReference!.update({'ngl': false});
        } catch (e) {
          debugPrint('DriverLogoutService offline flag: $e');
        }
      }
    } catch (_) {}

    try {
      DriverLiveLocationService.stopIdleSync(force: true);
    } catch (e) {
      debugPrint('DriverLogoutService stop location: $e');
    }

    try {
      await actions.stopTracking();
    } catch (e) {
      debugPrint('DriverLogoutService stopTracking: $e');
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('DriverLogoutService deleteToken: $e');
    }

    try {
      FFAppState().revOrder = null;
    } catch (_) {}

    try {
      await authManager.signOut();
    } catch (e) {
      debugPrint('DriverLogoutService signOut: $e');
      await FirebaseAuth.instance.signOut();
    }

    currentUserDocument = null;

    // Clear only this user's draft; keep guest draft / language / onboarding.
    if (uid != null && uid.isNotEmpty) {
      await DriverRegistrationDraft.clearForUid(uid);
    }
  }
}
