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
    });
  });
}
