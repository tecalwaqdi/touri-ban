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

/// Resize + JPEG encode for embedding in Firestore when Storage is unavailable.
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

Uint8List compressProfilePhotoBytes(Uint8List bytes) => compressImageBytes(bytes);

/// Shrinks until under Firestore field limit when possible.
Uint8List compressImageBytesForFirestore(
  Uint8List bytes, {
  int maxEdge = kAdminImageMaxEdge,
  int maxBytes = kProfilePhotoMaxFirestoreBytes,
}) {
  var edge = maxEdge;
  var quality = kAdminImageJpegQuality;

  for (var i = 0; i < 6; i++) {
    final out = compressImageBytes(bytes, maxEdge: edge, quality: quality);
    if (out.length <= maxBytes) {
      return out;
    }
    quality = (quality - 10).clamp(45, 95);
    edge = (edge * 0.82).round().clamp(320, maxEdge);
  }

  return compressImageBytes(bytes, maxEdge: 400, quality: 50);
}

String profilePhotoDataUrl(Uint8List jpegBytes) {
  return 'data:image/jpeg;base64,${base64Encode(jpegBytes)}';
}

bool isProfilePhotoDataUrl(String value) =>
    value.startsWith('data:image/');

bool isStorageBillingOrUnavailable(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('402') ||
      text.contains('billing') ||
      text.contains('delinquent') ||
      text.contains('payment') ||
      text.contains('quota exceeded') ||
      text.contains('bucket does not exist') ||
      text.contains('storage/object-not-found');
}

bool shouldFallbackToEmbeddedImage(Object error) {
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

/// Tries Firebase Storage; on failure stores a compressed data-URL in Firestore.
Future<String> uploadAdminImage({
  required String storagePath,
  required Uint8List bytes,
  String? filePath,
  int maxEdge = kAdminImageMaxEdge,
  int jpegQuality = kAdminImageJpegQuality,
  int maxEmbeddedBytes = kProfilePhotoMaxFirestoreBytes,
}) async {
  try {
    final url = await uploadData(storagePath, bytes, filePath: filePath);
    if (url != null && url.isNotEmpty) {
      // تأكد أن الرابط قابل للقراءة (تجنّب حفظ رابط Storage معطّل 402)
      try {
        final probe = await FirebaseStorage.instance
            .refFromURL(url)
            .getData(4096);
        if (probe != null && probe.isNotEmpty) {
          return url;
        }
      } catch (e) {
        debugPrint('uploadAdminImage URL not readable, embedding: $e');
      }
    }
  } catch (e) {
    debugPrint('uploadAdminImage storage failed: $e');
    if (!shouldFallbackToEmbeddedImage(e)) {
      throw Exception(uploadErrorMessage(e));
    }
  }

  final compressed = compressImageBytesForFirestore(
    bytes,
    maxEdge: maxEdge,
    maxBytes: maxEmbeddedBytes,
  );
  if (compressed.length > maxEmbeddedBytes) {
    throw Exception(
      'الصورة كبيرة جداً. اختر صورة أصغر أو فعّل فوترة Firebase Storage.',
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

/// User settings avatar — smallest embed to fit inside large user documents.
Future<String> uploadUserProfilePhoto({
  required String storagePath,
  required Uint8List bytes,
  String? filePath,
}) {
  return uploadAdminImage(
    storagePath: storagePath,
    bytes: bytes,
    filePath: filePath,
    maxEdge: kUserProfileMaxEdge,
    jpegQuality: 68,
    maxEmbeddedBytes: kUserProfileMaxEmbeddedBytes,
  );
}
