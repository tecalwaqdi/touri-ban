import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

import '/backend/schema/user_record.dart';
import '/core/driver_account_state_resolver.dart';

/// Compatibility helpers so UI / eligibility never branch on raw legacy
/// booleans for account routing or "approved" gates.
///
/// Admin panel continues writing the same Firestore fields; this layer only
/// maps them → [DriverLifecycle] for the driver app.
abstract final class DriverLegacyFieldCompat {
  DriverLegacyFieldCompat._();

  /// Documented meanings (code + Admi).
  static const fieldMeanings = <String, String>{
    'ismndob': 'Driver (or pending-driver) flag — admin queues filter on this',
    'ismndom': 'Pending-driver / new-driver flag used with ismndob',
    'actev_mndob': 'Admin activated — required before going online',
    'ngl': 'Operational online flag',
    'mndon_newacc': 'Busy / on active trip',
    'registration_status':
        'Review pipeline: pending_review|submitted|changes_requested|'
            'approved|rejected|suspended|blocked',
    'rejection_reason': 'Admin note when rejected / changes requested',
  };

  /// Admin request-changes dual-write (structured + legacy note).
  static Map<String, dynamic> adminRequestChangesPatch({
    required String reason,
    required String adminUid,
    List<Map<String, dynamic>>? requestedChanges,
  }) =>
      {
        'actev_mndob': false,
        'ngl': false,
        'registration_status': 'changes_requested',
        'submission_status': 'changesRequested',
        'account_status': 'inactive',
        'operational_status': 'offline',
        'rejection_reason': reason,
        'requested_changes': requestedChanges ??
            [
              {
                'section': 'general',
                'adminMessage': reason,
                'createdBy': adminUid,
                'resolved': false,
                'createdAt': FieldValue.serverTimestamp(),
              }
            ],
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
      };

  /// Admin reactivate after suspend.
  static Map<String, dynamic> adminReactivatePatch({
    required String adminUid,
  }) =>
      {
        'registration_status': 'approved',
        'account_status': 'active',
        'actev_mndob': true,
        'ngl': false,
        'operational_status': 'offline',
        'rejection_reason': '',
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
        'reactivated_at': FieldValue.serverTimestamp(),
      };

  /// Prerequisites before approval (shared with Admin / CF contract).
  /// Profile photo and ID documents are optional for the cash-wave auto-activate path.
  static List<String> approvalBlockingReasons(Map<String, dynamic> data) {
    final blockers = <String>[];
    final status = (data['registration_status'] as String?) ?? '';
    if (status == 'suspended' || status == 'blocked') {
      blockers.add('account_suspended_or_blocked');
    }
    if (data['mndob_vill'] == null) {
      blockers.add('village_required');
    }
    if (data['mndob_type_car'] == null && data['car_rev_mndob'] == null) {
      blockers.add('vehicle_type_required');
    }
    final open = (data['requested_changes'] as List?)
            ?.whereType<Map>()
            .where((e) => e['resolved'] != true) ??
        const [];
    if (open.isNotEmpty) {
      blockers.add('open_requested_changes');
    }
    return blockers;
  }

  /// Admin approve dual-write (keep both for compatibility).
  static Map<String, dynamic> adminApprovePatch({required String adminUid}) => {
        'actev_mndob': true,
        'ismndob': true,
        'ismndom': true,
        'ngl': false,
        'registration_status': 'approved',
        'submission_status': 'approved',
        'account_status': 'active',
        'operational_status': 'offline',
        'vehicle_review_status': 'approved',
        'document_review_status': 'approved',
        'rejection_reason': '',
        'requested_changes': <dynamic>[],
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
        'approved_at': FieldValue.serverTimestamp(),
      };

  /// Admin reject dual-write.
  static Map<String, dynamic> adminRejectPatch({
    required String reason,
    required String adminUid,
  }) =>
      {
        'actev_mndob': false,
        'registration_status': 'rejected',
        'rejection_reason': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
      };

  /// Admin suspend dual-write.
  static Map<String, dynamic> adminSuspendPatch({
    required String reason,
    required String adminUid,
  }) =>
      {
        'ngl': false,
        'registration_status': 'suspended',
        'rejection_reason': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
      };

  static bool isOperationallyApproved(DriverLifecycle life) =>
      life == DriverLifecycle.activeOffline ||
      life == DriverLifecycle.activeOnline ||
      life == DriverLifecycle.onTrip;

  static bool isOnline(DriverLifecycle life) =>
      life == DriverLifecycle.activeOnline || life == DriverLifecycle.onTrip;

  static bool isOnTrip(DriverLifecycle life) => life == DriverLifecycle.onTrip;

  /// i18n message key for status chip (not navigation).
  static String statusMessageKey(DriverLifecycle life) {
    switch (life) {
      case DriverLifecycle.loggedOut:
        return 'Please sign in first.';
      case DriverLifecycle.loading:
        return 'Loading your account…';
      case DriverLifecycle.incompleteProfile:
        return 'Please complete your profile.';
      case DriverLifecycle.pendingApproval:
        return 'Your account is waiting for admin approval before going online.';
      case DriverLifecycle.changesRequested:
        return 'Admin requested changes to your application.';
      case DriverLifecycle.rejected:
        return 'Your application was rejected.';
      case DriverLifecycle.suspended:
        return 'This account has been disabled.';
      case DriverLifecycle.activeOffline:
        return 'You are offline';
      case DriverLifecycle.activeOnline:
        return 'Ready to receive orders';
      case DriverLifecycle.onTrip:
        return 'Trip in progress';
    }
  }

  /// Snapshot for debug logs (no free-text rejection reason).
  static Map<String, Object?> rawSnapshot(UserRecord? doc) {
    if (doc == null) return const {'exists': false};
    return {
      'exists': true,
      'ismndob': doc.ismndob,
      'ismndom': doc.ismndom,
      'actev_mndob': doc.actevMndob,
      'ngl': doc.ngl,
      'mndon_newacc': doc.mndonNewacc,
      'registration_status': doc.registrationStatus,
    };
  }
}
