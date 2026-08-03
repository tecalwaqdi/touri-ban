import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_country_registry.dart';
import 'package:ara_oatan_app/flutter_flow/lat_lng.dart';

void main() {
  group('TouryCountryRegistry.normalizeIso', () {
    test('maps Kyrgyz aliases to KG', () {
      expect(TouryCountryRegistry.normalizeIso('KG'), 'KG');
      expect(TouryCountryRegistry.normalizeIso('Kyrgyzstan'), 'KG');
      expect(TouryCountryRegistry.normalizeIso('Kyrgyz Republic'), 'KG');
      expect(TouryCountryRegistry.normalizeIso('Кыргызстан'), 'KG');
      expect(TouryCountryRegistry.normalizeIso('Киргизия'), 'KG');
      expect(TouryCountryRegistry.normalizeIso('قيرغيزستان'), 'KG');
      expect(TouryCountryRegistry.normalizeIso('country_kg'), 'KG');
      expect(TouryCountryRegistry.normalizeIso('kyrgyzstan'), 'KG');
    });

    test('maps Saudi aliases to SA', () {
      expect(TouryCountryRegistry.normalizeIso('SA'), 'SA');
      expect(TouryCountryRegistry.normalizeIso('Saudi Arabia'), 'SA');
      expect(TouryCountryRegistry.normalizeIso('Kingdom of Saudi Arabia'), 'SA');
      expect(TouryCountryRegistry.normalizeIso('KSA'), 'SA');
      expect(TouryCountryRegistry.normalizeIso('السعودية'), 'SA');
      expect(TouryCountryRegistry.normalizeIso('المملكة العربية السعودية'), 'SA');
      expect(TouryCountryRegistry.normalizeIso('country_sa'), 'SA');
      expect(TouryCountryRegistry.normalizeIso('saudi_arabia'), 'SA');
    });

    test('maps RU and UZ', () {
      expect(TouryCountryRegistry.normalizeIso('Russia'), 'RU');
      expect(TouryCountryRegistry.normalizeIso('Россия'), 'RU');
      expect(TouryCountryRegistry.normalizeIso('Uzbekistan'), 'UZ');
      expect(TouryCountryRegistry.normalizeIso('Узбекистан'), 'UZ');
    });
  });

  group('TouryCountryRegistry coordinates', () {
    test('detects Bishkek as KG', () {
      const bishkek = LatLng(42.8746, 74.5698);
      expect(TouryCountryRegistry.isoFromCoordinates(bishkek), 'KG');
      expect(
        TouryCountryRegistry.mapCenterForIso('KG')!.latitude,
        closeTo(41.2044, 0.01),
      );
    });

    test('detects Makkah as SA not as global default for others', () {
      const makkah = LatLng(21.4225, 39.8262);
      expect(TouryCountryRegistry.isoFromCoordinates(makkah), 'SA');
      expect(
        TouryCountryRegistry.mapCenterForIso('KG')!.latitude,
        isNot(closeTo(21.4225, 0.5)),
      );
    });

    test('detects Riyadh as SA', () {
      const riyadh = LatLng(24.7136, 46.6753);
      expect(TouryCountryRegistry.isoFromCoordinates(riyadh), 'SA');
    });
  });

  group('region country aliases', () {
    test('country_kg and kyrgyzstan share alias set', () {
      final a = TouryCountryRegistry.aliasDocIdsForCountryId('country_kg');
      final b = TouryCountryRegistry.aliasDocIdsForCountryId('kyrgyzstan');
      expect(a.contains('kyrgyzstan'), isTrue);
      expect(a.contains('country_kg'), isTrue);
      expect(b.contains('country_kg'), isTrue);
      expect(a.intersection(b).length, greaterThanOrEqualTo(2));
    });

    test('saudi aliases cover both hyphen and underscore ids', () {
      final a = TouryCountryRegistry.aliasDocIdsForIso('SA');
      expect(a.contains('saudi_arabia'), isTrue);
      expect(a.contains('saudi-arabia'), isTrue);
      expect(a.contains('country_sa'), isTrue);
    });
  });
}
