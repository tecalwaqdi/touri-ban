import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_ops_filters.dart';
import 'package:admin_arawatan/core/finance/admin_finance_date_range.dart';
import 'package:admin_arawatan/core/finance/finance_comparable_kpis.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';
import 'package:admin_arawatan/core/finance/csv_export.dart';

void main() {
  group('AdminFinanceRiyadhClock', () {
    test('Sep 1 00:00 Riyadh = Aug 31 21:00 UTC', () {
      final utc = AdminFinanceRiyadhClock.midnightUtc(2026, 9, 1);
      expect(utc, DateTime.utc(2026, 8, 31, 21));
    });

    test('00:01 Riyadh belongs to Sep 1', () {
      // 2026-08-31 21:01 UTC = Sep 1 00:01 Riyadh
      final instant = DateTime.utc(2026, 8, 31, 21, 1);
      final dayStart = AdminFinanceRiyadhClock.startOfDayUtc(instant);
      expect(dayStart, DateTime.utc(2026, 8, 31, 21));
      final p = AdminFinanceRiyadhClock.parts(instant);
      expect(p.day, 1);
      expect(p.month, 9);
    });

    test('23:59 Riyadh still Sep 1', () {
      // Sep 1 23:59 Riyadh = Sep 1 20:59 UTC
      final instant = DateTime.utc(2026, 9, 1, 20, 59);
      final p = AdminFinanceRiyadhClock.parts(instant);
      expect(p.day, 1);
      expect(p.month, 9);
      final next = AdminFinanceRiyadhClock.midnightUtc(2026, 9, 2);
      expect(instant.isBefore(next), isTrue);
    });
  });

  group('AdminFinanceDateRangeResolver', () {
    // Fixed "now": 2026-09-01 12:00 Riyadh = 2026-09-01 09:00 UTC
    final now = DateTime.utc(2026, 9, 1, 9);

    test('today Riyadh', () {
      final r = AdminFinanceDateRangeResolver.resolve(
        preset: AdminDatePreset.today,
        now: now,
      )!;
      expect(r.queryStartUtc, DateTime.utc(2026, 8, 31, 21));
      // End = now (not end-of-day / not device-local).
      expect(r.queryEndUtcExclusive, now);
      expect(r.displayLabelAr, 'اليوم');
    });

    test('yesterday half-open', () {
      final r = AdminFinanceDateRangeResolver.resolve(
        preset: AdminDatePreset.yesterday,
        now: now,
      )!;
      expect(r.queryStartUtc, DateTime.utc(2026, 8, 30, 21));
      expect(r.queryEndUtcExclusive, DateTime.utc(2026, 8, 31, 21));
    });

    test('this month Riyadh', () {
      final r = AdminFinanceDateRangeResolver.resolve(
        preset: AdminDatePreset.thisMonth,
        now: now,
      )!;
      expect(r.queryStartUtc, DateTime.utc(2026, 8, 31, 21));
      expect(r.queryEndUtcExclusive, DateTime.utc(2026, 9, 30, 21));
      expect(r.displayLabelAr, 'هذا الشهر');
    });

    test('last 30 days distinct from this month', () {
      final month = AdminFinanceDateRangeResolver.resolve(
        preset: AdminDatePreset.thisMonth,
        now: now,
      )!;
      final d30 = AdminFinanceDateRangeResolver.resolve(
        preset: AdminDatePreset.last30Days,
        now: now,
      )!;
      expect(d30.displayLabelAr, 'آخر 30 يومًا');
      expect(d30.queryStartUtc, isNot(month.queryStartUtc));
    });

    test('custom Aug 1–31 → Sep 1 exclusive Riyadh', () {
      final r = AdminFinanceDateRangeResolver.resolve(
        preset: AdminDatePreset.custom,
        customStart: DateTime(2026, 8, 1),
        customEnd: DateTime(2026, 8, 31),
        now: now,
      )!;
      expect(r.queryStartUtc, DateTime.utc(2026, 7, 31, 21));
      expect(r.queryEndUtcExclusive, DateTime.utc(2026, 8, 31, 21));
    });

    test('invalid custom from > to', () {
      expect(
        AdminFinanceDateRangeResolver.isInvalidCustom(
          customStart: DateTime(2026, 9, 10),
          customEnd: DateTime(2026, 9, 1),
        ),
        isTrue,
      );
      expect(
        AdminFinanceDateRangeResolver.resolve(
          preset: AdminDatePreset.custom,
          customStart: DateTime(2026, 9, 10),
          customEnd: DateTime(2026, 9, 1),
          now: now,
        ),
        isNull,
      );
    });
  });

  group('AdminDateRangeResolver delegates to Riyadh', () {
    final now = DateTime.utc(2026, 9, 1, 9);

    test('today matches finance resolver', () {
      final ops = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.today,
        now: now,
      )!;
      final fin = AdminFinanceDateRangeResolver.resolve(
        preset: AdminDatePreset.today,
        now: now,
      )!;
      expect(ops.startInclusive, fin.queryStartUtc);
      expect(ops.endExclusive, fin.queryEndUtcExclusive);
    });
  });

  group('FinanceComparableKpis', () {
    test('hub equals report within tolerance', () {
      final t = FinancialCurrencyTotals(currency: 'SAR')
        ..customerPaidAll = const MoneyAmount(currency: 'SAR', minorUnits: 5000)
        ..platformFeeAll = const MoneyAmount(currency: 'SAR', minorUnits: 750)
        ..recordedVatAll = const MoneyAmount(currency: 'SAR', minorUnits: 0)
        ..driverEntitlementAll =
            const MoneyAmount(currency: 'SAR', minorUnits: 4250)
        ..cashDriversOweCompany =
            const MoneyAmount(currency: 'SAR', minorUnits: 0)
        ..completedAndCollected = 0
        ..completedButNotCollected = 1;
      final a = FinanceComparableKpis.fromCurrencyTotals(
        t,
        totalsSource: 'server_v2',
      );
      final b = FinanceComparableKpis.fromCurrencyTotals(
        t,
        totalsSource: 'server_v2',
      );
      expect(a.equalsWithinTolerance(b), isTrue);
      expect(a.deltasVs(b).values.every((d) => d == 0), isTrue);
    });
  });

  group('CSV Riyadh stamp', () {
    test('document uses Riyadh generated line', () {
      final csv = financeCsvDocument(
        preparedBy: 'tester',
        filters: 'هذا الشهر',
        currency: 'SAR',
        body: 'a,b\n1,2',
        generatedAtUtc: DateTime.utc(2026, 8, 31, 21, 30),
      );
      expect(csv.contains('تم الإنشاء (الرياض)'), isTrue);
      expect(csv.contains('01/09/2026'), isTrue);
      expect(csv.contains('Z'), isFalse);
    });
  });

  group('Cancelled exclusion invariant', () {
    test('cancelled line not in collected economics', () {
      const snap = FinancialOrderSnapshot(
        orderId: 'poison',
        currency: 'SAR',
        paymentMethodRaw: 'Cash',
        statusCode: 'cancelled_by_driver',
        paymentStatus: 'pending_cash',
        total: 50,
        totalApp: 7.5,
        totalVat: 0,
        totalMndob: 43,
        totalMndob2: 42.5,
        hasTotal: true,
        hasTotalApp: true,
        hasTotalVat: true,
        hasTotalMndob: true,
        hasTotalMndob2: true,
      );
      final line = FinancialAccountingEngine.analyze(snap);
      final totals =
          FinancialAccountingEngine.aggregateByCurrency([line])['SAR']!;
      expect(line.settlementEligible, isFalse);
      expect(totals.platformFeeAll.minorUnits, 0);
      expect(totals.cancelledOrExpired, 1);
    });
  });
}
