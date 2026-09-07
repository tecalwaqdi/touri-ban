import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '/components/admin_enterprise_kit.dart';
import '/components/admin_ui.dart';
import '/core/admin_design/admin_design.dart';
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
        child: AdminEmptyState(
          compact: true,
          title: uiTr(context, 'لا توجد رحلات مكتملة'),
          message: uiTr(context, 'لا توجد رحلات مكتملة ضمن الفلاتر الحالية.'),
          icon: Icons.inbox_outlined,
        ),
      );
    }

    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final headerBg = AdminColors.surfaceSecondaryOf(context);

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
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    headingRowColor: WidgetStateProperty.all(headerBg),
                    dividerThickness: 1,
                  ),
                ),
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 50,
                  columnSpacing: 20,
                  horizontalMargin: 12,
                  headingTextStyle: AccountantFinanceText.tableHeader(theme)
                      .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                  dataTextStyle: AccountantFinanceText.body(theme).copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: const Color(0xFFE9ECEF).withValues(
                        alpha: AdminColors.isDark(context) ? 0.2 : 1,
                      ),
                    ),
                  ),
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
                        color: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return AdminColors.isDark(context)
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFF7FAFA);
                          }
                          return null;
                        }),
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
                          DataCell(_ltr(r.grossDisplay)),
                          DataCell(Text(r.dueDirectionLabel)),
                          DataCell(Text(r.settlementStatusLabel)),
                          DataCell(_qualityChip(context, r)),
                          DataCell(
                            TextButton.icon(
                              onPressed: () => onOpenDetails(r),
                              icon: Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                                color: AdminUi.brandTeal,
                              ),
                              label: Text(
                                uiTr(context, 'التفاصيل'),
                                style:
                                    AccountantFinanceText.body(theme).copyWith(
                                  color: AdminUi.brandTeal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (rows.length > 200)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                uiTr(
                    context, 'يُعرض أول 200 صف. استخدم الفلاتر لتضييق النتائج.'),
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
        bg = AdminColors.primary50.withValues(
          alpha: AdminColors.isDark(context) ? 0.2 : 1,
        );
        break;
      case FinancialDataQuality.partial:
        bg = AdminColors.warningBg.withValues(
          alpha: AdminColors.isDark(context) ? 0.2 : 1,
        );
        break;
      case FinancialDataQuality.unresolved:
        bg = AdminColors.dangerBg.withValues(
          alpha: AdminColors.isDark(context) ? 0.2 : 1,
        );
        break;
    }
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        r.dataQualityLabel,
        style: AccountantFinanceText.label(theme).copyWith(
          color: AccountantFinanceText.ink(theme),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
