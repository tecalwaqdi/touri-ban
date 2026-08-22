import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_controls_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Lightweight operational health (no secrets).
class AdminDiagnosticsWidget extends StatefulWidget {
  const AdminDiagnosticsWidget({super.key});

  static const String routeName = 'AdminDiagnostics';
  static const String routePath = '/adminDiagnostics';

  @override
  State<AdminDiagnosticsWidget> createState() => _AdminDiagnosticsWidgetState();
}

class _AdminDiagnosticsWidgetState extends State<AdminDiagnosticsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  String _status = 'idle';
  Map<String, dynamic>? _home;
  int _metricCount = 0;
  Map<String, dynamic>? _lastMetric;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _ping();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _ping() async {
    setState(() => _status = 'checking');
    try {
      await FirebaseFirestore.instance.collection('financial_config').limit(1).get();
      final home = await FinanceControlsClient.accountantHome();
      int metrics = 0;
      Map<String, dynamic>? last;
      try {
        final m = await FirebaseFirestore.instance
            .collection('financial_aggregation_metrics')
            .orderBy('at', descending: true)
            .limit(20)
            .get();
        metrics = m.size;
        if (m.docs.isNotEmpty) {
          last = m.docs.first.data();
        }
      } catch (_) {
        try {
          final m = await FirebaseFirestore.instance
              .collection('financial_aggregation_metrics')
              .limit(20)
              .get();
          metrics = m.size;
          if (m.docs.isNotEmpty) {
            last = m.docs.first.data();
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _status = 'ok';
        _home = home;
        _metricCount = metrics;
        _lastMetric = last;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final flags = Map<String, dynamic>.from(_home?['featureFlags'] as Map? ?? {});
    final ordersScanned = (_lastMetric?['ordersScanned'] as num?)?.toInt() ?? 0;
    final expensive = ordersScanned > 5000;
    final approverOk = _home?['independentApproverConfigured'] == true;

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'Admin Diagnostics'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(uiTr(context, 'Admin Diagnostics'), style: theme.headlineSmall),
          Text(
            uiTr(context, 'No environment secrets are shown here.'),
            style: theme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('Firestore: ${_status == 'ok' ? 'reachable' : _status}'),
          Text('Finance functions: ${_home != null ? 'reachable' : '—'}'),
          Text('Aggregation metric samples: $_metricCount'),
          Text(
            'Independent approver (accountantHome): $approverOk',
          ),
          if (!approverOk)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                uiTr(
                  context,
                  'Financial pilot blocked: no independent approver configured',
                ),
                style: theme.bodyMedium.override(
                  fontFamily: 'Cairo',
                  color: theme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Text(
            approverOk
                ? uiTr(context, 'Approver availability: configured')
                : uiTr(context, 'Approver availability: missing / not configured'),
            style: theme.bodyMedium.override(
              fontFamily: 'Cairo',
              color: approverOk ? Colors.green.shade700 : theme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_lastMetric != null) ...[
            const SizedBox(height: 8),
            Text(uiTr(context, 'Last aggregation metric'), style: theme.titleSmall),
            Text('op: ${_lastMetric!['op'] ?? '—'}'),
            Text('ordersScanned: $ordersScanned'),
            Text('durationMs: ${_lastMetric!['durationMs'] ?? '—'}'),
            Text('cacheHit: ${_lastMetric!['cacheHit'] ?? '—'}'),
            Text('at: ${_lastMetric!['at'] ?? '—'}'),
            if (expensive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  uiTr(
                    context,
                    'Expensive query warning: ordersScanned > 5000. Prefer narrower filters or cache.',
                  ),
                  style: theme.bodyMedium.override(
                    fontFamily: 'Cairo',
                    color: theme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text(uiTr(context, 'Feature flags'), style: theme.titleSmall),
          for (final e in flags.entries) Text('${e.key}=${e.value}'),
          if ((_home?['warnings'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(uiTr(context, 'Warnings'), style: theme.titleSmall),
            for (final w in (_home!['warnings'] as List)) Text('• $w'),
          ],
          if (AdminRoleService.isSuperAdmin || AdminRoleService.isFinance)
            TextButton(
              onPressed: _ping,
              child: Text(uiTr(context, 'Refresh')),
            ),
        ],
      ),
    );
  }
}
