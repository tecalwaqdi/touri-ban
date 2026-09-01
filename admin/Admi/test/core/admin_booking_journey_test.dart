import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/admin_booking_journey.dart';
import 'package:admin_arawatan/core/toury_system_status_codes.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

OrderRecord _order(Map<String, dynamic> data, [String id = 'o1']) {
  final ref = FirebaseFirestore.instance.collection('order').doc(id);
  return OrderRecord.getDocumentFromData(data, ref);
}

Map<String, dynamic> _stop({
  required String name,
  bool? okdone,
}) =>
    {
      'naim': name,
      if (okdone != null) 'okdone': okdone,
    };

void main() {
  setUpAll(_initFirebase);

  group('AdminBookingJourneyView', () {
    test('empty listAmakn → empty journey', () {
      final j = AdminBookingJourneyView.fromOrder(_order({}));
      expect(j.isEmpty, isTrue);
      expect(j.hasStopMetadata, isFalse);
    });

    test('single stop without okdone → unknown state', () {
      final j = AdminBookingJourneyView.fromOrder(_order({
        'listAmakn': [_stop(name: 'المعلم')],
        'status_code': TourySystemStatusCodes.tripStarted,
      }));
      expect(j.stops.length, 1);
      expect(j.stops.first.state, AdminBookingJourneyStopState.unknown);
    });

    test('two stops: first visited, second current', () {
      final j = AdminBookingJourneyView.fromOrder(_order({
        'listAmakn': [
          _stop(name: 'محطة 1', okdone: true),
          _stop(name: 'محطة 2', okdone: false),
        ],
        'status_code': TourySystemStatusCodes.tripStarted,
      }));
      expect(j.stops[0].state, AdminBookingJourneyStopState.visited);
      expect(j.stops[1].state, AdminBookingJourneyStopState.current);
    });

    test('three landmark stops + return: return leg when all landmarks visited',
        () {
      final j = AdminBookingJourneyView.fromOrder(_order({
        'listAmakn': [
          _stop(name: 'أ', okdone: true),
          _stop(name: 'ب', okdone: true),
          _stop(name: 'العودة', okdone: false),
        ],
        'status_code': TourySystemStatusCodes.tripInProgress,
      }));
      expect(j.onReturnLeg, isTrue);
      expect(j.stops[0].state, AdminBookingJourneyStopState.visited);
      expect(j.stops[1].state, AdminBookingJourneyStopState.visited);
      expect(j.stops[2].state, AdminBookingJourneyStopState.current);
      expect(j.stops[2].isReturnDestination, isTrue);
    });

    test('completed trip does not auto-mark unvisited stops', () {
      final j = AdminBookingJourneyView.fromOrder(_order({
        'listAmakn': [
          _stop(name: 'أ', okdone: false),
          _stop(name: 'ب', okdone: false),
        ],
        'status_code': TourySystemStatusCodes.completed,
      }));
      expect(j.tripInProgress, isFalse);
      expect(j.stops[0].state, isNot(AdminBookingJourneyStopState.visited));
      expect(j.stops[1].state, isNot(AdminBookingJourneyStopState.visited));
    });

    test('malformed stop entry does not crash', () {
      final j = AdminBookingJourneyView.fromOrder(_order({
        'listAmakn': ['bad', _stop(name: 'صالح', okdone: true)],
        'status_code': TourySystemStatusCodes.tripStarted,
      }));
      expect(j.stops.length, 2);
      expect(j.stops[0].state, AdminBookingJourneyStopState.unknown);
      expect(j.stops[1].state, AdminBookingJourneyStopState.visited);
    });

    test('labels match fixture: stop1 visited stop2 current', () {
      final j = AdminBookingJourneyView.fromOrder(_order({
        'listAmakn': [
          _stop(name: 'Landmark A', okdone: true),
          _stop(name: 'Landmark B', okdone: false),
        ],
        'status_code': TourySystemStatusCodes.tripStarted,
      }));
      expect(
        AdminBookingJourneyView.stateLabelArabic(j.stops[0].state),
        'تمت الزيارة',
      );
      expect(
        AdminBookingJourneyView.stateLabelArabic(j.stops[1].state),
        'الحالي',
      );
    });
  });
}
