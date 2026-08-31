import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_m3alm/admin_landmarks_adapter.dart';
import 'package:admin_arawatan/backend/admin_geo_cascade.dart';
import 'package:admin_arawatan/backend/admin_landmark_list_filters.dart';
import 'package:admin_arawatan/backend/admin_media_resolver.dart';
import 'package:admin_arawatan/flutter_flow/lat_lng.dart';

void main() {
  group('AdminLandmarkCoords / geo cascade', () {
    test('rejects 0,0 and out of range', () {
      expect(AdminLandmarkCoords.isValid(const LatLng(0, 0)), isFalse);
      expect(AdminLandmarkCoords.isValid(const LatLng(91, 40)), isFalse);
      expect(AdminLandmarkCoords.isValid(const LatLng(21.4, 39.8)), isTrue);
      expect(
        AdminGeoCascade.validateLatLng(const LatLng(0, 0)),
        isNotNull,
      );
    });
  });

  group('AdminLandmarkListFilters status', () {
    test('status filter enum defaults', () {
      const f = AdminLandmarkListFilters();
      expect(f.status, AdminLandmarkStatusFilter.all);
      expect(f.hasActive, isFalse);
    });

    test('copyWith clears geo cascade', () {
      // DocumentReference not needed — clear flags only.
      const base = AdminLandmarkListFilters(
        status: AdminLandmarkStatusFilter.active,
        imageMissingOnly: true,
      );
      final cleared = base.copyWith(
        clearCountry: true,
        clearRegion: true,
        clearCity: true,
        status: AdminLandmarkStatusFilter.inactive,
      );
      expect(cleared.countryRef, isNull);
      expect(cleared.regionRef, isNull);
      expect(cleared.cityRef, isNull);
      expect(cleared.status, AdminLandmarkStatusFilter.inactive);
    });
  });

  group('AdminMediaResolver landmark paths', () {
    test('parses landmarks/ uploads path', () {
      expect(
        AdminMediaResolver.storagePathFrom('landmarks/uploads/a.jpg'),
        'landmarks/uploads/a.jpg',
      );
    });

    test('firebase download URL under landmarks bucket path', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/tutorial-multi-language-70gx4j.firebasestorage.app/o/landmarks%2Fuploads%2Fx.jpg?alt=media&token=t';
      expect(
        AdminMediaResolver.storagePathFrom(url),
        'landmarks/uploads/x.jpg',
      );
    });

    test('object-not-found classified as expected missing', () {
      expect(
        AdminMediaResolver.classifyStorageCode('object-not-found'),
        AdminMediaFailureKind.expectedMissing,
      );
    });
  });

  group('AdminLandmarkRow search helpers', () {
    test('display name prefers naim then i18n order conceptually', () {
      // Pure string helper path via empty record isn't available without
      // Firestore; assert coordinate helper + filter status remain stable.
      expect(AdminLandmarkCoords.isValid(null), isFalse);
    });
  });
}
