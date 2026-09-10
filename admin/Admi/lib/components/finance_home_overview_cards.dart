import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/admin_currency.dart';
import '/core/admin_design/admin_design.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Cash/online + open settlements cards for Finance Home (V2 snapshot only).
class FinanceHomeOverviewCards extends StatelessWidget {
  const FinanceHomeOverviewCards({
    super.key,
    required this.snapshot,
  });

  final FinanceCompanySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final sym =
        AdminCurrency.symbolByCode[snapshot.currency] ?? snapshot.currency;

    String money(MoneyAmount m) => AdminOrderMoneyDisplay.formatMoneyAmount(
          m,
          symbolOverride: sym,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdminContentCard(
                title: uiTr(context, 'نقدي'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kv(
                      theme,
                      uiTr(context, 'بانتظار التحصيل'),
                      '${snapshot.cashCompletedPending} · ${money(snapshot.cashCompletedPendingValue)}',
                    ),
                    _kv(
                      theme,
                      uiTr(context, 'محصّل'),
                      '${snapshot.cashCollectedTrips} · ${money(snapshot.cashCollectedValue)}',
                    ),
                    _kv(
                      theme,
                      uiTr(context, 'مستحق للشركة'),
                      money(snapshot.companyReceivable),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminContentCard(
                title: uiTr(context, 'إلكتروني'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kv(
                      theme,
                      uiTr(context, 'مدفوع'),
                      '${snapshot.onlinePaidTrips} · ${money(snapshot.onlinePaidValue)}',
                    ),
                    _kv(
                      theme,
                      uiTr(context, 'بانتظار الدفع'),
                      '${snapshot.onlineCompletedPending} · ${money(snapshot.onlineCompletedPendingValue)}',
                    ),
                    _kv(
                      theme,
                      uiTr(context, 'مستحق للسائقين'),
                      money(snapshot.companyPayable),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AdminContentCard(
          title: uiTr(context, 'التسويات المفتوحة'),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _chip(
                context,
                uiTr(context, 'مسددة'),
                '${snapshot.settledCount}',
              ),
              _chip(
                context,
                uiTr(context, 'غير مسددة'),
                '${snapshot.pendingSettlementCount}',
              ),
              _chip(
                context,
                uiTr(context, 'المتبقي'),
                money(
                  MoneyAmount(
                    currency: snapshot.currency,
                    minorUnits: snapshot.outstandingSettlementMinor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(FlutterFlowTheme theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: AccountantFinanceText.label(theme))),
          Text(
            v,
            style: AccountantFinanceText.body(theme).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSecondaryOf(context),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: AdminColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AccountantFinanceText.label(theme)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AccountantFinanceText.money(theme).copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

/// Banner when finance write flags / Super Admin write gate is off.
class FinanceWritesDisabledBanner extends StatelessWidget {
  const FinanceWritesDisabledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.warningBg.withValues(
          alpha: AdminColors.isDark(context) ? 0.25 : 1,
        ),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: AdminColors.borderOf(context)),
      ),
      child: Text(
        uiTr(context, 'غير مفعّل حاليًا'),
        style: AccountantFinanceText.body(theme).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
