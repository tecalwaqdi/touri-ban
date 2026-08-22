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

  group('AdminDateRangeResolver UTC', () {
    final now = DateTime.utc(2026, 8, 22, 12);

    test('today UTC day', () {
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.today,
        now: now,
      )!;
      expect(range.startInclusive, DateTime.utc(2026, 8, 22));
      expect(range.endExclusive, DateTime.utc(2026, 8, 23));
    });

    test('yesterday UTC day', () {
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.yesterday,
        now: now,
      )!;
      expect(range.startInclusive, DateTime.utc(2026, 8, 21));
      expect(range.endExclusive, DateTime.utc(2026, 8, 22));
    });

    test('custom UTC days', () {
      final range = AdminDateRangeResolver.resolve(
        preset: AdminDatePreset.custom,
        customStart: DateTime(2026, 8, 1),
        customEnd: DateTime(2026, 8, 3),
        now: now,
      )!;
      expect(range.startInclusive, DateTime.utc(2026, 8, 1));
      expect(range.endExclusive, DateTime.utc(2026, 8, 4));
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
    test('documents UTC until country tz', () {
      expect(AdminTimezonePolicy.policyId, 'UTC_UNTIL_COUNTRY_TZ');
    });
  });
}
