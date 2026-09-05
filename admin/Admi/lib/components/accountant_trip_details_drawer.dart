import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-only trip financial details drawer.
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
          style: theme.titleMedium.override(
            fontFamily: theme.titleMediumFamily,
            fontWeight: FontWeight.w700,
            useGoogleFonts: !theme.titleMediumIsCustom,
          ),
        ),
        const SizedBox(height: 12),
        _section(context, 'الرحلة', [
          _kv(context, 'المعرّف', row.orderId, ltr: true),
          _kv(context, 'حالة الرحلة', row.tripStatusLabel),
          _kv(
            context,
            'التاريخ',
            row.orderedAt == null
                ? '—'
                : dateFmt.format(row.orderedAt!.toLocal()),
          ),
          _kv(context, 'الدولة', row.countryPath ?? '—', ltr: true),
          _kv(context, 'السائق', row.driverLabel, ltr: true),
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
          _kv(context, 'القيمة', row.grossDisplay),
          _kv(context, 'عمولة الشركة', row.companyCommissionDisplay),
          _kv(context, 'الضريبة', row.vatDisplay),
          _kv(context, 'صافي السائق', row.driverNetDisplay),
          _kv(context, 'مبلغ الوكيل', row.agentAmountDisplay),
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
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.warning,
                useGoogleFonts: !theme.bodySmallIsCustom,
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
              style: theme.labelLarge,
            ),
            children: [
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
              style: theme.titleSmall.override(
                fontFamily: theme.titleSmallFamily,
                fontWeight: FontWeight.w700,
                color: AdminUi.brandTeal,
                useGoogleFonts: !theme.titleSmallIsCustom,
              ),
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
            width: 120,
            child: Text(
              uiTr(context, k),
              style: theme.labelMedium.override(
                fontFamily: theme.labelMediumFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelMediumIsCustom,
              ),
            ),
          ),
          Expanded(
            child: ltr
                ? Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(v, style: theme.bodyMedium),
                  )
                : Text(v, style: theme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
