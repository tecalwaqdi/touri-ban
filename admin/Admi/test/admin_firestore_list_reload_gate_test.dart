import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/components/admin_firestore_list.dart';

void main() {
  test('parent rebuild recreating countQueryBuilder does not force reload', () {
    final query = Object();
    expect(
      adminFirestoreListShouldReset(
        oldQuery: query,
        newQuery: query,
        oldPageSize: 25,
        newPageSize: 25,
        oldReloadKey: 'f=all',
        newReloadKey: 'f=all',
      ),
      isFalse,
    );
  });

  test('reloadKey change still forces reload', () {
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

  test('query or pageSize change forces reload', () {
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
}
