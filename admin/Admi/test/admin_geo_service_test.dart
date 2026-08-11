import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/backend/admin_country_geo_service.dart';
import 'package:admin_arawatan/flutter_flow/lat_lng.dart';

void main() {
  test('geoFieldsForFirestore includes currency and bounds', () {
    final geo = AdminGeoPlaceData(
      isoCode: 'KG',
      englishName: 'Kyrgyzstan',
      center: const LatLng(41.2, 74.7),
      boundsSouthWest: const LatLng(39.0, 69.0),
      boundsNorthEast: const LatLng(43.0, 80.0),
      currencyCode: 'KGS',
      currencySymbol: 'сом',
    );
    final map = AdminCountryGeoService.geoFieldsForFirestore(geo);
    expect(map['iso_code'], 'KG');
    expect(map['currency_code'], 'KGS');
    expect(map['CurrencySymbol'], 'сом');
    expect(map['geo_center'], isNotNull);
    expect(map['bounds_sw'], isNotNull);
  });

  test('cityGeoFieldsForFirestore sets lat_ling', () {
    final geo = AdminGeoPlaceData(
      center: const LatLng(42.87, 74.59),
      displayName: 'Bishkek',
    );
    final map = AdminCountryGeoService.cityGeoFieldsForFirestore(geo);
    expect(map['lat_ling'], isNotNull);
    expect(map['naim_viil_map'], 'Bishkek');
  });
}
