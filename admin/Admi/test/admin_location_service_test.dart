import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/components/admin_location_service.dart';

void main() {
  group('AdminLocationService.parseCoordinates', () {
    test('parses decimal pair', () {
      final p = AdminLocationService.parseCoordinates('21.4710805, 40.4971769');
      expect(p, isNotNull);
      expect(p!.latitude, closeTo(21.4710805, 1e-7));
      expect(p.longitude, closeTo(40.4971769, 1e-7));
    });

    test('parses Google Maps @lat,lng URL', () {
      final p = AdminLocationService.parseCoordinates(
        'https://www.google.com/maps/place/Foo/@21.422507,39.826208,17z',
      );
      expect(p, isNotNull);
      expect(p!.latitude, closeTo(21.422507, 1e-6));
      expect(p.longitude, closeTo(39.826208, 1e-6));
    });

    test('parses !3d!4d place data', () {
      final p = AdminLocationService.parseCoordinates(
        'https://www.google.com/maps/place/Foo/data=!3d21.27!4d40.41',
      );
      expect(p, isNotNull);
      expect(p!.latitude, closeTo(21.27, 1e-6));
      expect(p.longitude, closeTo(40.41, 1e-6));
    });

    test('parses q= query coords', () {
      final p = AdminLocationService.parseCoordinates(
        'https://maps.google.com/?q=24.7136,46.6753',
      );
      expect(p, isNotNull);
      expect(p!.latitude, closeTo(24.7136, 1e-6));
      expect(p.longitude, closeTo(46.6753, 1e-6));
    });
  });
}
