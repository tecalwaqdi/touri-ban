import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/core/finance/admin_finance_ui_labels.dart';
import 'package:admin_arawatan/core/finance/admin_money_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QA fixture id prefixes detected', () {
    expect(AdminQaFixture.isFixtureId('fin7_ctrl_1'), isTrue);
    expect(AdminQaFixture.isFixtureId('fin9_ctrl_1'), isTrue);
    expect(AdminQaFixture.isFixtureId('fin_rt_cash_1'), isTrue);
    expect(AdminQaFixture.isFixtureId('real_order_abc'), isFalse);
  });

  test('explicit metadata wins', () {
    expect(
      AdminQaFixture.isFixtureMap({'is_test_fixture': true}, orderId: 'x'),
      isTrue,
    );
  });

  test('money thousands + map formatter', () {
    expect(
      AdminOrderMoneyDisplay.formatMajor(5000, symbol: 'ر.س'),
      contains('5,000.00'),
    );
    expect(
      AdminFinanceUiLabels.formatMinorByCurrency({'SAR': 750}),
      contains('7.50'),
    );
    expect(AdminFinanceUiLabels.severityAr('high'), 'مرتفعة');
    expect(AdminFinanceUiLabels.settlementStatusAr('draft'), 'مسودة');
  });
}
