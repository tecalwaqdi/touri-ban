import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/app_state.dart';
import 'package:ara_oatan_app/backend/schema/mkan_record.dart';
import 'package:ara_oatan_app/core/toury_landmark_filter.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

MkanRecord _mkan({
  required String id,
  required DocumentReference village,
  String name = 'Test Landmark',
}) {
  return MkanRecord.getDocumentFromData({
    'naim': name,
    'acctev': true,
    'id_vill': village,
    'names_i18n': {'en': name, 'ar': name},
  }, FirebaseFirestore.instance.collection('mkan').doc(id));
}

void main() {
  setUpAll(_initFirebase);

  test('non-Saudi village keeps Admin landmarks (no Saudi bbox drop)', () {
    final app = FFAppState();
    final africaVillage = FirebaseFirestore.instance
        .collection('villages')
        .doc('city_ng_abuja');
    app.villa = africaVillage;
    app.naimvillatext = 'الرياض'; // leftover Saudi label must not filter

    final landmark = _mkan(
      id: 'lm_ng_test',
      village: africaVillage,
      name: 'National Mosque',
    );

    expect(touryLandmarkMatchesActiveCity(landmark, app), isTrue);
    final filtered = touryFilterLandmarksForUi([landmark], 'en', state: app);
    expect(filtered.map((e) => e.reference.id), contains('lm_ng_test'));
  });

  test('Admin write contract fields survive filter when active+named', () {
    final app = FFAppState();
    final village = FirebaseFirestore.instance
        .collection('villages')
        .doc('city_ng_abuja');
    app.villa = village;

    final landmark = _mkan(
      id: 'lm_admin_new',
      village: village,
      name: 'National Mosque',
    );
    expect(landmark.acctev, isTrue);
    expect(landmark.idVill?.path, village.path);
    expect(touryFilterLandmarksForUi([landmark], 'en', state: app), isNotEmpty);
  });
}
