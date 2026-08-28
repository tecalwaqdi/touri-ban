import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/driver_registration_submission_error_mapper.dart';
import '/core/driver_country_resolver.dart';
import '/core/driver_operational_eligibility_resolver.dart';
import '/core/driver_registration_validators.dart';
import '/core/tour_guide_status.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_maps_config.dart';

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
    required this.licenseImageUrl,
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
  final String licenseImageUrl;
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
        } else if (user.emailVerified != true) {
          reasons.add('Please verify your email before submitting');
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
    if (!_https(m.carImageUrl)) reasons.add('Vehicle registration');
    if (!_https(m.licenseImageUrl)) reasons.add('Driver license');
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

  static bool _https(String url) {
    final t = url.trim();
    return t.startsWith('https://');
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
/// Production: stays `pending_review` until admin/country agent approves.
abstract final class DriverRegistrationSubmissionService {
  DriverRegistrationSubmissionService._();

  static bool _submitInFlight = false;

  static String _newSubmissionId(String uid) =>
      'sub_${uid}_${DateTime.now().millisecondsSinceEpoch}';

  /// Resubmit after admin requested changes — server owns status transition.
  @visibleForTesting
  static bool isResubmitAfterChangesRequested(String status) =>
      status == 'changes_requested' ||
      status == 'needs_changes' ||
      status == 'rejected';

  /// Profile/doc fields only — must not alter review metadata (Rules + CF).
  @visibleForTesting
  static Map<String, dynamic> buildResubmitProfilePayload({
    required Map<String, dynamic> cleanedProfile,
    required String uid,
    required String submissionId,
    required DriverRegistrationReviewModel model,
  }) {
    final safeProfile = Map<String, dynamic>.from(cleanedProfile)
      ..remove('actev_mndob')
      ..remove('registration_status')
      ..remove('submission_status')
      ..remove('ismndob')
      ..remove('auto_activated')
      ..remove('approved_at')
      ..remove('approvedAt')
      ..remove('approvedBy')
      ..remove('rejectedAt')
      ..remove('rejectedBy')
      ..remove('rejectionReason')
      ..remove('changesRequestedAt')
      ..remove('changesRequestedBy')
      ..remove('changeRequestReason')
      ..remove('requested_changes')
      ..remove('fieldsToFix')
      ..remove('reviewVersion')
      ..remove('reviewAttemptCount')
      ..remove('vehicle_review_status')
      ..remove('document_review_status')
      ..remove('account_status')
      ..remove('operational_status');

    final payload = <String, dynamic>{
      ...safeProfile,
      'uid': uid,
      'submission_id': submissionId,
    };

    final isCompany = model.affiliationType == 'company' &&
        model.companyPath.trim().isNotEmpty;
    if (isCompany) {
      payload['transport_company'] =
          FirebaseFirestore.instance.doc(model.companyPath.trim());
      payload['transport_company_text'] = model.companyName.trim();
    }

    if (model.isTourGuide) {
      payload[TourGuideStatus.fieldIsTourGuide] = true;
      payload[TourGuideStatus.fieldStatus] = TourGuideStatus.pending;
      payload[TourGuideStatus.fieldPermitUrl] = model.guidePermitUrl.trim();
    } else {
      payload[TourGuideStatus.fieldIsTourGuide] = false;
      payload[TourGuideStatus.fieldStatus] = TourGuideStatus.none;
    }

    return payload;
  }

  /// Ensures pending-driver flags without self-activation.
  static Future<bool> repairPendingClaim({DocumentReference? userRef}) async {
    final ref = userRef ??
        (FirebaseAuth.instance.currentUser == null
            ? null
            : UserRecord.collection.doc(FirebaseAuth.instance.currentUser!.uid));
    if (ref == null) return false;
    try {
      final snap = await ref.get();
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      if (data['ismndob'] == true &&
          (data['registration_status'] == 'pending_review' ||
              data['registration_status'] == 'submitted' ||
              data['registration_status'] == 'changes_requested' ||
              data['registration_status'] == 'needs_changes' ||
              data['actev_mndob'] == true)) {
        return true;
      }
      await _claimPendingDriver(ref);
      final after = await ref.get();
      final afterData = after.data() as Map<String, dynamic>? ?? {};
      return afterData['ismndob'] == true;
    } catch (e) {
      debugPrint('DriverRegistrationSubmissionService.repairPendingClaim: $e');
      return false;
    }
  }

  /// @Deprecated Use [repairPendingClaim]. Kept for older call sites.
  static Future<bool> repairAutoActivate({DocumentReference? userRef}) =>
      repairPendingClaim(userRef: userRef);

  static Future<DriverSubmissionResult> submit({
    required DriverRegistrationReviewModel model,
    required Map<String, dynamic> profileFields,
    String? clientSubmissionId,
  }) async {
    if (_submitInFlight) {
      return const DriverSubmissionResult.fail(
        'Could not complete registration. Please try again.',
      );
    }
    _submitInFlight = true;
    try {
      return await _submitInner(
        model: model,
        profileFields: profileFields,
        clientSubmissionId: clientSubmissionId,
      );
    } finally {
      _submitInFlight = false;
    }
  }

  static Future<DriverSubmissionResult> _submitInner({
    required DriverRegistrationReviewModel model,
    required Map<String, dynamic> profileFields,
    String? clientSubmissionId,
  }) async {
    final blockers =
        DriverRegistrationCompletenessService.blockingReasons(model);
    if (blockers.isNotEmpty) {
      return DriverSubmissionResult.fail(blockers.first);
    }

    final canonicalCountry =
        DriverCountryResolver.canonicalCountryRef(model.countryRef);
    final countryReqs =
        await DriverDocumentRequirementResolver.resolveForCountryRef(
      canonicalCountry,
    );
    if (countryReqs.isEmpty) {
      debugPrint(
        '[DriverRegistration][country_requirements] empty after baseline fallback',
      );
      return const DriverSubmissionResult.fail(
        'Country registration requirements could not be loaded. Please try again later or contact support.',
      );
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
      final isResubmit = isResubmitAfterChangesRequested(existingStatus);
      final alreadyClaimedDriver = data['ismndob'] == true;

      // Never allow client payload to self-approve or set review metadata.
      final cleanedProfile = Map<String, dynamic>.from(profileFields)
        ..remove('actev_mndob')
        ..remove('registration_status')
        ..remove('submission_status')
        ..remove('ismndob')
        ..remove('auto_activated')
        ..remove('approved_at')
        ..remove('approvedAt')
        ..remove('approvedBy')
        ..remove('rejectedAt')
        ..remove('rejectedBy')
        ..remove('rejectionReason')
        ..remove('changesRequestedAt')
        ..remove('changesRequestedBy')
        ..remove('changeRequestReason')
        ..remove('reviewVersion')
        ..remove('reviewAttemptCount');

      if (isResubmit && alreadyClaimedDriver) {
        // Resubmit: editable profile/docs only. Keep registration_status and
        // requested_changes until submitDriverApplicationV2 transitions server-side.
        debugPrint(
          '[DriverRegistration][resubmit_profile_write] '
          'status=$existingStatus uid=${model.uid}',
        );
        final resubmitPayload = buildResubmitProfilePayload(
          cleanedProfile: cleanedProfile,
          uid: model.uid,
          submissionId: submissionId,
          model: model,
        );
        await ref.set(resubmitPayload, SetOptions(merge: true));
      } else {
        // First submit (or legacy reclaim): draft profile + pending claim.
        final openChanges =
            DriverRequestedChange.listFrom(data['requested_changes'])
                .map((c) => c.toMap()..['resolved'] = true)
                .toList();

        final payload = <String, dynamic>{
          ...cleanedProfile,
          'uid': model.uid,
          'ismndob': true,
          'ismndom': true,
          'actev_mndob': false,
          'ngl': false,
          'registration_flow_version': 2,
          'registration_status':
              (existingStatus == 'pending_review') ? 'pending_review' : 'draft',
          'submission_status': 'draft',
          'rejection_reason': '',
          'submission_id': submissionId,
          'registration_version': nextVersion,
          'requested_changes': openChanges,
          'vehicle_review_status': 'pending',
          'document_review_status': 'pending',
          'account_status': 'inactive',
          'operational_status': 'offline',
          'auto_activated': false,
        };

        final isCompany = model.affiliationType == 'company' &&
            model.companyPath.trim().isNotEmpty;
        if (isCompany) {
          payload['transport_company'] =
              FirebaseFirestore.instance.doc(model.companyPath.trim());
          payload['transport_company_text'] = model.companyName.trim();
        } else if (snap.exists) {
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

        debugPrint(
          '[DriverRegistration][first_submit_profile_write] uid=${model.uid}',
        );
        final writePayload = Map<String, dynamic>.from(payload)
          ..remove('ismndob');
        if (!snap.exists) {
          await ref.set(writePayload);
        } else {
          await ref.set(writePayload, SetOptions(merge: true));
        }

        final claimed = await _claimPendingDriver(ref);
        if (!claimed) {
          debugPrint(
            '[DriverRegistration][claim] pending claim failed uid=${model.uid}',
          );
          return const DriverSubmissionResult.fail(
            'Could not complete registration. Please try again.',
          );
        }
      }

      // Server-side submit: email/phone/docs gates + pending_review.
      // Never call autoActivateDriver for Registration V2.
      debugPrint(
        '[DriverRegistration][cloud_submit] '
        'resubmit=$isResubmit idempotencyKey=$submissionId',
      );
      final server = await makeCloudCall('submitDriverApplicationV2', {
        'idempotencyKey': submissionId,
      });
      if (server['ok'] != true) {
        final details = DriverRegistrationSubmissionErrorMapper.detailsFrom(
          server['details'],
        );
        final messageKey = DriverRegistrationSubmissionErrorMapper.messageKey(
          reasonCode: server['reasonCode']?.toString() ?? details['reasonCode']?.toString(),
          fallbackMessage: server['error']?.toString(),
          cfCode: server['code']?.toString(),
          missingDocuments: DriverRegistrationSubmissionErrorMapper.stringList(
            details['missingDocuments'],
          ),
          missingExpiryTypes: DriverRegistrationSubmissionErrorMapper.stringList(
            details['missingExpiryTypes'],
          ),
        );
        debugPrint(
          'DriverRegistrationSubmissionService: submit V2 failed: '
          '${server['reasonCode'] ?? details['reasonCode'] ?? server['code']}',
        );
        return DriverSubmissionResult.fail(messageKey);
      }

      return DriverSubmissionResult.ok(
        uid: model.uid,
        submissionId: submissionId,
        registrationVersion:
            (server['reviewVersion'] as num?)?.toInt() ?? nextVersion,
        idempotentReplay: server['idempotent'] == true,
      );
    } on FirebaseException catch (e, st) {
      debugPrint(
        '[DriverRegistration][firestore] code=${e.code} message=${e.message}',
      );
      debugPrint('$st');
      if (e.code == 'permission-denied') {
        return const DriverSubmissionResult.fail(
          'Could not complete registration. Please try again.',
        );
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return const DriverSubmissionResult.fail(
          'Could not reach the service. Check your connection and try again.',
        );
      }
      return const DriverSubmissionResult.fail(
        'Could not complete registration. Please try again.',
      );
    } catch (e, st) {
      debugPrint('[DriverRegistration][unexpected] $e');
      debugPrint('$st');
      return const DriverSubmissionResult.fail(
        'Could not complete registration. Please try again.',
      );
    }
  }

  /// Claims ismndob as pending V2 draft — never self-approves.
  static Future<bool> _claimPendingDriver(DocumentReference ref) async {
    try {
      await ref.update({
        'ismndob': true,
        'ismndom': true,
        'actev_mndob': false,
        'ngl': false,
        'registration_flow_version': 2,
        'registration_status': 'draft',
        'submission_status': 'draft',
        'account_status': 'inactive',
        'operational_status': 'offline',
        'auto_activated': false,
      });
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        '[DriverRegistration][claim] FirebaseException code=${e.code} '
        'message=${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('[DriverRegistration][claim] $e');
      return false;
    }
  }
}
