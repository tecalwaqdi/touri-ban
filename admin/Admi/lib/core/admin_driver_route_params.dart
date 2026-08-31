import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/user_record.dart';

/// Resolves driver Profile / Review route params to a Firestore [user] ref.
///
/// Accepts the formats actually seen in Admin:
/// - bare UID (FlutterFlow [serializeParam] for DocumentReference)
/// - `user|UID` (manual / legacy deep links — must NOT become path `user/user`)
/// - `user/UID` or `/user/UID`
class AdminDriverRouteParams {
  AdminDriverRouteParams._();

  /// Extracts the Firestore document id for a driver user, or null if invalid.
  static String? parseUserId(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;

    try {
      s = Uri.decodeComponent(s).trim();
    } catch (_) {
      // keep raw if already decoded / malformed percent-encoding
    }
    if (s.isEmpty) return null;

    // Path form: user/UID or /user/UID
    if (s.contains('/')) {
      final parts =
          s.split('/').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2 && parts.first == 'user') {
        final id = parts[1];
        if (id.isEmpty || id == 'user') return null;
        return id;
      }
      final id = parts.last;
      if (id.isEmpty || id == 'user') return null;
      return id;
    }

    // FlutterFlow delimiter form: UID or user|UID
    final parts =
        s.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    if (parts.length == 1) {
      final id = parts.first;
      if (id == 'user') return null;
      return id;
    }

    if (parts.first == 'user') {
      final id = parts[1];
      if (id.isEmpty || id == 'user') return null;
      return id;
    }

    final id = parts.last;
    if (id.isEmpty || id == 'user') return null;
    return id;
  }

  static DocumentReference? parseUserRef(String? raw) {
    final id = parseUserId(raw);
    if (id == null) return null;
    return UserRecord.collection.doc(id);
  }

  /// Prefer raw query string; fall back to an already-deserialized ref.
  static DocumentReference? resolveUserRef({
    required String? rawQuery,
    DocumentReference? deserialized,
  }) {
    final fromRaw = parseUserRef(rawQuery);
    if (fromRaw != null) return fromRaw;

    if (deserialized == null) return null;
    // Repair bad deserialize of `user|UID` → path `user/user`
    final path = deserialized.path.replaceFirst(RegExp(r'^/+'), '');
    final parts = path.split('/');
    if (parts.length == 2 && parts[0] == 'user' && parts[1] == 'user') {
      return null;
    }
    if (parts.length >= 2 && parts[0] == 'user' && parts[1].isNotEmpty) {
      return UserRecord.collection.doc(parts[1]);
    }
    if (deserialized.id.isNotEmpty && deserialized.id != 'user') {
      return UserRecord.collection.doc(deserialized.id);
    }
    return null;
  }
}
