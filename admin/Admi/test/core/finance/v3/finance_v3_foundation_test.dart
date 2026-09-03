import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/v3/financial_engine_version.dart';
import 'package:admin_arawatan/core/finance/v3/financial_truth_terms.dart';
import 'package:admin_arawatan/core/finance/v3/trip_financial_snapshot.dart';

void main() {
  group('FinancialTruthTerms', () {
    test('never labels GMV as revenue', () {
      expect(FinancialTruthTerms.labelEn(FinancialTruthTerms.gmv), isNot(contains('Revenue')));
      expect(
        FinancialTruthTerms.labelAr(FinancialTruthTerms.netPlatformRevenue),
        contains('إيراد'),
      );
    });

    test('unavailable metric is fake-zero risk', () {
      const m = FinancialMetricValue.unavailable(
        metricId: FinancialTruthTerms.gmv,
        source: 'server_v2',
      );
      expect(m.isFakeZeroRisk, isTrue);
      expect(m.byCurrencyMinor, isEmpty);
    });
  });

  group('TripFinancialSnapshot', () {
    test('round-trip map parse', () {
      final snap = TripFinancialSnapshot(
        schemaVersion: 1,
        generatedAt: DateTime.utc(2026, 9, 1),
        orderId: 'ord1',
        currency: 'SAR',
        customerTotalMinor: 5000,
        platformCommissionMinor: 750,
        vatMinor: 0,
        driverNetMinor: 4250,
        confidence: 'high',
        source: 'server_test',
        agentAttributionStatus: AgentAttributionStatusV3.attributed,
      );
      final parsed = TripFinancialSnapshot.tryParse(snap.toMap());
      expect(parsed, isNotNull);
      expect(parsed!.customerTotalMinor, 5000);
      expect(parsed.platformCommissionMinor, 750);
      expect(parsed.driverNetMinor, 4250);
      expect(parsed.validateSoftBalance(), isNull);
    });

    test('rejects incomplete map', () {
      expect(TripFinancialSnapshot.tryParse({'currency': 'SAR'}), isNull);
    });

    test('soft mismatch detected', () {
      final snap = TripFinancialSnapshot(
        schemaVersion: 1,
        generatedAt: DateTime.utc(2026, 9, 1),
        orderId: 'ord2',
        currency: 'SAR',
        customerTotalMinor: 10000,
        platformCommissionMinor: 100,
        vatMinor: 0,
        driverNetMinor: 100,
        confidence: 'derived',
        source: 'test',
      );
      expect(snap.validateSoftBalance(), 'SOFT_BREAKDOWN_MISMATCH');
    });
  });

  group('FinancialEngineVersion', () {
    test('defaults and snapshot prefer', () {
      expect(FinancialEngineVersion.productionDefault, 'v2');
      expect(FinancialEngineVersion.preferSnapshotWhenPresent('v3'), isTrue);
      expect(FinancialEngineVersion.preferSnapshotWhenPresent('v2'), isFalse);
    });
  });
}
