import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_currency.dart';
import '/core/finance/admin_finance_canonical_ui.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_cash_online_summary.dart';
import '/core/finance/finance_company_service.dart';
import '/core/finance/financial_accounting_unavailable.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// FIN-5 — Cash / Online operational accounting (read-only).
class AdminFinanceChannelsWidget extends StatefulWidget {
  const AdminFinanceChannelsWidget({super.key});

  static const String routeName = 'AdminFinanceChannels';
  static const String routePath = '/adminFinanceChannels';

  @override
  State<AdminFinanceChannelsWidget> createState() =>
      _AdminFinanceChannelsWidgetState();
}

class _AdminFinanceChannelsWidgetState extends State<AdminFinanceChannelsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  AdminDatePreset _preset = AdminDatePreset.all;
  Future<FinanceCashOnlineSummary>? _future;

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
      _future = FinanceCompanyService.loadFull(
        datePreset: _preset,
        periodLabel: 'الكل',
      ).then((r) => r.channels);
    });
  }

  String _m(MoneyAmount? m, String symbol) =>
      AdminOrderMoneyDisplay.formatMoneyAmount(m, symbolOverride: symbol);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'النقدي / الإلكتروني'),
      child: FutureBuilder<FinanceCashOnlineSummary>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError &&
              snap.error is FinancialAccountingUnavailableException) {
            return AdminFinanceCanonicalUnavailablePanel(onRetry: _reload);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          final sym =
              AdminCurrency.symbolByCode[d.currency] ?? d.currency;
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              AdminPageHeader(
                title: uiTr(context, 'محاسبة النقدي والإلكتروني'),
                subtitle: uiTr(
                  context,
                  'عرض تشغيلي — المرحلة C معطّلة؛ التحصيل اليدوي لا يُنشئ إيرادًا حتى الإثبات.',
                ),
              ),
              const SizedBox(height: 12),
              AdminContentCard(
                title: uiTr(context, 'النقدي'),
                child: _rows(theme, [
                  (uiTr(context, 'مكتملة — بانتظار التحصيل'),
                      '${d.cashCompletedPending} · ${_m(d.cashCompletedPendingValue, sym)}'),
                  (uiTr(context, 'مكتملة — محصّلة'),
                      '${d.cashCollectedTrips} · ${_m(d.cashCollectedValue, sym)}'),
                  (uiTr(context, 'نقد مع المندوب'),
                      _m(d.cashHeldByDrivers, sym)),
                  (uiTr(context, 'مستحق للشركة من المندوب'),
                      _m(d.companyDueFromDrivers, sym)),
                  (uiTr(context, 'المسدّد'), '${d.settledCompanyDueMinor}'),
                  (uiTr(context, 'المتبقي'),
                      _m(d.outstandingCompanyDue, sym)),
                ]),
              ),
              const SizedBox(height: 12),
              AdminContentCard(
                title: uiTr(context, 'الإلكتروني'),
                child: _rows(theme, [
                  (uiTr(context, 'مكتملة — مدفوعة'),
                      '${d.onlineCompletedPaid}'),
                  (uiTr(context, 'مكتملة — غير مدفوعة'),
                      '${d.onlineCompletedUnpaid}'),
                  (uiTr(context, 'ملغاة — مدفوعة'),
                      '${d.onlineCancelledPaid}'),
                  (uiTr(context, 'استرداد قيد المعالجة'),
                      '${d.refundPendingCount}'),
                  (uiTr(context, 'مسترد'), '${d.refundedCount}'),
                  (uiTr(context, 'محجوز'), '${d.capturedCount}'),
                  (uiTr(context, 'مستحق للمندوب'),
                      _m(d.driverPayable, sym)),
                  (uiTr(context, 'مدفوع للمندوب'),
                      _m(d.paidToDriver, sym)),
                  (uiTr(context, 'المتبقي للمندوب'),
                      _m(d.outstandingToDriver, sym)),
                ]),
              ),
              const SizedBox(height: 12),
              AdminContentCard(
                title: uiTr(context, 'ملغاة — بيانات دفع قديمة'),
                child: Text(
                  '${uiTr(context, 'ملغاة مع pending_cash قديم (غير قابلة للفوترة)')}: '
                  '${d.cancelledStalePendingCash}',
                  style: theme.bodyMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _rows(
    FlutterFlowTheme theme,
    List<(String, String)> rows,
  ) {
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(r.$1, style: theme.bodyMedium)),
                Text(
                  r.$2,
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
