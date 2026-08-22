import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/settlement_preview.dart';

FinancialOrderSnapshot snap({
  required String id,
  String method = 'Cash',
  String status = 'completed',
  String payment = 'cash_collected',
  String currency = 'SAR',
  num total = 100,
  num app = 15,
  num vat = 15,
  num? mndob,
  num? mndob2,
  num ksm = 0,
  bool hasMndob = false,
  bool hasMndob2 = false,
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
    ksm: ksm,
    hasTotal: true,
    hasTotalApp: true,
    hasTotalVat: true,
    hasTotalMndob: hasMndob,
    hasTotalMndob2: hasMndob2,
    hasKsm: true,
  );
}

void main() {
  test('totals include all lines beyond 500', () {
    final lines = List.generate(
      600,
      (i) => FinancialAccountingEngine.analyze(snap(id: 'o$i')),
    );
    final by = FinancialAccountingEngine.aggregateByCurrency(lines);
    expect(by['SAR']!.cashCollectedTrips, 600);
    expect(by['SAR']!.cashCustomerCollected.minorUnits, 600 * 10000);
  });

  test('settlement preview cash+online net company pays driver', () {
    final cash = List.generate(
      5,
      (i) => FinancialAccountingEngine.analyze(
        snap(id: 'c$i', total: 400, app: 60, vat: 60),
      ),
    );
    final online = List.generate(
      6,
      (i) => FinancialAccountingEngine.analyze(
        snap(
          id: 'n$i',
          method: 'OnlinePayment',
          payment: 'paid',
          total: 500,
          app: 75,
          vat: 75,
          mndob: 350,
          mndob2: 500,
          hasMndob: true,
          hasMndob2: true,
        ),
      ),
    );
    final preview = SettlementPreview.build(
      driverId: 'd1',
      currency: 'SAR',
      lines: [...cash, ...online],
    );
    expect(preview.cashHeld.majorUnits, 2000);
    expect(preview.cashDriverEntitlement.majorUnits, 1400);
    expect(preview.driverCashLiability.majorUnits, 600);
    expect(preview.companyOnlineLiability.majorUnits, 2100);
    expect(preview.netTripSettlement.majorUnits, -1500);
    expect(preview.direction, 'companyPaysDriver');
  });

  test('incomplete excluded from settlement', () {
    final line = FinancialAccountingEngine.analyze(
      snap(
        id: 'bad',
        total: 700,
        app: 120,
        vat: 120,
        ksm: 100,
        hasMndob: false,
        hasMndob2: false,
      ),
    );
    expect(line.confidence, FinancialConfidence.incomplete);
    expect(line.settlementEligible, isFalse);
    final preview = SettlementPreview.build(
      driverId: 'd',
      currency: 'SAR',
      lines: [line],
    );
    expect(preview.includedCount, 0);
    expect(preview.excludedCount, 1);
  });

  test('mixed currencies stay separate in preview', () {
    final sar = FinancialAccountingEngine.analyze(snap(id: 's'));
    final eur = FinancialAccountingEngine.analyze(
      snap(id: 'e', currency: 'EUR', total: 100, app: 15, vat: 15),
    );
    final pSar = SettlementPreview.build(
      driverId: 'd',
      currency: 'SAR',
      lines: [sar, eur],
    );
    final pEur = SettlementPreview.build(
      driverId: 'd',
      currency: 'EUR',
      lines: [sar, eur],
    );
    expect(pSar.includedCount, 1);
    expect(pEur.includedCount, 1);
    expect(pSar.cashHeld.code, 'SAR');
    expect(pEur.cashHeld.code, 'EUR');
  });
}
