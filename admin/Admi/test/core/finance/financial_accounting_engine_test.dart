import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';

FinancialOrderSnapshot _snap({
  String id = 'o1',
  String currency = 'SAR',
  String? method = 'Cash',
  String? status = 'completed',
  String? payment = 'cash_collected',
  num? total,
  num? app,
  num? vat,
  num? mndob,
  num? mndob2,
  num? ksm,
  bool hasMndob = false,
  bool hasMndob2 = false,
  bool hasKsm = true,
}) {
  return FinancialOrderSnapshot(
    orderId: id,
    currency: currency,
    paymentMethodRaw: method,
    statusCode: status,
    paymentStatus: payment,
    total: total,
    totalApp: app,
    totalVat: vat,
    totalMndob: mndob,
    totalMndob2: mndob2,
    ksm: ksm ?? 0,
    hasTotal: total != null,
    hasTotalApp: app != null,
    hasTotalVat: vat != null,
    hasTotalMndob: hasMndob,
    hasTotalMndob2: hasMndob2,
    hasKsm: hasKsm,
  );
}

void main() {
  group('MoneyAmount / CurrencyMoneyPolicy', () {
    test('SAR uses exponent 2', () {
      final m = MoneyAmount.fromMajor('SAR', 800)!;
      expect(m.minorUnits, 80000);
      expect(m.majorUnits, 800);
    });

    test('KWD uses exponent 3', () {
      final m = MoneyAmount.fromMajor('KWD', 1.5)!;
      expect(m.minorUnits, 1500);
    });

    test('unsupported currency', () {
      expect(MoneyAmount.fromMajor('XYZ', 10), isNull);
      expect(CurrencyMoneyPolicy.isSupported('XYZ'), isFalse);
    });

    test('rejects mixing currencies', () {
      final a = MoneyAmount.fromMajor('SAR', 1)!;
      final b = MoneyAmount.fromMajor('EUR', 1)!;
      expect(() => a + b, throwsArgumentError);
    });
  });

  group('Cash accounting', () {
    test('no discount — driver owes 240', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        method: 'Cash',
        payment: 'cash_collected',
        total: 800,
        app: 120,
        vat: 120,
        mndob: 560,
        mndob2: 800,
        ksm: 0,
        hasMndob: true,
        hasMndob2: true,
      ));
      expect(line.confidence, FinancialConfidence.high);
      expect(line.qualifiesCollectedCash, isTrue);
      expect(line.cashHeldByDriver!.majorUnits, 800);
      expect(line.driverNet!.majorUnits, 560);
      expect(line.signedCashPosition!.majorUnits, 240);
    });

    test('company-funded discount — owes 140', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        method: 'Cash',
        payment: 'cash_collected',
        total: 700,
        app: 120,
        vat: 120,
        mndob: 560,
        mndob2: 800,
        ksm: 100,
        hasMndob: true,
        hasMndob2: true,
      ));
      expect(line.cashHeldByDriver!.majorUnits, 700);
      expect(line.driverNet!.majorUnits, 560);
      expect(line.signedCashPosition!.majorUnits, 140);
      expect(line.reconciliationDifference, isNull);
    });

    test('pending_cash not collected', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        method: 'Cash',
        payment: 'pending_cash',
        total: 800,
        app: 120,
        vat: 120,
        mndob: 560,
        hasMndob: true,
      ));
      expect(line.qualifiesCollectedCash, isFalse);
      expect(line.bucket, FinancialCollectionBucket.completedButNotCollected);
    });
  });

  group('Online accounting', () {
    test('no discount — remaining 240', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        method: 'OnlinePayment',
        payment: 'paid',
        total: 800,
        app: 120,
        vat: 120,
        mndob: 560,
        mndob2: 800,
        hasMndob: true,
        hasMndob2: true,
      ));
      expect(line.qualifiesCollectedOnline, isTrue);
      expect(line.onlineHeldByCompany!.majorUnits, 800);
      expect(line.onlineRemainingPosition!.majorUnits, 240);
    });

    test('with discount — remaining 140', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        method: 'OnlinePayment',
        payment: 'paid',
        total: 700,
        app: 120,
        vat: 120,
        mndob: 560,
        mndob2: 800,
        ksm: 100,
        hasMndob: true,
        hasMndob2: true,
      ));
      expect(line.onlineHeldByCompany!.majorUnits, 700);
      expect(line.driverNet!.majorUnits, 560);
      expect(line.onlineRemainingPosition!.majorUnits, 140);
    });

    test('unpaid not collected', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        method: 'OnlinePayment',
        status: 'payment_pending',
        payment: 'unpaid',
        total: 300,
        app: 45,
        vat: 0,
        mndob: 255,
        mndob2: 300,
        hasMndob: true,
        hasMndob2: true,
      ));
      expect(line.qualifiesCollectedOnline, isFalse);
    });
  });

  group('Driver net derivation', () {
    test('missing mndob + ksm=0 → DERIVED from total', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        total: 800,
        app: 120,
        vat: 120,
        ksm: 0,
        hasMndob: false,
      ));
      expect(line.confidence, FinancialConfidence.derived);
      expect(line.driverNet!.majorUnits, 560);
    });

    test('missing mndob + ksm>0 + gross → DERIVED from gross', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        total: 700,
        app: 120,
        vat: 120,
        mndob2: 800,
        ksm: 100,
        hasMndob: false,
        hasMndob2: true,
      ));
      expect(line.confidence, FinancialConfidence.derived);
      expect(line.driverNet!.majorUnits, 560);
    });

    test('missing mndob + ksm>0 + no gross → INCOMPLETE', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        total: 700,
        app: 120,
        vat: 120,
        ksm: 100,
        hasMndob: false,
        hasMndob2: false,
      ));
      expect(line.confidence, FinancialConfidence.incomplete);
      expect(line.driverNet, isNull);
    });
  });

  group('Aggregation', () {
    test('mixed currencies never sum together', () {
      final sar = FinancialAccountingEngine.analyze(_snap(
        id: 's',
        currency: 'SAR',
        total: 800,
        app: 120,
        vat: 120,
        mndob: 560,
        hasMndob: true,
      ));
      final eur = FinancialAccountingEngine.analyze(_snap(
        id: 'e',
        currency: 'EUR',
        total: 100,
        app: 15,
        vat: 15,
        mndob: 70,
        hasMndob: true,
      ));
      final map = FinancialAccountingEngine.aggregateByCurrency([sar, eur]);
      expect(map.keys, containsAll(['SAR', 'EUR']));
      expect(map['SAR']!.cashCustomerCollected.majorUnits, 800);
      expect(map['EUR']!.cashCustomerCollected.majorUnits, 100);
    });

    test('cancelled paid not completed revenue', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        status: 'cancelled_by_customer',
        payment: 'paid',
        method: 'OnlinePayment',
        total: 300,
        app: 45,
        vat: 0,
        mndob: 255,
        hasMndob: true,
      ));
      expect(line.bucket, FinancialCollectionBucket.cancelledOrExpired);
      expect(line.notes, contains('CANCELLED_PAID_REVIEW'));
      expect(line.qualifiesCollectedOnline, isFalse);
    });
  });

  group('Payment normalization', () {
    test('legacy does not override payment_status', () {
      final o = FinancialOrderSnapshot(
        orderId: 'x',
        paymentStatus: 'pending_cash',
        halhOrder: 'Paid',
        statusCode: 'completed',
      );
      expect(
        FinancialAccountingEngine.normalizedPaymentStatus(o),
        FinancialPaymentState.pendingCash,
      );
    });
  });
}
