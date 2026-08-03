import '/backend/admin_panel_data_bootstrap.dart';

/// Country-agent bootstrap — delegates to [AdminPanelDataBootstrap].
class AdminAgentDataBootstrap {
  AdminAgentDataBootstrap._();

  static bool get isReady => AdminPanelDataBootstrap.isReady;

  static void reset() => AdminPanelDataBootstrap.reset();

  static Future<void> ensureReady({bool force = false}) =>
      AdminPanelDataBootstrap.ensureReady(force: force);
}
