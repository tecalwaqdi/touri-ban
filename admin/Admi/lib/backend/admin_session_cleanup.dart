import '/app_state.dart';
import '/backend/admin_landmark_count.dart';
import '/backend/admin_panel_session.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_country_landmark_filter.dart';
import '/backend/admin_perf_trace.dart';
import '/backend/admin_reports_country_scope.dart';
import '/backend/admin_reports_loader.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_landmark_search.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/dashboard_stats_loader.dart';
import '/backend/admin_auth_session_owner.dart';
import '/core/country/country_resolver.dart';
import '/core/finance/admin_finance_repository.dart';

/// Clears role-scoped client state on logout so the next user never inherits it.
class AdminSessionCleanup {
  AdminSessionCleanup._();

  static void onSignOut() {
    AdminLandmarkIndex.clear();
    AdminCountryScope.clearVillageCache();
    AdminSaudiCountry.clearCache();
    CountryResolver.clearCache();
    AdminFinanceRepository.instance.clearSession();
    AdminAuthSessionOwner.stop();
    AdminCountryLandmarkFilter.invalidateCache();
    AdminLandmarkCount.invalidateCache();
    clearAdminReportsSummaryCache();
    AdminReportsCountryScope.clear();
    clearDashboardStatsCache();
    AdminStatsCoordinator.instance.stopLiveSync();
    AdminPanelSession.reset();
    AdminPanelDataBootstrap.reset();
    AdminPerfTrace.resetCounters();
    FFAppState().update(() {
      FFAppState().RevDolh = null;
      FFAppState().RevdolhTEXT = '';
      FFAppState().dolh = null;
      FFAppState().naimdolh = '';
      FFAppState().workcite = null;
      FFAppState().workciteText = '';
    });
  }
}
