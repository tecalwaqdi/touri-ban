import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/finance_runtime_gate.dart';
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
  String _appVersion = '—';
  Map<String, dynamic>? _home;
  int _metricCount = 0;
  Map<String, dynamic>? _lastMetric;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _loadVersion();
    _ping();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    } catch (e, st) {
      AdminUi.logDiagnostic('diagnostics_version', e, st);
    }
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _ping() async {
    setState(() => _status = 'checking');
    try {
      await FirebaseFirestore.instance
          .collection('financial_config')
          .limit(1)
          .get();
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
    final flags =
        Map<String, dynamic>.from(_home?['featureFlags'] as Map? ?? {});
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
            softWrap: true,
            style: theme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('Admin build: $_appVersion', softWrap: true),
          Text(
            'Firestore: ${_status == 'ok' ? 'reachable' : _status}',
            softWrap: true,
          ),
          Text(
            'Finance functions: ${_home != null ? 'reachable' : '—'}',
            softWrap: true,
          ),
          Text(
            'Authenticated role: ${AdminRoleService.roleLabel(AdminRoleService.currentRole)}'
            '${AdminRoleService.isRoleResolving ? ' (resolving…)' : ''}',
            softWrap: true,
          ),
          Text(
            'Authoritative backend data: ${FinanceRuntimeGate.authoritativeBackendData}',
            softWrap: true,
          ),
          Text(
            'Approximate / fallback mode: ${!FinanceRuntimeGate.authoritativeBackendData}',
            softWrap: true,
          ),
          Text('Aggregation metric samples: $_metricCount', softWrap: true),
          Text(
            'Independent approver (accountantHome): $approverOk',
            softWrap: true,
          ),
          if (!approverOk)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                uiTr(
                  context,
                  'Financial pilot blocked: no independent approver configured',
                ),
                softWrap: true,
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
                : uiTr(
                    context, 'Approver availability: missing / not configured'),
            softWrap: true,
            style: theme.bodyMedium.override(
              fontFamily: 'Cairo',
              color: approverOk ? Colors.green.shade700 : theme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_lastMetric != null) ...[
            const SizedBox(height: 8),
            Text(uiTr(context, 'Last aggregation metric'),
                style: theme.titleSmall),
            Text('op: ${_lastMetric!['op'] ?? '—'}', softWrap: true),
            Text('ordersScanned: $ordersScanned', softWrap: true),
            Text('durationMs: ${_lastMetric!['durationMs'] ?? '—'}',
                softWrap: true),
            Text('cacheHit: ${_lastMetric!['cacheHit'] ?? '—'}',
                softWrap: true),
            Text('at: ${_lastMetric!['at'] ?? '—'}', softWrap: true),
            if (expensive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  uiTr(
                    context,
                    'Expensive query warning: ordersScanned > 5000. Prefer narrower filters or cache.',
                  ),
                  softWrap: true,
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
          for (final e in flags.entries)
            Text('${e.key}=${e.value}', softWrap: true),
          if ((_home?['warnings'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(uiTr(context, 'Warnings'), style: theme.titleSmall),
            for (final w in (_home!['warnings'] as List))
              Text('• $w', softWrap: true),
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
