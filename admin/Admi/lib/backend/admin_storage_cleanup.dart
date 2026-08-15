import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Best-effort cleanup of Firebase Storage objects referenced by admin media URLs.
///
/// Skips empty values, data-URL embeds, and non-Firebase hosts. Failures are
/// logged and ignored so Firestore deletes/saves are never blocked.
Future<void> deleteAdminStorageUrl(String? url) async {
  final value = (url ?? '').trim();
  if (value.isEmpty) return;
  if (value.startsWith('data:')) return;
  final lower = value.toLowerCase();
  final isFirebaseHost = lower.contains('firebasestorage.googleapis.com') ||
      lower.contains('firebasestorage.app') ||
      lower.contains('googleapis.com/v0/b/');
  if (!isFirebaseHost) return;

  try {
    final ref = FirebaseStorage.instance.refFromURL(value);
    await ref.delete();
  } on FirebaseException catch (e) {
    // object-not-found is fine (already gone / never uploaded).
    if (e.code != 'object-not-found' && e.code != 'storage/object-not-found') {
      debugPrint('deleteAdminStorageUrl [${e.code}]: $value');
    }
  } catch (e) {
    debugPrint('deleteAdminStorageUrl failed: $e');
  }
}

Future<void> deleteAdminStorageUrls(Iterable<String?> urls) async {
  final unique = <String>{};
  for (final url in urls) {
    final value = (url ?? '').trim();
    if (value.isNotEmpty) unique.add(value);
  }
  for (final url in unique) {
    await deleteAdminStorageUrl(url);
  }
}

/// If [nextUrl] replaces or clears [previousUrl], delete the previous Storage object.
Future<void> deleteReplacedAdminStorageUrl({
  required String previousUrl,
  required String nextUrl,
}) async {
  final prev = previousUrl.trim();
  final next = nextUrl.trim();
  if (prev.isEmpty || prev == next) return;
  await deleteAdminStorageUrl(prev);
}

String? _stringField(Map<String, dynamic>? data, String key) {
  final value = data?[key];
  return value is String ? value : null;
}

/// Collects common image fields from a Firestore doc map.
List<String?> adminImageUrlsFromData(Map<String, dynamic>? data) {
  if (data == null) return const [];
  return [
    _stringField(data, 'img'),
    _stringField(data, 'img1'),
    _stringField(data, 'img2'),
    _stringField(data, 'img3'),
    _stringField(data, 'hederImg'),
    _stringField(data, 'icon'),
  ];
}
