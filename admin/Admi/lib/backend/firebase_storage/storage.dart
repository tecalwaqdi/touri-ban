import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

String contentTypeForStoragePath(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
    case 'heif':
      return 'image/heic';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}

/// Upload bytes (or local file on mobile) to Firebase Storage.
Future<String?> uploadData(
  String path,
  Uint8List data, {
  String? filePath,
}) async {
  final storageRef = FirebaseStorage.instance.ref().child(path);
  final metadata = SettableMetadata(contentType: contentTypeForStoragePath(path));

  try {
    final TaskSnapshot snapshot;

    if (!kIsWeb &&
        filePath != null &&
        filePath.isNotEmpty &&
        await File(filePath).exists()) {
      snapshot = await storageRef.putFile(File(filePath), metadata);
    } else {
      if (data.isEmpty) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'empty-file',
          message: 'ملف الصورة فارغ أو لم يُقرأ من المعرض',
        );
      }
      snapshot = await storageRef.putData(data, metadata);
    }

    if (snapshot.state != TaskState.success) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'upload-failed',
        message: 'فشل رفع الملف (الحالة: ${snapshot.state})',
      );
    }

    return await snapshot.ref.getDownloadURL();
  } on FirebaseException catch (e) {
    debugPrint('uploadData FirebaseException [$path]: ${e.code} — ${e.message}');
    rethrow;
  } catch (e, st) {
    debugPrint('uploadData error [$path]: $e\n$st');
    rethrow;
  }
}

String uploadErrorMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unauthorized':
      case 'permission-denied':
      case 'storage/unauthorized':
        return 'صلاحيات التخزين مرفوضة. تأكد من تسجيل الدخول ونشر قواعد Storage على Firebase.';
      case 'unauthenticated':
      case 'storage/unauthenticated':
        return 'يجب تسجيل الدخول قبل رفع الصورة.';
      case 'empty-file':
        return 'لم يتم قراءة الصورة من المعرض. جرّب صورة أخرى.';
      case 'object-not-found':
        return 'مسار التخزين غير موجود على السيرفر.';
      case 'canceled':
        return 'تم إلغاء الرفع.';
      default:
        final msg = (error.message ?? '').toLowerCase();
        if (msg.contains('billing') ||
            msg.contains('delinquent') ||
            msg.contains('402') ||
            msg.contains('payment')) {
          return 'خدمة التخزين متوقفة: يجب تفعيل الفوترة في مشروع Firebase (Google Cloud Billing).';
        }
        final trimmed = error.message?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          return trimmed;
        }
        return 'خطأ في التخزين (${error.code})';
    }
  }
  return error.toString();
}
