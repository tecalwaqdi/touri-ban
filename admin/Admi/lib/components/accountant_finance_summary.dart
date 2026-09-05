import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/admin_currency.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact accountant summary — primary vs secondary emphasis (F2.1).
class AccountantFinanceSummaryStrip extends StatelessWidget {
  const AccountantFinanceSummaryStrip({
    super.key,
    required this.bundle,
  });

  final AccountantFinanceViewBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final m = bundle.model;
    final sym = AdminCurrency.symbolByCode[bundle.currency] ?? bundle.currency;
    String money(MoneyAmount amount) {
      // Real zero is valid for COMPLETE empty sums; never fabricate missing.
      if (m.completedTripsWithCompleteFinancialData == 0 &&
          amount.minorUnits == 0) {
        return m.completedTripCount == 0
            ? AccountantFinanceTextMoney.zeroOrDash(
                amount,
                sym,
                hasActivity: false,
              )
            : '—';
      }
      return AdminOrderMoneyDisplay.formatMoneyAmount(
        amount,
        symbolOverride: sym,
      );
    }

    final incomplete = bundle.partialOrUnresolved;

    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'ملخص المحاسبة'),
            style: AccountantFinanceText.sectionTitle(theme),
          ),
          const SizedBox(height: 6),
          Text(
            uiTr(
              context,
              'رحلات مكتملة: ${m.completedTripCount} · موثقة ماليًا: ${m.completedTripsWithCompleteFinancialData} · بيانات ناقصة: $incomplete',
            ),
            style: AccountantFinanceText.label(theme),
          ),
          if (incomplete > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.warning.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.warning.withValues(alpha: 0.5)),
              ),
              child: Text(
                uiTr(context, 'رحلات ببيانات مالية ناقصة: $incomplete'),
                style: AccountantFinanceText.body(theme).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (bundle.openSettlementsRemaining > 0) ...[
            const SizedBox(height: 6),
            Text(
              uiTr(
                context,
                'تسويات غير مسددة: ${bundle.openSettlementsRemaining}',
              ),
              style: AccountantFinanceText.label(theme),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            uiTr(context, 'أساسي'),
            style: AccountantFinanceText.label(theme),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(context, 'الرحلات المكتملة', '${m.completedTripCount}',
                  primary: true),
              _chip(
                context,
                'القيمة المالية الموثقة',
                money(m.completedGross),
                primary: true,
              ),
              _chip(context, 'المحصّل', money(m.collectedAmount), primary: true),
              _chip(
                context,
                'غير المحصّل',
                money(m.uncollectedAmount),
                primary: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            uiTr(context, 'تفصيلي'),
            style: AccountantFinanceText.label(theme),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(context, 'عمولة الشركة', money(m.companyCommission)),
              _chip(context, 'الضريبة', money(m.vat)),
              _chip(context, 'صافي السائقين', money(m.driverNet)),
              _chip(context, 'المستحق للشركة', money(m.companyReceivable)),
              _chip(context, 'المستحق للسائقين', money(m.driverPayable)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    String value, {
    bool primary = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: BoxConstraints(
        minWidth: primary ? 160 : 140,
        maxWidth: primary ? 260 : 220,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: primary ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: primary
            ? AdminUi.brandTeal.withValues(alpha: 0.10)
            : theme.primaryBackground,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(
          color: AdminUi.brandTeal.withValues(alpha: primary ? 0.35 : 0.16),
          width: primary ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(uiTr(context, label), style: AccountantFinanceText.label(theme)),
          const SizedBox(height: 4),
          Text(
            value,
            style: primary
                ? AccountantFinanceText.money(theme)
                : AccountantFinanceText.body(theme).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
          ),
        ],
      ),
    );
  }
}

abstract final class AccountantFinanceTextMoney {
  static String zeroOrDash(
    MoneyAmount amount,
    String sym, {
    required bool hasActivity,
  }) {
    if (!hasActivity) return '—';
    return AdminOrderMoneyDisplay.formatMoneyAmount(
      amount,
      symbolOverride: sym,
    );
  }
}

class AccountantFinanceAlertsBanner extends StatelessWidget {
  const AccountantFinanceAlertsBanner({
    super.key,
    required this.alerts,
  });

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);
    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'تنبيهات محاسبية'),
            style: AccountantFinanceText.sectionTitle(theme),
          ),
          const SizedBox(height: 8),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AdminUi.brandTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      uiTr(context, a),
                      style: AccountantFinanceText.body(theme),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
