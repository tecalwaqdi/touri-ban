import 'package:admin_arawatan/admin/admin_geo/admin_geo_adapter.dart';
import 'package:admin_arawatan/backend/schema/cities_record.dart';
import 'package:admin_arawatan/backend/schema/countries_record.dart';
import 'package:admin_arawatan/backend/schema/villages_record.dart';
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

CountriesRecord _country(String id) => CountriesRecord.getDocumentFromData(
      {'naim': id},
      FirebaseFirestore.instance.collection('countries').doc(id),
    );

CitiesRecord _region(String id, String countryId) =>
    CitiesRecord.getDocumentFromData(
      {
        'naim': id,
        'dolh': FirebaseFirestore.instance.doc('countries/$countryId'),
      },
      FirebaseFirestore.instance.collection('cities').doc(id),
    );

VillagesRecord _city(String id, String regionId, {String? countryId}) =>
    VillagesRecord.getDocumentFromData(
      {
        'naim': id,
        'cities': FirebaseFirestore.instance.doc('cities/$regionId'),
        if (countryId != null)
          'dolh': FirebaseFirestore.instance.doc('countries/$countryId'),
      },
      FirebaseFirestore.instance.collection('villages').doc(id),
    );

void main() {
  setUpAll(_initFirebase);

  test('integrityCounts tolerates orphan city region reference', () {
    final counts = AdminGeoAdapter.integrityCounts(
      countries: [_country('sa')],
      regions: [_region('riyadh', 'sa')],
      cities: [
        _city('jeddah', 'missing_region', countryId: 'sa'),
      ],
    );
    expect(counts['orphanCities'], 1);
  });

  test('integrityCounts handles empty collections', () {
    final counts = AdminGeoAdapter.integrityCounts(
      countries: [],
      regions: [],
      cities: [],
    );
    expect(counts['orphanRegions'], 0);
    expect(counts['orphanCities'], 0);
  });
}
