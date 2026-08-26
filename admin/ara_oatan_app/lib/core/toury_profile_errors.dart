import 'package:firebase_core/firebase_core.dart';

import '/backend/firebase_storage/storage.dart';

/// User-facing profile errors — never map Firestore phone/name failures to Storage.
String touryProfileErrorMessage(Object error, {required String operation}) {
  if (error is FirebaseException) {
    final code = error.code.toLowerCase();
    final plugin = error.plugin.toLowerCase();
    final msg = (error.message ?? '').toLowerCase();
    final isStorage = plugin.contains('storage') ||
        operation == 'photo_upload' ||
        code.startsWith('storage/');
    final isFirestore = plugin.contains('firestore') ||
        operation == 'profile_save' ||
        operation == 'photo_url_write';

    if (code.contains('unauthenticated') ||
        code == 'auth/user-token-expired' ||
        msg.contains('unauthenticated')) {
      return 'انتهت جلسة تسجيل الدخول. سجّل الدخول مرة أخرى.';
    }

    if (isStorage &&
        (code.contains('unauthorized') ||
            code.contains('permission-denied'))) {
      return 'تعذر رفع الصورة بسبب صلاحيات التخزين.';
    }

    if (isFirestore &&
        (code.contains('permission-denied') ||
            code.contains('unauthorized'))) {
      return 'تعذر حفظ بيانات الملف الشخصي.';
    }

    if (msg.contains('network') ||
        code.contains('unavailable') ||
        code.contains('deadline')) {
      return 'تعذر الاتصال. حاول مرة أخرى.';
    }
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('failed host lookup')) {
    return 'تعذر الاتصال. حاول مرة أخرى.';
  }
  if (text.contains('cloud_firestore') && text.contains('permission-denied')) {
    return 'تعذر حفظ بيانات الملف الشخصي.';
  }
  if (operation == 'photo_upload' &&
      (text.contains('unauthorized') || text.contains('permission-denied'))) {
    return 'تعذر رفع الصورة بسبب صلاحيات التخزين.';
  }

  // Photo upload may still use Storage-specific quota messages.
  if (operation == 'photo_upload') {
    return uploadErrorMessage(error);
  }

  return 'تعذر إكمال العملية. حاول مرة أخرى.';
}
