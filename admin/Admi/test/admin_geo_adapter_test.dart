import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_geo/admin_geo_adapter.dart';
import 'package:admin_arawatan/backend/admin_geo_cascade.dart';
import 'package:admin_arawatan/backend/admin_legacy_alias_filter.dart';

void main() {
  group('AdminGeoContract', () {
    test('collections match production naming', () {
      expect(AdminGeoContract.countryCollection, 'countries');
      expect(AdminGeoContract.regionCollection, 'cities');
      expect(AdminGeoContract.cityCollection, 'villages');
      expect(AdminGeoContract.regionParentField, 'dolh');
      expect(AdminGeoContract.cityRegionParentField, 'cities');
      expect(AdminGeoContract.legacyAliases['country'], contains('Rev_dolh'));
      expect(AdminGeoContract.legacyAliases['city'], contains('vill_text'));
    });
  });

  group('AdminGeoAdapter helpers', () {
    test('displayName falls back to id', () {
      expect(AdminGeoAdapter.displayName('مكة', 'city_sa_makkah'), 'مكة');
      expect(AdminGeoAdapter.displayName('  ', 'city_sa_makkah'), 'city_sa_makkah');
    });

    test('i18nName prefers locale then ar then en', () {
      const names = {'ar': 'السعودية', 'en': 'Saudi Arabia', 'ru': 'Саудовская'};
      expect(AdminGeoAdapter.i18nName(names, 'ru'), 'Саудовская');
      expect(AdminGeoAdapter.i18nName(names, 'ky'), 'السعودية');
      expect(AdminGeoAdapter.i18nName({'en': 'Only'}, 'ar'), 'Only');
    });

    test('integrityCounts empty inputs', () {
      final counts = AdminGeoAdapter.integrityCounts(
        countries: const [],
        regions: const [],
        cities: const [],
      );
      expect(counts['orphanRegions'], 0);
      expect(counts['orphanCities'], 0);
      expect(counts['invalidRelations'], 0);
      expect(counts['duplicateNames'], 0);
      expect(counts['missingAr'], 0);
      expect(counts['missingEn'], 0);
    });
  });

  group('AdminLegacyAliasFilter', () {
    test('keeps saudi hubs and drops intl aliases', () {
      expect(AdminLegacyAliasFilter.keepDocumentId('region_sa_makkah'), isTrue);
      expect(AdminLegacyAliasFilter.keepDocumentId('city_sa_jeddah'), isTrue);
      expect(
        AdminLegacyAliasFilter.isLegacyIntlAliasId('region_sa_es_madrid'),
        isTrue,
      );
    });
  });

  group('AdminGeoCascade parents', () {
    test('region requires country', () {
      expect(
        AdminGeoCascade.validateRegionParents(name: 'x', countryRef: null),
        'يرجى اختيار الدولة',
      );
      expect(
        AdminGeoCascade.validateRegionParents(name: '', countryRef: null),
        'اسم المنطقة مطلوب',
      );
    });

    test('city requires country then region', () {
      expect(
        AdminGeoCascade.validateCityParents(
          name: 'جدة',
          countryRef: null,
          regionRef: null,
        ),
        'يرجى اختيار الدولة',
      );
    });
  });
}
