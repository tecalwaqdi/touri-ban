import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase_storage/storage.dart';
import '/core/driver_document_upload_result.dart';
import '/core/driver_registration_validators.dart';
import '/flutter_flow/upload_data.dart';

/// Central upload helper — keeps Storage path compatible with existing rules:
/// `users/{uid}/uploads/...`
abstract final class DriverDocumentUploadService {
  DriverDocumentUploadService._();

  static String storageRootForUid(String uid) => 'users/$uid/uploads';

  /// Uploads selected media; returns storagePath (SoT) + optional preview URL.
  static Future<DriverDocumentUploadResult?> uploadSelectedFile({
    required SelectedFile selected,
    String? uid,
  }) async {
    final owner = (uid != null && uid.isNotEmpty) ? uid : currentUserUid;
    if (owner.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }

    final bytes = selected.bytes;
    final sizeCheck = DriverDocumentValidator.validateSize(bytes.length);
    if (!sizeCheck.isValid) {
      throw StateError(sizeCheck.errorKey ?? 'File is too large');
    }

    // Prefer storagePath from FF helper (already scoped under users/{uid}/uploads).
    final path = selected.storagePath;
    if (path.isEmpty) {
      throw StateError('Could not read the selected file');
    }
    if (!path.startsWith('users/$owner/')) {
      debugPrint(
        'DriverDocumentUploadService: refusing path outside user root: $path',
      );
      throw StateError('You are not allowed to perform this action.');
    }

    await uploadBytes(path, bytes);
    String? previewUrl;
    try {
      previewUrl =
          await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (_) {
      previewUrl = null;
    }
    return DriverDocumentUploadResult(
      storagePath: path,
      previewUrl: previewUrl,
    );
  }
}
