import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_trip_progress.dart';

void main() {
  group('touryResolveTripStage', () {
    test('maps canonical status codes to stages', () {
      expect(
        touryResolveTripStage(statusCode: 'pending_driver'),
        TouryTripStage.searching,
      );
      expect(
        touryResolveTripStage(statusCode: 'driver_assigned'),
        TouryTripStage.enRoute,
      );
      expect(
        touryResolveTripStage(statusCode: 'driver_arrived'),
        TouryTripStage.arrived,
      );
      expect(
        touryResolveTripStage(statusCode: 'trip_in_progress'),
        TouryTripStage.started,
      );
      expect(
        touryResolveTripStage(statusCode: 'completed'),
        TouryTripStage.completed,
      );
    });

    test('maps legacy Arabic halh_text to stages', () {
      expect(
        touryResolveTripStage(halhText: 'مقبول'),
        TouryTripStage.enRoute,
      );
      expect(
        touryResolveTripStage(halhText: 'وصل المندوب'),
        TouryTripStage.arrived,
      );
      expect(
        touryResolveTripStage(halhText: 'تم البدء في الرحلة'),
        TouryTripStage.started,
      );
      expect(
        touryResolveTripStage(halhText: 'مكتمل'),
        TouryTripStage.completed,
      );
    });

    test('driver-side completion wins over a stale order status', () {
      expect(
        touryResolveTripStage(
          statusCode: 'trip_in_progress',
          driverOrderStatus: 'Completed',
        ),
        TouryTripStage.completed,
      );
    });

    test('unknown status degrades to searching, not a crash', () {
      expect(
        touryResolveTripStage(statusCode: 'future_unmapped_code'),
        TouryTripStage.searching,
      );
      expect(touryResolveTripStage(), TouryTripStage.searching);
    });
  });

  group('timeline', () {
    test('stage indexes advance monotonically', () {
      final indexes = [
        TouryTripStage.searching,
        TouryTripStage.enRoute,
        TouryTripStage.arrived,
        TouryTripStage.started,
        TouryTripStage.completed,
      ].map(touryTripStageIndex).toList();

      expect(indexes, [0, 1, 2, 3, 4]);
      expect(touryTripTimeline.length, 5);
    });

    test('every stage has a distinct title key', () {
      final keys =
          touryTripTimeline.map(touryTripStageTitleKey).toSet();
      expect(keys.length, touryTripTimeline.length);
      expect(keys.every((k) => k.startsWith('track_stage_')), isTrue);
    });

    test('live stages are exactly the on-map ones', () {
      expect(touryTripStageIsLive(TouryTripStage.searching), isFalse);
      expect(touryTripStageIsLive(TouryTripStage.enRoute), isTrue);
      expect(touryTripStageIsLive(TouryTripStage.arrived), isTrue);
      expect(touryTripStageIsLive(TouryTripStage.started), isTrue);
      expect(touryTripStageIsLive(TouryTripStage.completed), isFalse);
    });
  });
}
