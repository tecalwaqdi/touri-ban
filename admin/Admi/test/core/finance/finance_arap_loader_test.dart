import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/finance_arap_loader.dart';

void main() {
  test('AR/AP settlement lifecycle codes cover required statuses', () {
    final codes = FinanceSettlementLifecycle.values.map((e) => e.code).toSet();
    expect(codes, containsAll({
      'UNSETTLED',
      'DRAFT',
      'LOCKED',
      'PARTIALLY_PAID',
      'SETTLED',
    }));
  });

  test('AR/AP sides are company receivable vs driver payable only', () {
    expect(FinanceArapSide.values, hasLength(2));
    expect(
      FinanceArapSide.values.map((e) => e.name).toSet(),
      containsAll({'companyReceivable', 'driverPayable'}),
    );
  });
}
