import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

Future<void> showAccountantTripDetailsDrawer(
  BuildContext context,
  AccountantTripRow row,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return AccountantTripDetailsPanel(
          row: row,
          scrollController: controller,
        );
      },
    ),
  );
}

class AccountantTripDetailsPanel extends StatelessWidget {
  const AccountantTripDetailsPanel({
    super.key,
    required this.row,
    this.scrollController,
  });

  final AccountantTripRow row;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.alternate,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          uiTr(context, 'تفاصيل الرحلة المالية'),
          style: AccountantFinanceText.pageTitle(theme),
        ),
        const SizedBox(height: 12),
        _section(context, 'الرحلة', [
          _kv(context, 'المرجع', row.tripRefLabel, ltr: true),
          _kv(context, 'حالة الرحلة', row.tripStatusLabel),
          _kv(
            context,
            'التاريخ',
            row.orderedAt == null
                ? '—'
                : dateFmt.format(row.orderedAt!.toLocal()),
          ),
          _kv(context, 'الدولة', row.countryLabel),
          _kv(context, 'السائق', row.driverLabel),
        ]),
        _section(context, 'الدفع', [
          _kv(context, 'طريقة الدفع', row.paymentMethodLabel),
          _kv(context, 'حالة الدفع', row.paymentStatusLabel),
        ]),
        _section(context, 'التحصيل', [
          _kv(context, 'حالة التحصيل', row.collectionStatusLabel),
          _kv(context, 'من يحتفظ بالمبلغ', row.moneyHolderLabel),
        ]),
        _section(context, 'التقسيم المالي', [
          _kv(context, 'القيمة (إجمالي الرحلة)', row.grossDisplay),
          _kv(context, 'عمولة الشركة', row.companyCommissionDisplay),
          _kv(context, 'الضريبة', row.vatDisplay),
          _kv(context, 'صافي السائق', row.driverNetDisplay),
          if (row.agentAmountIsShareOfCommission) ...[
            _kv(
              context,
              AccountantFinanceLabels.agentShareOfCommissionLabel(),
              row.agentAmountDisplay,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                uiTr(
                  context,
                  'حصة الوكيل جزء من عمولة الشركة وليست زيادة على قيمة الرحلة.',
                ),
                style: AccountantFinanceText.label(theme),
              ),
            ),
          ] else
            _kv(
              context,
              AccountantFinanceLabels.agentShareOfCommissionLabel(),
              row.agentAmountDisplay,
            ),
          if (row.agentAttribution == FinancialAgentAttribution.missing)
            _kv(
              context,
              'إسناد الوكيل',
              AccountantFinanceLabels.agentAttributionAr(row.agentAttribution),
            ),
        ]),
        _section(context, 'التسوية', [
          _kv(context, 'اتجاه المستحق', row.dueDirectionLabel),
          _kv(context, 'حالة التسوية', row.settlementStatusLabel),
        ]),
        _section(context, 'جودة البيانات', [
          _kv(context, 'الحالة', row.dataQualityLabel),
          _kv(
            context,
            'الحقول الناقصة',
            row.missingFields.isEmpty
                ? '—'
                : row.missingFields.join(' · '),
            ltr: true,
          ),
          _kv(context, 'درجة الثقة', row.confidenceLabel),
        ]),
        if (row.dataQuality != FinancialDataQuality.complete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              uiTr(
                context,
                'المبالغ غير معروضة كأصفار — البيانات المالية غير مكتملة.',
              ),
              style: AccountantFinanceText.body(theme).copyWith(
                color: AdminUi.brandTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              uiTr(context, 'بيانات تقنية'),
              style: AccountantFinanceText.label(theme),
            ),
            children: [
              _kv(context, 'معرّف الرحلة', row.orderId, ltr: true),
              _kv(context, 'معرّف السائق', row.driverId ?? '—', ltr: true),
              _kv(context, 'مسار الدولة', row.countryPath ?? '—', ltr: true),
              _kv(context, 'المصدر', row.source, ltr: true),
              _kv(context, 'العملة', row.currency, ltr: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> kids) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AdminContentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              uiTr(context, title),
              style: AccountantFinanceText.sectionTitle(theme),
            ),
            const SizedBox(height: 8),
            ...kids,
          ],
        ),
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String k,
    String v, {
    bool ltr = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(uiTr(context, k), style: AccountantFinanceText.label(theme)),
          ),
          Expanded(
            child: ltr
                ? Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(v, style: AccountantFinanceText.body(theme)),
                  )
                : Text(v, style: AccountantFinanceText.body(theme)),
          ),
        ],
      ),
    );
  }
}
