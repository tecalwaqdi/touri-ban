import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/driver_approved_profile_policy.dart';

/// Result of submitting a profile data-change request (not a live overwrite).
class DriverDataChangeSubmitResult {
  const DriverDataChangeSubmitResult._({
    required this.success,
    this.requestId,
    this.errorKey,
    this.reuseExistingCorrection = false,
  });

  const DriverDataChangeSubmitResult.ok({required String requestId})
      : this._(success: true, requestId: requestId);

  const DriverDataChangeSubmitResult.reuseCorrection()
      : this._(success: true, reuseExistingCorrection: true);

  const DriverDataChangeSubmitResult.fail(String errorKey)
      : this._(success: false, errorKey: errorKey);

  final bool success;
  final String? requestId;
  final String? errorKey;
  final bool reuseExistingCorrection;
}

/// Creates CHANGE REQUESTS only — never overwrites canonical approved profile.
abstract final class DriverDataChangeRequestService {
  DriverDataChangeRequestService._();

  static const collectionName = 'driver_data_change_requests';

  static List<String> get allowedSections =>
      DriverApprovedProfilePolicy.changeRequestSections;

  /// Submit a pending change request for an approved/active driver.
  ///
  /// If the driver already has `needs_changes` / `changes_requested`, returns
  /// [DriverDataChangeSubmitResult.reuseCorrection] so UI routes to existing
  /// correction flow instead of duplicating it.
  static Future<DriverDataChangeSubmitResult> submit({
    required UserRecord driver,
    required List<String> sections,
    Map<String, dynamic> proposedValues = const {},
    Map<String, dynamic> requestedFields = const {},
    String? reason,
    Map<String, dynamic>? documentUploads,
  }) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null || auth.isAnonymous || auth.uid != driver.uid) {
      return const DriverDataChangeSubmitResult.fail(
        'Please sign in again to continue.',
      );
    }

    if (DriverApprovedProfilePolicy.hasOpenCorrectionRequest(driver)) {
      return const DriverDataChangeSubmitResult.reuseCorrection();
    }

    if (!DriverApprovedProfilePolicy.isApprovedOrActive(driver)) {
      return const DriverDataChangeSubmitResult.fail(
        'Only approved drivers can request data changes.',
      );
    }

    final cleanSections = sections
        .map((s) => s.trim())
        .where((s) =>
            s.isNotEmpty &&
            DriverApprovedProfilePolicy.changeRequestSections.contains(s))
        .toSet()
        .toList();
    if (cleanSections.isEmpty) {
      return const DriverDataChangeSubmitResult.fail(
        'Select at least one field to change.',
      );
    }

    final merged = <String, dynamic>{
      ...requestedFields,
      ...proposedValues,
    };
    // Never allow status / wallet / finance keys in the payload.
    final safeProposed = Map<String, dynamic>.from(merged)
      ..removeWhere(
        (k, _) =>
            DriverRegistrationUpdatePayloadLike.forbiddenRequestKeys.contains(k) ||
            DriverApprovedProfilePolicy.changeRequestSections.contains(k),
      );

    if (safeProposed.isEmpty &&
        (documentUploads == null || documentUploads.isEmpty)) {
      return const DriverDataChangeSubmitResult.fail(
        'Enter the new values or upload the documents you want updated.',
      );
    }

    try {
      // Prefer CF when available (server-side audit + validation).
      final cf = await makeCloudCall(
        'submitDriverProfileChangeRequest',
        {
          'sections': cleanSections,
          'proposedValues': safeProposed,
          'requestedFields': safeProposed,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
          if (documentUploads != null && documentUploads.isNotEmpty)
            'documentUploads': documentUploads,
        },
      );
      if (cf['reuseExistingCorrection'] == true) {
        return const DriverDataChangeSubmitResult.reuseCorrection();
      }
      if (cf['ok'] == true || cf['success'] == true) {
        final id = (cf['requestId'] ?? cf['id'] ?? '').toString();
        if (id.isNotEmpty) {
          return DriverDataChangeSubmitResult.ok(requestId: id);
        }
      }
      if (cf.containsKey('error') || cf.containsKey('code')) {
        final msg = (cf['error'] ?? cf['message'] ?? '').toString();
        if (msg.isNotEmpty) {
          return DriverDataChangeSubmitResult.fail(msg);
        }
      }
    } catch (e) {
      debugPrint('[DriverDataChangeRequest] CF submit fallback: $e');
    }

    final ref =
        FirebaseFirestore.instance.collection(collectionName).doc();
    final payload = <String, dynamic>{
      'id': ref.id,
      'driverUid': auth.uid,
      'status': 'pending',
      'sections': cleanSections,
      'proposedValues': safeProposed,
      'requestedFields': safeProposed,
      if (documentUploads != null) 'documentUploads': documentUploads,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      'requestedBy': auth.uid,
      'requestedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
      'reviewedAt': null,
      'decision': null,
      'changedFields': safeProposed.keys.toList(),
      'currentSnapshot': _currentSnapshot(driver, safeProposed.keys),
    };

    try {
      await ref.set(payload);
      try {
        await UserRecord.collection.doc(auth.uid).set(
          {
            'pending_data_change_request_id': ref.id,
            'pending_data_change_request_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (pointerErr) {
        debugPrint(
          '[DriverDataChangeRequest] pointer update skipped: $pointerErr',
        );
      }
      return DriverDataChangeSubmitResult.ok(requestId: ref.id);
    } on FirebaseException catch (e) {
      debugPrint('[DriverDataChangeRequest] ${e.code} ${e.message}');
      return const DriverDataChangeSubmitResult.fail(
        'Could not submit change request. Please try again.',
      );
    } catch (e) {
      debugPrint('[DriverDataChangeRequest] $e');
      return const DriverDataChangeSubmitResult.fail(
        'Could not submit change request. Please try again.',
      );
    }
  }

  static Map<String, dynamic> _currentSnapshot(
    UserRecord driver,
    Iterable<String> keys,
  ) {
    final data = Map<String, dynamic>.from(driver.snapshotData);
    final out = <String, dynamic>{};
    for (final k in keys) {
      if (data.containsKey(k)) out[k] = data[k];
    }
    return out;
  }
}

/// Keys that must never appear in a client-authored change request payload.
abstract final class DriverRegistrationUpdatePayloadLike {
  DriverRegistrationUpdatePayloadLike._();

  static const forbiddenRequestKeys = <String>{
    'uid',
    'ismndob',
    'ismndom',
    'actev_mndob',
    'ngl',
    'registration_status',
    'submission_status',
    'wallet',
    'walletId',
    'wallet_id',
    'walletBalance',
    'currentBalance',
    'total_app',
    'finance',
    'super_admin',
    'isAdmin',
    'IsAdmin',
    'approvedAt',
    'approvedBy',
    'approved_at',
    'rejectedAt',
    'rejectedBy',
    'requested_changes',
    'fieldsToFix',
    'reviewVersion',
  };
}
