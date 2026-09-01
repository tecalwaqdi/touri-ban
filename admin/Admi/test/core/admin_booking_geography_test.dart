import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/admin_booking_geography.dart';
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

OrderRecord _order(Map<String, dynamic> data) {
  return OrderRecord.getDocumentFromData(
    data,
    FirebaseFirestore.instance.collection('order').doc('o1'),
  );
}

void main() {
  setUpAll(_initFirebase);

  test('uses vill_text as trip city', () {
    final geo = AdminBookingGeography.fromOrder(
      _order({
        'vill_text': 'Jeddah',
        'Rev_dolh': FirebaseFirestore.instance.doc('countries/saudi_arabia'),
      }),
    );
    expect(geo.tripCity, 'Jeddah');
    expect(geo.tripCityKnown, isTrue);
    expect(geo.tripCountry, contains('Saudi'));
  });

  test('legacy order without city shows unknown', () {
    final geo = AdminBookingGeography.fromOrder(_order({}));
    expect(geo.tripCity, AdminBookingGeography.unknownLabel);
    expect(geo.tripCityKnown, isFalse);
  });

  test('does not infer city from unrelated fields', () {
    final geo = AdminBookingGeography.fromOrder(
      _order({'naim_mndob_text': 'Riyadh Driver'}),
    );
    expect(geo.tripCity, AdminBookingGeography.unknownLabel);
  });
}
