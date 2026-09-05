import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Accountant money-movement table (completed real trips only).
class AccountantMoneyMovementTable extends StatelessWidget {
  const AccountantMoneyMovementTable({
    super.key,
    required this.rows,
    required this.onOpenDetails,
  });

  final List<AccountantTripRow> rows;
  final ValueChanged<AccountantTripRow> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (rows.isEmpty) {
      return AdminContentCard(
        child: Text(
          uiTr(context, 'لا توجد رحلات مكتملة ضمن الفلاتر الحالية.'),
          style: AccountantFinanceText.body(theme),
        ),
      );
    }

    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'حركة الأموال — الرحلات المكتملة'),
            style: AccountantFinanceText.sectionTitle(theme),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: AdminUi.adminTableMinWidth(context),
              ),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 56,
                columnSpacing: 16,
                headingTextStyle: AccountantFinanceText.tableHeader(theme),
                dataTextStyle: AccountantFinanceText.body(theme),
                columns: [
                  _h(context, 'الرحلة'),
                  _h(context, 'التاريخ'),
                  _h(context, 'الدولة'),
                  _h(context, 'السائق'),
                  _h(context, 'الوكيل'),
                  _h(context, 'طريقة الدفع'),
                  _h(context, 'حالة التحصيل'),
                  _h(context, 'القيمة'),
                  _h(context, 'المستحق'),
                  _h(context, 'حالة التسوية'),
                  _h(context, 'جودة البيانات'),
                  _h(context, ''),
                ],
                rows: [
                  for (final r in rows.take(200))
                    DataRow(
                      cells: [
                        DataCell(_ltr(r.tripRefLabel)),
                        DataCell(Text(
                          r.orderedAt == null
                              ? '—'
                              : dateFmt.format(r.orderedAt!.toLocal()),
                        )),
                        DataCell(Text(r.countryLabel)),
                        DataCell(Text(r.driverLabel)),
                        DataCell(Text(r.agentLabel)),
                        DataCell(Text(r.paymentMethodLabel)),
                        DataCell(Text(r.collectionStatusLabel)),
                        DataCell(Text(r.grossDisplay)),
                        DataCell(Text(r.dueDirectionLabel)),
                        DataCell(Text(r.settlementStatusLabel)),
                        DataCell(_qualityChip(context, r)),
                        DataCell(
                          TextButton(
                            onPressed: () => onOpenDetails(r),
                            child: Text(
                              uiTr(context, 'التفاصيل'),
                              style: AccountantFinanceText.body(theme).copyWith(
                                color: AdminUi.brandTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (rows.length > 200)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                uiTr(context, 'يُعرض أول 200 صف. استخدم الفلاتر لتضييق النتائج.'),
                style: AccountantFinanceText.label(theme),
              ),
            ),
        ],
      ),
    );
  }

  DataColumn _h(BuildContext context, String label) => DataColumn(
        label: Text(uiTr(context, label)),
      );

  Widget _ltr(String text) => Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Text(text),
      );

  Widget _qualityChip(BuildContext context, AccountantTripRow r) {
    final theme = FlutterFlowTheme.of(context);
    Color bg;
    switch (r.dataQuality) {
      case FinancialDataQuality.complete:
        bg = AdminUi.brandTeal.withValues(alpha: 0.12);
        break;
      case FinancialDataQuality.partial:
        bg = theme.warning.withValues(alpha: 0.2);
        break;
      case FinancialDataQuality.unresolved:
        bg = theme.error.withValues(alpha: 0.12);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        r.dataQualityLabel,
        style: AccountantFinanceText.label(theme).copyWith(
          color: AccountantFinanceText.ink(theme),
        ),
      ),
    );
  }
}
