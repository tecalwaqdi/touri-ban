import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact FIN-2 KPI groups A–F (Arabic, no giant cards).
class AdminFinanceKpiGroups extends StatelessWidget {
  const AdminFinanceKpiGroups({
    super.key,
    required this.snapshot,
    required this.symbol,
  });

  final FinanceCompanySnapshot snapshot;
  final String symbol;

  String _m(MoneyAmount? m) =>
      AdminOrderMoneyDisplay.formatMoneyAmount(m, symbolOverride: symbol);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _group(
          context,
          theme,
          uiTr(context, 'النشاط'),
          [
            _Metric(uiTr(context, 'إجمالي الرحلات'), '${snapshot.totalTrips}'),
            _Metric(uiTr(context, 'المكتملة'), '${snapshot.completedTrips}'),
            _Metric(uiTr(context, 'الملغاة'), '${snapshot.cancelledTrips}'),
            _Metric(
              uiTr(context, 'غير المكتملة ماليًا'),
              '${snapshot.financiallyIncomplete}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _group(
          context,
          theme,
          uiTr(context, 'المبيعات'),
          [
            _Metric(
              uiTr(context, 'إجمالي قيمة الرحلات المكتملة'),
              _m(snapshot.completedTripValue),
            ),
            _Metric(
              uiTr(context, 'محصّل'),
              _m(snapshot.collectedTripValue),
            ),
            _Metric(
              uiTr(context, 'غير محصّل'),
              _m(snapshot.unCollectedTripValue),
            ),
            _Metric(
              uiTr(context, 'الإيراد المحقق'),
              _m(snapshot.realizedRevenue),
              highlight: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _group(
          context,
          theme,
          uiTr(context, 'قنوات الدفع'),
          [
            _Metric(
              uiTr(context, 'نقدي — بانتظار التحصيل'),
              '${snapshot.cashCompletedPending} · ${_m(snapshot.cashCompletedPendingValue)}',
            ),
            _Metric(
              uiTr(context, 'نقدي — محصّل'),
              '${snapshot.cashCollectedTrips} · ${_m(snapshot.cashCollectedValue)}',
            ),
            _Metric(
              uiTr(context, 'إلكتروني — بانتظار'),
              '${snapshot.onlineCompletedPending} · ${_m(snapshot.onlineCompletedPendingValue)}',
            ),
            _Metric(
              uiTr(context, 'إلكتروني — مدفوع'),
              '${snapshot.onlinePaidTrips} · ${_m(snapshot.onlinePaidValue)}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _group(
          context,
          theme,
          uiTr(context, 'التوزيع'),
          [
            _Metric(
              uiTr(context, 'عمولة المنصة (محققة)'),
              _m(snapshot.realizedPlatformFee),
            ),
            _Metric(
              uiTr(context, 'ضريبة القيمة المضافة'),
              _m(snapshot.realizedVat),
            ),
            _Metric(
              uiTr(context, 'صافي أرباح المندوب'),
              _m(snapshot.realizedDriverNet),
            ),
            _Metric(
              uiTr(context, 'عمولة متوقعة بعد التحصيل'),
              _m(snapshot.expectedPlatformAfterCollection),
              muted: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _group(
          context,
          theme,
          uiTr(context, 'الذمم'),
          [
            _Metric(
              uiTr(context, 'مستحق للشركة'),
              _m(snapshot.companyReceivable),
            ),
            _Metric(
              uiTr(context, 'مستحق للمندوبين'),
              _m(snapshot.companyPayable),
            ),
            _Metric(
              uiTr(context, 'المتبقي'),
              _m(snapshot.outstandingReceivable),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _group(
          context,
          theme,
          uiTr(context, 'التسويات'),
          [
            _Metric(
              uiTr(context, 'المسدّد'),
              '${snapshot.settledCount}',
            ),
            _Metric(
              uiTr(context, 'قيد الانتظار'),
              '${snapshot.pendingSettlementCount}',
            ),
            _Metric(
              uiTr(context, 'المتبقي'),
              _m(MoneyAmount(
                currency: snapshot.currency,
                minorUnits: snapshot.outstandingSettlementMinor,
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _group(
    BuildContext context,
    FlutterFlowTheme theme,
    String title,
    List<_Metric> metrics,
  ) {
    return AdminContentCard(
      title: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final cols = w >= 1024 ? 4 : (w >= 640 ? 2 : 1);
          return Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final m in metrics)
                SizedBox(
                  width: cols == 1 ? w : (w - 12 * (cols - 1)) / cols,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.label,
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                        softWrap: true,
                      ),
                      Text(
                        m.value,
                        style: theme.titleSmall.override(
                          fontFamily: theme.titleSmallFamily,
                          color: m.highlight
                              ? AdminUi.brandTeal
                              : (m.muted
                                  ? theme.secondaryText
                                  : theme.primaryText),
                          fontWeight: FontWeight.w700,
                          useGoogleFonts: !theme.titleSmallIsCustom,
                        ),
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

class _Metric {
  const _Metric(
    this.label,
    this.value, {
    this.highlight = false,
    this.muted = false,
  });
  final String label;
  final String value;
  final bool highlight;
  final bool muted;
}
