import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/finance_cash_online_summary.dart';
import 'package:admin_arawatan/core/finance/finance_dq_classifier.dart';
import 'package:admin_arawatan/core/finance/finance_exception_classifier.dart';
import 'package:admin_arawatan/core/finance/finance_sot_settlement_stats.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';
import 'package:admin_arawatan/core/finance/platform_commission_policy.dart';

void main() {
  group('FinanceSotSettlementStatsResult', () {
    test('unavailable is not treated as authoritative zeros for UI', () {
      const r = FinanceSotSettlementStatsResult.unavailable(reason: 'load_failed');
      expect(r.available, isFalse);
      expect(r.unavailableReason, 'load_failed');
      // Counters may be 0 placeholders but available=false is the contract.
      expect(r.outstandingMinor, 0);
      expect(r.paidConfirmedMinor, 0);
    });

    test('available result exposes paidConfirmed separately from outstanding', () {
      const r = FinanceSotSettlementStatsResult(
        available: true,
        settled: 2,
        pending: 1,
        outstandingMinor: 500,
        paidConfirmedMinor: 1500,
        fixturesExcluded: 0,
        docsRead: 3,
      );
      expect(r.paidConfirmedMinor, 1500);
      expect(r.outstandingMinor, 500);
      expect(r.paidConfirmedMinor == r.outstandingMinor, isFalse);
    });
  });

  group('settledCompanyDue vs outstanding', () {
    test('fromTotals subtracts paidConfirmed, not outstanding', () {
      final t = FinancialCurrencyTotals(currency: 'SAR')
        ..cashDriversOweCompany =
            const MoneyAmount(currency: 'SAR', minorUnits: 10000);
      final summary = FinanceCashOnlineSummary.fromTotals(
        t,
        settledCompanyDueMinor: 4000, // confirmed payments
        settlementStatsAvailable: true,
      );
      expect(summary.settledCompanyDueMinor, 4000);
      expect(summary.outstandingCompanyDue.minorUnits, 6000);
    });

    test('unavailable settlement stats does not invent settled offset', () {
      final t = FinancialCurrencyTotals(currency: 'SAR')
        ..cashDriversOweCompany =
            const MoneyAmount(currency: 'SAR', minorUnits: 10000);
      final summary = FinanceCashOnlineSummary.fromTotals(
        t,
        settledCompanyDueMinor: 0,
        settlementStatsAvailable: false,
      );
      expect(summary.settlementStatsAvailable, isFalse);
      expect(summary.outstandingCompanyDue.minorUnits, 10000);
    });
  });

  group('PlatformCommissionPolicy', () {
    test('historical trip before effective date is not flagged', () {
      const line = FinancialOrderLine(
        orderId: 'o1',
        currency: 'SAR',
        channel: FinancialPaymentChannel.cash,
        lifecycle: FinancialLifecycle.completed,
        payment: FinancialPaymentState.cashCollected,
        bucket: FinancialCollectionBucket.completedAndCollected,
        confidence: FinancialConfidence.high,
        currencySupported: true,
        grossBase: MoneyAmount(currency: 'SAR', minorUnits: 10000),
        platformFee: MoneyAmount(currency: 'SAR', minorUnits: 1200), // 12%
        orderedAt: null, // treated as historical / unknown
      );
      // null orderedAt → policy does not apply
      expect(PlatformCommissionPolicy.hasCurrentPolicyMismatch(line), isFalse);
    });

    test('current-policy trip with wrong fee is flagged, not overwritten', () {
      final line = FinancialOrderLine(
        orderId: 'o2',
        currency: 'SAR',
        channel: FinancialPaymentChannel.cash,
        lifecycle: FinancialLifecycle.completed,
        payment: FinancialPaymentState.cashCollected,
        bucket: FinancialCollectionBucket.completedAndCollected,
        confidence: FinancialConfidence.high,
        currencySupported: true,
        grossBase: const MoneyAmount(currency: 'SAR', minorUnits: 10000),
        platformFee: const MoneyAmount(currency: 'SAR', minorUnits: 1000), // 10%
        orderedAt: DateTime.utc(2026, 9, 20),
      );
      expect(PlatformCommissionPolicy.hasCurrentPolicyMismatch(line), isTrue);
      expect(line.platformFee!.minorUnits, 1000); // unchanged
      final hits = FinanceExceptionClassifier.classify(line);
      expect(
        hits.any(
          (h) => h.code == FinanceExceptionCode.platformCommissionRateMismatch,
        ),
        isTrue,
      );
    });

    test('current-policy trip at 15% is not flagged', () {
      final line = FinancialOrderLine(
        orderId: 'o3',
        currency: 'SAR',
        channel: FinancialPaymentChannel.cash,
        lifecycle: FinancialLifecycle.completed,
        payment: FinancialPaymentState.cashCollected,
        bucket: FinancialCollectionBucket.completedAndCollected,
        confidence: FinancialConfidence.high,
        currencySupported: true,
        grossBase: const MoneyAmount(currency: 'SAR', minorUnits: 10000),
        platformFee: const MoneyAmount(currency: 'SAR', minorUnits: 1500),
        orderedAt: DateTime.utc(2026, 9, 20),
      );
      expect(PlatformCommissionPolicy.hasCurrentPolicyMismatch(line), isFalse);
    });
  });

  group('FinanceDqClassifier', () {
    test('maps commission mismatch to warning and missing money to critical', () {
      expect(
        FinanceDqClassifier.severityOf(
          FinanceExceptionCode.platformCommissionRateMismatch,
        ),
        FinanceDqSeverity.warning,
      );
      expect(
        FinanceDqClassifier.severityOf(
          FinanceExceptionCode.completedMissingMoney,
        ),
        FinanceDqSeverity.critical,
      );
    });
  });

  group('missing != 0 presentation contract', () {
    test('expected fee null when gross missing', () {
      expect(
        PlatformCommissionPolicy.expectedPlatformFeeMinor(null),
        isNull,
      );
    });
  });
}
