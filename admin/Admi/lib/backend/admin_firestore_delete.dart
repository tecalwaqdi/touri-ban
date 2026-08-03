import 'package:cloud_firestore/cloud_firestore.dart';

/// Ensures admin Firestore writes persist on the server (not UI-only).
abstract final class AdminFirestoreDelete {
  AdminFirestoreDelete._();

  static const _verifyAttempts = 3;
  static const _verifyDelay = Duration(milliseconds: 450);

  /// Confirms [ref] no longer exists on the server.
  static Future<void> verifyDeleted(DocumentReference ref) async {
    for (var attempt = 0; attempt < _verifyAttempts; attempt++) {
      final snap = await ref.get(const GetOptions(source: Source.server));
      if (!snap.exists) return;
      if (attempt < _verifyAttempts - 1) {
        await Future<void>.delayed(_verifyDelay);
      }
    }
    throw StateError('تعذر حذف السجل من قاعدة البيانات');
  }

  /// Confirms [ref] exists on the server after create/update.
  static Future<void> verifySaved(DocumentReference ref) async {
    for (var attempt = 0; attempt < _verifyAttempts; attempt++) {
      final snap = await ref.get(const GetOptions(source: Source.server));
      if (snap.exists) return;
      if (attempt < _verifyAttempts - 1) {
        await Future<void>.delayed(_verifyDelay);
      }
    }
    throw StateError('تعذر حفظ السجل في قاعدة البيانات');
  }

  /// Deletes [ref] then verifies absence on the server.
  static Future<void> deleteDocument(DocumentReference ref) async {
    await ref.delete();
    await verifyDeleted(ref);
  }

  /// Creates/merges [data] then verifies the document exists on the server.
  static Future<void> setDocument(
    DocumentReference ref,
    Map<String, dynamic> data, {
    SetOptions? options,
  }) async {
    if (options != null) {
      await ref.set(data, options);
    } else {
      await ref.set(data);
    }
    await verifySaved(ref);
  }

  /// Updates [ref] then verifies the document still exists on the server.
  static Future<void> updateDocument(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    await ref.update(data);
    await verifySaved(ref);
  }
}
