import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/admin_currency.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Period books: invoice split (must balance) and collection position.
class FinancePeriodStatement extends StatelessWidget {
  const FinancePeriodStatement({super.key, required this.snapshot});

  final FinanceCompanySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final s = snapshot;
    final sym = AdminCurrency.symbolByCode[s.currency] ?? s.currency;
    final active = s.completedTrips > 0;
    final fee = s.realizedPlatformFee.minorUnits;
    final vat = s.realizedVat.minorUnits;
    final driver = s.realizedDriverNet.minorUnits;
    final gross = s.completedTripValue.minorUnits;
    final split = fee + vat + driver;
    final gap = (gross - split).abs();
    final balanced = !active || gap <= 1;

    String money(MoneyAmount amount) {
      if (!active) return '';
      return AdminOrderMoneyDisplay.formatMoneyAmount(
        amount,
        symbolOverride: sym,
      );
    }

    String credit(MoneyAmount amount) => active ? money(amount) : '';
    String debit(MoneyAmount amount) => active ? money(amount) : '';

    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'دفتر الفترة'),
            style: AccountantFinanceText.sectionTitle(theme),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.periodLabel} · $sym',
            style: AccountantFinanceText.label(theme),
          ),
          const SizedBox(height: 4),
          Text(
            active
                ? uiTr(
                    context,
                    'فواتير مكتملة: {count}. الناقص لا يُرحَّل.',
                  )
                    .replaceAll('{count}', '${s.completedTrips}')
                    .replaceAll('{bad}', '${s.financiallyIncomplete}')
                : uiTr(
                    context,
                    'لا فواتير مكتملة في هذه الفترة. الأسماء أدناه دليل الحسابات.',
                  ),
            style: AccountantFinanceText.body(theme),
          ),
          if (active && s.financiallyIncomplete > 0) ...[
            const SizedBox(height: 4),
            Text(
              uiTr(
                context,
                'رحلات بياناتها ناقصة: {bad}. لم تدخل في الأرقام.',
              ).replaceAll('{bad}', '${s.financiallyIncomplete}'),
              style: AccountantFinanceText.label(theme),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            uiTr(context, 'توزيع الفاتورة'),
            style: AccountantFinanceText.label(theme).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _Head(theme),
          _Line(
            theme,
            uiTr(context, 'إجمالي الفواتير'),
            debit: debit(s.completedTripValue),
            credit: '',
          ),
          _Line(
            theme,
            uiTr(context, 'عمولة الشركة'),
            debit: '',
            credit: credit(s.realizedPlatformFee),
          ),
          _Line(
            theme,
            uiTr(context, 'الضريبة'),
            debit: '',
            credit: credit(s.realizedVat),
          ),
          _Line(
            theme,
            uiTr(context, 'صافي المندوبين'),
            debit: '',
            credit: credit(s.realizedDriverNet),
          ),
          if (active)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                balanced
                    ? uiTr(context, 'التوزيع متوازن مع إجمالي الفواتير.')
                    : uiTr(
                        context,
                        'التوزيع غير متوازن. الفرق {gap}.',
                      ).replaceAll(
                        '{gap}',
                        AdminOrderMoneyDisplay.formatMoneyAmount(
                          MoneyAmount(currency: s.currency, minorUnits: gap),
                          symbolOverride: sym,
                        ),
                      ),
                style: AccountantFinanceText.label(theme).copyWith(
                  color: balanced ? AdminUi.brandTeal : theme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            uiTr(context, 'التحصيل والذمم'),
            style: AccountantFinanceText.label(theme).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _Head(theme),
          _Line(
            theme,
            uiTr(context, 'نقد محصّل'),
            debit: debit(s.cashCollectedValue),
            credit: '',
          ),
          _Line(
            theme,
            uiTr(context, 'إلكتروني محصّل'),
            debit: debit(s.onlinePaidValue),
            credit: '',
          ),
          _Line(
            theme,
            uiTr(context, 'على المندوب للشركة'),
            debit: debit(s.companyReceivable),
            credit: '',
          ),
          _Line(
            theme,
            uiTr(context, 'على الشركة للمندوب'),
            debit: '',
            credit: credit(s.companyPayable),
          ),
          _Line(
            theme,
            uiTr(context, 'تسويات لم تُغلق'),
            debit: !s.settlementStatsAvailable
                ? uiTr(context, 'غير متوفر')
                : (s.pendingSettlementCount > 0 ||
                        s.outstandingSettlementMinor != 0
                    ? AdminOrderMoneyDisplay.formatMoneyAmount(
                        MoneyAmount(
                          currency: s.currency,
                          minorUnits: s.outstandingSettlementMinor,
                        ),
                        symbolOverride: sym,
                      )
                    : ''),
            credit: '',
            note: s.settlementStatsAvailable && s.pendingSettlementCount > 0
                ? uiTr(context, '{count} تسوية')
                    .replaceAll('{count}', '${s.pendingSettlementCount}')
                : null,
          ),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.theme);

  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final style = AccountantFinanceText.label(theme).copyWith(
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(uiTr(context, 'الحساب'), style: style)),
          Expanded(
            child: Text(
              uiTr(context, 'مدين'),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: Text(
              uiTr(context, 'دائن'),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(
    this.theme,
    this.account, {
    required this.debit,
    required this.credit,
    this.note,
  });

  final FlutterFlowTheme theme;
  final String account;
  final String debit;
  final String credit;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final body = AccountantFinanceText.body(theme);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              note == null ? account : '$account · $note',
              style: body,
            ),
          ),
          Expanded(child: Text(debit, style: body, textAlign: TextAlign.end)),
          Expanded(child: Text(credit, style: body, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
