import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/admin_finance_ui_labels.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/finance_runtime_gate.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Technical health for Super Admin only (not a business finance screen).
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
    if (!AdminRoleService.isSuperAdmin) {
      return AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: AdminFinanceUiLabels.diagnosticsTitleAr(),
        child: Center(
          child: Text(
            uiTr(context, 'هذه الشاشة للسوبر أدمن فقط.'),
            softWrap: true,
          ),
        ),
      );
    }

    final flags =
        Map<String, dynamic>.from(_home?['featureFlags'] as Map? ?? {});
    final policy =
        Map<String, dynamic>.from(_home?['policy'] as Map? ?? {});
    final ordersScanned = (_lastMetric?['ordersScanned'] as num?)?.toInt() ?? 0;
    final expensive = ordersScanned > 5000;
    final approverOk = _home?['independentApproverConfigured'] == true;
    final selfApproval = policy['allowSelfApproval'] == true;
    final warnings = (_home?['warnings'] as List?) ?? const [];
    final pilotHardBlock = warnings.any(
          (w) => '$w'.contains('Financial pilot blocked'),
        ) ||
        (!selfApproval && !approverOk);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: AdminFinanceUiLabels.diagnosticsTitleAr(),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(
            AdminFinanceUiLabels.diagnosticsTitleAr(),
            style: theme.headlineSmall,
            softWrap: true,
          ),
          Text(
            uiTr(context, 'لا تُعرض هنا أي أسرار للبيئة.'),
            softWrap: true,
            style: theme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('${uiTr(context, 'إصدار اللوحة')}: $_appVersion', softWrap: true),
          Text(
            '${uiTr(context, 'Firestore')}: ${_status == 'ok' ? uiTr(context, 'متصل') : _status}',
            softWrap: true,
          ),
          Text(
            '${uiTr(context, 'وظائف المالية')}: ${_home != null ? uiTr(context, 'متصلة') : '—'}',
            softWrap: true,
          ),
          Text(
            '${uiTr(context, 'الدور')}: ${AdminRoleService.roleLabelL10n(context, AdminRoleService.currentRole)}'
            '${AdminRoleService.isRoleResolving ? ' …' : ''}',
            softWrap: true,
          ),
          Text(
            '${uiTr(context, 'بيانات خلفية موثوقة')}: ${FinanceRuntimeGate.authoritativeBackendData}',
            softWrap: true,
          ),
          Text(
            '${uiTr(context, 'عينات مقاييس التجميع')}: $_metricCount',
            softWrap: true,
          ),
          Text(
            approverOk
                ? AdminFinanceUiLabels.pilotConfiguredAr()
                : AdminFinanceUiLabels.pilotMissingAr(),
            softWrap: true,
            style: theme.bodyMedium.override(
              fontFamily: 'Cairo',
              color: approverOk ? Colors.green.shade700 : theme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (selfApproval && !approverOk)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AdminFinanceUiLabels.pilotOptionalWhenSelfApprovalAr(),
                softWrap: true,
                style: theme.bodyMedium,
              ),
            )
          else if (pilotHardBlock)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AdminFinanceUiLabels.pilotBlockedAr(),
                softWrap: true,
                style: theme.bodyMedium.override(
                  fontFamily: 'Cairo',
                  color: theme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Text(
            '${uiTr(context, 'الاعتماد الذاتي')}: ${selfApproval ? uiTr(context, 'مفعّل') : uiTr(context, 'متوقف')}',
            softWrap: true,
          ),
          if (_lastMetric != null) ...[
            const SizedBox(height: 8),
            Text(uiTr(context, 'آخر مقياس تجميع'), style: theme.titleSmall),
            Text('op: ${_lastMetric!['op'] ?? '—'}', softWrap: true),
            Text('ordersScanned: $ordersScanned', softWrap: true),
            Text('durationMs: ${_lastMetric!['durationMs'] ?? '—'}',
                softWrap: true),
            if (expensive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  uiTr(
                    context,
                    'تحذير استعلام ثقيل: ordersScanned > 5000. فضّل فلاتر أضيق أو التخزين المؤقت.',
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
          Text(uiTr(context, 'أعلام الميزات'), style: theme.titleSmall),
          for (final e in flags.entries)
            Text('${e.key}=${e.value}', softWrap: true),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(uiTr(context, 'تحذيرات'), style: theme.titleSmall),
            for (final w in warnings) Text('• $w', softWrap: true),
          ],
          TextButton(
            onPressed: _busySafePing,
            child: Text(uiTr(context, 'إعادة الفحص')),
          ),
        ],
      ),
    );
  }

  void _busySafePing() {
    _ping();
  }
}
