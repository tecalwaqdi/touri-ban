import 'package:flutter_test/flutter_test.dart';

void main() {
  group('geo alias policy', () {
    final isoPrefixedVillage = RegExp(r'^city_[a-z]{2}_', caseSensitive: false);
    final isoPrefixedRegion = RegExp(r'^region_[a-z]{2}_', caseSensitive: false);
    const saudiLegacyVillages = {
      'makkah',
      'mecca',
      'jeddah',
      'riyadh',
      'madinah',
      'medina',
      'dammam',
      'taif',
      'abha',
    };
    const saudiLegacyRegions = {
      'makkah',
      'mecca',
      'jeddah',
      'riyadh',
      'madinah',
      'medina',
      'dammam',
      'taif',
      'abha',
    };

    String canonicalizeVillageId(String id) {
      if (isoPrefixedVillage.hasMatch(id)) return id;
      final legacyCity = RegExp(r'^city_(.+)$').firstMatch(id);
      if (legacyCity != null) {
        final slug = legacyCity.group(1)!.toLowerCase();
        if (!saudiLegacyVillages.contains(slug)) return id;
        return 'city_sa_$slug';
      }
      return id;
    }

    String canonicalizeRegionId(String id) {
      if (isoPrefixedRegion.hasMatch(id) ||
          id.startsWith('kg-') ||
          id.startsWith('uz-') ||
          id.startsWith('ru-')) {
        return id;
      }
      final legacy = RegExp(r'^region_(.+)$').firstMatch(id);
      if (legacy != null) {
        final slug = legacy.group(1)!.toLowerCase();
        if (!saudiLegacyRegions.contains(slug)) return id;
        return 'region_sa_$slug';
      }
      return id;
    }

    test('non-SA city ids must not become city_sa_*', () {
      expect(canonicalizeVillageId('city_makkah'), 'city_sa_makkah');
      expect(canonicalizeVillageId('city_bishkek'), 'city_bishkek');
      expect(canonicalizeVillageId('city_kg_osh'), 'city_kg_osh');
      expect(canonicalizeVillageId('city_sa_jeddah'), 'city_sa_jeddah');
      expect(canonicalizeVillageId('city_es_madrid'), 'city_es_madrid');
      expect(canonicalizeVillageId('city_in_new_delhi'), 'city_in_new_delhi');
      expect(canonicalizeVillageId('city_tm_ashgabat'), 'city_tm_ashgabat');
      expect(canonicalizeVillageId('city_kz_astana'), 'city_kz_astana');
      expect(canonicalizeVillageId('city_ge_tbilisi'), 'city_ge_tbilisi');
      expect(canonicalizeVillageId('city_eg_cairo'), 'city_eg_cairo');
      expect(canonicalizeVillageId('city_tr_istanbul'), 'city_tr_istanbul');
    });

    test('international region ids must not become region_sa_*', () {
      expect(canonicalizeRegionId('region_es_madrid'), 'region_es_madrid');
      expect(canonicalizeRegionId('region_ma_rabat'), 'region_ma_rabat');
      expect(canonicalizeRegionId('region_in_new_delhi'), 'region_in_new_delhi');
      expect(canonicalizeRegionId('region_makkah'), 'region_sa_makkah');
      expect(canonicalizeRegionId('region_kg_osh'), 'region_kg_osh');
      // Six-capitals + Turkey — previously remapped to region_sa_* and hid landmarks.
      expect(canonicalizeRegionId('region_tm_ashgabat'), 'region_tm_ashgabat');
      expect(canonicalizeRegionId('region_kz_astana'), 'region_kz_astana');
      expect(canonicalizeRegionId('region_ge_tbilisi'), 'region_ge_tbilisi');
      expect(canonicalizeRegionId('region_eg_cairo'), 'region_eg_cairo');
      expect(canonicalizeRegionId('region_tr_istanbul'), 'region_tr_istanbul');
      expect(canonicalizeRegionId('region_ru_moscow'), 'region_ru_moscow');
      expect(canonicalizeRegionId('region_uz_tashkent'), 'region_uz_tashkent');
    });
  });
}
