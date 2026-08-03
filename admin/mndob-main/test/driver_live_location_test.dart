import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_live_location_service.dart';
import 'package:mndob/flutter_flow/lat_lng.dart';

void main() {
  group('DriverLiveLocationService.isUsableCoordinate', () {
    test('rejects null and zero', () {
      expect(DriverLiveLocationService.isUsableCoordinate(null), isFalse);
      expect(
        DriverLiveLocationService.isUsableCoordinate(const LatLng(0, 0)),
        isFalse,
      );
    });

    test('accepts valid city coords', () {
      expect(
        DriverLiveLocationService.isUsableCoordinate(
          const LatLng(41.2995, 69.2401),
        ),
        isTrue,
      );
    });

    test('rejects out of range', () {
      expect(
        DriverLiveLocationService.isUsableCoordinate(
          const LatLng(120, 10),
        ),
        isFalse,
      );
    });
  });
}
