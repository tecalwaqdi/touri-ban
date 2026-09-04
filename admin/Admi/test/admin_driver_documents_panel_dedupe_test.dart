import 'dart:io';

import 'package:admin_arawatan/backend/schema/user_record.dart';
import 'package:admin_arawatan/components/admin_driver_documents_panel.dart';
import 'package:admin_arawatan/core/admin_driver_profile_view.dart';
import 'package:admin_arawatan/core/driver_license_document.dart';
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

UserRecord _driver(Map<String, dynamic> data) {
  return UserRecord.getDocumentFromData({
    'display_name': 'Driver One',
    'ismndob': true,
    'phone_number': '+966500000000',
    'registration_documents_status': 'complete',
    'actev_mndob': true,
    ...data,
  }, FirebaseFirestore.instance.collection('user').doc('d1'));
}

void main() {
  setUpAll(_initFirebase);

  test('documents panel can omit lifecycle strip (single status owner)', () {
    final defaultPanel = AdminDriverDocumentsPanel(user: _driver({}));
    expect(defaultPanel.showLifecycleStrip, isTrue);

    final deduped = AdminDriverDocumentsPanel(
      user: _driver({}),
      showLifecycleStrip: false,
    );
    expect(deduped.showLifecycleStrip, isFalse);
  });

  test('details drawer and profile body suppress duplicate lifecycle strip', () {
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
    // Phone owned by header in drawer personal section.
    expect(
      RegExp(r"label: uiTr\(context, 'الهاتف'\)").hasMatch(drawer),
      isFalse,
    );
  });

  test('profile body does not re-list name/phone in personal section', () {
    final profile = File(
      'lib/driver_profile/driver_profile_body.dart',
    ).readAsStringSync();
    // Personal section starts after _leftSections; header owns identity.
    expect(profile.contains("label: uiTr(context, 'الاسم')"), isFalse);
    expect(
      profile.contains(
        "// Name / email / phone owned by _ProfileHeader — avoid duplicates.",
      ),
      isTrue,
    );
  });

  test('front/back license suppresses legacy slot', () {
    final user = _driver({
      'doc_driver_license_front': {'storagePath': 'users/d1/front.jpg'},
      'doc_driver_license_back': {'storagePath': 'users/d1/back.jpg'},
      'doc_driver_license': {'url': 'https://example.com/legacy.jpg'},
    });
    expect(DriverLicenseDocument.hasFront(user.snapshotData), isTrue);
    expect(DriverLicenseDocument.hasBack(user.snapshotData), isTrue);
    final docs = AdminDriverProfileView.documents(user);
    final kinds = docs.map((d) => d.kind).toSet();
    expect(kinds.contains(AdminDriverDocKind.driverLicenseFront), isTrue);
    expect(kinds.contains(AdminDriverDocKind.driverLicenseBack), isTrue);
    expect(kinds.contains(AdminDriverDocKind.driverLicenseLegacy), isFalse);
  });

  test('legacy license slot when front/back absent', () {
    final user = _driver({
      'doc_driver_license': {'url': 'https://example.com/legacy.jpg'},
    });
    final docs = AdminDriverProfileView.documents(user);
    final legacy = docs.where(
      (d) => d.kind == AdminDriverDocKind.driverLicenseLegacy,
    );
    expect(legacy.length, 1);
    expect(legacy.first.presence, AdminDriverDocPresence.legacy);
  });

  test('parseDocExpiry never invents dates from garbage', () {
    expect(AdminDriverProfileView.parseDocExpiry('not-a-date'), isNull);
    expect(AdminDriverProfileView.parseDocExpiry({}), isNull);
  });
}
