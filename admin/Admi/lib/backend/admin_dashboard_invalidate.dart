import 'dart:async';

import '/backend/admin_landmark_count.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_reports_loader.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/dashboard_stats_loader.dart';
import '/components/dashboard_stats_section.dart';

Timer? _dashboardInvalidateDebounce;
bool _dashboardInvalidatePending = false;

/// Clears dashboard caches and refreshes visible stat cards (debounced).
void invalidateAdminDashboardStats() {
  _dashboardInvalidatePending = true;
  _dashboardInvalidateDebounce?.cancel();
  _dashboardInvalidateDebounce = Timer(
    const Duration(milliseconds: 900),
    _flushDashboardInvalidate,
  );
}

/// Immediate refresh after delete — optimistic −1 then server recount.
void refreshDashboardStatsAfterDelete({
  String? refreshScope,
  Iterable<String>? refreshScopes,
}) {
  optimisticallyAdjustDashboardStatsForDelete(
    refreshScope: refreshScope,
    refreshScopes: refreshScopes,
  );
  DashboardStatsSectionState.applyOptimisticPatch();

  AdminLandmarkCount.invalidateCache();
  AdminLandmarkCountCache.invalidate();
  clearAdminReportsSummaryCache();
  cancelDashboardStatsLoadInFlight();
  AdminStatsCoordinator.instance.invalidate();

  if (DashboardStatsSectionState.hasLiveSections) {
    DashboardStatsSectionState.reloadAllFromServer();
  } else {
    markDashboardStatsStale();
    clearDashboardStatsCache();
  }
}

/// Immediate refresh — use after add/edit.
void flushAdminDashboardStatsNow() {
  _dashboardInvalidateDebounce?.cancel();
  _dashboardInvalidatePending = true;
  _flushDashboardInvalidate();
}

void _flushDashboardInvalidate() {
  if (!_dashboardInvalidatePending) return;
  _dashboardInvalidatePending = false;

  clearDashboardStatsCache();
  clearAdminReportsSummaryCache();
  AdminLandmarkCount.invalidateCache();
  AdminLandmarkCountCache.invalidate();
  AdminStatsCoordinator.instance.invalidate();
  if (DashboardStatsSectionState.hasLiveSections) {
    DashboardStatsSectionState.invalidateAll();
  }
}

/// Clears reports summary cache when dashboard stats refresh after CRUD.
void invalidateAdminReportsStats() {
  clearAdminReportsSummaryCache();
  AdminStatsCoordinator.instance.invalidate(domains: const [StatsDomain.reports]);
}

/// Maps list refresh scopes to dashboard stat keys adjusted after delete.
void optimisticallyAdjustDashboardStatsForDelete({
  String? refreshScope,
  Iterable<String>? refreshScopes,
}) {
  var landmarks = 0;
  var partners = 0;
  var countries = 0;
  var regions = 0;
  var cities = 0;
  var users = 0;
  var agents = 0;
  var reps = 0;
  var transport = 0;
  var bookings = 0;
  var support = 0;

  void applyScope(String scope) {
    switch (scope) {
      case 'landmarks':
        landmarks--;
        break;
      case 'partners':
        partners--;
        landmarks--;
        break;
      case 'countries':
        countries--;
        break;
      case 'regions':
        regions--;
        break;
      case 'cities':
        cities--;
        break;
      case 'users':
        users--;
        break;
      case 'agents':
        agents--;
        break;
      case 'representatives':
      case 'drivers':
        reps--;
        break;
      case 'transport_companies':
        transport--;
        break;
      case 'bookings':
        bookings--;
        break;
      case 'support':
        support--;
        break;
      case 'super_admins':
        users--;
        break;
    }
  }

  if (refreshScope != null) applyScope(refreshScope);
  if (refreshScopes != null) {
    for (final scope in refreshScopes) {
      applyScope(scope);
    }
  }

  if (landmarks == 0 &&
      partners == 0 &&
      countries == 0 &&
      regions == 0 &&
      cities == 0 &&
      users == 0 &&
      agents == 0 &&
      reps == 0 &&
      transport == 0 &&
      bookings == 0 &&
      support == 0) {
    return;
  }

  patchDashboardStatsCache(
    landmarksDelta: landmarks,
    partnersDelta: partners,
    countriesDelta: countries,
    regionsDelta: regions,
    citiesDelta: cities,
    appUsersDelta: users,
    agentsDelta: agents,
    representativesDelta: reps,
    transportCompaniesDelta: transport,
    activeBookingsDelta: bookings,
    supportTicketsDelta: support,
  );
}
