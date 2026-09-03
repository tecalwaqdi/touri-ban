import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/admin/admin_a_l_lhg_z/admin_bookings_presentation.dart';
import '/backend/schema/order_record.dart';
import '/components/admin_ui.dart';
import '/core/admin_booking_status_label.dart';
import '/core/admin_currency.dart';
import '/core/admin_qa_fixture.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Modern bookings table with horizontal scroll (page stays RTL, no page overflow).
class AdminBookingsTable extends StatelessWidget {
  const AdminBookingsTable({
    super.key,
    required this.bookings,
    required this.onDetails,
    required this.onCancel,
    required this.canCancel,
  });

  final List<OrderRecord> bookings;
  final void Function(OrderRecord) onDetails;
  final Future<void> Function(OrderRecord) onCancel;
  final bool canCancel;

  static const double _minWidth = 1120;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 1280;
        final hidePayment = constraints.maxWidth < 1100;
        final hideCity = constraints.maxWidth < 1024;
        final width =
            constraints.maxWidth < _minWidth ? _minWidth : constraints.maxWidth;
        return Scrollbar(
          thumbVisibility: constraints.maxWidth < _minWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AdminUi.brandTeal.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _h(context, uiTr(context, 'الحجز'), 15),
                        _h(context, uiTr(context, 'العميل'), 12),
                        _h(context, uiTr(context, 'المندوب'), 11),
                        _h(context, uiTr(context, 'الحالة'), 12),
                        if (!hideCity) _h(context, uiTr(context, 'المدينة'), 9),
                        _h(context, uiTr(context, 'الانطلاق'), narrow ? 10 : 12),
                        _h(context, uiTr(context, 'الوجهة'), narrow ? 10 : 12),
                        _h(context, uiTr(context, 'المبلغ'), 9),
                        if (!hidePayment)
                          _h(context, uiTr(context, 'الدفع'), 8),
                        _h(context, uiTr(context, 'التاريخ'), 10),
                        _h(context, uiTr(context, 'إجراءات'), 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  ...bookings.map((order) {
                    final row = AdminBookingRow.fromOrder(order);
                    return _BookingsTableRow(
                      row: row,
                      theme: theme,
                      canCancel: canCancel && !row.isTerminal,
                      hideCity: hideCity,
                      hidePayment: hidePayment,
                      onDetails: () => onDetails(order),
                      onCancel: () => onCancel(order),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _h(BuildContext context, String text, int flex) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.labelSmall.override(
          fontFamily: theme.labelSmallFamily,
          fontWeight: FontWeight.w700,
          color: AdminUi.brandTeal,
          fontSize: 12,
          useGoogleFonts: !theme.labelSmallIsCustom,
        ),
      ),
    );
  }
}

class _BookingsTableRow extends StatelessWidget {
  const _BookingsTableRow({
    required this.row,
    required this.theme,
    required this.canCancel,
    required this.hideCity,
    required this.hidePayment,
    required this.onDetails,
    required this.onCancel,
  });

  final AdminBookingRow row;
  final FlutterFlowTheme theme;
  final bool canCancel;
  final bool hideCity;
  final bool hidePayment;
  final VoidCallback onDetails;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final customer = row.customerName.isEmpty ? '—' : row.customerName;
    final driver =
        AdminBookingsPresentation.driverCellLabel(context, row.driverName);
    final amountText = formatNumber(
      row.amount,
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
      currency: AdminCurrency.asFormatPrefix(row.currencySymbol),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetails,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _cell(_BookingIdCell(orderId: row.orderId, theme: theme), 15),
              _cell(
                _EllipsisText(
                  customer,
                  maxLines: 2,
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
                12,
              ),
              _cell(
                _EllipsisText(
                  driver,
                  maxLines: 2,
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: row.driverName.trim().isEmpty
                        ? theme.secondaryText
                        : theme.primaryText,
                    useGoogleFonts: !theme.bodySmallIsCustom,
                  ),
                ),
                11,
              ),
              _cell(AdminBookingStatusBadge(order: row.order), 12),
              if (!hideCity)
                _cell(
                  _EllipsisText(
                    row.city.isEmpty ? '—' : row.city,
                    maxLines: 1,
                    style: theme.bodySmall,
                  ),
                  9,
                ),
              _cell(
                _EllipsisText(
                  row.pickupLabel.isEmpty ? '—' : row.pickupLabel,
                  maxLines: 2,
                  style: theme.bodySmall,
                ),
                12,
              ),
              _cell(
                _EllipsisText(
                  row.destinationLabel.isEmpty ? '—' : row.destinationLabel,
                  maxLines: 2,
                  style: theme.bodySmall,
                ),
                12,
              ),
              _cell(
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      fontWeight: FontWeight.w700,
                      color: theme.success,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
                ),
                9,
              ),
              if (!hidePayment)
                _cell(
                  _EllipsisText(
                    row.paymentLabel.isEmpty
                        ? '—'
                        : uiTr(context, row.paymentLabel),
                    maxLines: 1,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
                  8,
                ),
              _cell(
                Tooltip(
                  message: AdminBookingsPresentation.tableDateTimeTooltip(
                    row.createdAt,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AdminBookingsPresentation.tableDate(row.createdAt),
                        maxLines: 1,
                        style: theme.bodySmall.override(
                          fontFamily: theme.bodySmallFamily,
                          fontWeight: FontWeight.w600,
                          useGoogleFonts: !theme.bodySmallIsCustom,
                        ),
                      ),
                      if (row.createdAt != null)
                        Text(
                          AdminBookingsPresentation.tableTime(row.createdAt),
                          maxLines: 1,
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.labelSmallIsCustom,
                          ),
                        ),
                    ],
                  ),
                ),
                10,
              ),
              _cell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 8,
                      buttonSize: 32,
                      fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: AdminUi.brandTeal,
                        size: 16,
                      ),
                      onPressed: onDetails,
                    ),
                    if (canCancel) ...[
                      const SizedBox(width: 2),
                      FlutterFlowIconButton(
                        borderRadius: 8,
                        buttonSize: 32,
                        fillColor: const Color(0xFFFFEBEE),
                        icon: Icon(
                          Icons.cancel_outlined,
                          color: theme.error,
                          size: 16,
                        ),
                        onPressed: onCancel,
                      ),
                    ],
                  ],
                ),
                8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(Widget child, int flex) => Expanded(flex: flex, child: child);
}

class _BookingIdCell extends StatelessWidget {
  const _BookingIdCell({required this.orderId, required this.theme});

  final String orderId;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final id = orderId.trim().isEmpty ? '—' : orderId.trim();
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: id,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                id,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmallFamily,
                  fontWeight: FontWeight.w700,
                  color: AdminUi.brandTeal,
                  useGoogleFonts: !theme.bodySmallIsCustom,
                ),
              ),
            ),
          ),
        ),
        if (id != '—')
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: uiTr(context, 'نسخ'),
            icon: Icon(Icons.copy_rounded, size: 14, color: theme.secondaryText),
            onPressed: () => Clipboard.setData(ClipboardData(text: id)),
          ),
      ],
    );
  }
}

class _EllipsisText extends StatelessWidget {
  const _EllipsisText(this.text, {this.maxLines = 1, this.style});

  final String text;
  final int maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class AdminBookingStatusBadge extends StatelessWidget {
  const AdminBookingStatusBadge({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = AdminBookingStatusLabel.of(order);
    final colors = _statusColors(AdminBookingStatusLabel.toneOf(order), theme);
    final label =
        status.isNotEmpty ? uiTr(context, status) : uiTr(context, 'غير محدد');
    final qa = AdminQaFixture.isFixtureOrder(order);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: colors.foreground.withValues(alpha: 0.18)),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: colors.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
          if (qa) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AdminQaFixture.badgeAr(order),
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.warning,
                  useGoogleFonts: !theme.labelSmallIsCustom,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});
  final Color background;
  final Color foreground;
}

_StatusColors _statusColors(AdminBookingStatusTone tone, FlutterFlowTheme theme) {
  switch (tone) {
    case AdminBookingStatusTone.pending:
      return const _StatusColors(
        background: Color(0xFFFFF3E0),
        foreground: Color(0xFFE65100),
      );
    case AdminBookingStatusTone.assigned:
      return const _StatusColors(
        background: Color(0xFFE3F2FD),
        foreground: Color(0xFF1565C0),
      );
    case AdminBookingStatusTone.onTheWay:
      return const _StatusColors(
        background: Color(0xFFE0F7FA),
        foreground: Color(0xFF00838F),
      );
    case AdminBookingStatusTone.arrived:
      return const _StatusColors(
        background: Color(0xFFE8EAF6),
        foreground: Color(0xFF3949AB),
      );
    case AdminBookingStatusTone.inTrip:
      return const _StatusColors(
        background: Color(0xFFE0F2F1),
        foreground: AdminUi.brandTeal,
      );
    case AdminBookingStatusTone.canceled:
      return _StatusColors(
        background: const Color(0xFFFFEBEE),
        foreground: theme.error,
      );
    case AdminBookingStatusTone.completed:
      return _StatusColors(
        background: theme.success.withValues(alpha: 0.12),
        foreground: theme.success,
      );
    case AdminBookingStatusTone.expired:
      return _StatusColors(
        background: theme.alternate.withValues(alpha: 0.5),
        foreground: theme.secondaryText,
      );
    case AdminBookingStatusTone.unknown:
      return _StatusColors(
        background: theme.accent4,
        foreground: theme.secondaryText,
      );
  }
}

/// Compact card for narrow viewports.
class AdminBookingListCard extends StatelessWidget {
  const AdminBookingListCard({
    super.key,
    required this.order,
    required this.onDetails,
    required this.onCancel,
    required this.canCancel,
  });

  final OrderRecord order;
  final VoidCallback onDetails;
  final VoidCallback onCancel;
  final bool canCancel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final row = AdminBookingRow.fromOrder(order);
    final showCancel = canCancel && !row.isTerminal;
    final driver =
        AdminBookingsPresentation.driverCellLabel(context, row.driverName);

    return Container(
      decoration: AdminUi.cardDecoration(context, elevated: false).copyWith(
        color: theme.primaryBackground,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    row.orderId.trim().isEmpty ? '—' : row.orderId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w700,
                      color: AdminUi.brandTeal,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                ),
              ),
              AdminBookingStatusBadge(order: order),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            row.customerName.isEmpty ? '—' : row.customerName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${uiTr(context, 'المندوب')}: $driver',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.bodySmall,
          ),
          if (row.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${uiTr(context, 'المدينة')}: ${row.city}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatNumber(
                    row.amount,
                    formatType: FormatType.decimal,
                    decimalType: DecimalType.automatic,
                    currency: AdminCurrency.asFormatPrefix(row.currencySymbol),
                  ),
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    color: theme.success,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
              if (row.createdAt != null)
                Text(
                  '${AdminBookingsPresentation.tableDate(row.createdAt)} '
                  '${AdminBookingsPresentation.tableTime(row.createdAt)}',
                  style: theme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AdminPrimaryButton(
                  label: uiTr(context, 'التفاصيل'),
                  icon: Icons.visibility_outlined,
                  onPressed: onDetails,
                ),
              ),
              if (showCancel) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: AdminPrimaryButton(
                    label: uiTr(context, 'إلغاء'),
                    icon: Icons.cancel_outlined,
                    outlined: true,
                    onPressed: onCancel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholders while the first page loads.
class AdminBookingsSkeleton extends StatelessWidget {
  const AdminBookingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: List.generate(6, (i) {
        return Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: theme.alternate.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
