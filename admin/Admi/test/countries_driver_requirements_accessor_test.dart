import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_driver_market_readiness.dart';
import 'package:admin_arawatan/backend/schema/countries_record.dart';

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

  group('CountriesRecord.driverRequirements', () {
    test('reads existing Firestore map without inventing keys', () {
      final doc = FirebaseFirestore.instance.collection('countries').doc('sa');
      final country = CountriesRecord.getDocumentFromData(
        {
          'naim': 'Saudi',
          'acctev': true,
          'driver_requirements': {
            'driver_license_front': {'enabled': true, 'required': true},
            'driver_license_back': {'enabled': true, 'required': false},
          },
        },
        doc,
      );
      expect(country.hasDriverRequirements(), isTrue);
      expect(country.driverRequirements['driver_license_back'], isA<Map>());
      expect(
        (country.driverRequirements['driver_license_back'] as Map)['required'],
        isFalse,
      );
      final readiness = AdminDriverMarketReadinessResolver.forCountry(
        country: country,
        activeVehicles: 2,
      );
      expect(readiness.enabledRequirements, 2);
      expect(readiness.isReady, isTrue);
    });

    test('empty when field absent', () {
      final doc = FirebaseFirestore.instance.collection('countries').doc('kg');
      final country = CountriesRecord.getDocumentFromData(
        {'naim': 'KG', 'acctev': true},
        doc,
      );
      expect(country.driverRequirements, isEmpty);
      expect(country.hasDriverRequirements(), isFalse);
      final readiness = AdminDriverMarketReadinessResolver.forCountry(
        country: country,
        activeVehicles: 2,
      );
      expect(readiness.enabledRequirements, 0);
      expect(
        readiness.status,
        AdminDriverMarketStatus.missingDriverRequirements,
      );
    });
  });
}
