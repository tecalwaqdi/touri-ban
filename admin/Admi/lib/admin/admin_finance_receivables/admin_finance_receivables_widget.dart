import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_error_messages.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// FIN-8 — Company receivables / payables + admin cash exception confirm.
class AdminFinanceReceivablesWidget extends StatefulWidget {
  const AdminFinanceReceivablesWidget({super.key});

  static const String routeName = 'AdminFinanceReceivables';
  static const String routePath = '/adminFinanceReceivables';

  @override
  State<AdminFinanceReceivablesWidget> createState() =>
      _AdminFinanceReceivablesWidgetState();
}

class _AdminFinanceReceivablesWidgetState
    extends State<AdminFinanceReceivablesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  Future<Map<String, dynamic>>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _reload();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = CloudFunctionsClient.aggregateSettlementExposureV2();
    });
  }

  String _m(int minor, String currency) =>
      AdminOrderMoneyDisplay.formatMoneyAmount(
        MoneyAmount(currency: currency, minorUnits: minor),
      );

  Future<void> _adminConfirmCash(String orderId) async {
    if (!AdminRoleService.canWriteSettlements) return;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(ctx, 'تأكيد تحصيل نقدي استثنائي')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              uiTr(
                ctx,
                'المسار الأساسي هو تأكيد السائق. استخدم هذا للإغلاق اليدوي للحالات العالقة فقط.',
              ),
            ),
            const SizedBox(height: 8),
            Text('order/$orderId'),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(labelText: uiTr(ctx, 'السبب')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(uiTr(ctx, 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(uiTr(ctx, 'تأكيد')),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (ok != true || reason.length < 3 || !mounted) return;
    setState(() => _busy = true);
    try {
      await FinanceControlsClient.adminConfirmCashCollection(
        orderId: orderId,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تم تأكيد التحصيل'))),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminFriendlyError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'الذمم المالية'),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return AdminEmptyState(
              title: uiTr(context, 'تعذر التحميل'),
              message: adminFriendlyError(context, snap.error!),
              icon: Icons.error_outline,
              action: AdminPrimaryButton(
                label: uiTr(context, 'إعادة المحاولة'),
                onPressed: _reload,
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final raw = snap.data!['byCurrency'];
          final by =
              raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              AdminPageHeader(
                title: uiTr(context, 'ذمم مستحقة للشركة / على الشركة'),
                subtitle: uiTr(
                  context,
                  'مصدر الخادم — التسويات المقفلة والمدفوعة جزئيًا فقط.',
                ),
              ),
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              for (final e in by.entries) ...[
                AdminContentCard(
                  title: e.key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _row(
                        theme,
                        uiTr(context, 'مستحق للشركة (ذمم مدينة)'),
                        _m(
                          (e.value['receivablesOutstandingMinor'] as num?)
                                  ?.toInt() ??
                              0,
                          e.key,
                        ),
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مستحق على الشركة (ذمم دائنة)'),
                        _m(
                          (e.value['payablesOutstandingMinor'] as num?)
                                  ?.toInt() ??
                              0,
                          e.key,
                        ),
                      ),
                      _row(
                        theme,
                        uiTr(context, 'المحصّل'),
                        _m(
                          (e.value['collectedMinor'] as num?)?.toInt() ?? 0,
                          e.key,
                        ),
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مسدد'),
                        '${e.value['settledCount'] ?? 0}',
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مدفوع جزئيًا'),
                        '${e.value['partiallyPaidCount'] ?? 0}',
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مقفل'),
                        '${e.value['lockedCount'] ?? 0}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (by.isEmpty)
                AdminEmptyState(
                  title: uiTr(context, 'لا توجد تسويات نشطة'),
                  message: uiTr(context, 'لا ذمم مفتوحة بعد'),
                  icon: Icons.account_balance_outlined,
                ),
              const SizedBox(height: 16),
              AdminContentCard(
                title: uiTr(context, 'نقد عالق — تأكيد استثنائي'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      uiTr(
                        context,
                        'طلبات مكتملة بـ pending_cash. التأكيد من اللوحة استثنائي (يتطلب علم التحصيل V2).',
                      ),
                      style: theme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('order')
                          .where('payment_status', isEqualTo: 'pending_cash')
                          .limit(30)
                          .snapshots(),
                      builder: (context, cashSnap) {
                        if (!cashSnap.hasData) {
                          return const LinearProgressIndicator(minHeight: 2);
                        }
                        final docs = cashSnap.data!.docs.where((d) {
                          final code =
                              '${d.data()['status_code'] ?? ''}'.toLowerCase();
                          return code == 'completed' ||
                              code == 'trip_completed';
                        }).toList();
                        if (docs.isEmpty) {
                          return Text(
                            uiTr(context, 'لا توجد حالات عالقة ظاهرة'),
                            style: theme.bodySmall,
                          );
                        }
                        return Column(
                          children: [
                            for (final d in docs)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(d.id),
                                subtitle: Text(
                                  '${d.data()['PaymentMethod'] ?? ''} · '
                                  '${d.data()['total'] ?? ''}',
                                ),
                                trailing: AdminRoleService.canWriteSettlements
                                    ? TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _adminConfirmCash(d.id),
                                        child: Text(uiTr(context, 'تأكيد')),
                                      )
                                    : null,
                              ),
                          ],
                        );
                      },
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

  Widget _row(FlutterFlowTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.bodyMedium)),
          Text(value, style: theme.titleSmall),
        ],
      ),
    );
  }
}
