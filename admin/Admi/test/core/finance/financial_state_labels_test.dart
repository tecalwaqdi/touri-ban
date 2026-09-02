import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/financial_state_labels.dart';

void main() {
  test('cancelled lifecycle label is Arabic', () {
    expect(
      FinancialStateLabels.lifecycleAr(FinancialLifecycle.cancelled),
      'ملغاة',
    );
  });

  test('pending cash payment label is Arabic', () {
    expect(
      FinancialStateLabels.paymentAr(FinancialPaymentState.pendingCash),
      'بانتظار التحصيل النقدي',
    );
  });

  test('cancelled bucket is not billable in status label', () {
    const line = FinancialOrderLine(
      orderId: 'x',
      currency: 'SAR',
      channel: FinancialPaymentChannel.cash,
      lifecycle: FinancialLifecycle.cancelled,
      payment: FinancialPaymentState.pendingCash,
      bucket: FinancialCollectionBucket.cancelledOrExpired,
      confidence: FinancialConfidence.incomplete,
      currencySupported: true,
      exclusionReason: 'CANCELLED',
    );
    expect(
      FinancialStateLabels.financialStatusAr(line),
      'غير قابل للفوترة',
    );
  });
}
