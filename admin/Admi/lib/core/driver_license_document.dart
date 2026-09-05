/// Driver license V2 slots — front/back with legacy single-image fallback.
///
/// Business rule (Phase 4D): license **back is optional**.
/// Canonical requirement = front **or** legacy single license.
abstract final class DriverLicenseDocumentFields {
  DriverLicenseDocumentFields._();

  static const legacy = 'doc_driver_license';
  static const front = 'doc_driver_license_front';
  static const back = 'doc_driver_license_back';
}

enum DriverLicenseSide { front, back, legacy }

abstract final class DriverLicenseDocument {
  DriverLicenseDocument._();

  /// Authoritative product rule: back is never required.
  static const bool backSideRequired = false;

  static bool isStoragePath(String? raw) {
    final p = (raw ?? '').trim();
    return p.startsWith('users/') && !p.contains('..');
  }

  static bool _hasAssetInSlot(Map<String, dynamic> data, String v2Key) {
    final slot = data[v2Key];
    if (slot is Map) {
      final path = (slot['storagePath'] as String?)?.trim() ?? '';
      if (isStoragePath(path)) return true;
      final url = (slot['url'] as String?)?.trim() ?? '';
      if (url.startsWith('https://')) return true;
    }
    return false;
  }

  static bool hasFront(Map<String, dynamic> data) =>
      _hasAssetInSlot(data, DriverLicenseDocumentFields.front);

  static bool hasBack(Map<String, dynamic> data) =>
      _hasAssetInSlot(data, DriverLicenseDocumentFields.back);

  static bool hasLegacySingle(Map<String, dynamic> data) =>
      _hasAssetInSlot(data, DriverLicenseDocumentFields.legacy);

  /// Front or legacy satisfies the license requirement. Back never blocks.
  static bool satisfiesCanonicalRequirement(Map<String, dynamic> data) {
    if (hasFront(data)) return true;
    if (hasLegacySingle(data)) return true;
    return false;
  }

  static bool isCompleteForSubmit(
    Map<String, dynamic> data, {
    bool requireBothSides = false,
    bool backRequired = backSideRequired,
  }) {
    if (requireBothSides) {
      if (!hasFront(data)) return false;
      if (backRequired && !hasBack(data)) return false;
      return true;
    }
    return satisfiesCanonicalRequirement(data);
  }

  static bool isApprovedLegacyLicenseOnly(Map<String, dynamic> data) {
    final status = (data['registration_status'] as String?)?.trim() ?? '';
    final approved = status == 'approved' && data['actev_mndob'] == true;
    return approved &&
        hasLegacySingle(data) &&
        !hasFront(data) &&
        !hasBack(data);
  }

  static Map<String, dynamic> buildFirestoreSlot({
    required String side,
    required String storagePath,
    String? url,
  }) {
    return {
      'documentType': 'driver_license',
      'side': side,
      if (url != null && url.isNotEmpty) 'url': url,
      'storagePath': storagePath,
      'status': 'uploaded',
    };
  }

  static String? validationErrorKey({
    required bool frontRequired,
    required bool backRequired,
    required bool frontReady,
    required bool backReady,
  }) {
    if (!frontRequired && !backRequired) return null;
    if (frontRequired && !frontReady && backRequired && !backReady) {
      return 'Driver license (front) and (back) are required';
    }
    if (frontRequired && !frontReady) {
      return 'Driver license (front) is required';
    }
    if (backRequired && !backReady) {
      return 'Driver license (back) is required';
    }
    return null;
  }
}
