import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '/backend/firebase_storage/storage.dart';

const int kProfilePhotoMaxEdge = 480;
const int kProfilePhotoJpegQuality = 72;
const int kAdminImageMaxEdge = 900;
const int kAdminImageJpegQuality = 74;
const int kProfilePhotoMaxFirestoreBytes = 750000;

/// Smaller embed for records with multiple images (e.g. mkan img1–img3).
const int kContentImageMaxEmbeddedBytes = 200000;
const int kContentImageMaxEdge = 720;
const int kContentImageJpegQuality = 70;

/// Smaller cap for [user] docs (many fields + base64 overhead + 1 MiB doc limit).
const int kUserProfileMaxEmbeddedBytes = 90000;
const int kUserProfileMaxEdge = 320;
const int kUserProfileJpegQuality = 68;

/// Thrown when Firebase Storage rejects the upload for a clear, user-safe reason.
class StorageUploadException implements Exception {
  StorageUploadException(this.message, {this.isQuotaOrBilling = false});

  final String message;
  final bool isQuotaOrBilling;

  @override
  String toString() => message;
}

/// Resize + JPEG encode before Storage upload / Firestore embed.
Uint8List compressImageBytes(
  Uint8List bytes, {
  int maxEdge = kProfilePhotoMaxEdge,
  int quality = kProfilePhotoJpegQuality,
}) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }

    final w = decoded.width;
    final h = decoded.height;
    final longest = w > h ? w : h;
    img.Image resized = decoded;

    if (longest > maxEdge) {
      resized = img.copyResize(
        decoded,
        width: w >= h ? maxEdge : null,
        height: h > w ? maxEdge : null,
      );
    }

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );
  } catch (e) {
    debugPrint('compressImageBytes: $e');
    return bytes;
  }
}

Uint8List compressProfilePhotoBytes(Uint8List bytes) =>
    compressImageBytes(bytes);

/// Shrinks until under Firestore field limit when possible.
Uint8List compressImageBytesForFirestore(
  Uint8List bytes, {
  int maxEdge = kAdminImageMaxEdge,
  int quality = kAdminImageJpegQuality,
  int maxBytes = kProfilePhotoMaxFirestoreBytes,
}) {
  var edge = maxEdge;
  var q = quality;

  for (var i = 0; i < 6; i++) {
    final out = compressImageBytes(bytes, maxEdge: edge, quality: q);
    if (out.length <= maxBytes) {
      return out;
    }
    q = (q - 10).clamp(45, 95);
    edge = (edge * 0.82).round().clamp(240, maxEdge);
  }

  return compressImageBytes(bytes, maxEdge: 280, quality: 48);
}

String profilePhotoDataUrl(Uint8List jpegBytes) {
  return 'data:image/jpeg;base64,${base64Encode(jpegBytes)}';
}

bool isProfilePhotoDataUrl(String value) => value.startsWith('data:image/');

/// Force `.jpg` after we re-encode so Storage metadata matches the payload.
String jpegStoragePath(String path) {
  final slash = path.lastIndexOf('/');
  final name = slash >= 0 ? path.substring(slash + 1) : path;
  final dir = slash >= 0 ? path.substring(0, slash + 1) : '';
  final dot = name.lastIndexOf('.');
  final base = dot > 0 ? name.substring(0, dot) : name;
  return '$dir$base.jpg';
}

/// Stable avatar object — overwrites instead of creating timestamped duplicates.
String userProfilePhotoStoragePath(String uid) => 'users/$uid/profile.jpg';

bool isStorageBillingOrUnavailable(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('402') ||
      text.contains('billing') ||
      text.contains('delinquent') ||
      text.contains('payment') ||
      text.contains('quota') ||
      text.contains('quota-exceeded') ||
      text.contains('bucket does not exist') ||
      text.contains('storage/object-not-found');
}

bool shouldFallbackToEmbeddedImage(Object error) {
  if (error is StorageUploadException && error.isQuotaOrBilling) {
    return true;
  }
  if (isStorageBillingOrUnavailable(error)) {
    return true;
  }
  if (error is FirebaseException) {
    final combined = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (isStorageBillingOrUnavailable(combined)) {
      return true;
    }
    switch (error.code) {
      case 'unknown':
      case 'upload-failed':
      case 'retry-limit-exceeded':
      case 'quota-exceeded':
      case 'storage/quota-exceeded':
      case 'unauthorized':
      case 'permission-denied':
      case 'storage/unauthorized':
      case 'storage/unauthenticated':
        return true;
      default:
        return false;
    }
  }
  return false;
}

/// Tries Firebase Storage with compressed bytes; on quota/billing falls back
/// to a compressed data-URL stored in Firestore (no random deletes).
Future<String> uploadAdminImage({
  required String storagePath,
  required Uint8List bytes,
  String? filePath,
  int maxEdge = kAdminImageMaxEdge,
  int jpegQuality = kAdminImageJpegQuality,
  int maxEmbeddedBytes = kProfilePhotoMaxFirestoreBytes,
}) async {
  // Compress once before any network write — avoids oversized uploads and
  // reduces chance of hitting free-tier transfer quotas.
  final forStorage = compressImageBytes(
    bytes,
    maxEdge: maxEdge,
    quality: jpegQuality,
  );
  final path = jpegStoragePath(storagePath);

  try {
    final url = await uploadData(path, forStorage, filePath: filePath);
    if (url != null && url.isNotEmpty) {
      // Bust CDN/browser cache when overwriting the same Storage object.
      final sep = url.contains('?') ? '&' : '?';
      return '$url${sep}v=${DateTime.now().millisecondsSinceEpoch}';
    }
  } catch (e) {
    debugPrint('uploadAdminImage storage failed: $e');
    if (!shouldFallbackToEmbeddedImage(e)) {
      throw StorageUploadException(uploadErrorMessage(e));
    }
  }

  final compressed = compressImageBytesForFirestore(
    forStorage,
    maxEdge: maxEdge,
    quality: jpegQuality,
    maxBytes: maxEmbeddedBytes,
  );
  if (compressed.length > maxEmbeddedBytes) {
    throw StorageUploadException(
      'حصة Firebase Storage ممتلئة والصورة كبيرة للتخزين الاحتياطي. '
      'افتح Console → Storage واحذف ملفات غير لازمة، أو فعّل خطة Blaze.',
      isQuotaOrBilling: true,
    );
  }

  return profilePhotoDataUrl(compressed);
}

/// Profile avatars — tighter compression than general admin images.
Future<String> uploadProfilePhoto({
  required String storagePath,
  required Uint8List bytes,
  String? filePath,
}) {
  return uploadAdminImage(
    storagePath: storagePath,
    bytes: bytes,
    filePath: filePath,
    maxEdge: kProfilePhotoMaxEdge,
    jpegQuality: kProfilePhotoJpegQuality,
    maxEmbeddedBytes: kUserProfileMaxEmbeddedBytes,
  );
}

/// Logged-in admin settings avatar — always uses a stable Storage path.
Future<String> uploadUserProfilePhoto({
  required String uid,
  required Uint8List bytes,
  String? filePath,
  @Deprecated('Ignored — path is always users/{uid}/profile.jpg')
  String? storagePath,
}) {
  if (uid.isEmpty) {
    throw StorageUploadException('يجب تسجيل الدخول قبل رفع الصورة.');
  }
  if (bytes.isEmpty) {
    throw StorageUploadException('لم يتم قراءة الصورة. جرّب صورة أخرى.');
  }
  return uploadAdminImage(
    storagePath: userProfilePhotoStoragePath(uid),
    bytes: bytes,
    filePath: filePath,
    maxEdge: kUserProfileMaxEdge,
    jpegQuality: kUserProfileJpegQuality,
    maxEmbeddedBytes: kUserProfileMaxEmbeddedBytes,
  );
}
