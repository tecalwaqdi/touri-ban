import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart' show AdminEmptyState;
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/admin_finance_ui_labels.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/financial_state_labels.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminReconciliationWidget extends StatefulWidget {
  const AdminReconciliationWidget({super.key});

  static const String routeName = 'AdminReconciliation';
  static const String routePath = '/adminReconciliation';

  @override
  State<AdminReconciliationWidget> createState() =>
      _AdminReconciliationWidgetState();
}

class _AdminReconciliationWidgetState extends State<AdminReconciliationWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _future = FinanceControlsClient.scanExceptions();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Color _tone(String severity, FlutterFlowTheme theme) {
    switch (severity) {
      case 'critical':
        return theme.error;
      case 'high':
        return Colors.orange.shade800;
      case 'medium':
        return AdminUi.brandTeal;
      default:
        return theme.secondaryText;
    }
  }

  String _whyItMatters(String code) {
    switch (code) {
      case 'MISSING_DRIVER':
        return 'رحلة مكتملة بدون مندوب معيّن — جودة بيانات تشغيلية.';
      case 'UNALLOCATED_PAYMENT':
        return 'دفعة شركة قديمة غير مربوطة بتسوية — سجل تاريخي للمراجعة.';
      case 'INCOMPLETE_FINANCIAL_RECORD':
        return 'حقول مالية ناقصة تمنع الاعتماد المحاسبي الكامل.';
      case 'ORPHAN_CLAIM':
        return 'مطالبة تسوية بلا تسوية صالحة.';
      default:
        return 'يحتاج مراجعة محاسبية قبل إغلاق الفترة عند اللزوم.';
    }
  }

  Future<void> _openIncomplete() async {
    final data = await FinanceControlsClient.listIncomplete();
    if (!mounted) return;
    final orders = (data['orders'] as List?) ?? [];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${uiTr(ctx, 'سجلات ناقصة')}: ${data['count']}',
                  style: FlutterFlowTheme.of(ctx).titleMedium,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final o = Map<String, dynamic>.from(orders[i] as Map);
                    final missing = (o['missingFields'] as List?) ?? [];
                    return ListTile(
                      title: Text('${o['orderId']}', softWrap: true),
                      subtitle: Text(
                        '${FinancialStateLabels.exceptionCodeAr('${o['reason']}')} · '
                        '${o['currency']} · '
                        '${uiTr(ctx, 'المندوب')}: ${o['driverId'] ?? '—'} · '
                        '${o['paymentMethod']} · ${o['lifecycle']}\n'
                        '${uiTr(ctx, 'الحقول الناقصة')}: ${missing.join(', ')}\n'
                        '${uiTr(ctx, 'يمنع التسوية')}: ${o['blocksSettlement'] == true ? uiTr(ctx, 'نعم') : uiTr(ctx, 'لا')}',
                        softWrap: true,
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSample(String label, List sample) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final maxW = MediaQuery.sizeOf(ctx).width - 48;
        return AlertDialog(
          title: Text(label),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW.clamp(280.0, 520.0),
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Text(
                sample
                    .map((e) => e is Map
                        ? (e['orderId'] ??
                                e['settlementCode'] ??
                                e['paymentId'] ??
                                e.toString())
                            .toString()
                        : e.toString())
                    .join('\n'),
                softWrap: true,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'المطابقة المالية'),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data!['items'] as List?) ?? [];
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              Text(
                uiTr(context, 'مركز مراجعة المحاسب'),
                style: theme.headlineSmall,
                softWrap: true,
              ),
              Text(
                uiTr(
                  context,
                  'عرض للقراءة فقط — لا يتم تعديل الطلبات من هذه الصفحة.',
                ),
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                AdminEmptyState(
                  title: uiTr(context, 'لا توجد استثناءات'),
                  message: uiTr(
                    context,
                    'لا توجد مشاكل مفتوحة في المطابقة المالية حالياً.',
                  ),
                  icon: Icons.verified_outlined,
                ),
              for (final raw in items)
                Builder(
                  builder: (context) {
                    final it = Map<String, dynamic>.from(raw as Map);
                    final code = '${it['code']}';
                    final label = FinancialStateLabels.exceptionCodeAr(code);
                    final severityRaw = '${it['severity']}';
                    final severity =
                        AdminFinanceUiLabels.severityAr(severityRaw);
                    final count = it['count'] ?? 0;
                    final blocks = it['blocksClose'] == true;
                    final sample = (it['sample'] as List?) ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AdminUi.radiusMd),
                          onTap: code == 'INCOMPLETE_FINANCIAL_RECORD'
                              ? _openIncomplete
                              : () => _openSample(label, sample),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: _tone(severityRaw, theme),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: theme.titleSmall,
                                        softWrap: true,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _tone(severityRaw, theme)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        severity,
                                        style: theme.labelSmall.copyWith(
                                          color: _tone(severityRaw, theme),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${uiTr(context, 'العدد')}: $count',
                                  style: theme.bodyMedium,
                                ),
                                Text(
                                  _whyItMatters(code),
                                  style: theme.bodySmall.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  blocks
                                      ? uiTr(context, 'يمنع إغلاق الفترة: نعم')
                                      : uiTr(
                                          context,
                                          'يمنع إغلاق الفترة: لا',
                                        ),
                                  style: theme.labelMedium.copyWith(
                                    color: blocks
                                        ? theme.error
                                        : AdminUi.brandTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton(
                                    onPressed:
                                        code == 'INCOMPLETE_FINANCIAL_RECORD'
                                            ? _openIncomplete
                                            : () => _openSample(label, sample),
                                    child: Text(uiTr(context, 'عرض الحالات')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (AdminRoleService.canWriteSettlements) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final o = await FinanceControlsClient.detectOrphans();
                    if (!context.mounted) return;
                    final items = (o['items'] as List?) ?? [];
                    showDialog<void>(
                      context: context,
                      builder: (ctx) {
                        final maxW = MediaQuery.sizeOf(ctx).width - 48;
                        return AlertDialog(
                          title: Text(AdminFinanceUiLabels.orphanDetectionAr()),
                          content: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxW.clamp(280.0, 480.0),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                '${uiTr(ctx, 'تقرير فقط — بدون إصلاح تلقائي.')}\n'
                                '${items.map((e) => e is Map ? '${FinancialStateLabels.exceptionCodeAr('${e['code']}')}: ${e['count']}' : e).join('\n')}',
                                softWrap: true,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(AdminFinanceUiLabels.orphanReportAr()),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
