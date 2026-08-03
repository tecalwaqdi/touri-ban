import '/backend/admin_country_geo_service.dart';
import '/backend/backend.dart';

/// نتيجة تعبئة الحدود الجغرافية للدول.
class CountryBoundsBackfillResult {
  const CountryBoundsBackfillResult({
    required this.updated,
    required this.skipped,
    this.error,
  });

  final int updated;
  final int skipped;
  final String? error;

  bool get success => error == null;
}

/// يجلب ويحفظ bounds_sw / bounds_ne للدول التي تفتقدها.
abstract final class AdminCountryBoundsBackfill {
  AdminCountryBoundsBackfill._();

  static Future<CountryBoundsBackfillResult> run({
    int limit = 200,
    void Function(String message)? onProgress,
  }) async {
    try {
      final countries = await queryCountriesRecordOnce(
        queryBuilder: (q) => q.orderBy('naim'),
        limit: limit,
      );

      var updated = 0;
      var skipped = 0;

      for (final country in countries) {
        if (country.hasBounds()) {
          skipped++;
          continue;
        }

        final iso = country.isoCode.trim();
        AdminCountryGeoData? geo;
        if (iso.length == 2) {
          geo = await AdminCountryGeoService.fetchForIsoCode(iso);
        }
        geo ??= await AdminCountryGeoService.fetchForCountryName(country.naim);

        if (geo == null || !geo.hasBounds) {
          skipped++;
          onProgress?.call('تخطّي ${country.naim} — لا توجد حدود');
          continue;
        }

        final fields = AdminCountryGeoService.geoFieldsForFirestore(geo);
        await country.reference.set(fields, SetOptions(merge: true));
        updated++;
        onProgress?.call('تم: ${country.naim}');
      }

      return CountryBoundsBackfillResult(updated: updated, skipped: skipped);
    } catch (e) {
      return CountryBoundsBackfillResult(
        updated: 0,
        skipped: 0,
        error: e.toString(),
      );
    }
  }
}
