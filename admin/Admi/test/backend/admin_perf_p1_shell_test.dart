import 'package:admin_arawatan/backend/admin_perf_trace.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/backend/admin_settlements_query.dart';
import 'package:admin_arawatan/backend/admin_stats_coordinator.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/core/country/country_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AdminRoleService.resetSession();
    AdminPerfTrace.enabled = true;
    AdminPerfTrace.resetCounters();
    AdminStatsCoordinator.instance.stopLiveSync();
  });

  tearDown(() {
    AdminStatsCoordinator.instance.stopLiveSync();
    AdminRoleService.resetSession();
    AdminPerfTrace.resetCounters();
  });

  group('PERF-P1 accountant shell trim', () {
    test('accountant does not want operational live sync or hub badges', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
      expect(AdminRoleService.isAccountant, isTrue);
      expect(AdminRoleService.wantsOperationalLiveSync, isFalse);
      expect(AdminRoleService.wantsFinanceHubAttentionBadges, isFalse);
    });

    test('startLiveSync is a no-op for accountant', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
      AdminStatsCoordinator.instance.startLiveSync();
      expect(AdminPerfTrace.liveOrderListenerStarts, 0);
    });

    test('super admin still wants live sync + finance hub badges', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'super_admin': true}),
      );
      expect(AdminRoleService.wantsOperationalLiveSync, isTrue);
      expect(AdminRoleService.wantsFinanceHubAttentionBadges, isTrue);
    });

    test('country agent wants live sync + finance hub badges', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'agent': true,
          'country_admin': true,
          'country_id': 'countries/spain',
        }),
      );
      expect(AdminRoleService.wantsOperationalLiveSync, isTrue);
      expect(AdminRoleService.wantsFinanceHubAttentionBadges, isTrue);
    });
  });

  group('PERF-P1 settlements stream owner', () {
    test('query key ignores client-side status chips', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
      final a = AdminSettlementsQuery.keyForCurrentUser();
      final b = AdminSettlementsQuery.keyForCurrentUser();
      expect(a, b);
      expect(a, contains('financial_settlements'));
      expect(a, contains('limit=40'));
      expect(a, contains('orderBy=createdAtDesc'));
      expect(a, isNot(contains('status=')));
    });

    test('country agent key includes countryId scope', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'agent': true,
          'country_admin': true,
          'country_id': 'countries/spain',
        }),
      );
      final key = AdminSettlementsQuery.keyForCurrentUser();
      expect(key, contains('countryId=countries/spain'));
    });

    test('same-key streamForCurrentUser reuses stream instance', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
      var factoryCalls = 0;
      final owner = AdminSettlementsStreamOwner(
        keyFactory: () => 'settlements|test|limit=200',
        streamFactory: (key) {
          factoryCalls++;
          AdminPerfTrace.settlementStreamCreate(key);
          return const Stream.empty();
        },
      );
      final s1 = owner.streamForCurrentUser();
      final s2 = owner.streamForCurrentUser();
      expect(identical(s1, s2), isTrue);
      expect(factoryCalls, 1);
      expect(AdminPerfTrace.settlementStreamCreates, 1);
      owner.dispose();
      expect(AdminPerfTrace.settlementStreamDisposes, 1);
      expect(AdminPerfTrace.settlementStreamBalance, 0);
    });

    test('key change replaces stream exactly once', () {
      var key = 'settlements|a|limit=200';
      final owner = AdminSettlementsStreamOwner(
        keyFactory: () => key,
        streamFactory: (k) {
          AdminPerfTrace.settlementStreamCreate(k);
          return const Stream.empty();
        },
      );
      owner.streamForCurrentUser();
      key = 'settlements|b|limit=200';
      owner.streamForCurrentUser();
      expect(AdminPerfTrace.settlementStreamCreates, 2);
      expect(AdminPerfTrace.settlementStreamDisposes, 1);
      owner.dispose();
      expect(AdminPerfTrace.settlementStreamBalance, 0);
    });

    test('dispose then reopen creates a fresh stream (no leak balance)', () {
      final owner = AdminSettlementsStreamOwner(
        keyFactory: () => 'settlements|test|limit=200',
        streamFactory: (key) {
          AdminPerfTrace.settlementStreamCreate(key);
          return const Stream.empty();
        },
      );
      owner.streamForCurrentUser();
      owner.dispose();
      expect(AdminPerfTrace.settlementStreamBalance, 0);

      final owner2 = AdminSettlementsStreamOwner(
        keyFactory: () => 'settlements|test|limit=200',
        streamFactory: (key) {
          AdminPerfTrace.settlementStreamCreate(key);
          return const Stream.empty();
        },
      );
      owner2.streamForCurrentUser();
      expect(AdminPerfTrace.settlementStreamCreates, 2);
      owner2.dispose();
      expect(AdminPerfTrace.settlementStreamBalance, 0);
    });
  });

  group('PERF-P1 session cleanup', () {
    test('perf counters reset and role session clears across users', () {
      AdminPerfTrace.profileRead(forceRefresh: true, source: 'test');
      expect(AdminPerfTrace.profileReads, 1);

      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
      expect(AdminRoleService.isAccountant, isTrue);

      AdminPerfTrace.resetCounters();
      CountryResolver.clearCache();
      AdminRoleService.resetSession();
      AdminStatsCoordinator.instance.stopLiveSync();

      expect(AdminPerfTrace.profileReads, 0);
      expect(AdminRoleService.currentRole, AdminRole.none);

      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'super_admin': true}),
      );
      expect(AdminRoleService.isSuperAdmin, isTrue);
      expect(AdminRoleService.isAccountant, isFalse);
    });
  });
}
