import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/backend/schema/mkan_record.dart';
import 'package:ara_oatan_app/core/toury_firestore_cache.dart';
import 'package:ara_oatan_app/core/toury_mkan_pagination.dart';

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

  tearDown(() {
    TouryMkanPaginationHub.clearForTests();
  });

  test('re-bind same village with items schedules soft server refresh', () {
    final village =
        FirebaseFirestore.instance.collection('villages').doc('city_ng_abuja');
    final existing = MkanRecord.getDocumentFromData(
      {
        'naim': 'Cached Landmark',
        'acctev': true,
        'id_vill': village,
        'names_i18n': {'en': 'Cached Landmark'},
      },
      FirebaseFirestore.instance.collection('mkan').doc('lm_cached'),
    );

    TouryFirestoreCache.storeMkanPage(
      village,
      TouryMkanCachedPage(
        items: [existing],
        lastDoc: null,
        hasMore: false,
        fetchedAt: DateTime.now(),
      ),
    );

    final c = TouryMkanPaginationController();
    c.bindVillage(village);
    expect(c.items, isNotEmpty);
    expect(c.softRefreshInvocations, greaterThanOrEqualTo(1));

    final before = c.softRefreshInvocations;
    // Simulate returning to city after Admin add — same session, same village.
    c.bindVillage(village);
    expect(c.softRefreshInvocations, greaterThan(before));
    expect(c.isLoading, isFalse);
    c.dispose();
  });
}
