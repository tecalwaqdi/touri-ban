import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_car_marker.dart';

void main() {
  group('touryNormalizeHeading', () {
    test('wraps into [0, 360)', () {
      expect(touryNormalizeHeading(0), 0);
      expect(touryNormalizeHeading(360), 0);
      expect(touryNormalizeHeading(370), closeTo(10, 1e-9));
      expect(touryNormalizeHeading(-10), closeTo(350, 1e-9));
      expect(touryNormalizeHeading(-370), closeTo(350, 1e-9));
    });

    test('non-finite input degrades to 0 instead of poisoning the marker', () {
      expect(touryNormalizeHeading(double.nan), 0);
      expect(touryNormalizeHeading(double.infinity), 0);
    });
  });

  group('touryLerpHeading', () {
    test('interpolates the short way across the 0/360 seam', () {
      // 350° -> 10° must go forwards through 0°, not backwards through 180°.
      expect(touryLerpHeading(350, 10, 0.5), closeTo(0, 1e-6));
      expect(touryLerpHeading(10, 350, 0.5), closeTo(0, 1e-6));
    });

    test('never takes the long way round for near-opposite angles', () {
      final mid = touryLerpHeading(0, 179, 0.5);
      expect(mid, closeTo(89.5, 1e-6));
    });

    test('endpoints are exact', () {
      expect(touryLerpHeading(30, 200, 0), closeTo(30, 1e-6));
      expect(touryLerpHeading(30, 200, 1), closeTo(200, 1e-6));
    });

    test('result always stays inside [0, 360)', () {
      for (var from = 0; from < 360; from += 37) {
        for (var to = 0; to < 360; to += 53) {
          for (final t in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
            final value = touryLerpHeading(from.toDouble(), to.toDouble(), t);
            expect(value, greaterThanOrEqualTo(0));
            expect(value, lessThan(360));
          }
        }
      }
    });
  });

  group('touryBearingDegrees', () {
    test('due north / east / south / west', () {
      expect(touryBearingDegrees(0, 0, 1, 0), closeTo(0, 0.5));
      expect(touryBearingDegrees(0, 0, 0, 1), closeTo(90, 0.5));
      expect(touryBearingDegrees(1, 0, 0, 0), closeTo(180, 0.5));
      expect(touryBearingDegrees(0, 1, 0, 0), closeTo(270, 0.5));
    });

    test('identical points do not produce NaN', () {
      final bearing = touryBearingDegrees(24.7136, 46.6753, 24.7136, 46.6753);
      expect(bearing.isNaN, isFalse);
      expect(bearing, greaterThanOrEqualTo(0));
    });
  });

  group('descriptor cache', () {
    // Rasterizing the bitmap itself needs a real raster backend, so the cache
    // contract is asserted here and the artwork is verified on device.
    test('starts empty and is clearable', () {
      TouryMapMarkers.debugClearCache();
      expect(TouryMapMarkers.debugCacheSize, 0);
    });
  });
}
