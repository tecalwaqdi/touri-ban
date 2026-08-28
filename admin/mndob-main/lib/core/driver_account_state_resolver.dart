import 'package:flutter/foundation.dart';

import '/backend/schema/user_record.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Canonical driver lifecycle used by AuthGate / Router / screens.
/// Compatibility: maps legacy Firestore flags without deleting them.
enum DriverLifecycle {
  loggedOut,
  loading,
  incompleteProfile,
  pendingApproval,
  changesRequested,
  rejected,
  suspended,
  activeOffline,
  activeOnline,
  onTrip,
}

/// Single adapter: legacy `user` fields → one lifecycle.
///
/// Legacy field meanings (from code + admin):
/// - `ismndob` / `ismndom`: driver / pending-driver flags
/// - `actev_mndob`: admin activated (may go online)
/// - `ngl`: online
/// - `mndon_newacc`: busy / on trip
/// - `registration_status`: pending_review | submitted | changes_requested |
///   approved | rejected | suspended | blocked
/// - `rejection_reason`: admin note
abstract final class DriverAccountStateResolver {
  DriverAccountStateResolver._();

  /// Pure resolve from auth snapshot + optional driver doc.
  static DriverLifecycle resolve({
    required bool hasAuthUser,
    required bool isAnonymous,
    required bool driverDocumentExists,
    UserRecord? doc,
    bool? hasActiveTrip,
    bool debugLog = false,
  }) {
    if (!hasAuthUser || isAnonymous) {
      _log(debugLog, 'loggedOut', reason: 'noAuthOrAnonymous');
      return DriverLifecycle.loggedOut;
    }

    if (!driverDocumentExists || doc == null) {
      _log(debugLog, 'incompleteProfile', reason: 'missingDriverDocument');
      return DriverLifecycle.incompleteProfile;
    }

    final life = resolveFromLegacyFields(
      hasAuthUser: true,
      isAnonymous: false,
      driverDocumentExists: true,
      ismndob: valueOrDefault<bool>(doc.ismndob, false),
      ismndom: valueOrDefault<bool>(doc.ismndom, false),
      actevMndob: valueOrDefault<bool>(doc.actevMndob, false),
      ngl: valueOrDefault<bool>(doc.ngl, false),
      mndonNewacc: valueOrDefault<bool>(doc.mndonNewacc, false),
      registrationStatus: doc.registrationStatus,
      displayName: doc.displayName,
      hasCar: doc.mndobTypeCar != null,
      hasActiveTrip: hasActiveTrip,
    );
    _log(debugLog, life.name, reason: 'legacyMapped');
    return life;
  }

  static DriverLifecycle resolveFromDocument(
    UserRecord doc, {
    bool? hasActiveTrip,
    bool debugLog = false,
  }) {
    return resolve(
      hasAuthUser: true,
      isAnonymous: false,
      driverDocumentExists: true,
      doc: doc,
      hasActiveTrip: hasActiveTrip,
      debugLog: debugLog,
    );
  }

  /// Test / adapter entry without constructing Firestore [UserRecord].
  static DriverLifecycle resolveFromLegacyFields({
    required bool hasAuthUser,
    required bool isAnonymous,
    required bool driverDocumentExists,
    bool ismndob = false,
    bool ismndom = false,
    bool actevMndob = false,
    bool ngl = false,
    bool mndonNewacc = false,
    String registrationStatus = '',
    String displayName = '',
    bool hasCar = false,
    bool? hasActiveTrip,
  }) {
    if (!hasAuthUser || isAnonymous) {
      return DriverLifecycle.loggedOut;
    }
    if (!driverDocumentExists) {
      return DriverLifecycle.incompleteProfile;
    }

    final status = registrationStatus.trim().toLowerCase();
    // Operational access requires admin activation flag (actev_mndob).
    // registration_status==approved alone is not enough to open Home/ops.
    final approved = actevMndob;
    final isDriver = ismndob || ismndom;
    final name = displayName.trim();
    final onTrip = hasActiveTrip == true || mndonNewacc;

    if (status == 'suspended' || status == 'blocked') {
      return DriverLifecycle.suspended;
    }
    if (status == 'rejected') {
      return DriverLifecycle.rejected;
    }
    if (status == 'changes_requested' || status == 'needs_changes') {
      return DriverLifecycle.changesRequested;
    }
    if (!approved) {
      // Registration V2 draft → continue registration, not pending queue.
      if (status == 'draft') {
        return DriverLifecycle.incompleteProfile;
      }
      final submitted = status == 'pending_review' ||
          status == 'submitted';
      if (submitted || (isDriver && name.isNotEmpty && hasCar)) {
        return DriverLifecycle.pendingApproval;
      }
      if (isDriver && name.isNotEmpty) {
        return DriverLifecycle.pendingApproval;
      }
      return DriverLifecycle.incompleteProfile;
    }
    if (onTrip) return DriverLifecycle.onTrip;
    if (ngl) return DriverLifecycle.activeOnline;
    return DriverLifecycle.activeOffline;
  }

  static void _log(bool enabled, String state, {required String reason}) {
    if (!enabled || !kDebugMode) return;
    debugPrint('DriverAccountStateResolver → $state ($reason)');
  }
}
