import 'package:ara_oatan_app/core/toury_billable_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TouryBillableHours.serviceMinutes', () {
    test('50 travel + 1 landmark = 65', () {
      expect(
        TouryBillableHours.serviceMinutes(
          outboundTravelMinutes: 50,
          landmarkCount: 1,
        ),
        65,
      );
    });

    test('50 travel + 1 landmark + 50 return = 115', () {
      expect(
        TouryBillableHours.serviceMinutes(
          outboundTravelMinutes: 50,
          landmarkCount: 1,
          returnTravelMinutes: 50,
        ),
        115,
      );
    });

    test('two landmarks add 30 visit minutes', () {
      expect(
        TouryBillableHours.serviceMinutes(
          outboundTravelMinutes: 40,
          landmarkCount: 2,
        ),
        70,
      );
    });
  });

  group('TouryBillableHours.compute', () {
    test('65 service min + selected 1h => 2h (ceil)', () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          estimatedRouteDurationMinutes: 65,
        ),
        2,
      );
    });

    test('115 service min still 2h', () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          estimatedRouteDurationMinutes: 115,
        ),
        2,
      );
    });

    test('135 service min => 3h', () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          estimatedRouteDurationMinutes: 135,
        ),
        3,
      );
    });

    test('55 min travel only (no landmark visit in minutes arg) + selected 1h => 1h',
        () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          estimatedRouteDurationMinutes: 55,
        ),
        1,
      );
    });

    test('70 min + selected 1h => 2h', () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          estimatedRouteDurationMinutes: 70,
        ),
        2,
      );
    });

    test('121 min + selected 1h => 3h', () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          estimatedRouteDurationMinutes: 121,
        ),
        3,
      );
    });

    test('selected 3h + ETA 70 min => keep 3h', () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 3,
          vehicleMinimumHours: 1,
          estimatedRouteDurationMinutes: 70,
        ),
        3,
      );
    });

    test('vehicle minimum hours respected', () {
      expect(
        TouryBillableHours.compute(
          userSelectedHours: 1,
          vehicleMinimumHours: 4,
          estimatedRouteDurationMinutes: 55,
        ),
        4,
      );
    });

    test('computeFromLegs matches example mechanism', () {
      // 50 travel + 15 visit = 65 → 2h even if customer picks 1h
      expect(
        TouryBillableHours.computeFromLegs(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          outboundTravelMinutes: 50,
          landmarkCount: 1,
        ),
        2,
      );
      // +50 return = 115 → still 2h
      expect(
        TouryBillableHours.computeFromLegs(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          outboundTravelMinutes: 50,
          landmarkCount: 1,
          returnTravelMinutes: 50,
        ),
        2,
      );
      // 2h15 equivalent: 50+15+70 = 135 → 3h
      expect(
        TouryBillableHours.computeFromLegs(
          userSelectedHours: 1,
          vehicleMinimumHours: 1,
          outboundTravelMinutes: 50,
          landmarkCount: 1,
          returnTravelMinutes: 70,
        ),
        3,
      );
    });
  });

  group('TouryBillableHours helpers', () {
    test('hoursFromRouteMinutes ceils', () {
      expect(TouryBillableHours.hoursFromRouteMinutes(0), 0);
      expect(TouryBillableHours.hoursFromRouteMinutes(55), 1);
      expect(TouryBillableHours.hoursFromRouteMinutes(60), 1);
      expect(TouryBillableHours.hoursFromRouteMinutes(61), 2);
      expect(TouryBillableHours.hoursFromRouteMinutes(121), 3);
    });

    test('splitDurationMinutes', () {
      expect(TouryBillableHours.splitDurationMinutes(70), (1, 10));
      expect(TouryBillableHours.splitDurationMinutes(55), (0, 55));
    });
  });
}
