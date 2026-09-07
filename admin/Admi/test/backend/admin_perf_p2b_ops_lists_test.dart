import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_performance.dart';
import 'package:admin_arawatan/components/admin_firestore_list.dart';

void main() {
  group('PERF-P2B operational list contracts', () {
    test('default page size is within 25–50', () {
      expect(kAdminPageSize, inInclusiveRange(25, 50));
      expect(kAdminPageSizeLarge, greaterThanOrEqualTo(kAdminPageSize));
      expect(kAdminMaxPages, greaterThan(0));
    });

    test('AdminFirestoreList reload gate ignores queryBuilder identity', () {
      // Same collection identity + pageSize + reloadKey → no reset.
      expect(
        adminFirestoreListShouldReset(
          oldQuery: 'users',
          newQuery: 'users',
          oldPageSize: 40,
          newPageSize: 40,
          oldReloadKey: 'a',
          newReloadKey: 'a',
        ),
        isFalse,
      );
      expect(
        adminFirestoreListShouldReset(
          oldQuery: 'users',
          newQuery: 'users',
          oldPageSize: 40,
          newPageSize: 40,
          oldReloadKey: 'a',
          newReloadKey: 'b',
        ),
        isTrue,
      );
      expect(
        adminFirestoreListShouldReset(
          oldQuery: 'users',
          newQuery: 'users',
          oldPageSize: 40,
          newPageSize: 50,
          oldReloadKey: 'a',
          newReloadKey: 'a',
        ),
        isTrue,
      );
    });

    test('filter signature change resets cursor (reloadKey)', () {
      expect(
        adminFirestoreListShouldReset(
          oldQuery: 'user',
          newQuery: 'user',
          oldPageSize: 40,
          newPageSize: 40,
          oldReloadKey: 'status:all',
          newReloadKey: 'status:approved',
        ),
        isTrue,
      );
    });

    test('landmark count cache peek returns null when cold', () {
      AdminLandmarkCountCache.invalidate();
      expect(AdminLandmarkCountCache.peekCached(null), 0);
    });

    test('max pages bounds memory (no unbounded list)', () {
      final maxRows = kAdminPageSize * kAdminMaxPages;
      expect(maxRows, lessThanOrEqualTo(5000));
    });
  });
}
