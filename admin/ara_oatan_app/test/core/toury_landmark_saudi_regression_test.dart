import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/app_state.dart';
import 'package:ara_oatan_app/backend/schema/mkan_record.dart';
import 'package:ara_oatan_app/core/toury_landmark_filter.dart';
import 'package:ara_oatan_app/flutter_flow/lat_lng.dart';

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
  required String name,
  LatLng? location,
}) {
  return MkanRecord.getDocumentFromData(
    {
      'naim': name,
      'acctev': true,
      'id_vill': village,
      'names_i18n': {'en': name, 'ar': name},
      if (location != null) 'Location': location,
    },
    FirebaseFirestore.instance.collection('mkan').doc(id),
  );
}

void main() {
  setUpAll(_initFirebase);

  test('Saudi village still drops landmarks outside Saudi city bbox', () {
    final app = FFAppState();
    final riyadhVillage =
        FirebaseFirestore.instance.collection('villages').doc('city_sa_riyadh');
    app.villa = riyadhVillage;
    app.naimvillatext = 'الرياض';

    final jeddahLandmark = _mkan(
      id: 'lm_wrong_city',
      village: riyadhVillage,
      name: 'Jeddah Corniche',
      location: const LatLng(21.4858, 39.1925), // Jeddah
    );

    expect(touryLandmarkMatchesActiveCity(jeddahLandmark, app), isFalse);
  });

  test('Saudi village keeps landmarks inside active Saudi city', () {
    final app = FFAppState();
    final riyadhVillage =
        FirebaseFirestore.instance.collection('villages').doc('city_sa_riyadh');
    app.villa = riyadhVillage;
    app.naimvillatext = 'الرياض';

    final riyadhLandmark = _mkan(
      id: 'lm_riyadh_ok',
      village: riyadhVillage,
      name: 'Kingdom Centre',
      location: const LatLng(24.7111, 46.6744),
    );

    expect(touryLandmarkMatchesActiveCity(riyadhLandmark, app), isTrue);
  });
}
