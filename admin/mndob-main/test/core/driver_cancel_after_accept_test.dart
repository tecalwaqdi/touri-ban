import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_lifecycle_state.dart';
import 'package:mndob/core/driver_trip_constants.dart';
import 'package:mndob/core/toury_system_status_codes.dart';

void main() {
  group('DriverTripActionGates.canCancel', () {
    test('accepted driver cannot cancel', () {
      expect(
        DriverTripActionGates.canCancel(
          TourySystemStatusCodes.driverAssigned,
          DriverTripHalh.accepted,
        ),
        isFalse,
      );
      expect(
        DriverTripActionGates.canCancel(
          TourySystemStatusCodes.driverArrived,
          DriverTripHalh.driverArrived,
        ),
        isFalse,
      );
      expect(
        DriverTripActionGates.canCancel(
          TourySystemStatusCodes.tripInProgress,
          DriverTripHalh.inProgress,
        ),
        isFalse,
      );
    });
  });

  group('DriverTripActionGates.isTripStarted', () {
    test('false before start', () {
      expect(
        DriverTripActionGates.isTripStarted(
          TourySystemStatusCodes.driverAssigned,
          DriverTripHalh.accepted,
        ),
        isFalse,
      );
      expect(
        DriverTripActionGates.isTripStarted(
          TourySystemStatusCodes.driverArrived,
          DriverTripHalh.driverArrived,
        ),
        isFalse,
      );
    });

    test('true after start', () {
      expect(
        DriverTripActionGates.isTripStarted(
          TourySystemStatusCodes.tripStarted,
          DriverTripHalh.inProgress,
        ),
        isTrue,
      );
      expect(
        DriverTripActionGates.isTripStarted(
          TourySystemStatusCodes.tripInProgress,
          DriverTripHalh.inProgress,
        ),
        isTrue,
      );
      expect(
        DriverTripActionGates.isTripStarted(
          '',
          DriverTripHalh.inProgress,
        ),
        isTrue,
      );
    });
  });
}
