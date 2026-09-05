import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/admin_currency.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/admin_money_presentation.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact accountant summary from [AccountantFinanceReadModel] only.
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
    String money(amount) =>
        AdminOrderMoneyDisplay.formatMoneyAmount(amount, symbolOverride: sym);
    final incomplete = bundle.partialOrUnresolved;

    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'ملخص المحاسبة'),
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w700,
              color: AdminUi.brandTeal,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(context, 'الرحلات المكتملة', '${m.completedTripCount}'),
              _chip(
                context,
                'الموثقة ماليًا',
                '${m.completedTripsWithCompleteFinancialData}',
              ),
              _chip(
                context,
                'بيانات مالية ناقصة',
                '$incomplete',
                warn: incomplete > 0,
              ),
              _chip(context, 'القيمة المالية الموثقة', money(m.completedGross)),
              _chip(context, 'المحصّل', money(m.collectedAmount)),
              _chip(context, 'غير المحصّل', money(m.uncollectedAmount)),
              _chip(context, 'عمولة الشركة', money(m.companyCommission)),
              _chip(context, 'الضريبة', money(m.vat)),
              _chip(context, 'صافي السائقين', money(m.driverNet)),
              _chip(context, 'المستحق للشركة', money(m.companyReceivable)),
              _chip(context, 'المستحق للسائقين', money(m.driverPayable)),
              _chip(
                context,
                'تسويات غير مسددة',
                '${bundle.openSettlementsRemaining}',
              ),
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
    bool warn = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warn
            ? theme.warning.withValues(alpha: 0.12)
            : AdminUi.brandTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(
          color: warn
              ? theme.warning.withValues(alpha: 0.35)
              : AdminUi.brandTeal.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            uiTr(context, label),
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w700,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
        ],
      ),
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
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w700,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(height: 8),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: theme.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(uiTr(context, a), style: theme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
