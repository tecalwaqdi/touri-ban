import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/driver_registration_document_status.dart';

/// Admin-side dual-write patches for driver registration review.
/// Mirrors mndob-main `DriverLegacyFieldCompat` (no cross-package import).
///
/// [approvalBlockingReasons] returns **l10n keys** (adm_drv_blocker_*),
/// not display strings — callers must pass them through [appTr].
abstract final class AdminDriverReviewActions {
  AdminDriverReviewActions._();

  static List<String> approvalBlockingReasons(Map<String, dynamic> data) {
    final blockers = <String>[];
    final status = (data['registration_status'] as String?) ?? '';
    if (status == 'suspended' || status == 'blocked') {
      blockers.add('adm_drv_blocker_suspended');
    }
    if (data['mndob_vill'] == null) {
      blockers.add('adm_drv_blocker_work_area');
    }
    if (data['mndob_type_car'] == null && data['car_rev_mndob'] == null) {
      blockers.add('adm_drv_blocker_vehicle_type');
    }
    // Registration V2: require dedicated docs (or legacy dual-write).
    final flow = data['registration_flow_version'];
    final isV2 = flow is num ? flow.toInt() == 2 : int.tryParse('$flow') == 2;
    if (isV2) {
      if (!DriverRegistrationDocumentStatus.profilePhotoOk(data)) {
        blockers.add('adm_drv_blocker_photo');
      }
      if (DriverRegistrationDocumentStatus.statusForType(data, 'national_id') !=
          DriverRegistrationDocStatus.complete) {
        blockers.add('adm_drv_blocker_national_id');
      }
      if (DriverRegistrationDocumentStatus.statusForType(
            data,
            'vehicle_registration',
          ) !=
          DriverRegistrationDocStatus.complete) {
        blockers.add('adm_drv_blocker_vehicle_reg');
      }
      if (DriverRegistrationDocumentStatus.statusForType(
            data,
            'driver_license',
          ) !=
          DriverRegistrationDocStatus.complete) {
        blockers.add('adm_drv_blocker_driver_license');
      }
    }
    final open =
        (data['requested_changes'] as List?)?.whereType<Map>().where(
          (e) => e['resolved'] != true,
        ) ??
        const [];
    if (open.isNotEmpty) {
      blockers.add('adm_drv_blocker_open_changes');
    }
    return blockers;
  }

  static const fieldsToFixAllowlist = <String>[
    'personal_info',
    'vehicle',
    'national_id',
    'vehicle_registration',
    'driver_license',
    'plate',
    'other',
  ];

  static bool isRegistrationV2(Map<String, dynamic> data) {
    final flow = data['registration_flow_version'];
    if (flow is num) return flow.toInt() == 2;
    return int.tryParse('$flow') == 2;
  }

  static Map<String, dynamic> approvePatch({required String adminUid}) => {
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
    'rejection_reason': FieldValue.delete(),
    'rejectionReason': FieldValue.delete(),
    'changeRequestReason': FieldValue.delete(),
    'fieldsToFix': <dynamic>[],
    'requested_changes': <dynamic>[],
    'reviewed_at': FieldValue.serverTimestamp(),
    'reviewed_by': adminUid,
    // Dual-write camelCase + snake_case (CF V2 + legacy readers).
    'approved_at': FieldValue.serverTimestamp(),
    'approvedAt': FieldValue.serverTimestamp(),
    'approvedBy': adminUid,
  };

  static Map<String, dynamic> rejectPatch({
    required String reason,
    required String adminUid,
  }) => {
    'actev_mndob': false,
    'ngl': false,
    'registration_status': 'rejected',
    'submission_status': 'rejected',
    'account_status': 'inactive',
    'rejection_reason': reason,
    'rejectionReason': reason,
    'rejectedAt': FieldValue.serverTimestamp(),
    'rejectedBy': adminUid,
    'reviewed_at': FieldValue.serverTimestamp(),
    'reviewed_by': adminUid,
  };

  static Map<String, dynamic> requestChangesPatch({
    required String reason,
    required String adminUid,
    String section = 'general',
    List<String>? fieldsToFix,
  }) {
    final fields = (fieldsToFix == null || fieldsToFix.isEmpty)
        ? <String>[section]
        : fieldsToFix
              .where((f) => fieldsToFixAllowlist.contains(f))
              .toList(growable: false);
    final effective = fields.isEmpty ? <String>['other'] : fields;
    return {
      'actev_mndob': false,
      'ngl': false,
      // Canonical V2 + legacy Driver App aliases (read both).
      'registration_status': 'needs_changes',
      'submission_status': 'changesRequested',
      'account_status': 'inactive',
      'operational_status': 'offline',
      'rejection_reason': reason,
      'changeRequestReason': reason,
      'fieldsToFix': effective,
      'changesRequestedAt': FieldValue.serverTimestamp(),
      'changesRequestedBy': adminUid,
      'requested_changes': [
        {
          'section': effective.first,
          'adminMessage': reason,
          'createdBy': adminUid,
          'resolved': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ],
      'reviewed_at': FieldValue.serverTimestamp(),
      'reviewed_by': adminUid,
    };
  }

  static Map<String, dynamic> suspendPatch({
    required String reason,
    required String adminUid,
  }) => {
    'ngl': false,
    'actev_mndob': false,
    'registration_status': 'suspended',
    'account_status': 'suspended',
    'operational_status': 'offline',
    'rejection_reason': reason,
    'suspended_at': FieldValue.serverTimestamp(),
    'suspended_by': adminUid,
    'reviewed_at': FieldValue.serverTimestamp(),
    'reviewed_by': adminUid,
  };

  /// Operational account flag only — does **not** change registration_status.
  ///
  /// Use after registration is already `approved`. Distinct from [approvePatch]
  /// (registration review) and [suspendPatch] (registration suspension).
  static Map<String, dynamic> operationalActivatePatch({
    required String adminUid,
  }) => {
    'actev_mndob': true,
    'ismndob': true,
    'ismndom': true,
    'ngl': false,
    'account_status': 'active',
    'operational_status': 'offline',
    'actev_mndob_at': FieldValue.serverTimestamp(),
    'reviewed_at': FieldValue.serverTimestamp(),
    'reviewed_by': adminUid,
  };

  /// Flip operational activation off without suspending registration.
  static Map<String, dynamic> operationalDeactivatePatch({
    required String adminUid,
  }) => {
    'actev_mndob': false,
    'ngl': false,
    'account_status': 'inactive',
    'operational_status': 'offline',
    'reviewed_at': FieldValue.serverTimestamp(),
    'reviewed_by': adminUid,
  };

  /// Guards for **operational** activate (not registration approve).
  ///
  /// Returns l10n keys (`adm_drv_blocker_*`). Suspended accounts must go through
  /// registration review / unsuspend — not this path.
  static List<String> operationalActivationBlockers(Map<String, dynamic> data) {
    final blockers = <String>[];
    final status = (data['registration_status'] as String?)?.trim() ?? '';
    final submission = (data['submission_status'] as String?)?.trim() ?? '';
    final account = (data['account_status'] as String?)?.trim() ?? '';
    final effective = status.isNotEmpty ? status : submission;

    if (effective == 'suspended' ||
        effective == 'blocked' ||
        account == 'suspended') {
      blockers.add('adm_drv_blocker_suspended');
    }

    final approved =
        effective == 'approved' ||
        submission == 'approved' ||
        // Legacy docs often lack registration_status but were admin-created.
        (effective.isEmpty &&
            (data['ismndob'] == true || data['ismndom'] == true));

    if (!approved) {
      blockers.add('adm_drv_blocker_registration_not_approved');
    }

    if (data['mndob_vill'] == null) {
      blockers.add('adm_drv_blocker_work_area');
    }
    if (data['mndob_type_car'] == null && data['car_rev_mndob'] == null) {
      blockers.add('adm_drv_blocker_vehicle_type');
    }

    final open =
        (data['requested_changes'] as List?)?.whereType<Map>().where(
          (e) => e['resolved'] != true,
        ) ??
        const [];
    if (open.isNotEmpty) {
      blockers.add('adm_drv_blocker_open_changes');
    }

    return blockers;
  }
}
