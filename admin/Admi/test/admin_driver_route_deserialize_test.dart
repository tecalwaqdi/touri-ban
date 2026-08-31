import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/flutter_flow/nav/serialization_util.dart';

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

  group('DocumentReference deserialize (user collection)', () {
    test('bare uid → user/{uid}', () {
      final ref = deserializeParam(
        'DZbM2HXJeNTCwiVUtahiaT79paH2',
        ParamType.DocumentReference,
        false,
        collectionNamePath: ['user'],
      );
      expect(ref, isNotNull);
      expect(ref.path, 'user/DZbM2HXJeNTCwiVUtahiaT79paH2');
    });

    test('user|uid must not become user/user', () {
      final ref = deserializeParam(
        'user|DZbM2HXJeNTCwiVUtahiaT79paH2',
        ParamType.DocumentReference,
        false,
        collectionNamePath: ['user'],
      );
      expect(ref, isNotNull);
      expect(ref.path, 'user/DZbM2HXJeNTCwiVUtahiaT79paH2');
      expect(ref.path, isNot(equals('user/user')));
    });
  });
}
