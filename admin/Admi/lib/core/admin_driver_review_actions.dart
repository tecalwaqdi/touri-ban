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
      if (DriverRegistrationDocumentStatus.statusForType(
              data, 'national_id') !=
          DriverRegistrationDocStatus.complete) {
        blockers.add('adm_drv_blocker_national_id');
      }
      if (DriverRegistrationDocumentStatus.statusForType(
              data, 'vehicle_registration') !=
          DriverRegistrationDocStatus.complete) {
        blockers.add('adm_drv_blocker_vehicle_reg');
      }
      if (DriverRegistrationDocumentStatus.statusForType(
              data, 'driver_license') !=
          DriverRegistrationDocStatus.complete) {
        blockers.add('adm_drv_blocker_driver_license');
      }
    }
    final open = (data['requested_changes'] as List?)
            ?.whereType<Map>()
            .where((e) => e['resolved'] != true) ??
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
        'requested_changes': <dynamic>[],
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
        'approved_at': FieldValue.serverTimestamp(),
      };

  static Map<String, dynamic> rejectPatch({
    required String reason,
    required String adminUid,
  }) =>
      {
        'actev_mndob': false,
        'ngl': false,
        'registration_status': 'rejected',
        'submission_status': 'rejected',
        'account_status': 'inactive',
        'rejection_reason': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
      };

  static Map<String, dynamic> requestChangesPatch({
    required String reason,
    required String adminUid,
    String section = 'general',
  }) =>
      {
        'actev_mndob': false,
        'ngl': false,
        'registration_status': 'needs_changes',
        'submission_status': 'changesRequested',
        'account_status': 'inactive',
        'operational_status': 'offline',
        'rejection_reason': reason,
        'changeRequestReason': reason,
        'fieldsToFix': [section],
        'requested_changes': [
          {
            'section': section,
            'adminMessage': reason,
            'createdBy': adminUid,
            'resolved': false,
            'createdAt': FieldValue.serverTimestamp(),
          }
        ],
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminUid,
      };

  static Map<String, dynamic> suspendPatch({
    required String reason,
    required String adminUid,
  }) =>
      {
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
}
