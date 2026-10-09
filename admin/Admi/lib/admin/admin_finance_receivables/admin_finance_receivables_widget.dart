import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/finance_home_overview_cards.dart';
import '/components/menu2_model.dart';
import '/core/admin_error_messages.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_arap_loader.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Canonical Receivables & Payables — trip unsettled + settlement outstanding.
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
  Future<FinanceArapSnapshot>? _future;
  bool _busy = false;
  AdminDatePreset _preset = AdminDatePreset.thisMonth;

  static const _presetLabels = <AdminDatePreset, String>{
    AdminDatePreset.today: 'اليوم',
    AdminDatePreset.yesterday: 'أمس',
    AdminDatePreset.last7Days: 'آخر 7 أيام',
    AdminDatePreset.thisMonth: 'هذا الشهر',
    AdminDatePreset.last30Days: 'آخر 30 يومًا',
    AdminDatePreset.lastMonth: 'الشهر السابق',
    AdminDatePreset.thisYear: 'هذه السنة',
  };

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
      _future = FinanceArapLoader.load(datePreset: _preset);
    });
  }

  String _m(int? minor, String currency) {
    if (minor == null) return '—';
    return AdminOrderMoneyDisplay.formatMoneyAmount(
      MoneyAmount(currency: currency, minorUnits: minor),
    );
  }

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
      _reload();
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
      child: FutureBuilder<FinanceArapSnapshot>(
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
          final data = snap.data!;
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              AdminPageHeader(
                title: uiTr(context, 'الذمم المدينة والدائنة'),
                subtitle: uiTr(
                  context,
                  'ما على المندوب للشركة هو النقد المحصّل ولم يُسوَّ بعد. ما على الشركة للمندوب هو الأجرة الإلكترونية المدفوعة ولم تُسوَّ بعد. رصيد المحفظة ليس هذا الرقم.',
                ),
              ),
              if (!AdminRoleService.canWriteSettlements)
                const FinanceWritesDisabledBanner(),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DropdownButton<AdminDatePreset>(
                  value: _preset,
                  items: [
                    for (final e in _presetLabels.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Text(uiTr(context, e.value)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _preset = v);
                    _reload();
                  },
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              AdminContentCard(
                title: uiTr(context, 'حالات التسوية'),
                child: Builder(
                  builder: (context) {
                    final shown = FinanceSettlementLifecycle.values
                        .where((s) => (data.settlementsByStatus[s] ?? 0) > 0)
                        .toList();
                    if (shown.isEmpty) {
                      return Text(
                        uiTr(context, 'لا تسويات مسجّلة'),
                        style: theme.bodySmall,
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in shown)
                          Chip(
                            label: Text(
                              '${s.labelAr}: ${data.settlementsByStatus[s]}',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              AdminContentCard(
                title: uiTr(context, 'على المندوب للشركة'),
                child: _tripList(
                  theme,
                  data.tripCompanyReceivables,
                  empty: 'لا ذمم مدينة على مستوى الرحلة',
                ),
              ),
              const SizedBox(height: 12),
              AdminContentCard(
                title: uiTr(context, 'على الشركة للمندوب'),
                child: _tripList(
                  theme,
                  data.tripDriverPayables,
                  empty: 'لا ذمم دائنة على مستوى الرحلة',
                ),
              ),
              const SizedBox(height: 12),
              AdminContentCard(
                title: uiTr(context, 'تسويات لم يُغلق فيها ما على المندوب'),
                child: _settlementList(
                  theme,
                  data.companyReceivableSettlements
                      .where(
                        (r) => r.status != FinanceSettlementLifecycle.settled,
                      )
                      .toList(),
                  empty: 'لا تسويات مدينة مفتوحة',
                ),
              ),
              const SizedBox(height: 12),
              AdminContentCard(
                title: uiTr(context, 'تسويات لم يُغلق فيها ما على الشركة'),
                child: _settlementList(
                  theme,
                  data.driverPayableSettlements
                      .where(
                        (r) => r.status != FinanceSettlementLifecycle.settled,
                      )
                      .toList(),
                  empty: 'لا تسويات دائنة مفتوحة',
                ),
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
                        'طلبات مكتملة بـ pending_cash. التأكيد من اللوحة استثنائي.',
                      ),
                      style: theme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final country = AdminCountryScope.activeCountryRef ??
                            (AdminRoleService.usesCountryFinanceScope
                                ? AdminRoleService.scopedCountryRef
                                : null);
                        if (AdminRoleService.usesCountryFinanceScope &&
                            country == null) {
                          return Text(
                            uiTr(
                              context,
                              'نطاق الدولة مطلوب لعرض الذمم النقدية',
                            ),
                            style: theme.bodySmall,
                          );
                        }
                        Query<Map<String, dynamic>> q = FirebaseFirestore
                            .instance
                            .collection('order')
                            .where('payment_status',
                                isEqualTo: 'pending_cash');
                        if (country != null) {
                          q = q.where('Rev_dolh', isEqualTo: country);
                        }
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: q.limit(50).snapshots(),
                          builder: (context, cashSnap) {
                            if (!cashSnap.hasData) {
                              return const LinearProgressIndicator(
                                  minHeight: 2);
                            }
                            final docs = cashSnap.data!.docs.where((d) {
                              final data = d.data();
                              if (AdminQaFixture.isFixtureMap(
                                data,
                                orderId: d.id,
                              )) {
                                return false;
                              }
                              final code =
                                  '${data['status_code'] ?? ''}'.toLowerCase();
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
                                    title: Text(uiTr(context, 'نقد بانتظار التأكيد')),
                                    subtitle: Text(
                                      '${d.data()['total'] ?? '—'}',
                                    ),
                                    trailing:
                                        AdminRoleService.canWriteSettlements
                                            ? TextButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () =>
                                                        _adminConfirmCash(d.id),
                                                child: Text(
                                                    uiTr(context, 'تأكيد')),
                                              )
                                            : null,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pushNamed(
                  AdminSettlementsWidget.routeName,
                ),
                child: Text(uiTr(context, 'فتح التسويات')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tripList(
    FlutterFlowTheme theme,
    List trips, {
    required String empty,
  }) {
    if (trips.isEmpty) {
      return Text(uiTr(context, empty), style: theme.bodySmall);
    }
    return Column(
      children: [
        for (final r in trips.take(80))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              r.driverLabel.trim().isEmpty
                  ? r.tripRefLabel
                  : r.driverLabel,
            ),
            subtitle: Text(
              '${r.paymentChannelLabel} · ${r.settlementStatusLabel} · ${r.currency}',
            ),
            trailing: Text(r.obligationDisplay),
          ),
      ],
    );
  }

  Widget _settlementList(
    FlutterFlowTheme theme,
    List<FinanceSettlementOutstandingRow> rows, {
    required String empty,
  }) {
    if (rows.isEmpty) {
      return Text(uiTr(context, empty), style: theme.bodySmall);
    }
    return Column(
      children: [
        for (final r in rows.take(80))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(r.status.labelAr),
            subtitle: Text(r.currency),
            trailing: Text(
              _m(r.outstandingMinor ?? r.netMinor, r.currency),
            ),
            onTap: () => context.pushNamed(
              AdminSettlementDetailsWidget.routeName,
              queryParameters: {'settlementId': r.settlementId},
            ),
          ),
      ],
    );
  }
}
