import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Outcome of resolving a driver document for the admin viewer.
class AdminDriverDocViewResult {
  const AdminDriverDocViewResult({
    this.bytes,
    this.url,
    this.contentType,
    this.errorCode,
    this.errorDetail,
  });

  final Uint8List? bytes;
  final String? url;
  final String? contentType;

  /// Machine code: [denied], [not_found], [unauthorized], [empty],
  /// [unsupported], [network], [unknown].
  final String? errorCode;
  final String? errorDetail;

  bool get ok =>
      (bytes != null && bytes!.isNotEmpty) ||
      (url != null && url!.trim().isNotEmpty);

  bool get isImage {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.startsWith('image/')) return true;
    if (bytes != null && bytes!.isNotEmpty) {
      // Heuristic when Storage omits contentType.
      return !_looksLikePdf(bytes!);
    }
    return url != null && url!.isNotEmpty;
  }

  bool get isPdf {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('pdf')) return true;
    if (bytes != null && bytes!.isNotEmpty) return _looksLikePdf(bytes!);
    return false;
  }

  static bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < 5) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46; // %PDF
  }

  /// Localized-ready message key / Arabic default for UI.
  String get userMessageAr {
    switch (errorCode) {
      case 'denied':
        return 'لا صلاحية لعرض وثائق هذا المندوب ضمن نطاقك.';
      case 'not_found':
        return 'الملف غير موجود في التخزين. قد يكون المسار قديماً أو لم يُرفع.';
      case 'unauthorized':
        return 'رفض التخزين الوصول. تحقق من صلاحية المشرف وقواعد Storage.';
      case 'empty':
        return 'لا يوجد مسار تخزين ولا رابط صالح لهذه الوثيقة.';
      case 'unsupported':
        return 'تم جلب الملف لكن نوعه غير مدعوم للمعاينة هنا (مثلاً PDF).';
      case 'network':
        return 'تعذر الاتصال بالتخزين. تحقق من الشبكة ثم أعد المحاولة.';
      default:
        return errorDetail?.trim().isNotEmpty == true
            ? errorDetail!.trim()
            : 'تعذر عرض الوثيقة';
    }
  }
}

/// Admin authenticated document access with country scope check.
abstract final class AdminDriverDocumentAccess {
  AdminDriverDocumentAccess._();

  static const legacyAccessLabel = 'LEGACY_DOCUMENT_ACCESS';
  static const _maxBytes = 15 * 1024 * 1024;

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

  /// Country scope is enforced in Storage Rules (Firestore lookup).
  /// This check is UX-only — not a security boundary.
  static bool canAccessDriverDocuments(UserRecord driver) {
    if (AdminRoleService.isSuperAdmin) return true;
    if (!AdminRoleService.isCountryAgent) return false;
    final scope = AdminRoleService.scopedCountryRef;
    if (scope == null) return false;
    final driverCountry = driverCountryRef(driver);
    if (driverCountry == null) return false;
    return driverCountry.path == scope.path;
  }

  /// Prefer authenticated [Reference.getData] (works on Flutter Web without
  /// bucket CORS). Fall back to download URL, then legacy HTTPS.
  static Future<AdminDriverDocViewResult> resolveView({
    required UserRecord driver,
    required String storagePath,
    String? legacyHttpsUrl,
  }) async {
    if (!canAccessDriverDocuments(driver)) {
      return const AdminDriverDocViewResult(errorCode: 'denied');
    }

    final path = storagePath.trim();
    final legacy = (legacyHttpsUrl ?? '').trim();

    if (isStoragePath(path)) {
      final fromSdk = await _loadViaSdk(path);
      if (fromSdk.ok) return fromSdk;

      // Legacy URL often still works when path is stale / object missing.
      if (legacy.startsWith('https://')) {
        return AdminDriverDocViewResult(
          url: legacy,
          contentType: 'image/*',
          errorCode: fromSdk.errorCode,
          errorDetail:
              'storage_failed_using_legacy:${fromSdk.errorCode ?? 'unknown'}',
        );
      }
      return fromSdk;
    }

    if (legacy.startsWith('https://')) {
      return AdminDriverDocViewResult(url: legacy, contentType: 'image/*');
    }

    return const AdminDriverDocViewResult(errorCode: 'empty');
  }

  /// Back-compat for older callers that only need a URL.
  static Future<String?> resolveViewUrl({
    required UserRecord driver,
    required String storagePath,
    String? legacyHttpsUrl,
  }) async {
    final r = await resolveView(
      driver: driver,
      storagePath: storagePath,
      legacyHttpsUrl: legacyHttpsUrl,
    );
    if (r.url != null && r.url!.isNotEmpty) return r.url;
    return null;
  }

  static Future<AdminDriverDocViewResult> _loadViaSdk(String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    try {
      final meta = await ref.getMetadata();
      final ct = meta.contentType;
      final bytes = await ref.getData(_maxBytes);
      if (bytes == null || bytes.isEmpty) {
        return AdminDriverDocViewResult(
          errorCode: 'not_found',
          contentType: ct,
          errorDetail: 'empty_bytes:$path',
        );
      }
      String? downloadUrl;
      final isPdf = (ct ?? '').toLowerCase().contains('pdf') ||
          AdminDriverDocViewResult._looksLikePdf(bytes);
      if (isPdf) {
        try {
          downloadUrl = await ref.getDownloadURL();
        } catch (_) {
          downloadUrl = null;
        }
      }
      return AdminDriverDocViewResult(
        bytes: bytes,
        url: downloadUrl,
        contentType: ct,
      );
    } on FirebaseException catch (e) {
      return AdminDriverDocViewResult(
        errorCode: mapStorageErrorCode(e.code),
        errorDetail: '${e.code}:${e.message ?? ''}',
      );
    } catch (e) {
      return AdminDriverDocViewResult(
        errorCode: 'network',
        errorDetail: e.toString(),
      );
    }
  }

  /// Maps Firebase Storage error codes to stable UI codes (testable).
  static String mapStorageErrorCode(String raw) {
    final c = raw.toLowerCase();
    if (c.contains('object-not-found') || c.contains('not-found')) {
      return 'not_found';
    }
    if (c.contains('unauthorized') ||
        c.contains('unauthenticated') ||
        c.contains('permission-denied')) {
      return 'unauthorized';
    }
    if (c.contains('retry') ||
        c.contains('network') ||
        c.contains('unavailable') ||
        c.contains('timeout')) {
      return 'network';
    }
    return 'unknown';
  }
}
