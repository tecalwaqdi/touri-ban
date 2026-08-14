import 'package:flutter_test/flutter_test.dart';

void main() {
  group('geo alias policy', () {
    test('non-SA city ids must not become city_sa_*', () {
      String canonicalizeVillageId(String id) {
        if (id.startsWith('city_sa_') ||
            id.startsWith('city_kg_') ||
            id.startsWith('city_uz_') ||
            id.startsWith('city_ru_')) {
          return id;
        }
        final legacyCity = RegExp(r'^city_(.+)$').firstMatch(id);
        if (legacyCity != null) {
          final slug = legacyCity.group(1)!.toLowerCase();
          const saudiLegacy = {
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
          if (!saudiLegacy.contains(slug)) return id;
          return 'city_sa_$slug';
        }
        return id;
      }

      expect(canonicalizeVillageId('city_makkah'), 'city_sa_makkah');
      expect(canonicalizeVillageId('city_bishkek'), 'city_bishkek');
      expect(canonicalizeVillageId('city_kg_osh'), 'city_kg_osh');
      expect(canonicalizeVillageId('city_sa_jeddah'), 'city_sa_jeddah');
      expect(canonicalizeVillageId('city_es_madrid'), 'city_es_madrid');
      expect(canonicalizeVillageId('city_in_new_delhi'), 'city_in_new_delhi');
    });

    test('international region ids must not become region_sa_*', () {
      String canonicalizeRegionId(String id) {
        const intlPrefixes = {
          'region_es_',
          'region_ma_',
          'region_pt_',
          'region_tn_',
          'region_id_',
          'region_my_',
          'region_in_',
        };
        if (id.startsWith('region_sa_') ||
            id.startsWith('region_kg_') ||
            id.startsWith('region_uz_') ||
            id.startsWith('region_ru_') ||
            intlPrefixes.any(id.startsWith)) {
          return id;
        }
        final legacy = RegExp(r'^region_(.+)$').firstMatch(id);
        if (legacy != null) {
          final slug = legacy.group(1)!.toLowerCase();
          if (slug.startsWith('kg_') ||
              slug.startsWith('uz_') ||
              slug.startsWith('ru_') ||
              slug.startsWith('sa_') ||
              slug.startsWith('es_') ||
              slug.startsWith('ma_') ||
              slug.startsWith('pt_') ||
              slug.startsWith('tn_') ||
              slug.startsWith('id_') ||
              slug.startsWith('my_') ||
              slug.startsWith('in_')) {
            return id;
          }
          return 'region_sa_$slug';
        }
        return id;
      }

      expect(canonicalizeRegionId('region_es_madrid'), 'region_es_madrid');
      expect(canonicalizeRegionId('region_ma_rabat'), 'region_ma_rabat');
      expect(canonicalizeRegionId('region_in_new_delhi'), 'region_in_new_delhi');
      expect(canonicalizeRegionId('region_makkah'), 'region_sa_makkah');
      expect(canonicalizeRegionId('region_kg_osh'), 'region_kg_osh');
    });
  });
}
