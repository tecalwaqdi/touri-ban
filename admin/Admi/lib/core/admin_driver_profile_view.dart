import 'package:flutter/widgets.dart';

import '/backend/backend.dart';
import '/components/admin_status_badge.dart';
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
  driverLicense,
  tourGuidePermit,
}

enum AdminDriverDocPresence {
  present,
  missing,
  legacy,
}

enum AdminDriverDocAccessMode {
  v2StoragePath,
  legacyUrl,
  missing,
}

/// Single document slot on the driver profile.
class AdminDriverDocumentSlot {
  const AdminDriverDocumentSlot({
    required this.kind,
    required this.fieldKey,
    required this.storagePath,
    required this.legacyUrl,
    required this.presence,
    required this.accessMode,
  });

  final AdminDriverDocKind kind;
  final String fieldKey;
  final String storagePath;
  final String legacyUrl;
  final AdminDriverDocPresence presence;
  final AdminDriverDocAccessMode accessMode;

  bool get canView =>
      accessMode == AdminDriverDocAccessMode.v2StoragePath ||
      accessMode == AdminDriverDocAccessMode.legacyUrl;
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

  static AdminDriverVehicleSummary vehicle(UserRecord user) {
    final data = user.snapshotData;
    final classification = user.textTypeCarMndob.isNotEmpty
        ? user.textTypeCarMndob
        : _str(data, 'mdenh_aml');
    final name = _str(data, 'NameCar');
    final model = _str(data, 'ModelCar');
    final plate = _str(data, 'number_lohh_car').isNotEmpty
        ? _str(data, 'number_lohh_car')
        : _str(data, 'normalized_plate');
    final color = _str(data, 'vehicle_color');
    final incomplete = classification.isEmpty &&
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

    AdminDriverDocumentSlot slot(AdminDriverDocKind kind, String key) {
      final storagePath = storagePathOf(key);
      final mapUrl = urlFromMap(key);
      if (DriverRegistrationDocumentStatus.isStoragePath(storagePath)) {
        return AdminDriverDocumentSlot(
          kind: kind,
          fieldKey: key,
          storagePath: storagePath,
          legacyUrl: mapUrl,
          presence: AdminDriverDocPresence.present,
          accessMode: AdminDriverDocAccessMode.v2StoragePath,
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
        );
      }
      return AdminDriverDocumentSlot(
        kind: kind,
        fieldKey: key,
        storagePath: '',
        legacyUrl: '',
        presence: AdminDriverDocPresence.missing,
        accessMode: AdminDriverDocAccessMode.missing,
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
              storagePathOf('doc_national_id')) &&
          urlFromMap('doc_national_id').isEmpty)
        slot(AdminDriverDocKind.nationalId, 'img_id_rksh'),
      slot(AdminDriverDocKind.vehicleRegistration, 'doc_vehicle_registration'),
      if (!DriverRegistrationDocumentStatus.isStoragePath(
              storagePathOf('doc_vehicle_registration')) &&
          urlFromMap('doc_vehicle_registration').isEmpty)
        slot(AdminDriverDocKind.vehiclePhoto, 'img_id_car'),
      slot(AdminDriverDocKind.driverLicense, 'doc_driver_license'),
    ];
    if (user.isTourGuide || legacyUrlOf('tour_guide_permit_url').isNotEmpty) {
      out.add(slot(AdminDriverDocKind.tourGuidePermit, 'tour_guide_permit_url'));
    }
    return out;
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
    final raw =
        '${user.snapshotData['registration_documents_status'] ?? ''}'.trim();
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
      case AdminDriverDocKind.driverLicense:
        return uiTr(context, 'رخصة القيادة');
      case AdminDriverDocKind.tourGuidePermit:
        return uiTr(context, 'تصريح المرشد');
    }
  }
}
