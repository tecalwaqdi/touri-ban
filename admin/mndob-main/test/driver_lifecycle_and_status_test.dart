import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_trip_constants.dart';
import 'package:mndob/core/toury_country_registry.dart';
import 'package:mndob/core/toury_system_status_codes.dart';

void main() {
  group('TourySystemStatusCodes', () {
    test('pending_driver is assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable('pending_driver', '', 'Pending'),
        isTrue,
      );
    });

    test('already assigned is not assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable('driver_assigned', 'مقبول', ''),
        isFalse,
      );
    });

    test('completed is not assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable('completed', 'مكتمل', 'Paid'),
        isFalse,
      );
    });

    test('legacy Arabic waiting is assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable(
          '',
          'بإنتظار قبول المندوب',
          '',
        ),
        isTrue,
      );
    });

    test('fromHalhText maps arrived and in progress', () {
      expect(
        TourySystemStatusCodes.fromHalhText('وصل المندوب'),
        TourySystemStatusCodes.driverArrived,
      );
      expect(
        TourySystemStatusCodes.fromHalhText('تم البدء في الرحلة'),
        TourySystemStatusCodes.tripInProgress,
      );
    });

    test('isActiveTripCode covers arrive and start', () {
      expect(
        TourySystemStatusCodes.isActiveTripCode('driver_arrived'),
        isTrue,
      );
      expect(
        TourySystemStatusCodes.isActiveTripCode('trip_in_progress'),
        isTrue,
      );
      expect(
        TourySystemStatusCodes.isActiveTripCode('completed'),
        isFalse,
      );
    });

    test('displayHalhForCode dual-write mapping', () {
      expect(
        TourySystemStatusCodes.displayHalhForCode('driver_arrived'),
        'وصل المندوب',
      );
      expect(
        TourySystemStatusCodes.displayHalhForCode('cancelled_by_driver'),
        'ملغي',
      );
    });
  });

  group('TouryCountryRegistry currency', () {
    test('currency by iso', () {
      expect(TouryCountryRegistry.currencyForIso('SA'), 'SAR');
      expect(TouryCountryRegistry.currencyForIso('KG'), 'KGS');
      expect(TouryCountryRegistry.currencyForIso('RU'), 'RUB');
      expect(TouryCountryRegistry.currencyForIso('UZ'), 'UZS');
    });
  });

  group('DriverTripHalh', () {
    test('completed aliases', () {
      expect(DriverTripHalh.isCompleted('مكتمل'), isTrue);
      expect(DriverTripHalh.isCompleted('مكتملة'), isTrue);
      expect(DriverTripHalh.isCompleted('ملغي'), isFalse);
    });

    test('active trip set includes arrived', () {
      expect(DriverTripHalh.isActiveTrip('وصل المندوب'), isTrue);
      expect(DriverTripHalh.isActiveTrip('مقبول'), isTrue);
    });
  });
}
