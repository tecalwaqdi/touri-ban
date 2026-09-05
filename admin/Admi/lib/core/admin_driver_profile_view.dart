import 'package:flutter/widgets.dart';

import '/backend/backend.dart';
import '/components/admin_status_badge.dart';
import '/core/driver_license_document.dart';
import '/core/driver_registration_document_status.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Normalized driver review/account view for Admin (read-only helpers).
///
/// Does **not** invent expiry dates or missing vehicle fields.
enum AdminDriverReviewBucket {
  pendingReview,
  approved,
  rejected,
  needsChanges,
  suspended,
  draft,
  unknownLegacy,
}

enum AdminDriverDocKind {
  profilePhoto,
  nationalId,
  vehiclePhoto,
  vehicleRegistration,
  driverLicenseFront,
  driverLicenseBack,
  driverLicenseLegacy,
  tourGuidePermit,
}

enum AdminDriverDocPresence { present, missing, legacy, optionalMissing }

enum AdminDriverDocAccessMode { v2StoragePath, legacyUrl, missing }

/// Single document slot on the driver profile.
class AdminDriverDocumentSlot {
  const AdminDriverDocumentSlot({
    required this.kind,
    required this.fieldKey,
    required this.storagePath,
    required this.legacyUrl,
    required this.presence,
    required this.accessMode,
    this.expiryDate,
  });

  final AdminDriverDocKind kind;
  final String fieldKey;
  final String storagePath;
  final String legacyUrl;
  final AdminDriverDocPresence presence;
  final AdminDriverDocAccessMode accessMode;
  final DateTime? expiryDate;

  bool get canView =>
      accessMode == AdminDriverDocAccessMode.v2StoragePath ||
      accessMode == AdminDriverDocAccessMode.legacyUrl;

  bool get isExpired {
    final e = expiryDate;
    if (e == null) return false;
    return e.toUtc().isBefore(DateTime.now().toUtc());
  }

  bool get isExpiringSoon {
    final e = expiryDate;
    if (e == null || isExpired) return false;
    return e.toUtc().difference(DateTime.now().toUtc()).inDays <= 30;
  }
}

/// Vehicle summary from live SoT fields (type_car ref + denormalized text).
class AdminDriverVehicleSummary {
  const AdminDriverVehicleSummary({
    required this.classificationLabel,
    required this.name,
    required this.modelYear,
    required this.plate,
    required this.color,
    required this.typeCarRef,
    required this.isLegacyIncomplete,
  });

  final String classificationLabel;
  final String name;
  final String modelYear;
  final String plate;
  final String color;
  final DocumentReference? typeCarRef;
  final bool isLegacyIncomplete;

  String get oneLine {
    final parts = <String>[];
    if (classificationLabel.isNotEmpty) parts.add(classificationLabel);
    final car = [name, modelYear].where((e) => e.isNotEmpty).join(' ');
    if (car.isNotEmpty) parts.add(car);
    if (plate.isNotEmpty) parts.add(plate);
    if (parts.isEmpty) return 'Missing / Legacy';
    return parts.join(' · ');
  }
}

abstract final class AdminDriverProfileView {
  AdminDriverProfileView._();

  static String _str(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return '';
    return v.toString().trim();
  }

  static DateTime? _date(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is DateTime) return v;
    return null;
  }

  /// Prefer `registration_status`, fall back to `submission_status`.
  static String rawRegistrationStatusFromMap(Map<String, dynamic> data) {
    final a = _str(data, 'registration_status');
    if (a.isNotEmpty) return a;
    return _str(data, 'submission_status');
  }

  static String rawRegistrationStatus(UserRecord user) =>
      rawRegistrationStatusFromMap(user.snapshotData);

  static AdminDriverReviewBucket reviewBucketFromRaw(String rawIn) {
    final raw = rawIn.toLowerCase();
    if (raw.isEmpty) return AdminDriverReviewBucket.unknownLegacy;
    switch (raw) {
      case 'pending_review':
      case 'submitted':
      case 'pending':
        return AdminDriverReviewBucket.pendingReview;
      case 'approved':
        return AdminDriverReviewBucket.approved;
      case 'rejected':
        return AdminDriverReviewBucket.rejected;
      case 'changes_requested':
      case 'needs_changes':
      case 'changesrequested':
        return AdminDriverReviewBucket.needsChanges;
      case 'suspended':
      case 'blocked':
        return AdminDriverReviewBucket.suspended;
      case 'draft':
        return AdminDriverReviewBucket.draft;
      default:
        return AdminDriverReviewBucket.unknownLegacy;
    }
  }

  static AdminDriverReviewBucket reviewBucket(UserRecord user) =>
      reviewBucketFromRaw(rawRegistrationStatus(user));

  static String reviewLabel(BuildContext context, AdminDriverReviewBucket b) {
    switch (b) {
      case AdminDriverReviewBucket.pendingReview:
        return uiTr(context, 'تحت المراجعة');
      case AdminDriverReviewBucket.approved:
        return uiTr(context, 'معتمد');
      case AdminDriverReviewBucket.rejected:
        return uiTr(context, 'مرفوض');
      case AdminDriverReviewBucket.needsChanges:
        return uiTr(context, 'يحتاج استكمال');
      case AdminDriverReviewBucket.suspended:
        return uiTr(context, 'موقوف');
      case AdminDriverReviewBucket.draft:
        return uiTr(context, 'مسودة');
      case AdminDriverReviewBucket.unknownLegacy:
        return uiTr(context, 'حالة غير محددة');
    }
  }

  static AdminStatusKind reviewBadgeKind(AdminDriverReviewBucket b) {
    switch (b) {
      case AdminDriverReviewBucket.pendingReview:
        return AdminStatusKind.pending;
      case AdminDriverReviewBucket.approved:
        return AdminStatusKind.active;
      case AdminDriverReviewBucket.rejected:
        return AdminStatusKind.cancelled;
      case AdminDriverReviewBucket.needsChanges:
        return AdminStatusKind.medium;
      case AdminDriverReviewBucket.suspended:
        return AdminStatusKind.inactive;
      case AdminDriverReviewBucket.draft:
        return AdminStatusKind.draft;
      case AdminDriverReviewBucket.unknownLegacy:
        return AdminStatusKind.unknown;
    }
  }

  static String _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = _str(data, k);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static AdminDriverVehicleSummary vehicle(UserRecord user) {
    final data = user.snapshotData;
    final classification = user.textTypeCarMndob.isNotEmpty
        ? user.textTypeCarMndob
        : _firstNonEmpty(data, [
            'mdenh_aml',
            'vehicle_type',
            'classification',
            'text_type_car_mndob',
          ]);
    final name = _firstNonEmpty(data, [
      'NameCar',
      'vehicle_make',
      'make',
      'brand',
    ]);
    final model = _firstNonEmpty(data, [
      'ModelCar',
      'model',
      'year',
      'vehicle_year',
    ]);
    final plate = _firstNonEmpty(data, [
      'number_lohh_car',
      'normalized_plate',
      'plate',
    ]);
    final color = _firstNonEmpty(data, ['vehicle_color', 'color']);
    final incomplete =
        classification.isEmpty &&
        name.isEmpty &&
        model.isEmpty &&
        plate.isEmpty &&
        !user.hasMndobTypeCar();
    return AdminDriverVehicleSummary(
      classificationLabel: classification,
      name: name,
      modelYear: model,
      plate: plate,
      color: color,
      typeCarRef: user.mndobTypeCar,
      isLegacyIncomplete: incomplete,
    );
  }

  static DateTime? parseDocExpiry(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      return DateTime.tryParse(t);
    }
    // Firestore-like map {seconds, nanoseconds} from some loaders.
    if (raw is Map) {
      final sec = raw['seconds'] ?? raw['_seconds'];
      if (sec is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          sec.toInt() * 1000,
          isUtc: true,
        );
      }
    }
    return null;
  }

  static List<AdminDriverDocumentSlot> documents(UserRecord user) {
    String legacyUrlOf(String key) {
      final v = user.snapshotData[key];
      if (v is String) return v.trim();
      return '';
    }

    String storagePathOf(String key) {
      final v = user.snapshotData[key];
      if (v is Map && v['storagePath'] is String) {
        return (v['storagePath'] as String).trim();
      }
      return '';
    }

    String urlFromMap(String key) {
      final v = user.snapshotData[key];
      if (v is Map && v['url'] is String) return (v['url'] as String).trim();
      return '';
    }

    DateTime? expiryOf(String key) {
      final v = user.snapshotData[key];
      if (v is Map) {
        return parseDocExpiry(v['expiryDate'] ?? v['expiry_date']);
      }
      return null;
    }

    AdminDriverDocumentSlot slot(AdminDriverDocKind kind, String key) {
      final storagePath = storagePathOf(key);
      final mapUrl = urlFromMap(key);
      final expiry = expiryOf(key);
      if (DriverRegistrationDocumentStatus.isStoragePath(storagePath)) {
        return AdminDriverDocumentSlot(
          kind: kind,
          fieldKey: key,
          storagePath: storagePath,
          legacyUrl: mapUrl,
          presence: AdminDriverDocPresence.present,
          accessMode: AdminDriverDocAccessMode.v2StoragePath,
          expiryDate: expiry,
        );
      }
      final legacy = mapUrl.isNotEmpty ? mapUrl : legacyUrlOf(key);
      if (legacy.startsWith('https://')) {
        return AdminDriverDocumentSlot(
          kind: kind,
          fieldKey: key,
          storagePath: '',
          legacyUrl: legacy,
          presence: AdminDriverDocPresence.legacy,
          accessMode: AdminDriverDocAccessMode.legacyUrl,
          expiryDate: expiry,
        );
      }
      return AdminDriverDocumentSlot(
        kind: kind,
        fieldKey: key,
        storagePath: '',
        legacyUrl: '',
        presence: AdminDriverDocPresence.missing,
        accessMode: AdminDriverDocAccessMode.missing,
        expiryDate: expiry,
      );
    }

    AdminDriverDocumentSlot photoSlot() {
      final photoPath =
          (user.snapshotData['photo_storage_path'] as String?)?.trim() ?? '';
      final photoUrl = user.photoUrl.trim();
      // Also accept nested map shape if ever mirrored like other docs.
      final mapPhoto = user.snapshotData['doc_profile_photo'];
      final mapPath = mapPhoto is Map && mapPhoto['storagePath'] is String
          ? (mapPhoto['storagePath'] as String).trim()
          : '';
      final mapUrl = mapPhoto is Map && mapPhoto['url'] is String
          ? (mapPhoto['url'] as String).trim()
          : '';
      final path = DriverRegistrationDocumentStatus.isStoragePath(photoPath)
          ? photoPath
          : (DriverRegistrationDocumentStatus.isStoragePath(mapPath)
                ? mapPath
                : '');
      final fallbackUrl = photoUrl.startsWith('https://')
          ? photoUrl
          : (mapUrl.startsWith('https://') ? mapUrl : '');

      if (path.isNotEmpty) {
        return AdminDriverDocumentSlot(
          kind: AdminDriverDocKind.profilePhoto,
          fieldKey: 'photo_storage_path',
          storagePath: path,
          legacyUrl: fallbackUrl,
          presence: AdminDriverDocPresence.present,
          accessMode: AdminDriverDocAccessMode.v2StoragePath,
        );
      }
      if (fallbackUrl.isNotEmpty) {
        return AdminDriverDocumentSlot(
          kind: AdminDriverDocKind.profilePhoto,
          fieldKey: 'photo_url',
          storagePath: '',
          legacyUrl: fallbackUrl,
          presence: AdminDriverDocPresence.legacy,
          accessMode: AdminDriverDocAccessMode.legacyUrl,
        );
      }
      return AdminDriverDocumentSlot(
        kind: AdminDriverDocKind.profilePhoto,
        fieldKey: 'photo_url',
        storagePath: '',
        legacyUrl: '',
        presence: AdminDriverDocPresence.missing,
        accessMode: AdminDriverDocAccessMode.missing,
      );
    }

    final out = <AdminDriverDocumentSlot>[
      photoSlot(),
      slot(AdminDriverDocKind.nationalId, 'doc_national_id'),
      if (!DriverRegistrationDocumentStatus.isStoragePath(
            storagePathOf('doc_national_id'),
          ) &&
          urlFromMap('doc_national_id').isEmpty)
        slot(AdminDriverDocKind.nationalId, 'img_id_rksh'),
      slot(AdminDriverDocKind.vehicleRegistration, 'doc_vehicle_registration'),
      if (!DriverRegistrationDocumentStatus.isStoragePath(
            storagePathOf('doc_vehicle_registration'),
          ) &&
          urlFromMap('doc_vehicle_registration').isEmpty)
        slot(AdminDriverDocKind.vehiclePhoto, 'img_id_car'),
      ..._licenseSlots(user, slot),
    ];
    if (user.isTourGuide || legacyUrlOf('tour_guide_permit_url').isNotEmpty) {
      out.add(
        slot(AdminDriverDocKind.tourGuidePermit, 'tour_guide_permit_url'),
      );
    }
    return out;
  }

  /// License visual contract (back optional):
  /// A) front exists → show front; back present OR optional-missing (never ناقصة)
  /// B) front missing + legacy → ONE canonical license (legacy) only
  /// C) nothing → one required missing license
  static List<AdminDriverDocumentSlot> _licenseSlots(
    UserRecord user,
    AdminDriverDocumentSlot Function(AdminDriverDocKind, String) slot,
  ) {
    final data = user.snapshotData;
    final hasF = DriverLicenseDocument.hasFront(data);
    final hasB = DriverLicenseDocument.hasBack(data);
    final hasL = DriverLicenseDocument.hasLegacySingle(data);

    AdminDriverDocumentSlot build(
      AdminDriverDocKind kind,
      String key, {
      AdminDriverDocPresence? forcePresence,
    }) {
      final base = slot(kind, key);
      if (forcePresence == null) return base;
      return AdminDriverDocumentSlot(
        kind: base.kind,
        fieldKey: base.fieldKey,
        storagePath: base.storagePath,
        legacyUrl: base.legacyUrl,
        presence: forcePresence,
        accessMode: base.accessMode,
        expiryDate: base.expiryDate,
      );
    }

    // CASE B first when legacy satisfies and front is absent — never emit
    // front-missing + back-missing beside a valid legacy card.
    if (!hasF && hasL) {
      return [
        build(AdminDriverDocKind.driverLicenseLegacy, 'doc_driver_license'),
      ];
    }

    if (hasF) {
      final out = <AdminDriverDocumentSlot>[
        build(
          AdminDriverDocKind.driverLicenseFront,
          'doc_driver_license_front',
        ),
      ];
      if (hasB) {
        out.add(
          build(
            AdminDriverDocKind.driverLicenseBack,
            'doc_driver_license_back',
          ),
        );
      } else {
        out.add(
          build(
            AdminDriverDocKind.driverLicenseBack,
            'doc_driver_license_back',
            forcePresence: AdminDriverDocPresence.optionalMissing,
          ),
        );
      }
      // Legacy companion is suppressed when front exists (avoid triple cards).
      return out;
    }

    // CASE C — single required missing state (not three cards).
    return [
      build(
        AdminDriverDocKind.driverLicenseLegacy,
        'doc_driver_license',
        forcePresence: AdminDriverDocPresence.missing,
      ),
    ];
  }

  /// Complete = shared V2 helper (national ID + vehicle reg + license + photo).
  static bool documentsComplete(UserRecord user) {
    final auth = authoritativeDocumentsStatus(user);
    if (auth == 'complete') return true;
    if (auth == 'missing' ||
        auth == 'needs_reupload' ||
        auth == 'unknown_legacy') {
      return false;
    }
    return DriverRegistrationDocumentStatus.isComplete(
      Map<String, dynamic>.from(user.snapshotData),
    );
  }

  /// Backend-controlled `registration_documents_status` when present.
  static String authoritativeDocumentsStatus(UserRecord user) {
    final raw = '${user.snapshotData['registration_documents_status'] ?? ''}'
        .trim();
    return raw;
  }

  static bool documentsMissing(UserRecord user) => !documentsComplete(user);

  static DateTime? registeredAt(UserRecord user) {
    final data = user.snapshotData;
    return _date(data, 'submitted_at') ??
        _date(data, 'created_time') ??
        user.createdTime;
  }

  static DateTime? lastUpdatedAt(UserRecord user) {
    final data = user.snapshotData;
    return _date(data, 'reviewed_at') ??
        _date(data, 'resubmitted_at') ??
        _date(data, 'submitted_at') ??
        user.createdTime;
  }

  static String countryLabel(UserRecord user) {
    // Denormalized country name is not always present; show path id if needed.
    final ref = user.revDolh;
    if (ref == null) return '';
    return ref.id;
  }

  /// Denormalized expiry queue bucket from CF (`none` / `expiring_soon` / `expired`).
  static String docExpiryBucket(UserRecord user) {
    final raw = '${user.snapshotData['doc_expiry_bucket'] ?? ''}'.trim();
    return raw;
  }

  static bool isActivated(UserRecord user) => user.actevMndob == true;

  /// Compact lifecycle line for profile / list sheets (localized keys via uiTr).
  static List<String> lifecycleChips(UserRecord user) {
    final chips = <String>[];
    final review = rawRegistrationStatus(user);
    if (review.isNotEmpty) {
      chips.add('reg:$review');
    }
    final docs = authoritativeDocumentsStatus(user);
    if (docs.isNotEmpty) {
      chips.add('docs:$docs');
    } else {
      chips.add(documentsComplete(user) ? 'docs:complete' : 'docs:missing');
    }
    chips.add(isActivated(user) ? 'act:on' : 'act:off');
    final exp = docExpiryBucket(user);
    if (exp.isNotEmpty && exp != 'none') {
      chips.add('exp:$exp');
    }
    return chips;
  }

  static String docKindLabel(BuildContext context, AdminDriverDocKind kind) {
    switch (kind) {
      case AdminDriverDocKind.profilePhoto:
        return uiTr(context, 'الصورة الشخصية');
      case AdminDriverDocKind.nationalId:
        return uiTr(context, 'بطاقة الهوية');
      case AdminDriverDocKind.vehiclePhoto:
        return uiTr(context, 'صورة / استمارة السيارة');
      case AdminDriverDocKind.vehicleRegistration:
        return uiTr(context, 'استمارة السيارة');
      case AdminDriverDocKind.driverLicenseFront:
        return uiTr(context, 'رخصة القيادة (الوجه الأمامي)');
      case AdminDriverDocKind.driverLicenseBack:
        return uiTr(context, 'الوجه الخلفي — اختياري');
      case AdminDriverDocKind.driverLicenseLegacy:
        // Single-slot presentation (legacy-only or fully missing).
        return uiTr(context, 'رخصة القيادة');
      case AdminDriverDocKind.tourGuidePermit:
        return uiTr(context, 'تصريح المرشد');
    }
  }
}
