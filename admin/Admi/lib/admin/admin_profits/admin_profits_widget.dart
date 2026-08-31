import 'dart:async';

import '/backend/admin_stats_coordinator.dart';
import '/components/admin_financial_v2_panel.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'admin_profits_model.dart';
export 'admin_profits_model.dart';

class AdminProfitsWidget extends StatefulWidget {
  const AdminProfitsWidget({super.key});

  static String routeName = 'AdminProfits';
  static String routePath = '/adminProfits';

  @override
  State<AdminProfitsWidget> createState() => _AdminProfitsWidgetState();
}

class _AdminProfitsWidgetState extends State<AdminProfitsWidget> {
  late AdminProfitsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<_AdminFinancialV2PanelHostState> _panelKey =
      GlobalKey<_AdminFinancialV2PanelHostState>();
  StreamSubscription<int>? _statsInvalidationSub;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminProfitsModel());
    _statsInvalidationSub =
        AdminStatsCoordinator.instance.stream(StatsDomain.profits).listen((_) {
      _panelKey.currentState?.reload();
    });
  }

  @override
  void dispose() {
    _statsInvalidationSub?.cancel();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final l10n = FFLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        padContent: false,
        title: l10n.getText('nn2n9yup'),
        child: RefreshIndicator(
          color: AdminUi.brandTeal,
          backgroundColor: theme.secondaryBackground,
          onRefresh: () async => _panelKey.currentState?.reload(),
          child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AdminUi.pagePadding(context),
                  children: [
              Text(
                uiTr(context, 'التقرير المالي'),
                style: theme.headlineSmall,
              ),
              const SizedBox(height: 4),
                          Text(
                uiTr(
                  context,
                  'محاسبة قرائية فقط — بدون تسوية أو تعديل أرصدة',
                ),
                style: theme.labelMedium,
              ),
              const SizedBox(height: 16),
              _AdminFinancialV2PanelHost(key: _panelKey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminFinancialV2PanelHost extends StatefulWidget {
  const _AdminFinancialV2PanelHost({super.key});

  @override
  State<_AdminFinancialV2PanelHost> createState() =>
      _AdminFinancialV2PanelHostState();
}

class _AdminFinancialV2PanelHostState extends State<_AdminFinancialV2PanelHost> {
  Key _reloadKey = UniqueKey();

  void reload() => setState(() => _reloadKey = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return AdminFinancialV2Panel(key: _reloadKey);
  }
}
