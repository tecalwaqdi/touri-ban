import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Admin-only media resolution for Flutter Web.
///
/// Root cause of console Storage "CORS" noise: `users/**` objects require
/// authenticated reads (Storage Rules). Browser `CachedNetworkImage`/`Image.network`
/// fetch download URLs without Firebase Auth → HTTP 403, which Chromium often
/// reports as a CORS failure even when bucket CORS allows the Origin.
///
/// Prefer [FirebaseStorage.ref].getData() (SDK auth) over anonymous HTTPS GET.
///
/// Failure classification:
/// - [AdminMediaFailureKind.expectedMissing] — object gone / bad path → UI Missing, no spam
/// - [AdminMediaFailureKind.realStorageError] — permission / bucket / unexpected → log once
enum AdminMediaFailureKind {
  expectedMissing,
  realStorageError,
}

class AdminMediaResolved {
  const AdminMediaResolved._({
    this.bytes,
    this.networkUrl,
    this.empty = false,
    this.failureKind,
  });

  factory AdminMediaResolved.memory(Uint8List bytes) =>
      AdminMediaResolved._(bytes: bytes);

  factory AdminMediaResolved.network(String url) =>
      AdminMediaResolved._(networkUrl: url);

  factory AdminMediaResolved.none({AdminMediaFailureKind? failureKind}) =>
      AdminMediaResolved._(empty: true, failureKind: failureKind);

  final Uint8List? bytes;
  final String? networkUrl;
  final bool empty;
  final AdminMediaFailureKind? failureKind;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasNetwork => (networkUrl ?? '').trim().isNotEmpty;
  bool get ok => hasBytes || hasNetwork;
}

abstract final class AdminMediaResolver {
  AdminMediaResolver._();

  static const _maxBytes = 8 * 1024 * 1024;

  /// Session negative cache: path → failure kind (avoids repeat getData spam).
  static final Map<String, AdminMediaFailureKind> _negativeCache = {};

  /// In-flight getData by path (coalesce concurrent probes for the same object).
  static final Map<String, Future<Uint8List?>> _inflight = {};

  /// Test / heal helpers.
  @visibleForTesting
  static void clearNegativeCache() {
    _negativeCache.clear();
    _inflight.clear();
  }

  @visibleForTesting
  static Map<String, AdminMediaFailureKind> get negativeCacheView =>
      Map.unmodifiable(_negativeCache);

  /// Resolve any admin image field: data-URL, https, gs://, or storage path.
  static Future<AdminMediaResolved> resolve(String? raw) async {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return AdminMediaResolved.none();

    if (value.startsWith('data:image/')) {
      final decoded = _decodeDataUrl(value);
      return decoded != null
          ? AdminMediaResolved.memory(decoded)
          : AdminMediaResolved.none(
              failureKind: AdminMediaFailureKind.expectedMissing,
            );
    }

    final storagePath = storagePathFrom(value);
    if (storagePath != null) {
      final cached = _negativeCache[storagePath];
      if (cached != null) {
        return AdminMediaResolved.none(failureKind: cached);
      }

      final fromSdk = await _loadBytes(storagePath);
      if (fromSdk != null) return AdminMediaResolved.memory(fromSdk);

      final kind =
          _negativeCache[storagePath] ?? AdminMediaFailureKind.expectedMissing;
      return AdminMediaResolved.none(failureKind: kind);
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      // Non-Firebase hosts only (CDN / external / Google avatar).
      return AdminMediaResolved.network(value);
    }

    return AdminMediaResolved.none(
      failureKind: AdminMediaFailureKind.expectedMissing,
    );
  }

  /// Extract a Storage object path from https / gs:// / bare paths.
  static String? storagePathFrom(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('gs://')) {
      final without = value.substring(5);
      final slash = without.indexOf('/');
      if (slash < 0 || slash >= without.length - 1) return null;
      return without.substring(slash + 1);
    }

    // Bare relative path used by some legacy fields.
    if (!value.contains('://') &&
        (value.startsWith('users/') ||
            value.startsWith('landmarks/') ||
            value.startsWith('countries/') ||
            value.startsWith('regions/') ||
            value.startsWith('cities/') ||
            value.startsWith('type_car/') ||
            value.startsWith('representatives/') ||
            value.startsWith('places/'))) {
      return value.split('?').first;
    }

    if (!(value.startsWith('http://') || value.startsWith('https://'))) {
      return null;
    }

    Uri uri;
    try {
      uri = Uri.parse(value);
    } catch (_) {
      return null;
    }

    final host = uri.host.toLowerCase();
    final isFirebaseHost = host.contains('firebasestorage.googleapis.com') ||
        host.endsWith('.firebasestorage.app') ||
        host.contains('googleapis.com') && host.contains('firebasestorage');
    if (!isFirebaseHost) return null;

    // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encodedPath>
    final segments = uri.pathSegments;
    final oIndex = segments.indexOf('o');
    if (oIndex >= 0 && oIndex < segments.length - 1) {
      final encoded = segments.sublist(oIndex + 1).join('/');
      try {
        return Uri.decodeComponent(encoded);
      } catch (_) {
        return encoded;
      }
    }

    // https://<bucket>.firebasestorage.app/<path> (rare)
    if (host.endsWith('.firebasestorage.app') && segments.isNotEmpty) {
      try {
        return Uri.decodeComponent(segments.join('/'));
      } catch (_) {
        return segments.join('/');
      }
    }

    return null;
  }

  static AdminMediaFailureKind classifyStorageCode(String code) {
    final c = code.toLowerCase();
    if (c == 'object-not-found' ||
        c == 'not-found' ||
        c == 'storage/object-not-found' ||
        c == 'storage/not-found') {
      return AdminMediaFailureKind.expectedMissing;
    }
    // unauthorized / unauthenticated / canceled / unknown → real (or access)
    return AdminMediaFailureKind.realStorageError;
  }

  static Uint8List? _decodeDataUrl(String dataUrl) {
    try {
      final comma = dataUrl.indexOf(',');
      if (comma < 0) return null;
      return Uint8List.fromList(base64Decode(dataUrl.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _loadBytes(String path) {
    final existing = _inflight[path];
    if (existing != null) return existing;

    final future = _loadBytesUncached(path).whenComplete(() {
      _inflight.remove(path);
    });
    _inflight[path] = future;
    return future;
  }

  static Future<Uint8List?> _loadBytesUncached(String path) async {
    try {
      final bytes = await FirebaseStorage.instance.ref(path).getData(_maxBytes);
      if (bytes == null || bytes.isEmpty) {
        _negativeCache[path] = AdminMediaFailureKind.expectedMissing;
        return null;
      }
      return bytes;
    } on FirebaseException catch (e) {
      final kind = classifyStorageCode(e.code);
      _negativeCache[path] = kind;
      // EXPECTED_MISSING: silent in release; one debug line max via cache.
      if (kind == AdminMediaFailureKind.realStorageError) {
        debugPrint('AdminMediaResolver REAL_STORAGE_ERROR: $path → ${e.code}');
      } else if (kDebugMode) {
        debugPrint('AdminMediaResolver EXPECTED_MISSING_MEDIA: $path');
      }
      return null;
    } catch (e) {
      _negativeCache[path] = AdminMediaFailureKind.realStorageError;
      debugPrint('AdminMediaResolver REAL_STORAGE_ERROR: $path → $e');
      return null;
    }
  }
}
