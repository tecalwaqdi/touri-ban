import 'package:firebase_storage/firebase_storage.dart';

import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Admin authenticated document access with country scope check.
abstract final class AdminDriverDocumentAccess {
  AdminDriverDocumentAccess._();

  static const legacyAccessLabel = 'LEGACY_DOCUMENT_ACCESS';

  static bool isStoragePath(String? raw) {
    final p = (raw ?? '').trim();
    return p.startsWith('users/') && !p.contains('..');
  }

  static DocumentReference? driverCountryRef(UserRecord user) {
    if (user.hasRevDolh()) return user.revDolh;
    final raw = user.snapshotData['Rev_dolh'];
    if (raw is DocumentReference) return raw;
    return null;
  }

  /// Country agents may only access drivers in their scoped country.
  static bool canAccessDriverDocuments(UserRecord driver) {
    if (AdminRoleService.isSuperAdmin) return true;
    if (!AdminRoleService.isCountryAgent) return AdminRoleService.isSuperAdmin;
    final scope = AdminRoleService.scopedCountryRef;
    if (scope == null) return false;
    final driverCountry = driverCountryRef(driver);
    if (driverCountry == null) return false;
    return driverCountry.path == scope.path;
  }

  static Future<String?> resolveViewUrl({
    required UserRecord driver,
    required String storagePath,
    String? legacyHttpsUrl,
  }) async {
    if (!canAccessDriverDocuments(driver)) return null;
    if (isStoragePath(storagePath)) {
      try {
        return await FirebaseStorage.instance.ref(storagePath).getDownloadURL();
      } catch (_) {
        return null;
      }
    }
    final leg = (legacyHttpsUrl ?? '').trim();
    if (leg.startsWith('https://')) return leg;
    return null;
  }

  static bool usesLegacyUrlOnly({
    required String storagePath,
    required String legacyHttpsUrl,
  }) =>
      !isStoragePath(storagePath) && legacyHttpsUrl.trim().startsWith('https://');
}
