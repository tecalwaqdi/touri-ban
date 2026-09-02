import 'package:admin_arawatan/core/admin_notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

void main() {
  setUpAll(_initFirebase);

  group('adminMaskSensitiveText', () {
    test('masks password and token patterns', () {
      const raw = 'password=secret123 token=abc Bearer xyz';
      final masked = adminMaskSensitiveText(raw);
      expect(masked.contains('secret123'), isFalse);
      expect(masked.contains('[مخفي]'), isTrue);
    });
  });

  group('AdminPanelNotification.dedupe', () {
    test('keeps first occurrence per dedup key', () {
      final ref = FirebaseFirestore.instance
          .collection('admin_panel_notifications')
          .doc('a');
      final items = [
        AdminPanelNotification(
          id: 'a',
          reference: ref,
          type: 'driver_registration',
          title: 'A',
          subtitle: '',
          category: AdminNotificationCategory.drivers,
          unread: true,
          createdAt: null,
          dedupKey: 'same',
        ),
        AdminPanelNotification(
          id: 'b',
          reference: ref,
          type: 'driver_registration',
          title: 'B',
          subtitle: '',
          category: AdminNotificationCategory.drivers,
          unread: true,
          createdAt: null,
          dedupKey: 'same',
        ),
      ];
      final out = AdminPanelNotification.dedupe(items);
      expect(out.length, 1);
      expect(out.first.title, 'A');
    });
  });
}
