import 'package:flutter/foundation.dart';

/// DEV/PERF counters for Admin shell bootstrap (PERF-P1).
///
/// Disabled unless [enabled] is true (tests) or [kDebugMode].
/// Never logs PII.
abstract final class AdminPerfTrace {
  AdminPerfTrace._();

  static bool enabled = kDebugMode;
  static bool _muteLogs = true;

  static int profileReads = 0;
  static int claimRefreshCalls = 0;
  static int scopeBootstrapCalls = 0;
  static int countryResolverLoads = 0;
  static int liveOrderListenerStarts = 0;
  static int menuBadgeListenerBuilds = 0;
  static int settlementStreamCreates = 0;
  static int settlementStreamDisposes = 0;

  static final List<String> events = <String>[];

  static void resetCounters() {
    profileReads = 0;
    claimRefreshCalls = 0;
    scopeBootstrapCalls = 0;
    countryResolverLoads = 0;
    liveOrderListenerStarts = 0;
    menuBadgeListenerBuilds = 0;
    settlementStreamCreates = 0;
    settlementStreamDisposes = 0;
    events.clear();
  }

  static void _note(String event) {
    if (!enabled) return;
    events.add(event);
    if (!_muteLogs && kDebugMode) {
      // ignore: avoid_print
      print('[AdminPerf] $event');
    }
  }

  static void profileRead({required bool forceRefresh, required String source}) {
    if (!enabled) return;
    profileReads++;
    _note('profile_read#$profileReads force=$forceRefresh src=$source');
  }

  static void claimRefresh({required String source}) {
    if (!enabled) return;
    claimRefreshCalls++;
    _note('claims_refresh#$claimRefreshCalls src=$source');
  }

  static void scopeBootstrap({required bool force}) {
    if (!enabled) return;
    scopeBootstrapCalls++;
    _note('scope_bootstrap#$scopeBootstrapCalls force=$force');
  }

  static void countryResolverLoad() {
    if (!enabled) return;
    countryResolverLoads++;
    _note('country_resolver_load#$countryResolverLoads');
  }

  static void liveOrderListenerStart({required String role}) {
    if (!enabled) return;
    liveOrderListenerStarts++;
    _note('live_order_listener#$liveOrderListenerStarts role=$role');
  }

  static void menuBadgeListenerBuild() {
    if (!enabled) return;
    menuBadgeListenerBuilds++;
    _note('menu_badge_listener_build#$menuBadgeListenerBuilds');
  }

  static void settlementStreamCreate(String key) {
    if (!enabled) return;
    settlementStreamCreates++;
    _note('settlement_stream_create#$settlementStreamCreates key=$key');
  }

  static void settlementStreamDispose(String? key) {
    if (!enabled) return;
    settlementStreamDisposes++;
    _note('settlement_stream_dispose#$settlementStreamDisposes key=$key');
  }

  /// Active settlement stream creates minus disposes (test helper).
  static int get settlementStreamBalance =>
      settlementStreamCreates - settlementStreamDisposes;
}
