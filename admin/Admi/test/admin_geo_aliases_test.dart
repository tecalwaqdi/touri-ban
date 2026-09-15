import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_geo_aliases.dart';

void main() {
  group('AdminGeoAliases', () {
    test('canonicalizes legacy Saudi village ids', () {
      expect(AdminGeoAliases.canonicalVillageId('city_makkah'), 'city_sa_makkah');
      expect(AdminGeoAliases.canonicalVillageId('city_alkhobar'), 'city_sa_khobar');
    });

    test('leaves already-canonical village ids', () {
      expect(
        AdminGeoAliases.canonicalVillageId('city_sa_jeddah'),
        'city_sa_jeddah',
      );
    });

    test('does not remap non-Saudi hubs', () {
      expect(
        AdminGeoAliases.canonicalVillageId('city_bishkek'),
        'city_bishkek',
      );
    });

    test('canonicalizes legacy Saudi region ids', () {
      expect(
        AdminGeoAliases.canonicalRegionId('region_makkah'),
        'region_sa_makkah',
      );
      expect(
        AdminGeoAliases.canonicalRegionId('region_sa_makkah'),
        'region_sa_makkah',
      );
    });
  });
}
