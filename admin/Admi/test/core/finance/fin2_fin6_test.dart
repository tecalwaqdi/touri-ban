import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/finance_agent_attribution.dart';
import 'package:admin_arawatan/core/finance/finance_company_snapshot.dart';
import 'package:admin_arawatan/core/finance/finance_exception_classifier.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/financial_state_labels.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';

FinancialOrderSnapshot _snap({
  String id = 'o1',
  String? method = 'Cash',
  String? status = 'completed',
  String? payment = 'pending_cash',
  num? total = 50,
  num? app = 7.5,
  num? vat = 0,
  num? mndob = 42.5,
  bool hasMndob = true,
}) {
  return FinancialOrderSnapshot(
    orderId: id,
    currency: 'SAR',
    paymentMethodRaw: method,
    statusCode: status,
    paymentStatus: payment,
    total: total,
    totalApp: app,
    totalVat: vat,
    totalMndob: mndob,
    totalMndob2: total,
    ksm: 0,
    hasTotal: total != null,
    hasTotalApp: app != null,
    hasTotalVat: vat != null,
    hasTotalMndob: hasMndob,
    hasTotalMndob2: true,
    hasKsm: true,
  );
}

void main() {
  group('FIN-2 sales vs realization', () {
    test('50 SAR pending cash — realized 0, uncollected 50', () {
      final line = FinancialAccountingEngine.analyze(_snap());
      expect(line.bucket, FinancialCollectionBucket.completedButNotCollected);
      final totals =
          FinancialAccountingEngine.aggregateByCurrency([line])['SAR']!;
      expect(totals.completedButNotCollected, 1);
      expect(totals.completedButNotCollectedMinor.majorUnits, 50);
      expect(totals.customerPaidAll.majorUnits, 0);
      expect(totals.expectedPlatformAfterCollection.majorUnits, 7.5);
    });

    test('50 SAR collected — realized 50', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        payment: 'cash_collected',
      ));
      final totals =
          FinancialAccountingEngine.aggregateByCurrency([line])['SAR']!;
      expect(totals.completedAndCollected, 1);
      expect(totals.customerPaidAll.majorUnits, 50);
      expect(totals.platformFeeAll.majorUnits, 7.5);
      expect(totals.driverEntitlementAll.majorUnits, 42.5);
    });
  });

  group('FIN-5 cancelled stale pending', () {
    test('cancelled + pending_cash is not billable', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        status: 'cancelled',
        payment: 'pending_cash',
      ));
      expect(line.bucket, FinancialCollectionBucket.cancelledOrExpired);
      expect(
        FinancialStateLabels.financialStatusAr(line),
        'غير قابل للفوترة',
      );
      final hits = FinanceExceptionClassifier.classify(line);
      expect(
        hits.any(
          (h) =>
              h.code == FinanceExceptionCode.cancelledWithStalePendingCash,
        ),
        isTrue,
      );
    });
  });

  group('FIN-6 exceptions', () {
    test('incomplete completed flags missing money', () {
      final line = FinancialAccountingEngine.analyze(_snap(
        total: null,
        app: null,
        vat: null,
        mndob: null,
        hasMndob: false,
      ));
      final hits = FinanceExceptionClassifier.classify(line);
      expect(
        hits.any((h) => h.code == FinanceExceptionCode.completedMissingMoney),
        isTrue,
      );
    });
  });

  group('FIN-4 agent contract', () {
    test('historical per-order snapshot not supported', () {
      expect(
        AgentAttributionContract.canonical.historicalPerOrderSnapshotSupported,
        isFalse,
      );
      expect(
        AgentAttributionContract.canonical.scope,
        AgentAttributionScope.countryScopeOnly,
      );
    });
  });

  group('Money precision', () {
    test('0.01 SAR minor units', () {
      final m = MoneyAmount.fromMajor('SAR', 0.01)!;
      expect(m.minorUnits, 1);
    });
  });
}
