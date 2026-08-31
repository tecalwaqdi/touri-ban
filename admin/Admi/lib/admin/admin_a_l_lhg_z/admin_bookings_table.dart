import 'package:flutter/material.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/backend/schema/order_record.dart';
import '/components/admin_ui.dart';
import '/core/admin_booking_status_label.dart';
import '/core/admin_currency.dart';
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

  static const double _minWidth = 1180;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
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
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AdminUi.brandTeal.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _h(context, uiTr(context, 'رقم الحجز'), 1.1),
                        _h(context, uiTr(context, 'العميل'), 1.4),
                        _h(context, uiTr(context, 'المندوب'), 1.2),
                        _h(context, uiTr(context, 'الحالة'), 1.3),
                        _h(context, uiTr(context, 'المدينة'), 1.0),
                        _h(context, uiTr(context, 'الانطلاق'), 1.3),
                        _h(context, uiTr(context, 'الوجهة'), 1.3),
                        _h(context, uiTr(context, 'المبلغ'), 0.9),
                        _h(context, uiTr(context, 'الدفع'), 0.8),
                        _h(context, uiTr(context, 'التاريخ'), 1.2),
                        _h(context, uiTr(context, 'إجراءات'), 0.9),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...bookings.map((order) {
                    final row = AdminBookingRow.fromOrder(order);
                    return _BookingsTableRow(
                      row: row,
                      theme: theme,
                      canCancel: canCancel && !row.isTerminal,
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

  Widget _h(BuildContext context, String text, double flex) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      flex: (flex * 10).round(),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.labelMedium.override(
          fontFamily: theme.labelMediumFamily,
          fontWeight: FontWeight.w700,
          color: AdminUi.brandTeal,
          useGoogleFonts: !theme.labelMediumIsCustom,
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
    required this.onDetails,
    required this.onCancel,
  });

  final AdminBookingRow row;
  final FlutterFlowTheme theme;
  final bool canCancel;
  final VoidCallback onDetails;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetails,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.55)),
            ),
          ),
          child: Row(
            children: [
              _cell(
                Text(
                  '#${row.orderId}',
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w700,
                    color: AdminUi.brandTeal,
                    useGoogleFonts: !theme.bodyMediumIsCustom,
                  ),
                ),
                11,
              ),
              _cell(
                Text(
                  row.customerName.isEmpty ? '—' : row.customerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                14,
              ),
              _cell(
                Text(
                  row.driverName.isEmpty
                      ? uiTr(context, 'لم يُربط')
                      : row.driverName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                12,
              ),
              _cell(AdminBookingStatusBadge(order: row.order), 13),
              _cell(
                Text(
                  row.city.isEmpty ? '—' : row.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                10,
              ),
              _cell(
                Text(
                  row.pickupLabel.isEmpty ? '—' : row.pickupLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                13,
              ),
              _cell(
                Text(
                  row.destinationLabel.isEmpty ? '—' : row.destinationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                13,
              ),
              _cell(
                Text(
                  formatNumber(
                    row.amount,
                    formatType: FormatType.decimal,
                    decimalType: DecimalType.automatic,
                    currency: AdminCurrency.asFormatPrefix(row.currencySymbol),
                  ),
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w700,
                    color: theme.success,
                    useGoogleFonts: !theme.bodyMediumIsCustom,
                  ),
                ),
                9,
              ),
              _cell(
                Text(
                  row.paymentLabel.isEmpty ? '—' : uiTr(context, row.paymentLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
                8,
              ),
              _cell(
                Text(
                  row.createdAt == null
                      ? '—'
                      : dateTimeFormat(
                          'd/M/y HH:mm',
                          row.createdAt,
                          locale: 'ar',
                        ),
                  style: theme.bodySmall,
                ),
                12,
              ),
              _cell(
                Wrap(
                  spacing: 4,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 8,
                      buttonSize: 34,
                      fillColor: AdminUi.brandTeal.withValues(alpha: 0.1),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: AdminUi.brandTeal,
                        size: 17,
                      ),
                      onPressed: onDetails,
                    ),
                    if (canCancel)
                      FlutterFlowIconButton(
                        borderRadius: 8,
                        buttonSize: 34,
                        fillColor: const Color(0xFFFFEBEE),
                        icon: Icon(
                          Icons.cancel_outlined,
                          color: theme.error,
                          size: 17,
                        ),
                        onPressed: onCancel,
                      ),
                  ],
                ),
                9,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(Widget child, int flex) => Expanded(flex: flex, child: child);
}

class AdminBookingStatusBadge extends StatelessWidget {
  const AdminBookingStatusBadge({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = AdminBookingStatusLabel.of(order);
    final colors = _statusColors(AdminBookingStatusLabel.toneOf(order), theme);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          status.isNotEmpty ? uiTr(context, status) : uiTr(context, 'غير محدد'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: colors.foreground,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
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
                child: Text(
                  '#${row.orderId}',
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    color: AdminUi.brandTeal,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
              AdminBookingStatusBadge(order: order),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            row.customerName.isEmpty ? '—' : row.customerName,
            style: theme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${uiTr(context, 'المندوب')}: ${row.driverName.isEmpty ? uiTr(context, 'لم يُربط') : row.driverName}',
            style: theme.bodySmall,
          ),
          if (row.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${uiTr(context, 'المدينة')}: ${row.city}',
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
                  dateTimeFormat('d/M/y HH:mm', row.createdAt, locale: 'ar'),
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
          height: 52,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.alternate.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
