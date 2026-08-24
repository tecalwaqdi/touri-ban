import 'package:firebase_storage/firebase_storage.dart';

/// Authenticated document access — storagePath is SoT; legacy HTTPS URLs supported.
abstract final class DriverDocumentAccess {
  DriverDocumentAccess._();

  static const legacyAccessLabel = 'LEGACY_DOCUMENT_ACCESS';

  static bool isOwnedPath(String storagePath, String uid) {
    final p = storagePath.trim();
    return p.startsWith('users/$uid/');
  }

  static bool isStoragePath(String? raw) {
    final p = (raw ?? '').trim();
    return p.startsWith('users/') && !p.contains('..');
  }

  /// Resolve a short-lived download URL via authenticated Storage SDK.
  static Future<String?> resolveViewUrl({
    required String storagePath,
    String? legacyHttpsUrl,
  }) async {
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
