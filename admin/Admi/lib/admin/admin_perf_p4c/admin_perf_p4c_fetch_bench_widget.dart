import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_finance_route_trace.dart';
import '/backend/admin_firestore_web_config.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_order_query.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// PERF-P4C — same modern_page shape; mode via `?mode=server|default|snap`.
///
/// Not linked from production menus. Accountant allowlisted.
class AdminPerfP4cFetchBenchWidget extends StatefulWidget {
  const AdminPerfP4cFetchBenchWidget({super.key});

  static const String routeName = 'AdminPerfP4cFetchBench';
  static const String routePath = '/adminPerfP4cFetchBench';

  @override
  State<AdminPerfP4cFetchBenchWidget> createState() =>
      _AdminPerfP4cFetchBenchWidgetState();
}

class _AdminPerfP4cFetchBenchWidgetState
    extends State<AdminPerfP4cFetchBenchWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  String _status = 'loading';
  int? _sdkMs;
  String _mode = 'server';
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    _mode = Uri.base.queryParameters['mode'] ?? 'server';
    AdminFinanceRouteTrace.begin('p4c_fetch_$_mode');
    AdminFinanceRouteTrace.mark('FIRST_BUILD_START');
    _menu2Model = createModel(context, () => Menu2Model());
    _run();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final range = AdminDateRangeResolver.resolve(
      preset: AdminDatePreset.thisMonth,
    );
    DocumentReference? country;
    if (AdminRoleService.usesCountryFinanceScope) {
      country = AdminRoleService.scopedCountryRef;
    }

    FinanceOrderFetchMode fetchMode = FinanceOrderFetchMode.get;
    GetOptions? options = AdminFirestoreWebConfig.financeOneShotGetOptions;
    if (_mode == 'default') {
      options = const GetOptions();
    } else if (_mode == 'snap') {
      fetchMode = FinanceOrderFetchMode.snapshotsFirst;
      options = null;
    }

    final sdkSw = Stopwatch()..start();
    final page = await FinanceOrderQuery.fetchModernPage(
      range: range,
      country: country,
      limit: 40,
      fetchMode: fetchMode,
      getOptions: options,
    );
    sdkSw.stop();
    _sdkMs = sdkSw.elapsedMilliseconds;

    if (!mounted) return;
    setState(() {
      _status =
          'mode=$_mode docs=${page.docsRead} accepted=${page.orders.length} '
          'fromCache=${page.fromCache} cfg=${AdminFirestoreWebConfig.describe()}';
      AdminFinanceRouteTrace.markStateEmitAndSchedulePaint();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_marked) {
      _marked = true;
      AdminFinanceRouteTrace.mark('FIRST_BUILD_END');
    }
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () {},
      title: 'PERF-P4C Fetch Bench',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status, style: theme.bodyMedium),
            Text('sdkFetchMs=$_sdkMs mode=$_mode', style: theme.labelMedium),
          ],
        ),
      ),
    );
  }
}
