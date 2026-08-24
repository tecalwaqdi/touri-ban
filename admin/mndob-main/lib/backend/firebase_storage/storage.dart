
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime_type/mime_type.dart';

Future<void> uploadBytes(String path, Uint8List data) async {
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
        detected = 'image/jpeg';
      }
    }
    final metadata = SettableMetadata(contentType: detected);
    final result = await storageRef.putData(data, metadata);
    if (result.state != TaskState.success) {
      throw StateError('Document upload is incomplete');
    }
  } catch (e, st) {
    debugPrint('uploadBytes failed path=$path: $e\n$st');
    rethrow;
  }
}

Future<String?> uploadData(String path, Uint8List data) async {
  try {
    await uploadBytes(path, data);
    final storageRef = FirebaseStorage.instance.ref().child(path);
    return storageRef.getDownloadURL();
  } catch (e, st) {
    debugPrint('uploadData failed path=$path: $e\n$st');
    rethrow;
  }
}
