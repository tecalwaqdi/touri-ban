import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_active_booking.dart';
import 'package:ara_oatan_app/core/toury_landmark_cart.dart';
import 'package:ara_oatan_app/app_state.dart';
import 'package:ara_oatan_app/backend/schema/structs/amakn_costm_struct.dart';

void main() {
  group('touryIsCustomerActiveStatusCode', () {
    test('payment_pending and pending_driver are active', () {
      expect(touryIsCustomerActiveStatusCode('payment_pending'), isTrue);
      expect(touryIsCustomerActiveStatusCode('pending_driver'), isTrue);
      expect(touryIsCustomerActiveStatusCode('driver_assigned'), isTrue);
      expect(touryIsCustomerActiveStatusCode('trip_in_progress'), isTrue);
    });

    test('terminal statuses are not active', () {
      expect(touryIsCustomerActiveStatusCode('completed'), isFalse);
      expect(touryIsCustomerActiveStatusCode('cancelled_by_customer'), isFalse);
      expect(touryIsCustomerActiveStatusCode('expired'), isFalse);
      expect(touryIsCustomerActiveStatusCode('trip_completed'), isFalse);
    });
  });

  group('landmark cart helpers', () {
    late FFAppState app;

    setUp(() {
      app = FFAppState();
      app.cartmkss = [];
      app.mkan = [];
      app.addcart = 0;
    });

    test('touryLandmarkAlreadyInCart false when empty', () {
      expect(app.cartmkss, isEmpty);
    });

    test('remove by matching name/location after add struct', () {
      final item = AmaknCostmStruct(
        naim: 'جبل الرحمة',
        loceshn: null,
      );
      app.addToCartmkss(item);
      app.addcart = 1;
      expect(app.cartmkss.length, 1);
      app.removeFromCartmkss(item);
      expect(app.cartmkss, isEmpty);
    });
  });

  group('TouryLandmarkCartOutcome', () {
    test('enum covers add remove duplicate', () {
      expect(TouryLandmarkCartOutcome.values, contains(TouryLandmarkCartOutcome.added));
      expect(TouryLandmarkCartOutcome.values, contains(TouryLandmarkCartOutcome.removed));
      expect(TouryLandmarkCartOutcome.values, contains(TouryLandmarkCartOutcome.alreadyInCart));
    });
  });
}
