import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/settlement_exposure.dart';

void main() {
  test('aging buckets', () {
    final now = DateTime.utc(2026, 8, 22);
    expect(
      SettlementExposureBucket.agingBucket(DateTime.utc(2026, 8, 20), now),
      '0-7',
    );
    expect(
      SettlementExposureBucket.agingBucket(DateTime.utc(2026, 8, 1), now),
      '8-30',
    );
    expect(
      SettlementExposureBucket.agingBucket(DateTime.utc(2026, 6, 1), now),
      '61-90',
    );
    expect(
      SettlementExposureBucket.agingBucket(DateTime.utc(2026, 1, 1), now),
      '>90',
    );
  });
}
