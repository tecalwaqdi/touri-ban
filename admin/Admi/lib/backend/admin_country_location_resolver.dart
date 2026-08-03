import '/backend/backend.dart';
import '/backend/admin_country_geo_service.dart';
import '/flutter_flow/lat_lng.dart';

/// يحدد الدولة من إحداثيات GPS باستخدام الحدود المخزنة.
abstract final class AdminCountryLocationResolver {
  AdminCountryLocationResolver._();

  static Future<CountriesRecord?> resolveCountry(
    LatLng position, {
    List<CountriesRecord>? countries,
  }) async {
    final list = countries ??
        await queryCountriesRecordOnce(
          queryBuilder: (q) => q.where('acctev', isEqualTo: true),
          limit: 200,
        );

    CountriesRecord? best;
    var bestArea = double.infinity;

    for (final country in list) {
      if (!country.hasBounds()) continue;
      final sw = country.boundsSw!;
      final ne = country.boundsNe!;
      if (!AdminCountryGeoService.pointInBounds(position, sw, ne)) {
        continue;
      }
      final area = (ne.latitude - sw.latitude).abs() *
          (ne.longitude - sw.longitude).abs();
      if (area < bestArea) {
        bestArea = area;
        best = country;
      }
    }
    return best;
  }
}
