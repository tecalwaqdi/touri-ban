import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_agent_session_ready.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_prefetch.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/dashboard_stats_loader.dart';
import '/core/country/country_resolver.dart';

/// Fast scope bootstrap + background dashboard warming.
class AdminPanelSession {
  AdminPanelSession._();

  static Future<void>? _scopeInFlight;
  static Future<void>? _statsInFlight;
  static String? _scopeReadyForUid;
  static String? _statsWarmedForUid;

  /// Scope (country / role) is ready — safe to query lists.
  static bool get isScopeReady {
    if (_scopeReadyForUid == null || _scopeReadyForUid != currentUserUid) {
      return false;
    }
    if (!AdminPanelDataBootstrap.isReady) return false;
    if (AdminRoleService.isCountryAgent &&
        !AdminPanelDataBootstrap.isAgentScopeReady) {
      return false;
    }
    return true;
  }

  /// Back-compat alias for UI gates.
  static bool get isPrepared => isScopeReady;

  static void reset() {
    _scopeReadyForUid = null;
    _statsWarmedForUid = null;
    _scopeInFlight = null;
    _statsInFlight = null;
    AdminStatsCoordinator.instance.stopLiveSync();
  }

  /// Bootstrap only — opens the panel immediately after this completes.
  static Future<void> ensureScopeReady({bool force = false}) async {
    if (!loggedIn || !AdminRoleService.hasPanelAccess) return;

    final uid = currentUserUid;
    if (uid.isEmpty) return;

    if (!force && isScopeReady) return;

    if (!force && _scopeInFlight != null) {
      await _scopeInFlight;
      return;
    }

    _scopeInFlight = _bootstrapScope(uid, force: force);
    try {
      await _scopeInFlight;
    } finally {
      _scopeInFlight = null;
    }
  }

  /// Warm stats + list cache without blocking navigation.
  static Future<void> warmDashboard({bool force = false}) async {
    if (!loggedIn || !AdminRoleService.hasPanelAccess) return;
    if (!isScopeReady) {
      await ensureScopeReady(force: force);
    }

    final uid = currentUserUid;
    if (uid.isEmpty) return;

    if (!force && _statsWarmedForUid == uid) return;

    if (!force && _statsInFlight != null) {
      await _statsInFlight;
      return;
    }

    _statsInFlight = _warmStats(uid, force: force);
    try {
      await _statsInFlight;
    } finally {
      _statsInFlight = null;
    }
  }

  /// Scope first, then stats in background (non-blocking for callers).
  static Future<void> ensurePrepared({bool force = false}) async {
    await ensureScopeReady(force: force);
    unawaited(warmDashboard(force: force));
  }

  static Future<void> _bootstrapScope(String uid, {required bool force}) async {
    if (force) {
      clearDashboardStatsCache();
      AdminPrefetch.resetForLogin();
      AdminPanelDataBootstrap.reset();
      _scopeReadyForUid = null;
      _statsWarmedForUid = null;
    }

    await AdminPanelDataBootstrap.ensureReady(force: force);
    await CountryResolver.ensureLoaded();
    AdminAgentCountryLock.applyToAppState();

    if (AdminRoleService.isCountryAgent &&
        !AdminPanelDataBootstrap.isAgentScopeReady) {
      await AdminPanelDataBootstrap.ensureReady(force: true);
      AdminAgentCountryLock.applyToAppState();
    }

    _scopeReadyForUid = uid;
    AdminAgentSessionReady.notify();
    AdminStatsCoordinator.instance.startLiveSync();
  }

  static Future<void> _warmStats(String uid, {required bool force}) async {
    if (_scopeReadyForUid != uid || currentUserUid != uid) return;

    try {
      await loadDashboardStats(
        forceRefresh: force || _statsWarmedForUid != uid,
        quickLandmarks: AdminRoleService.isCountryAgent,
        priorityOnly: false,
      ).timeout(const Duration(seconds: 18));
      if (_scopeReadyForUid == uid && currentUserUid == uid) {
        _statsWarmedForUid = uid;
      }
    } catch (_) {}
  }
}
