import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/admin_currency.dart';
import '/core/admin_design/admin_design.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact accountant summary — primary vs secondary emphasis (F2.1 / UI V2.1).
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (incomplete > 0) ...[
          _IncompleteWarningBanner(count: incomplete),
          const SizedBox(height: 12),
        ],
        AdminContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                uiTr(context, 'ملخص المحاسبة'),
                style: AccountantFinanceText.sectionTitle(theme),
              ),
              const SizedBox(height: 4),
              Text(
                uiTr(
                  context,
                  'رحلات مكتملة: ${m.completedTripCount} · موثقة ماليًا: ${m.completedTripsWithCompleteFinancialData} · بيانات ناقصة: $incomplete',
                ),
                style: AccountantFinanceText.label(theme),
              ),
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
                style: AccountantFinanceText.label(theme).copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                  _chip(context, 'المحصّل', money(m.collectedAmount),
                      primary: true),
                  _chip(
                    context,
                    'غير المحصّل',
                    money(m.uncollectedAmount),
                    primary: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                uiTr(context, 'تفصيلي'),
                style: AccountantFinanceText.label(theme).copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    String value, {
    bool primary = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = AdminColors.isDark(context);
    return Container(
      constraints: BoxConstraints(
        minWidth: primary ? 148 : 132,
        maxWidth: primary ? 240 : 200,
        minHeight: 90,
        maxHeight: 110,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primary
            ? (isDark
                ? AdminColors.primary700.withValues(alpha: 0.18)
                : AdminColors.primary50)
            : AdminColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(
          color: primary
              ? AdminColors.primary100.withValues(alpha: isDark ? 0.35 : 1)
              : AdminColors.borderOf(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            uiTr(context, label),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AccountantFinanceText.label(theme).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AccountantFinanceText.money(theme).copyWith(
              fontSize: primary ? 24 : 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncompleteWarningBanner extends StatelessWidget {
  const _IncompleteWarningBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.warningBg.withValues(
          alpha: AdminColors.isDark(context) ? 0.18 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: theme.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  uiTr(context, 'بيانات مالية ناقصة'),
                  style: AccountantFinanceText.body(theme).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  uiTr(context, '$count رحلة تحتاج مراجعة'),
                  style: AccountantFinanceText.label(theme).copyWith(
                    fontSize: 12,
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
          const SizedBox(height: 6),
          for (var i = 0; i < alerts.length; i++) ...[
            if (i > 0)
              Divider(
                height: 16,
                color: AdminColors.borderOf(context),
              ),
            _AlertRow(raw: alerts[i]),
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.raw});

  final String raw;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final parsed = _parseAlert(raw);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 18, color: theme.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      uiTr(context, parsed.title),
                      style: AccountantFinanceText.body(theme).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (parsed.count != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.warning.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${parsed.count}',
                        style: AccountantFinanceText.label(theme).copyWith(
                          color: AccountantFinanceText.ink(theme),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              if (parsed.detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  uiTr(context, parsed.detail!),
                  style: AccountantFinanceText.label(theme).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static ({String title, String? detail, int? count}) _parseAlert(String raw) {
    final countMatch = RegExp(r'^(\d+)\s+(.+)$').firstMatch(raw.trim());
    if (countMatch != null) {
      final count = int.tryParse(countMatch.group(1)!);
      final rest = countMatch.group(2)!.trim();
      return (
        title: rest,
        detail: 'يحتاج مراجعة محاسبية',
        count: count,
      );
    }
    return (title: raw, detail: null, count: null);
  }
}
