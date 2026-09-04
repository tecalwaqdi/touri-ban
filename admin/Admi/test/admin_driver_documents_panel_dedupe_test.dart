import 'dart:io';

import 'package:admin_arawatan/backend/schema/user_record.dart';
import 'package:admin_arawatan/components/admin_driver_documents_panel.dart';
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

UserRecord _driver() {
  return UserRecord.getDocumentFromData(
    {
      'display_name': 'Driver One',
      'ismndob': true,
      'phone_number': '+966500000000',
      'registration_documents_status': 'complete',
      'actev_mndob': true,
    },
    FirebaseFirestore.instance.collection('user').doc('d1'),
  );
}

void main() {
  setUpAll(_initFirebase);

  test('documents panel can omit lifecycle strip (single status owner)', () {
    final defaultPanel = AdminDriverDocumentsPanel(user: _driver());
    expect(defaultPanel.showLifecycleStrip, isTrue);

    final deduped = AdminDriverDocumentsPanel(
      user: _driver(),
      showLifecycleStrip: false,
    );
    expect(deduped.showLifecycleStrip, isFalse);
  });

  test('details drawer and profile body suppress duplicate lifecycle strip',
      () {
    final drawer = File(
      'lib/admin/admindrever/admin_drivers_details_drawer.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/driver_profile/driver_profile_body.dart',
    ).readAsStringSync();

    expect(drawer.contains('showLifecycleStrip: false'), isTrue);
    expect(profile.contains('showLifecycleStrip: false'), isTrue);
    // Header owns status stack — drawer must not mount a second StatusStack section.
    expect(drawer.contains('AdminDriverStatusStack('), isFalse);
  });
}
