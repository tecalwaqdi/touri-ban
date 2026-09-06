import 'dart:async';


import '/backend/admin_cache_policy.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_perf_trace.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Domains that expose admin statistics UIs.
enum StatsDomain {
  dashboard,
  reports,
  profits,
  agent,
  bookings,
  support,
}

/// Broadcasts stat invalidation so every stats screen reloads together.
///
/// Live sync: **one** scoped order listener (limit 8) for near-real-time
/// booking metrics — not a full-collection stream. Other domains rely on
/// CRUD hooks via [invalidate] / [invalidateAdminDashboardStats].
class AdminStatsCoordinator {
  AdminStatsCoordinator._();

  static final AdminStatsCoordinator instance = AdminStatsCoordinator._();

  final Map<StatsDomain, StreamController<int>> _controllers = {
    for (final d in StatsDomain.values)
      d: StreamController<int>.broadcast(),
  };

  final Map<StatsDomain, int> _generation = {
    for (final d in StatsDomain.values) d: 0,
  };

  StreamSubscription<QuerySnapshot>? _orderWatch;
  Timer? _orderWatchDebounce;
  int _requestEpoch = 0;

  /// Monotonic epoch for stale-request protection across loaders.
  int nextRequestEpoch() => ++_requestEpoch;

  int get requestEpoch => _requestEpoch;

  int generation(StatsDomain domain) => _generation[domain] ?? 0;

  Stream<int> stream(StatsDomain domain) => _controllers[domain]!.stream;

  /// Bump generation and notify listeners for the given domains.
  void invalidate({Iterable<StatsDomain>? domains}) {
    final targets = domains ?? StatsDomain.values;
    for (final domain in targets) {
      final next = (_generation[domain] ?? 0) + 1;
      _generation[domain] = next;
      final controller = _controllers[domain];
      if (controller != null && !controller.isClosed) {
        controller.add(next);
      }
    }
  }

  /// After booking CRUD — refresh dashboard + bookings surfaces quickly.
  void invalidateAfterBookingChange() {
    invalidate(domains: const [
      StatsDomain.dashboard,
      StatsDomain.bookings,
      StatsDomain.reports,
      StatsDomain.profits,
      StatsDomain.agent,
    ]);
  }

  void invalidateAfterUserChange() {
    invalidate(domains: const [
      StatsDomain.dashboard,
      StatsDomain.reports,
    ]);
  }

  void invalidateAfterSupportChange() {
    invalidate(domains: const [
      StatsDomain.dashboard,
      StatsDomain.support,
    ]);
  }

  void invalidateAfterGeoChange() {
    invalidate(domains: const [
      StatsDomain.dashboard,
      StatsDomain.reports,
    ]);
  }

  /// Listen to recent order changes (scoped) and debounce stat refresh.
  ///
  /// PERF-P1: callers must not start this for Accountant / finance-only personas
  /// ([AdminPanelSession] gates). Defense-in-depth skip here too.
  void startLiveSync() {
    stopLiveSync();

    if (AdminRoleService.isAccountant || AdminRoleService.isFinanceStaff) {
      return;
    }

    if (!AdminRoleService.wantsOperationalLiveSync) {
      return;
    }

    Query query = OrderRecord.collection
        .orderBy('data_order', descending: true)
        .limit(8);

    // Prefer role lock, then active country scope — never global for agents.
    final countryRef = AdminRoleService.scopedCountryRef ??
        AdminCountryScope.activeCountryRef;
    if (countryRef != null) {
      query = OrderRecord.collection
          .where('Rev_dolh', isEqualTo: countryRef)
          .orderBy('data_order', descending: true)
          .limit(8);
    } else if (AdminRoleService.isCountryAgent) {
      // Agent without country — do not attach a global listener.
      return;
    }

    AdminPerfTrace.liveOrderListenerStart(
      role: AdminRoleService.currentRole.name,
    );
    _orderWatch = query.snapshots().listen((_) {
      _orderWatchDebounce?.cancel();
      _orderWatchDebounce = Timer(
        AdminCachePolicy.liveInvalidateDebounce,
        () {
          invalidateAfterBookingChange();
        },
      );
    });
  }

  void stopLiveSync() {
    _orderWatchDebounce?.cancel();
    _orderWatchDebounce = null;
    _orderWatch?.cancel();
    _orderWatch = null;
  }

  void dispose() {
    stopLiveSync();
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }
}
