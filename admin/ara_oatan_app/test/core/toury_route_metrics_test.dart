import 'package:ara_oatan_app/core/toury_route_metrics.dart';
import 'package:ara_oatan_app/flutter_flow/lat_lng.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const riyadh = LatLng(24.7136, 46.6753);
  const jeddah = LatLng(21.4858, 39.1925);

  group('route coordinate validation', () {
    test('accepts real Riyadh and Jeddah coordinates', () {
      expect(touryIsValidCoordinate(riyadh), isTrue);
      expect(touryIsValidCoordinate(jeddah), isTrue);
      final distance = touryStraightLineDistanceKm(riyadh, jeddah);
      expect(distance, inInclusiveRange(800, 900));
    });

    test('rejects null, zero, NaN, and infinite coordinates', () {
      expect(touryIsValidCoordinate(null), isFalse);
      expect(touryIsValidCoordinate(const LatLng(0, 0)), isFalse);
      expect(touryIsValidCoordinate(LatLng(double.nan, 46)), isFalse);
      expect(touryIsValidCoordinate(LatLng(24, double.infinity)), isFalse);
    });

    test('rejects an out-of-area or swapped destination', () {
      final validation = touryValidateRoutePoints(
        origin: riyadh,
        selectedAreaCenter: riyadh,
        destinations: const [
          jeddah,
          LatLng(46.6753, 24.7136),
        ],
      );

      expect(validation.rejectedCount, 2);
      expect(validation.canRoute, isFalse);
      expect(validation.errorKey, 'map_no_valid_destinations');
    });

    test('adds route legs sequentially instead of taking the longest leg', () {
      final validation = touryValidateRoutePoints(
        origin: riyadh,
        destinations: const [
          LatLng(24.75, 46.70),
          LatLng(24.80, 46.75),
        ],
      );
      final estimate = touryEstimateRoute(validation.points);

      expect(validation.canRoute, isTrue);
      expect(estimate.distanceKm, greaterThan(10));
      expect(estimate.distanceKm, lessThan(30));
      expect(estimate.durationHours, greaterThan(0));
    });

    test('rejects impossible road metrics such as 13036 km and 211 h', () {
      expect(
        touryRoadMetricsArePlausible(
          distanceKm: 13036.7,
          durationSeconds: const Duration(hours: 211).inSeconds.toDouble(),
          points: const [riyadh, jeddah],
        ),
        isFalse,
      );
    });
  });
}
