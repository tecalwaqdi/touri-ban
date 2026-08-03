import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime_type/mime_type.dart';

Future<String?> uploadData(String path, Uint8List data) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    var detected = mime(path);
    final lower = path.toLowerCase();
    if (detected == null || detected == 'application/octet-stream') {
      if (lower.endsWith('.png')) {
        detected = 'image/png';
      } else if (lower.endsWith('.webp')) {
        detected = 'image/webp';
      } else if (lower.endsWith('.gif')) {
        detected = 'image/gif';
      } else if (lower.endsWith('.pdf')) {
        detected = 'application/pdf';
      } else {
        // Camera/gallery bytes are usually JPEG even without a clear extension.
        detected = 'image/jpeg';
      }
    }
    final metadata = SettableMetadata(contentType: detected);
    final result = await storageRef.putData(data, metadata);
    return result.state == TaskState.success ? result.ref.getDownloadURL() : null;
  } catch (e, st) {
    debugPrint('uploadData failed path=$path: $e\n$st');
    rethrow;
  }
}
