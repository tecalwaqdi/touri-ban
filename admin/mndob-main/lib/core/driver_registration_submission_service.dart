import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/core/driver_registration_validators.dart';
import '/core/tour_guide_status.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Structured admin change request (stored on user doc + compatibility).
class DriverRequestedChange {
  const DriverRequestedChange({
    required this.section,
    this.field = '',
    this.documentType = '',
    this.code = '',
    this.adminMessage = '',
    this.createdAt,
    this.createdBy = '',
    this.resolved = false,
    this.resolvedAt,
  });

  final String section;
  final String field;
  final String documentType;
  final String code;
  final String adminMessage;
  final DateTime? createdAt;
  final String createdBy;
  final bool resolved;
  final DateTime? resolvedAt;

  Map<String, dynamic> toMap() => {
        'section': section,
        'field': field,
        'documentType': documentType,
        'code': code,
        'adminMessage': adminMessage,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        'resolved': resolved,
        if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      };

  factory DriverRequestedChange.fromMap(Map<String, dynamic> map) {
    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return DriverRequestedChange(
      section: (map['section'] as String?) ?? '',
      field: (map['field'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? '',
      code: (map['code'] as String?) ?? '',
      adminMessage:
          (map['adminMessage'] as String?) ?? (map['message'] as String?) ?? '',
      createdAt: ts(map['createdAt']),
      createdBy: (map['createdBy'] as String?) ?? '',
      resolved: map['resolved'] == true,
      resolvedAt: ts(map['resolvedAt']),
    );
  }

  static List<DriverRequestedChange> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DriverRequestedChange.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// Snapshot used for Review screen + submit gate.
class DriverRegistrationReviewModel {
  const DriverRegistrationReviewModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phoneE164,
    required this.idNumber,
    required this.birthDate,
    required this.countryRef,
    required this.regionRef,
    required this.villageRef,
    required this.regionName,
    required this.villageName,
    required this.vehicleTypeRef,
    required this.vehicleTypeText,
    required this.vehicleName,
    required this.modelYear,
    required this.plate,
    required this.color,
    required this.seats,
    required this.photoUrl,
    required this.idImageUrl,
    required this.carImageUrl,
    required this.location,
    required this.isResubmit,
    required this.uploadInFlight,
    this.affiliationType = 'independent',
    this.companyPath = '',
    this.companyName = '',
    this.isTourGuide = false,
    this.guidePermitUrl = '',
  });

  final String uid;
  final String displayName;
  final String email;
  final String phoneE164;
  final String idNumber;
  final DateTime? birthDate;
  final DocumentReference? countryRef;
  final DocumentReference? regionRef;
  final DocumentReference? villageRef;
  final String regionName;
  final String villageName;
  final DocumentReference? vehicleTypeRef;
  final String vehicleTypeText;
  final String vehicleName;
  final String modelYear;
  final String plate;
  final String color;
  final int? seats;
  final String photoUrl;
  final String idImageUrl;
  final String carImageUrl;
  final LatLng? location;
  final bool isResubmit;
  final bool uploadInFlight;

  /// `'independent'` | `'company'`
  final String affiliationType;
  final String companyPath;
  final String companyName;
  final bool isTourGuide;
  final String guidePermitUrl;
}

/// Pre-submit completeness (Auth + location refs + docs).
abstract final class DriverRegistrationCompletenessService {
  DriverRegistrationCompletenessService._();

  static List<String> blockingReasons(DriverRegistrationReviewModel m) {
    final reasons = <String>[];
    if (m.uid.isEmpty) {
      reasons.add('Please sign in first.');
    } else {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.isAnonymous || user.uid != m.uid) {
          reasons.add('Please sign in first.');
        }
      } catch (_) {
        // Unit tests / Firebase not initialized — treat as unsigned.
        reasons.add('Please sign in first.');
      }
    }
    if (m.uploadInFlight) {
      reasons.add('Document is still uploading');
    }
    final iso = TouryCountryRegistry.normalizeIso(m.countryRef?.id) ??
        (m.location != null
            ? TouryCountryRegistry.isoFromCoordinates(m.location!)
            : null);
    reasons.addAll(
      DriverRegistrationCompletenessValidator.missingKeys(
        name: m.displayName,
        email: m.email,
        phone: m.phoneE164,
        idNumber: m.idNumber,
        vehicleName: m.vehicleName,
        modelYear: m.modelYear,
        plate: m.plate,
        hasVehicleType:
            m.vehicleTypeRef != null && m.vehicleTypeText.trim().isNotEmpty,
        hasCountry: m.countryRef != null,
        hasLocation: TouryMapsConfig.isUsableCoordinate(m.location),
        hasRegion: m.regionRef != null,
        hasCity: m.villageRef != null,
        photoUrl: m.photoUrl,
        idImageUrl: m.idImageUrl,
        birthDate: m.birthDate,
        seats: m.seats,
        color: m.color,
        phoneIso2: iso,
      ),
    );
    if (m.villageRef == null) {
      if (!reasons.contains('City')) reasons.add('City');
    }
    if (m.affiliationType == 'company' && m.companyPath.trim().isEmpty) {
      reasons.add('Transport company');
    }
    if (m.isTourGuide && m.guidePermitUrl.trim().isEmpty) {
      reasons.add('Tour guide permit');
    }
    return reasons.toSet().toList();
  }

  static bool isComplete(DriverRegistrationReviewModel m) =>
      blockingReasons(m).isEmpty;
}

class DriverSubmissionResult {
  const DriverSubmissionResult.ok({
    required this.uid,
    required this.submissionId,
    required this.registrationVersion,
    this.idempotentReplay = false,
  })  : success = true,
        errorKey = null;

  const DriverSubmissionResult.fail(this.errorKey)
      : success = false,
        uid = '',
        submissionId = '',
        registrationVersion = 0,
        idempotentReplay = false;

  final bool success;
  final String? errorKey;
  final String uid;
  final String submissionId;
  final int registrationVersion;
  final bool idempotentReplay;
}

/// Writes registration payload to `user/{uid}` with idempotency.
/// Cash-wave: auto-activates (`actev_mndob=true`, `registration_status=approved`).
abstract final class DriverRegistrationSubmissionService {
  DriverRegistrationSubmissionService._();

  static String _newSubmissionId(String uid) =>
      'sub_${uid}_${DateTime.now().millisecondsSinceEpoch}';

  /// Re-applies ismndob + actev for accounts stuck on approved-but-inactive.
  static Future<bool> repairAutoActivate({DocumentReference? userRef}) async {
    final ref = userRef ??
        (FirebaseAuth.instance.currentUser == null
            ? null
            : UserRecord.collection.doc(FirebaseAuth.instance.currentUser!.uid));
    if (ref == null) return false;
    try {
      final snap = await ref.get();
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      if (data['actev_mndob'] == true && data['ismndob'] == true) {
        return true;
      }
      await _claimAndAutoActivateDriver(ref);
      final after = await ref.get();
      final afterData = after.data() as Map<String, dynamic>? ?? {};
      return afterData['actev_mndob'] == true && afterData['ismndob'] == true;
    } catch (e) {
      debugPrint('DriverRegistrationSubmissionService.repairAutoActivate: $e');
      return false;
    }
  }

  static Future<DriverSubmissionResult> submit({
    required DriverRegistrationReviewModel model,
    required Map<String, dynamic> profileFields,
    String? clientSubmissionId,
  }) async {
    final blockers =
        DriverRegistrationCompletenessService.blockingReasons(model);
    if (blockers.isNotEmpty) {
      return DriverSubmissionResult.fail(blockers.first);
    }

    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null || auth.isAnonymous || auth.uid != model.uid) {
      return const DriverSubmissionResult.fail('Please sign in first.');
    }

    final submissionId =
        (clientSubmissionId != null && clientSubmissionId.isNotEmpty)
            ? clientSubmissionId
            : _newSubmissionId(model.uid);
    final ref = UserRecord.collection.doc(model.uid);

    try {
      final snap = await ref.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final existingStatus = (data['registration_status'] as String?) ?? '';
      final existingSubId = (data['submission_id'] as String?) ?? '';
      final existingVersion =
          (data['registration_version'] as num?)?.toInt() ?? 0;

      // Idempotent replay: same submission already pending.
      if (existingSubId == submissionId &&
          (existingStatus == 'pending_review' ||
              existingStatus == 'submitted')) {
        return DriverSubmissionResult.ok(
          uid: model.uid,
          submissionId: submissionId,
          registrationVersion: existingVersion,
          idempotentReplay: true,
        );
      }

      if (existingStatus == 'approved' && data['actev_mndob'] == true) {
        return const DriverSubmissionResult.fail(
          'Your account is already approved.',
        );
      }
      if (existingStatus == 'suspended' || existingStatus == 'blocked') {
        return const DriverSubmissionResult.fail(
          'This account has been disabled.',
        );
      }

      final nextVersion = existingVersion + 1;
      final isResubmit = model.isResubmit ||
          existingStatus == 'changes_requested' ||
          existingStatus == 'rejected';

      final openChanges =
          DriverRequestedChange.listFrom(data['requested_changes'])
              .map((c) => c.toMap()..['resolved'] = true)
              .toList();

      // Profile fields may force pending/inactive — strip then set approved.
      final cleanedProfile = Map<String, dynamic>.from(profileFields)
        ..remove('actev_mndob')
        ..remove('registration_status')
        ..remove('ismndob');

      final payload = <String, dynamic>{
        ...cleanedProfile,
        'uid': model.uid,
        'ismndob': true,
        'ismndom': true,
        // Cash-wave: auto-activate after registration (docs optional).
        'actev_mndob': true,
        'ngl': false,
        'registration_status': 'approved',
        'submission_status': 'approved',
        'rejection_reason': '',
        'submission_id': submissionId,
        'registration_version': nextVersion,
        'submitted_at': FieldValue.serverTimestamp(),
        'approved_at': FieldValue.serverTimestamp(),
        if (isResubmit) 'resubmitted_at': FieldValue.serverTimestamp(),
        if (isResubmit) 'resubmission_id': submissionId,
        'requested_changes': openChanges,
        'vehicle_review_status': 'approved',
        'document_review_status': 'not_required',
        'account_status': 'active',
        'operational_status': 'offline',
        'auto_activated': true,
        'auto_activated_at': FieldValue.serverTimestamp(),
      };

      final isCompany = model.affiliationType == 'company' &&
          model.companyPath.trim().isNotEmpty;
      if (isCompany) {
        payload['transport_company'] =
            FirebaseFirestore.instance.doc(model.companyPath.trim());
        payload['transport_company_text'] = model.companyName.trim();
      } else if (snap.exists) {
        // Clear company link when switching to independent on update.
        payload['transport_company'] = FieldValue.delete();
        payload['transport_company_text'] = FieldValue.delete();
      } else {
        payload.remove('transport_company');
        payload.remove('transport_company_text');
      }

      if (model.isTourGuide) {
        payload[TourGuideStatus.fieldIsTourGuide] = true;
        payload[TourGuideStatus.fieldStatus] = TourGuideStatus.pending;
        payload[TourGuideStatus.fieldPermitUrl] = model.guidePermitUrl.trim();
      } else {
        payload[TourGuideStatus.fieldIsTourGuide] = false;
        payload[TourGuideStatus.fieldStatus] = TourGuideStatus.none;
      }

      // Firestore create rules forbid `ismndob` on first write. Create the
      // profile without it, then claim driver + auto-activate via update.
      if (!snap.exists) {
        final createPayload = Map<String, dynamic>.from(payload)
          ..remove('ismndob')
          ..['actev_mndob'] = false;
        await ref.set(createPayload);
        await _claimAndAutoActivateDriver(ref);
      } else {
        try {
          await ref.set(payload, SetOptions(merge: true));
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
          final safe = Map<String, dynamic>.from(payload)
            ..remove('ismndob')
            ..['actev_mndob'] = false
            ..['registration_status'] = 'pending_review';
          await ref.set(safe, SetOptions(merge: true));
          await _claimAndAutoActivateDriver(ref);
        }
      }

      // Always re-assert activation (covers partial writes / older rules).
      final activated = await repairAutoActivate(userRef: ref);
      if (!activated) {
        debugPrint(
          'DriverRegistrationSubmissionService: activation incomplete '
          'after submit for ${model.uid}',
        );
      }

      return DriverSubmissionResult.ok(
        uid: model.uid,
        submissionId: submissionId,
        registrationVersion: nextVersion,
      );
    } catch (e) {
      debugPrint('DriverRegistrationSubmissionService.submit failed: $e');
      return const DriverSubmissionResult.fail(
        'Could not complete registration. Please try again.',
      );
    }
  }

  /// Claims ismndob and auto-activates (temporary cash-wave policy).
  static Future<void> _claimAndAutoActivateDriver(DocumentReference ref) async {
    try {
      await ref.update({
        'ismndob': true,
        'ismndom': true,
        'actev_mndob': true,
        'registration_status': 'approved',
        'submission_status': 'approved',
        'account_status': 'active',
        'document_review_status': 'not_required',
        'vehicle_review_status': 'approved',
        'auto_activated': true,
        'auto_activated_at': FieldValue.serverTimestamp(),
        'approved_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'DriverRegistrationSubmissionService: auto-activate skipped: $e',
      );
      // Fallback: at least claim pending-driver flag so Admin list can see them.
      try {
        await ref.update({
          'ismndob': true,
          'ismndom': true,
          'actev_mndob': false,
          'registration_status': 'pending_review',
          'submission_status': 'pending_review',
        });
      } catch (e2) {
        debugPrint(
          'DriverRegistrationSubmissionService: ismndob claim skipped: $e2',
        );
      }
    }
  }
}
