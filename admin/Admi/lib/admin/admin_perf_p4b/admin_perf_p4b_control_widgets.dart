import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/backend/admin_finance_route_trace.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_order_query.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// PERF-P4B DEV/PERF-only control surfaces — not linked from production menus.
class AdminPerfP4bStaticWidget extends StatefulWidget {
  const AdminPerfP4bStaticWidget({super.key});

  static const String routeName = 'AdminPerfP4bStatic';
  static const String routePath = '/adminPerfP4bStatic';

  @override
  State<AdminPerfP4bStaticWidget> createState() =>
      _AdminPerfP4bStaticWidgetState();
}

class _AdminPerfP4bStaticWidgetState extends State<AdminPerfP4bStaticWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    AdminFinanceRouteTrace.begin('p4b_static');
    AdminFinanceRouteTrace.mark('FIRST_BUILD_START');
    _menu2Model = createModel(context, () => Menu2Model());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminFinanceRouteTrace.markStateEmitAndSchedulePaint(
        stateEvent: 'STATE_EMIT',
      );
    });
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
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
      title: 'PERF-P4B Static',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Static authenticated page — no Firestore query.\n'
          'Trace: ${AdminFinanceRouteTrace.activeTraceId ?? '—'}',
          style: theme.bodyMedium,
        ),
      ),
    );
  }
}

/// Minimal modern_page query + plain text list (no Finance F2 UI).
class AdminPerfP4bControlQueryWidget extends StatefulWidget {
  const AdminPerfP4bControlQueryWidget({super.key});

  static const String routeName = 'AdminPerfP4bControlQuery';
  static const String routePath = '/adminPerfP4bControlQuery';

  @override
  State<AdminPerfP4bControlQueryWidget> createState() =>
      _AdminPerfP4bControlQueryWidgetState();
}

class _AdminPerfP4bControlQueryWidgetState
    extends State<AdminPerfP4bControlQueryWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  List<String> _lines = const [];
  String _status = 'loading';
  int? _sdkMs;
  int? _tokenMs;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    AdminFinanceRouteTrace.begin('p4b_control_query');
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

    final tokenSw = Stopwatch()..start();
    AdminFinanceRouteTrace.mark('AUTH_TOKEN_REQUEST_START');
    await FirebaseAuth.instance.currentUser?.getIdToken(false);
    tokenSw.stop();
    AdminFinanceRouteTrace.mark('AUTH_TOKEN_REQUEST_END');
    _tokenMs = tokenSw.elapsedMilliseconds;

    final sdkSw = Stopwatch()..start();
    final page = await FinanceOrderQuery.fetchModernPage(
      range: range,
      country: country,
      limit: 40,
    );
    sdkSw.stop();
    _sdkMs = sdkSw.elapsedMilliseconds;

    AdminFinanceRouteTrace.mark('MODEL_BUILD_START');
    final lines = page.orders
        .take(10)
        .map((o) => '${o.reference.id} | ${o.dataOrder}')
        .toList();
    AdminFinanceRouteTrace.mark('MODEL_BUILD_END', extra: {'n': lines.length});

    if (!mounted) return;
    setState(() {
      _lines = lines;
      _status =
          'ok docs=${page.docsRead} accepted=${page.orders.length} fromCache=${page.fromCache}';
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
      title: 'PERF-P4B Control Query',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_status, style: theme.bodyMedium),
          Text('tokenMs=$_tokenMs sdkFetchMs=$_sdkMs', style: theme.labelMedium),
          const SizedBox(height: 12),
          for (final line in _lines) Text(line, style: theme.bodySmall),
        ],
      ),
    );
  }
}
