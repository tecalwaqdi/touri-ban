import 'dart:typed_data';

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

/// Upload bytes to Firebase Storage. Callers must not invoke this twice for
/// the same pick. Prefer stable paths (e.g. users/{uid}/profile.jpg) to avoid
/// duplicate objects that fill free-tier quota.
Future<String?> uploadData(String path, Uint8List data) async {
  final storageRef = FirebaseStorage.instance.ref().child(path);
  final metadata =
      SettableMetadata(contentType: contentTypeForStoragePath(path));

  try {
    if (data.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'empty-file',
        message: 'ملف الصورة فارغ أو لم يُقرأ من المعرض',
      );
    }
    final snapshot = await storageRef.putData(data, metadata);

    if (snapshot.state != TaskState.success) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'upload-failed',
        message: 'فشل رفع الملف (الحالة: ${snapshot.state})',
      );
    }

    return await snapshot.ref.getDownloadURL();
  } on FirebaseException catch (e) {
    debugPrint(
      'uploadData FirebaseException [$path]: ${e.code} — ${e.message}',
    );
    rethrow;
  } catch (e, st) {
    debugPrint('uploadData error [$path]: $e\n$st');
    rethrow;
  }
}

String uploadErrorMessage(Object error) {
  if (error is FirebaseException) {
    final code = error.code.toLowerCase();
    final msg = (error.message ?? '').toLowerCase();
    final combined = '$code $msg';

    if (code.contains('quota') ||
        msg.contains('quota') ||
        combined.contains('402')) {
      return 'تم تجاوز حصة Firebase Storage لهذا المشروع '
          '(Quota exceeded). هذا حد على مشروع Firebase وليس خطأ في التطبيق. '
          'افتح Firebase Console → Storage / Usage، احذف ملفات غير لازمة '
          'أو فعّل خطة Blaze، ثم أعد المحاولة.';
    }

    switch (error.code) {
      case 'unauthorized':
      case 'permission-denied':
      case 'storage/unauthorized':
        return 'صلاحيات التخزين مرفوضة. تأكد من تسجيل الدخول ونشر قواعد Storage.';
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
        if (msg.contains('billing') ||
            msg.contains('delinquent') ||
            msg.contains('payment')) {
          return 'خدمة التخزين متوقفة: يجب تفعيل الفوترة (Blaze) في مشروع Firebase.';
        }
        return 'تعذر رفع الصورة إلى التخزين السحابي. حاول مرة أخرى أو اختر صورة أصغر.';
    }
  }

  final text = error.toString().toLowerCase();
  if (text.contains('quota') || text.contains('402')) {
    return 'تم تجاوز حصة Firebase Storage لهذا المشروع. '
        'راجع Usage في Firebase Console أو فعّل Blaze.';
  }
  if (text.contains('billing') || text.contains('payment')) {
    return 'خدمة التخزين متوقفة: يجب تفعيل الفوترة (Blaze) في مشروع Firebase.';
  }

  final raw = error.toString().trim();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length);
  }
  return raw.isNotEmpty ? raw : 'تعذر رفع الصورة. حاول مرة أخرى.';
}
