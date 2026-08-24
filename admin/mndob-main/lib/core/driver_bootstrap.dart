import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/user_record.dart';
import '/core/driver_account_state_resolver.dart';
import '/core/driver_auto_activation_service.dart';

/// Result of app start / session resolution. Navigation is NOT done here.
enum DriverBootstrapStatus {
  loading,
  firstLaunch,
  unauthenticated,
  authenticatedMissingDriverDocument,
  registrationIncomplete,
  pendingApproval,
  changesRequested,
  rejected,
  suspended,
  activeOffline,
  activeOnline,
  activeTrip,
  bootstrapError,
}

class DriverBootstrapResult {
  const DriverBootstrapResult({
    required this.status,
    this.lifecycle = DriverLifecycle.loggedOut,
    this.uid,
    this.errorMessage,
    this.driverDocument,
    this.onboardingCompleted = false,
  });

  final DriverBootstrapStatus status;
  final DriverLifecycle lifecycle;
  final String? uid;
  final String? errorMessage;
  final UserRecord? driverDocument;
  final bool onboardingCompleted;

  bool get isAuthenticated =>
      status != DriverBootstrapStatus.unauthenticated &&
      status != DriverBootstrapStatus.firstLaunch &&
      status != DriverBootstrapStatus.loading;
}

/// Central bootstrap: Firebase is expected initialized; resolves session only.
abstract final class DriverBootstrapService {
  DriverBootstrapService._();

  static const onboardingDoneKey = 'driver_onboarding_done_v1';
  static const _docReadTimeout = Duration(seconds: 10);
  static const _prefsTimeout = Duration(seconds: 3);

  /// Drop guest sessions — never used for routing into registration.
  static Future<void> clearAnonymousSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        await FirebaseAuth.instance
            .signOut()
            .timeout(const Duration(seconds: 5));
        currentUserDocument = null;
      } catch (e) {
        debugPrint('DriverBootstrapService.clearAnonymousSession: $e');
      }
    }
  }

  static Future<bool> isOnboardingDone() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(_prefsTimeout);
      return prefs.getBool(onboardingDoneKey) ?? false;
    } on TimeoutException {
      debugPrint('DriverBootstrapService.isOnboardingDone: prefs timeout');
      return true; // Prefer Login over stuck Onboarding when prefs hang.
    }
  }

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingDoneKey, true);
  }

  /// Alias kept for older call sites.
  static Future<void> clearAnonymousSessionLegacy() => clearAnonymousSession();

  static Future<DriverBootstrapResult> resolve({
    bool? hasActiveTrip,
  }) async {
    try {
      await clearAnonymousSession();

      final onboardingDone = await isOnboardingDone();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.isAnonymous) {
        if (!onboardingDone) {
          return const DriverBootstrapResult(
            status: DriverBootstrapStatus.firstLaunch,
            lifecycle: DriverLifecycle.loggedOut,
            onboardingCompleted: false,
          );
        }
        return const DriverBootstrapResult(
          status: DriverBootstrapStatus.unauthenticated,
          lifecycle: DriverLifecycle.loggedOut,
          onboardingCompleted: true,
        );
      }

      UserRecord? doc;
      var exists = false;
      try {
        final snap = await UserRecord.collection
            .doc(user.uid)
            .get()
            .timeout(_docReadTimeout);
        exists = snap.exists;
        if (exists) {
          doc = UserRecord.fromSnapshot(snap);
          currentUserDocument = doc;
        } else {
          currentUserDocument = null;
        }
      } on TimeoutException {
        debugPrint('DriverBootstrapService doc read: timeout');
        return DriverBootstrapResult(
          status: DriverBootstrapStatus.bootstrapError,
          lifecycle: DriverLifecycle.loading,
          uid: user.uid,
          errorMessage: 'Timed out loading driver profile',
          onboardingCompleted: onboardingDone,
        );
      } on FirebaseException catch (e) {
        debugPrint('DriverBootstrapService doc read: ${e.code}');
        return DriverBootstrapResult(
          status: DriverBootstrapStatus.bootstrapError,
          lifecycle: DriverLifecycle.loading,
          uid: user.uid,
          errorMessage: e.message ?? e.code,
          onboardingCompleted: onboardingDone,
        );
      }

      if (!exists || doc == null) {
        _devLog(
          uid: user.uid,
          isAnonymous: false,
          docExists: false,
          lifecycle: DriverLifecycle.incompleteProfile,
          routeHint: 'regdrever',
        );
        return DriverBootstrapResult(
          status: DriverBootstrapStatus.authenticatedMissingDriverDocument,
          lifecycle: DriverLifecycle.incompleteProfile,
          uid: user.uid,
          onboardingCompleted: onboardingDone,
        );
      }

      var activeTrip =
          hasActiveTrip ?? (FFAppState().revOrder != null);
      var life = DriverAccountStateResolver.resolve(
        hasAuthUser: true,
        isAnonymous: false,
        driverDocumentExists: true,
        doc: doc,
        hasActiveTrip: activeTrip,
        debugLog: kDebugMode,
      );

      if (life == DriverLifecycle.pendingApproval) {
        // Registration V2: never auto-activate — wait for admin review.
        final flowVersion = doc?.snapshotData['registration_flow_version'];
        final isV2 = flowVersion is num
            ? flowVersion.toInt() == 2
            : int.tryParse('$flowVersion') == 2;
        if (!isV2) {
          final activation =
              await DriverAutoActivationService.tryAutoActivate();
          if (activation.ok && !activation.alreadyActive) {
            try {
              doc = await UserRecord.getDocumentOnce(
                  UserRecord.collection.doc(user.uid));
              currentUserDocument = doc;
              life = DriverAccountStateResolver.resolve(
                hasAuthUser: true,
                isAnonymous: false,
                driverDocumentExists: true,
                doc: doc,
                hasActiveTrip: activeTrip,
                debugLog: kDebugMode,
              );
            } catch (e) {
              debugPrint('DriverBootstrapService auto-activate reload: $e');
            }
          }
        }
      }

      final status = _mapLifecycleToBootstrap(life, missingDoc: false);
      final profile = doc!;
      _devLog(
        uid: user.uid,
        isAnonymous: false,
        docExists: true,
        lifecycle: life,
        routeHint: status.name,
        raw: {
          'ismndob': profile.ismndob,
          'ismndom': profile.ismndom,
          'actev_mndob': profile.actevMndob,
          'ngl': profile.ngl,
          'mndon_newacc': profile.mndonNewacc,
          'registration_status': profile.registrationStatus,
        },
      );

      return DriverBootstrapResult(
        status: status,
        lifecycle: life,
        uid: user.uid,
        driverDocument: profile,
        onboardingCompleted: onboardingDone,
      );
    } catch (e, st) {
      debugPrint('DriverBootstrapService.resolve failed: $e\n$st');
      return DriverBootstrapResult(
        status: DriverBootstrapStatus.bootstrapError,
        lifecycle: DriverLifecycle.loading,
        errorMessage: e.toString(),
      );
    }
  }

  static DriverBootstrapStatus _mapLifecycleToBootstrap(
    DriverLifecycle life, {
    required bool missingDoc,
  }) {
    if (missingDoc) {
      return DriverBootstrapStatus.authenticatedMissingDriverDocument;
    }
    switch (life) {
      case DriverLifecycle.loggedOut:
        return DriverBootstrapStatus.unauthenticated;
      case DriverLifecycle.loading:
        return DriverBootstrapStatus.loading;
      case DriverLifecycle.incompleteProfile:
        return DriverBootstrapStatus.registrationIncomplete;
      case DriverLifecycle.pendingApproval:
        return DriverBootstrapStatus.pendingApproval;
      case DriverLifecycle.changesRequested:
        return DriverBootstrapStatus.changesRequested;
      case DriverLifecycle.rejected:
        return DriverBootstrapStatus.rejected;
      case DriverLifecycle.suspended:
        return DriverBootstrapStatus.suspended;
      case DriverLifecycle.activeOffline:
        return DriverBootstrapStatus.activeOffline;
      case DriverLifecycle.activeOnline:
        return DriverBootstrapStatus.activeOnline;
      case DriverLifecycle.onTrip:
        return DriverBootstrapStatus.activeTrip;
    }
  }

  static void _devLog({
    required String? uid,
    required bool isAnonymous,
    required bool docExists,
    required DriverLifecycle lifecycle,
    required String routeHint,
    Map<String, Object?>? raw,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      'DriverBootstrap uid=${uid ?? '-'} anon=$isAnonymous '
      'doc=$docExists life=$lifecycle → $routeHint raw=$raw',
    );
  }
}

/// Back-compat aliases used by older imports.
typedef DriverBootstrap = DriverBootstrapService;
