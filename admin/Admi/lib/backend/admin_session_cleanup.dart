import '/app_state.dart';
import '/backend/admin_landmark_count.dart';
import '/backend/admin_panel_session.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_country_landmark_filter.dart';
import '/backend/admin_reports_country_scope.dart';
import '/backend/admin_reports_loader.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_landmark_search.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/admin_stats_coordinator.dart';
import '/backend/dashboard_stats_loader.dart';

/// Clears role-scoped client state on logout so the next user never inherits it.
class AdminSessionCleanup {
  AdminSessionCleanup._();

  static void onSignOut() {
    AdminLandmarkIndex.clear();
    AdminCountryScope.clearVillageCache();
    AdminSaudiCountry.clearCache();
    AdminCountryLandmarkFilter.invalidateCache();
    AdminLandmarkCount.invalidateCache();
    clearAdminReportsSummaryCache();
    AdminReportsCountryScope.clear();
    clearDashboardStatsCache();
    AdminStatsCoordinator.instance.stopLiveSync();
    AdminPanelSession.reset();
    AdminPanelDataBootstrap.reset();
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
