import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_finance_route_trace.dart';

void main() {
  setUp(() {
    AdminFinanceRouteTrace.enabled = true;
  });

  test('PERF-P4B single clock marks are monotonic', () {
    AdminFinanceRouteTrace.begin('test_route');
    AdminFinanceRouteTrace.mark('QUERY_START');
    AdminFinanceRouteTrace.mark('FIRESTORE_FIRST_SNAPSHOT');
    AdminFinanceRouteTrace.mark('MODEL_BUILD_END');
    AdminFinanceRouteTrace.mark('STATE_EMIT');

    final q = AdminFinanceRouteTrace.ms('QUERY_START')!;
    final s = AdminFinanceRouteTrace.ms('FIRESTORE_FIRST_SNAPSHOT')!;
    final m = AdminFinanceRouteTrace.ms('MODEL_BUILD_END')!;
    final st = AdminFinanceRouteTrace.ms('STATE_EMIT')!;
    expect(q, lessThanOrEqualTo(s));
    expect(s, lessThanOrEqualTo(m));
    expect(m, lessThanOrEqualTo(st));
    expect(AdminFinanceRouteTrace.delta('ROUTE_ENTER', 'STATE_EMIT'), isNotNull);
  });

  test('PERF-P4B snapshot exposes deltas map', () {
    AdminFinanceRouteTrace.begin('hub');
    AdminFinanceRouteTrace.mark('QUERY_START');
    final snap = AdminFinanceRouteTrace.snapshot();
    expect(snap['traceId'], isNotNull);
    expect(snap['deltas'], isA<Map>());
  });
}
