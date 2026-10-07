import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/core/driver_country_service.dart';
import '/core/driver_phone_number_service.dart';

/// Secure Auth updates for approved drivers (phone / email / password).
/// Never writes Auth-sensitive values via Firestore-only paths.
abstract final class DriverSecureAccountUpdateService {
  DriverSecureAccountUpdateService._();

  static Future<String?> reauthenticateWithPassword(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return 'Please sign in again to continue.';
    }
    final email = (user.email ?? '').trim();
    if (email.isEmpty) {
      return 'Email is required to reauthenticate.';
    }
    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[DriverSecureAccount] reauth ${e.code}');
      return 'Incorrect password. Please try again.';
    } catch (e) {
      debugPrint('[DriverSecureAccount] reauth $e');
      return 'Something went wrong. Please try again.';
    }
  }

  static Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final reauth = await reauthenticateWithPassword(currentPassword);
    if (reauth != null) return reauth;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Please sign in again to continue.';
    try {
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[DriverSecureAccount] password ${e.code}');
      if (e.code == 'weak-password') {
        return 'Password is too weak. Use at least 6 characters.';
      }
      return 'Could not update password. Please try again.';
    } catch (e) {
      debugPrint('[DriverSecureAccount] password $e');
      return 'Could not update password. Please try again.';
    }
  }

  static Future<String?> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final email = newEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }
    final reauth = await reauthenticateWithPassword(currentPassword);
    if (reauth != null) return reauth;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Please sign in again to continue.';
    try {
      await user.verifyBeforeUpdateEmail(email);
      await UserRecord.collection.doc(user.uid).set(
        {
          'email': email,
          'uid': user.uid,
          'profile_update_source': 'driver_app_auth_email',
          'profile_updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[DriverSecureAccount] email ${e.code}');
      if (e.code == 'email-already-in-use') {
        return 'This email is already in use.';
      }
      return 'Could not update email. Please try again.';
    } catch (e) {
      debugPrint('[DriverSecureAccount] email $e');
      return 'Could not update email. Please try again.';
    }
  }

  /// Mirrors E.164 phone to Firestore allowlisted contact fields only.
  static Future<String?> updatePhoneNumber({
    required String rawPhone,
    String? currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return 'Please sign in again to continue.';
    }
    final iso = DriverCountryService.currentIso2() ?? 'SA';
    final e164 = DriverPhoneNumberService.toE164(raw: rawPhone, iso2: iso);
    if (e164 == null || e164.isEmpty) {
      return 'Enter a valid phone number.';
    }
    if (currentPassword != null && currentPassword.isNotEmpty) {
      final reauth = await reauthenticateWithPassword(currentPassword);
      if (reauth != null) return reauth;
    }
    try {
      await UserRecord.collection.doc(user.uid).set(
        {
          'phone_number': e164,
          'uid': user.uid,
          'profile_update_source': 'driver_app_auth_phone',
          'profile_updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return null;
    } on FirebaseException catch (e) {
      debugPrint('[DriverSecureAccount] phone ${e.code} ${e.message}');
      return 'Could not update phone number. Please try again.';
    } catch (e) {
      debugPrint('[DriverSecureAccount] phone $e');
      return 'Could not update phone number. Please try again.';
    }
  }
}
