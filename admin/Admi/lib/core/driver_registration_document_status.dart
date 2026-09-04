import '/core/driver_license_document.dart';

/// Canonical Registration V2 document completeness (Admin + Driver shared logic).
///
/// Required V2 slots: national_id, vehicle_registration, driver_license (front+back).
/// Profile photo is also required for submit (kept separate in [profilePhotoOk]).
///
/// V2 SoT: `doc_*.storagePath` under `users/{uid}/...`.
/// Legacy records may still use HTTPS URL strings only.
enum DriverRegistrationDocStatus {
  complete,
  missing,
  needsReupload,
  rejected,
}

class DriverRegistrationDocumentSlotStatus {
  const DriverRegistrationDocumentSlotStatus({
    required this.type,
    required this.status,
    required this.hasAsset,
    this.usesStoragePath = false,
  });

  final String type;
  final DriverRegistrationDocStatus status;
  final bool hasAsset;
  final bool usesStoragePath;
}

abstract final class DriverRegistrationDocumentStatus {
  DriverRegistrationDocumentStatus._();

  static const requiredTypes = <String>[
    'national_id',
    'vehicle_registration',
    'driver_license',
  ];

  static bool isStoragePath(String? raw) {
    final p = (raw ?? '').trim();
    return p.startsWith('users/') && !p.contains('..');
  }

  static String? _storagePathFrom(Map<String, dynamic> data, String v2Key) {
    final slot = data[v2Key];
    if (slot is Map && slot['storagePath'] is String) {
      final p = (slot['storagePath'] as String).trim();
      if (isStoragePath(p)) return p;
    }
    return null;
  }

  static String? _urlFrom(
      Map<String, dynamic> data, String v2Key, String legacyKey) {
    final slot = data[v2Key];
    if (slot is Map && slot['url'] is String) {
      final u = (slot['url'] as String).trim();
      if (u.isNotEmpty) return u;
    }
    final leg = data[legacyKey];
    if (leg is String && leg.trim().isNotEmpty) return leg.trim();
    return null;
  }

  static bool _hasPresentAsset(
    Map<String, dynamic> data,
    String v2Key,
    String legacyKey,
  ) {
    if (_storagePathFrom(data, v2Key) != null) return true;
    final url = _urlFrom(data, v2Key, legacyKey);
    return url != null && url.startsWith('https://');
  }

  static String _slotStatusRaw(Map<String, dynamic> data, String v2Key) {
    final slot = data[v2Key];
    if (slot is Map && slot['status'] is String) {
      return (slot['status'] as String).trim().toLowerCase();
    }
    return '';
  }

  static DriverRegistrationDocStatus statusForType(
    Map<String, dynamic> data,
    String type,
  ) {
    late final String v2;
    late final String legacy;
    switch (type) {
      case 'national_id':
        v2 = 'doc_national_id';
        legacy = 'img_id_rksh';
        break;
      case 'vehicle_registration':
        v2 = 'doc_vehicle_registration';
        legacy = 'img_id_car';
        break;
      case 'driver_license':
        return _driverLicenseAggregateStatus(data);
      default:
        return DriverRegistrationDocStatus.missing;
    }
    final raw = _slotStatusRaw(data, v2);
    if (raw == 'rejected') return DriverRegistrationDocStatus.rejected;
    if (raw == 'needs_reupload')
      return DriverRegistrationDocStatus.needsReupload;
    if (_hasPresentAsset(data, v2, legacy)) {
      return DriverRegistrationDocStatus.complete;
    }
    return DriverRegistrationDocStatus.missing;
  }

  static DriverRegistrationDocStatus _driverLicenseAggregateStatus(
    Map<String, dynamic> data,
  ) {
    for (final key in [
      DriverLicenseDocumentFields.front,
      DriverLicenseDocumentFields.back,
      DriverLicenseDocumentFields.legacy,
    ]) {
      final raw = _slotStatusRaw(data, key);
      if (raw == 'rejected') return DriverRegistrationDocStatus.rejected;
      if (raw == 'needs_reupload') {
        return DriverRegistrationDocStatus.needsReupload;
      }
    }
    if (DriverLicenseDocument.isCompleteForSubmit(data)) {
      return DriverRegistrationDocStatus.complete;
    }
    if (DriverLicenseDocument.isApprovedLegacyLicenseOnly(data)) {
      return DriverRegistrationDocStatus.complete;
    }
    return DriverRegistrationDocStatus.missing;
  }

  static bool profilePhotoOk(Map<String, dynamic> data) {
    final path = (data['photo_storage_path'] as String?)?.trim() ?? '';
    if (isStoragePath(path)) return true;
    final u = (data['photo_url'] as String?)?.trim() ?? '';
    return u.startsWith('https://');
  }

  /// Overall V2 required docs (excluding profile photo).
  static DriverRegistrationDocStatus overall(Map<String, dynamic> data) {
    final slots = requiredTypes.map((t) => statusForType(data, t)).toList();
    if (slots.any((s) => s == DriverRegistrationDocStatus.rejected)) {
      return DriverRegistrationDocStatus.rejected;
    }
    if (slots.any((s) => s == DriverRegistrationDocStatus.needsReupload)) {
      return DriverRegistrationDocStatus.needsReupload;
    }
    if (slots.any((s) => s == DriverRegistrationDocStatus.missing)) {
      return DriverRegistrationDocStatus.missing;
    }
    return DriverRegistrationDocStatus.complete;
  }

  static bool isComplete(Map<String, dynamic> data) =>
      overall(data) == DriverRegistrationDocStatus.complete &&
      profilePhotoOk(data);

  static List<String> missingTypes(Map<String, dynamic> data) {
    return requiredTypes
        .where((t) =>
            statusForType(data, t) != DriverRegistrationDocStatus.complete)
        .toList();
  }
}
