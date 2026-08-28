import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_geo_cascade.dart';
import 'package:admin_arawatan/backend/admin_landmark_list_filters.dart';
import 'package:admin_arawatan/backend/admin_legacy_alias_filter.dart';
import 'package:admin_arawatan/flutter_flow/lat_lng.dart';

void main() {
  group('AdminLegacyAliasFilter', () {
    test('keeps real Saudi hubs', () {
      expect(AdminLegacyAliasFilter.keepDocumentId('city_sa_makkah'), isTrue);
      expect(AdminLegacyAliasFilter.keepDocumentId('region_sa_riyadh'), isTrue);
      expect(AdminLegacyAliasFilter.keepDocumentId('lm_sa_jeddah_kaia'), isTrue);
    });

    test('excludes intl alias docs', () {
      expect(
        AdminLegacyAliasFilter.isLegacyIntlAliasId('lm_sa_es_madrid_prado'),
        isTrue,
      );
      expect(
        AdminLegacyAliasFilter.keepDocumentId('city_sa_ma_casablanca'),
        isFalse,
      );
    });
  });

  group('AdminGeoCascade', () {
    test('rejects empty name', () {
      expect(
        AdminGeoCascade.validateLandmarkParents(
          name: '  ',
          countryRef: null,
          regionRef: null,
          cityRef: null,
          requireLocation: false,
        ),
        'اسم المعلم مطلوب',
      );
    });

    test('validates lat/lng ranges', () {
      expect(AdminGeoCascade.validateLatLng(null), isNotNull);
      expect(
        AdminGeoCascade.validateLatLng(const LatLng(91, 10)),
        contains('خط العرض'),
      );
      expect(
        AdminGeoCascade.validateLatLng(const LatLng(24.7, 46.6)),
        isNull,
      );
      expect(
        AdminGeoCascade.validateLatLng(const LatLng(0, 0)),
        'الموقع غير محدد',
      );
    });
  });

  group('AdminLandmarkListFilters', () {
    test('imageMissingOnly and status flags', () {
      const f = AdminLandmarkListFilters(
        status: AdminLandmarkStatusFilter.active,
        imageMissingOnly: true,
      );
      expect(f.hasActive, isTrue);
      expect(
        f.copyWith(status: AdminLandmarkStatusFilter.all).status,
        AdminLandmarkStatusFilter.all,
      );
    });
  });
}
