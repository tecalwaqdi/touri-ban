import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/components/admin_firestore_list.dart';

void main() {
  group('adminFirestoreListShouldReset', () {
    test(
      'equivalent parent rebuild (same query/page/reloadKey) does NOT reset',
      () {
        final query = Object();
        expect(
          adminFirestoreListShouldReset(
            oldQuery: query,
            newQuery: query,
            oldPageSize: 25,
            newPageSize: 25,
            oldReloadKey: 'f=all|ps=20|extra=all|all',
            newReloadKey: 'f=all|ps=20|extra=all|all',
          ),
          isFalse,
        );
      },
    );

    test('reloadKey / semantic filter change DOES reset', () {
      final query = Object();
      expect(
        adminFirestoreListShouldReset(
          oldQuery: query,
          newQuery: query,
          oldPageSize: 25,
          newPageSize: 25,
          oldReloadKey: 'f=all',
          newReloadKey: 'f=pending',
        ),
        isTrue,
      );
    });

    test('pageSize change DOES reset', () {
      final q = Object();
      expect(
        adminFirestoreListShouldReset(
          oldQuery: q,
          newQuery: q,
          oldPageSize: 25,
          newPageSize: 50,
          oldReloadKey: null,
          newReloadKey: null,
        ),
        isTrue,
      );
    });

    test('query (collection) identity change DOES reset', () {
      expect(
        adminFirestoreListShouldReset(
          oldQuery: Object(),
          newQuery: Object(),
          oldPageSize: 25,
          newPageSize: 25,
          oldReloadKey: null,
          newReloadKey: null,
        ),
        isTrue,
      );
    });

    test('null → non-null reloadKey DOES reset (explicit refresh key)', () {
      final q = Object();
      expect(
        adminFirestoreListShouldReset(
          oldQuery: q,
          newQuery: q,
          oldPageSize: 20,
          newPageSize: 20,
          oldReloadKey: null,
          newReloadKey: 'refresh-1',
        ),
        isTrue,
      );
    });
  });
}
