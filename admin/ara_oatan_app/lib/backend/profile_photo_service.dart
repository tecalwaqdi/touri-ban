import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '/backend/firebase_storage/storage.dart';

const int kProfilePhotoMaxEdge = 480;
const int kProfilePhotoJpegQuality = 72;

/// Cap for Firestore-embedded fallback (user docs are large).
const int kUserProfileMaxEmbeddedBytes = 90000;
const int kUserProfileMaxEdge = 320;
const int kUserProfileJpegQuality = 68;

/// Thrown when upload fails for a clear, user-safe reason.
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
  int maxEdge = kUserProfileMaxEdge,
  int quality = kUserProfileJpegQuality,
  int maxBytes = kUserProfileMaxEmbeddedBytes,
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

/// Force `.jpg` after re-encode so Storage metadata matches the payload.
String jpegStoragePath(String path) {
  final slash = path.lastIndexOf('/');
  final name = slash >= 0 ? path.substring(slash + 1) : path;
  final dir = slash >= 0 ? path.substring(0, slash + 1) : '';
  final dot = name.lastIndexOf('.');
  final base = dot > 0 ? name.substring(0, dot) : name;
  return '$dir$base.jpg';
}

/// Stable path — overwrites the same object instead of creating duplicates.
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

/// Compress once, upload once to a stable path; on quota fall back to
/// a compressed data-URL in Firestore (no duplicate Storage objects).
Future<String> uploadUserProfilePhoto({
  required String uid,
  required Uint8List bytes,
}) async {
  if (uid.isEmpty) {
    throw StorageUploadException('يجب تسجيل الدخول قبل رفع الصورة.');
  }
  if (bytes.isEmpty) {
    throw StorageUploadException('لم يتم قراءة الصورة. جرّب صورة أخرى.');
  }

  final forStorage = compressImageBytes(
    bytes,
    maxEdge: kProfilePhotoMaxEdge,
    quality: kProfilePhotoJpegQuality,
  );
  final path = userProfilePhotoStoragePath(uid);

  try {
    final url = await uploadData(path, forStorage);
    if (url != null && url.isNotEmpty) {
      // Cache-bust so UI refreshes when overwriting the same object path.
      final sep = url.contains('?') ? '&' : '?';
      return '$url${sep}v=${DateTime.now().millisecondsSinceEpoch}';
    }
  } catch (e) {
    debugPrint('uploadUserProfilePhoto storage failed: $e');
    if (!shouldFallbackToEmbeddedImage(e)) {
      throw StorageUploadException(uploadErrorMessage(e));
    }
  }

  final embedded = compressImageBytesForFirestore(
    forStorage,
    maxEdge: kUserProfileMaxEdge,
    quality: kUserProfileJpegQuality,
    maxBytes: kUserProfileMaxEmbeddedBytes,
  );
  if (embedded.length > kUserProfileMaxEmbeddedBytes) {
    throw StorageUploadException(
      'حصة Firebase Storage ممتلئة والصورة كبيرة جداً للتخزين الاحتياطي. '
      'احذف ملفات غير لازمة من Storage أو فعّل خطة Blaze، ثم أعد المحاولة.',
      isQuotaOrBilling: true,
    );
  }

  return profilePhotoDataUrl(embedded);
}
