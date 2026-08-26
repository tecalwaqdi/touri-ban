import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

/// Ensures profile mutations refresh canonical in-memory state and UI listeners.
abstract final class TouryProfileState {
  TouryProfileState._();

  static final ValueNotifier<int> refreshTick = ValueNotifier<int>(0);

  /// Refetch Firestore user doc after a successful profile write.
  static Future<UserRecord?> refreshFromServer() async {
    final ref = currentUserReference;
    if (ref == null) return null;
    try {
      final doc = await UserRecord.getDocumentOnce(ref);
      currentUserDocument = doc;
      refreshTick.value++;
      return doc;
    } catch (e) {
      debugPrint('TouryProfileState.refreshFromServer: $e');
      refreshTick.value++;
      return currentUserDocument;
    }
  }
}
