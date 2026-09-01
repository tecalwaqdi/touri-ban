import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_cache_policy.dart';
import 'package:admin_arawatan/backend/admin_ops_counters.dart';
import 'package:admin_arawatan/backend/admin_ops_filters.dart';
import 'package:admin_arawatan/backend/admin_ops_search.dart';

void main() {
  group('AdminOpsCounters driversUnknown', () {
    test('Active + Inactive + Unknown = Total', () {
      expect(
        AdminOpsCounters.driversUnknown(
          totalDrivers: 327,
          active: 244,
          inactive: 2,
        ),
        81,
      );
    });
  });

  group('AdminDateRangeResolver Asia/Riyadh', () {
    // 12:00 Riyadh on 22 Aug 2026 = 09:00 UTC
    final now = DateTime.utc(2026, 8, 22, 9);

    test('today Riyadh day', () {
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.today,
        now: now,
      )!;
      expect(range.startInclusive, DateTime.utc(2026, 8, 21, 21));
      // Today ends at now (half-open), not end-of-Riyadh-day.
      expect(range.endExclusive, now);
    });

    test('yesterday Riyadh day', () {
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.yesterday,
        now: now,
      )!;
      expect(range.startInclusive, DateTime.utc(2026, 8, 20, 21));
      expect(range.endExclusive, DateTime.utc(2026, 8, 21, 21));
    });

    test('custom Riyadh days', () {
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.custom,
        customStart: DateTime(2026, 8, 1),
        customEnd: DateTime(2026, 8, 3),
        now: now,
      )!;
      expect(range.startInclusive, DateTime.utc(2026, 7, 31, 21));
      expect(range.endExclusive, DateTime.utc(2026, 8, 3, 21));
    });
  });

  group('AdminOpsSearch', () {
    test('email → exactContact', () {
      final p = AdminOpsSearch.classify('a@b.com');
      expect(p.mode, AdminSearchMode.exactContact);
      expect(p.isServerSide, isTrue);
    });

    test('phone → exactContact', () {
      final p = AdminOpsSearch.classify('+966501234567');
      expect(p.mode, AdminSearchMode.exactContact);
    });

    test('id → exactId', () {
      final p = AdminOpsSearch.classify('abc123XYZ');
      expect(p.mode, AdminSearchMode.exactId);
    });

    test('name → loadedPageName', () {
      final p = AdminOpsSearch.classify('محمد علي');
      expect(p.mode, AdminSearchMode.loadedPageName);
      expect(p.isLoadedPageOnly, isTrue);
    });
  });

  group('AdminTimezonePolicy', () {
    test('documents Asia/Riyadh accounting', () {
      expect(AdminTimezonePolicy.policyId, 'ASIA_RIYADH_ACCOUNTING');
    });
  });
}
