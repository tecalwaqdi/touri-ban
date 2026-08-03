import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_a11y.dart';
import 'package:mndob/core/driver_trip_constants.dart';
import 'package:mndob/core/toury_system_status_codes.dart';

void main() {
  group('DriverA11y', () {
    test('min touch target is 48', () {
      expect(DriverA11y.minTouchTarget, 48);
    });
  });

  group('Trip recovery next-action mapping (status codes)', () {
    String nextAction(String code) {
      if (code == TourySystemStatusCodes.driverAssigned ||
          code == TourySystemStatusCodes.driverArriving) {
        return 'arrive';
      }
      if (code == TourySystemStatusCodes.driverArrived) return 'start';
      if (code == TourySystemStatusCodes.tripInProgress ||
          code == TourySystemStatusCodes.tripStarted) {
        return 'complete';
      }
      return 'none';
    }

    test('assigned → arrive', () {
      expect(nextAction(TourySystemStatusCodes.driverAssigned), 'arrive');
    });
    test('arrived → start', () {
      expect(nextAction(TourySystemStatusCodes.driverArrived), 'start');
    });
    test('in progress → complete', () {
      expect(nextAction(TourySystemStatusCodes.tripInProgress), 'complete');
    });
    test('completed → none', () {
      expect(nextAction(TourySystemStatusCodes.completed), 'none');
    });
  });

  group('Wallet / cash rules', () {
    test('min cash wallet positive', () {
      expect(DriverWalletRules.minCashWalletBalance, greaterThan(0));
    });
  });

  group('FCM route aliases', () {
    test('legacy names normalize to TfaselOrser', () {
      String normalize(String raw) => switch (raw) {
            'tfasel_order' || 'tfaselOrser' || 'tfasel_orser' => 'TfaselOrser',
            _ => raw,
          };
      expect(normalize('tfasel_order'), 'TfaselOrser');
      expect(normalize('tfaselOrser'), 'TfaselOrser');
      expect(normalize('TfaselOrser'), 'TfaselOrser');
      expect(normalize('home'), 'home');
    });
  });
}
