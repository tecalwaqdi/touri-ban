import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_enterprise_kit.dart' hide showAdminConfirmDialog;
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_error_messages.dart';
import '/core/finance/admin_finance_ui_labels.dart';
import '/core/finance/finance_runtime_gate.dart';
import '/core/finance/finance_controls_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminFinancialPeriodsWidget extends StatefulWidget {
  const AdminFinancialPeriodsWidget({super.key});

  static const String routeName = 'AdminFinancialPeriods';
  static const String routePath = '/adminFinancialPeriods';

  @override
  State<AdminFinancialPeriodsWidget> createState() =>
      _AdminFinancialPeriodsWidgetState();
}

class _AdminFinancialPeriodsWidgetState
    extends State<AdminFinancialPeriodsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = TextEditingController(text: 'August 2026');
    final start = TextEditingController(text: '2026-08-01');
    final end = TextEditingController(text: '2026-09-01');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(ctx, 'فترة مالية')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: uiTr(context, 'الاسم'))),
            TextField(controller: start, decoration: InputDecoration(labelText: uiTr(context, 'البداية YYYY-MM-DD'))),
            TextField(controller: end, decoration: InputDecoration(labelText: uiTr(context, 'النهاية YYYY-MM-DD'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(uiTr(ctx, 'إلغاء'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(uiTr(ctx, 'إنشاء'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await FinanceControlsClient.createPeriod({
        'name': name.text.trim(),
        'countryRef': 'all',
        'currency': 'all',
        'startAt': DateTime.parse(start.text.trim()).toUtc().toIso8601String(),
        'endAt': DateTime.parse(end.text.trim()).toUtc().toIso8601String(),
      });
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snackError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(adminFriendlyError(context, e))),
    );
  }

  Future<void> _close(String id, Map<String, dynamic> data) async {
    if (!FinanceRuntimeGate.canAttemptFinanceWrites) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(
              context,
              'Financial data is approximate — financial writes unavailable',
            ),
          ),
        ),
      );
      return;
    }
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'قائمة إغلاق الفترة'),
      whatHappens: uiTr(
        context,
        'الإغلاق يمنع إضافة قيود مالية بأثر رجعي لهذه الفترة.',
      ),
      subject: '${data['name'] ?? id}',
      impact: uiTr(context, 'الفترات المغلقة تمنع إضافة قيود مالية بأثر رجعي.'),
      confirmLabel: uiTr(context, 'إغلاق'),
      destructive: true,
      irreversible: true,
      currency: '${data['currency'] ?? ''}',
      reference: id,
    );
    if (!confirmed || !mounted) return;

    final reason = TextEditingController();
    final override = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(ctx, 'Period Close Checklist')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason')),
            TextField(
              controller: override,
              decoration: const InputDecoration(
                labelText: 'Override reason (SuperAdmin, optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(uiTr(ctx, 'إلغاء'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(uiTr(ctx, 'Close'))),
        ],
      ),
    );
    final reasonText = reason.text.trim();
    final overrideText = override.text.trim();
    reason.dispose();
    override.dispose();
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final cl = await FinanceControlsClient.periodChecklist(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(uiTr(ctx, 'Period Close Checklist')),
          content: Text('${cl['items']}'),
        ),
      );
      await FinanceControlsClient.closePeriod({
        'periodId': id,
        'reason': reasonText,
        if (overrideText.isNotEmpty) 'override': true,
        if (overrideText.isNotEmpty) 'overrideReason': overrideText,
      });
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reopen(String id, Map<String, dynamic> data) async {
    if (!FinanceRuntimeGate.canAttemptFinanceWrites) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(
              context,
              'Financial data is approximate — financial writes unavailable',
            ),
          ),
        ),
      );
      return;
    }
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'إعادة فتح الفترة'),
      whatHappens: uiTr(
        context,
        'إعادة الفتح تسمح بالترحيل مجددًا. تتطلب سوبر أدمن وسببًا مسجّلًا.',
      ),
      subject: '${data['name'] ?? id}',
      impact: uiTr(context, 'يصبح الترحيل بأثر رجعي ممكنًا مجددًا'),
      confirmLabel: uiTr(context, 'إعادة فتح'),
      destructive: true,
      irreversible: false,
      currency: '${data['currency'] ?? ''}',
      reference: id,
    );
    if (!confirmed || !mounted) return;

    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(ctx, 'إعادة فتح الفترة')),
        content: TextField(controller: reason, decoration: InputDecoration(labelText: uiTr(ctx, 'السبب'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(uiTr(ctx, 'إلغاء'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(uiTr(ctx, 'إعادة فتح'))),
        ],
      ),
    );
    final reasonText = reason.text.trim();
    reason.dispose();
    if (ok != true || !mounted) return;
    try {
      await FinanceControlsClient.reopenPeriod({
        'periodId': id,
        'reason': reasonText,
      });
    } catch (e) {
      _snackError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'الفترات المالية'),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('financial_periods')
            .limit(200)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: AdminUi.pagePadding(context),
                child: Text(
                  uiTr(context, 'تعذر تحميل الفترات المالية'),
                  softWrap: true,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              Text(uiTr(context, 'الفترات المالية'), style: theme.headlineSmall),
          Text(
            uiTr(
              context,
              'الفترات المغلقة تمنع إضافة قيود مالية بأثر رجعي. إعادة فتح الفترة متاحة للسوبر أدمن فقط مع تسجيل السبب.',
            ),
            softWrap: true,
            style: theme.bodySmall,
          ),
              if (AdminRoleService.canWriteSettlements)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _busy ? null : _create,
                    child: Text(uiTr(context, '+ إنشاء فترة مالية')),
                  ),
                ),
              if (docs.isEmpty)
                AdminEmptyState(
                  title: uiTr(context, 'لا توجد فترات مالية حتى الآن'),
                  message: uiTr(
                    context,
                    'أنشئ فترة مالية لتنظيم القيود ومنع الترحيل بأثر رجعي بعد الإغلاق.',
                  ),
                  icon: Icons.date_range_outlined,
                ),
              for (final d in docs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${d.data()['name']} · ${AdminFinanceUiLabels.periodStatusAr('${d.data()['status']}')}',
                        softWrap: true,
                        style: theme.titleSmall,
                      ),
                      Text(
                        '${d.data()['currency']} · ${d.data()['startAt']} → ${d.data()['endAt']}',
                        softWrap: true,
                        style: theme.bodySmall,
                      ),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final dash =
                                  await FinanceControlsClient.periodDashboard(
                                      d.id);
                              if (!context.mounted) return;
                              showDialog<void>(
                                context: context,
                                builder: (ctx) {
                                  final maxW =
                                      MediaQuery.sizeOf(ctx).width - 48;
                                  return AlertDialog(
                                    title: Text(uiTr(ctx, 'لوحة الفترة')),
                                    content: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: maxW.clamp(280.0, 560.0),
                                        maxHeight:
                                            MediaQuery.sizeOf(ctx).height * 0.7,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Text('$dash', softWrap: true),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Text(uiTr(context, 'لوحة')),
                          ),
                          if (d.data()['status'] != 'closed')
                            TextButton(
                              onPressed:
                                  _busy ? null : () => _close(d.id, d.data()),
                              child: Text(uiTr(context, 'إغلاق')),
                            ),
                          if (d.data()['status'] == 'closed' &&
                              AdminRoleService.isSuperAdmin)
                            TextButton(
                              onPressed: () => _reopen(d.id, d.data()),
                              child: Text(uiTr(context, 'إعادة فتح')),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
