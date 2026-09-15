import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_app_visibility_location.dart';
import 'package:admin_arawatan/flutter_flow/lat_lng.dart';

void main() {
  group('AdminAppVisibilityLocation', () {
    test('keeps Taif pin north of bbox (no clamp)', () {
      const pin = LatLng(21.4710805, 40.4971769);
      final next = AdminAppVisibilityLocation.ensureVisibleInStoreApp(
        pin: pin,
        villageId: 'city_sa_taif',
      );
      expect(next.latitude, pin.latitude);
      expect(next.longitude, pin.longitude);
    });

    test('keeps Taif pin south of bbox (no clamp)', () {
      const pin = LatLng(21.1233522, 40.2733962);
      final next = AdminAppVisibilityLocation.ensureVisibleInStoreApp(
        pin: pin,
        villageId: 'city_sa_taif',
      );
      expect(next.latitude, pin.latitude);
      expect(next.longitude, pin.longitude);
    });

    test('keeps pin already inside box', () {
      const pin = LatLng(21.27, 40.42);
      final next = AdminAppVisibilityLocation.ensureVisibleInStoreApp(
        pin: pin,
        villageId: 'city_sa_taif',
      );
      expect(next.latitude, pin.latitude);
      expect(next.longitude, pin.longitude);
    });

    test('falls back to village center when pin missing', () {
      const village = LatLng(21.27, 40.42);
      final next = AdminAppVisibilityLocation.ensureVisibleInStoreApp(
        pin: null,
        villageId: 'city_sa_taif',
        villageCenter: village,
      );
      expect(next.latitude, village.latitude);
      expect(next.longitude, village.longitude);
    });
  });
}
