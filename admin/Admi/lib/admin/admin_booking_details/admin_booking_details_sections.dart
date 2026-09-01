import 'dart:async';
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/admin/admin_booking_details/admin_booking_details_adapter.dart';
import '/components/admin_location_service.dart';
import '/components/admin_ui.dart';
import '/components/profile_photo_image.dart';
import '/core/admin_booking_status_label.dart';
import '/core/admin_currency.dart';
import '/core/finance/financial_engine.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

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

String _dash(String v) => v.trim().isEmpty ? '—' : v.trim();

String _durationLabel(int minutes) {
  if (minutes <= 0) return '';
  if (minutes < 60) return '$minutes دقيقة';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '$h ساعة';
  return '$h ساعة $m دقيقة';
}

// ---------------------------------------------------------------------------
// Section card + KV row
// ---------------------------------------------------------------------------

class AdminBookingDetailsSectionCard extends StatelessWidget {
  const AdminBookingDetailsSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: AdminUi.cardDecoration(context, elevated: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class AdminBookingDetailsKvRow extends StatelessWidget {
  const AdminBookingDetailsKvRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueWidget,
    this.isLtr = false,
    this.onCopy,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? valueWidget;
  final bool isLtr;
  final VoidCallback? onCopy;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final display = _dash(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: theme.secondaryText),
            const SizedBox(width: 6),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: valueWidget ??
                      Directionality(
                        textDirection:
                            isLtr ? ui.TextDirection.ltr : ui.TextDirection.rtl,
                        child: Text(
                          display,
                          style: (emphasizeValue
                                  ? theme.titleSmall
                                  : theme.bodyMedium)
                              .override(
                            fontFamily: emphasizeValue
                                ? theme.titleSmallFamily
                                : theme.bodyMediumFamily,
                            fontWeight:
                                emphasizeValue ? FontWeight.w700 : FontWeight.w600,
                            useGoogleFonts: emphasizeValue
                                ? !theme.titleSmallIsCustom
                                : !theme.bodyMediumIsCustom,
                          ),
                        ),
                      ),
                ),
                if (onCopy != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: theme.secondaryText,
                    ),
                    onPressed: onCopy,
                    tooltip: uiTr(context, 'نسخ'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminBookingDetailsStatusBadge extends StatelessWidget {
  const AdminBookingDetailsStatusBadge({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final colors = _statusColors(view.row.statusTone, theme);
    final label = view.row.statusLabel.isEmpty ? '—' : view.row.statusLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: theme.labelMedium.override(
          fontFamily: theme.labelMediumFamily,
          color: colors.foreground,
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelMediumIsCustom,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class AdminBookingDetailsHeader extends StatefulWidget {
  const AdminBookingDetailsHeader({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  State<AdminBookingDetailsHeader> createState() =>
      _AdminBookingDetailsHeaderState();
}

class _AdminBookingDetailsHeaderState extends State<AdminBookingDetailsHeader> {
  bool _copied = false;

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final view = widget.view;
    final row = view.row;
    final bookingId = row.orderId.trim().isNotEmpty
        ? row.orderId.trim()
        : row.order.reference.id;
    final created = row.createdAt != null
        ? dateTimeFormat('d/M/y – HH:mm', row.createdAt, locale: 'ar')
        : '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      uiTr(context, 'رقم الحجز'),
                      style: theme.labelSmall.override(
                        fontFamily: theme.labelSmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.labelSmallIsCustom,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Text(
                          bookingId,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: theme.titleSmall.override(
                            fontFamily: theme.titleSmallFamily,
                            fontWeight: FontWeight.w700,
                            color: AdminUi.brandTeal,
                            useGoogleFonts: !theme.titleSmallIsCustom,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: _copied ? theme.success : theme.secondaryText,
                      ),
                      onPressed: () => _copyId(bookingId),
                      tooltip: _copied
                          ? uiTr(context, 'تم النسخ')
                          : uiTr(context, 'نسخ'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AdminBookingDetailsStatusBadge(view: view),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _metaChip(context, Icons.calendar_today_outlined,
                  uiTr(context, 'تاريخ الإنشاء'), created),
              if (view.tripTypeLabel.isNotEmpty)
                _metaChip(context, Icons.route_outlined,
                    uiTr(context, 'نوع الرحلة'), view.tripTypeLabel),
              if (row.city.isNotEmpty)
                _metaChip(context, Icons.location_city_outlined,
                    uiTr(context, 'المدينة'), row.city),
              if (row.paymentLabel.isNotEmpty)
                _metaChip(context, Icons.payments_outlined,
                    uiTr(context, 'طريقة الدفع'), row.paymentLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.secondaryText),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
        Text(
          value,
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary strip
// ---------------------------------------------------------------------------

class AdminBookingDetailsSummaryStrip extends StatelessWidget {
  const AdminBookingDetailsSummaryStrip({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final row = view.row;
    final sym = AdminCurrency.asFormatPrefix(row.currencySymbol);
    final items = <(String, String)>[
      (uiTr(context, 'الحالة'), row.statusLabel),
      if (row.amount > 0)
        (
          uiTr(context, 'قيمة الرحلة'),
          AdminBookingDetailsView.money(row.amount, sym),
        ),
      if (row.paymentLabel.isNotEmpty)
        (uiTr(context, 'الدفع'), row.paymentLabel),
      (
        uiTr(context, 'المندوب'),
        view.hasDriver
            ? (row.driverName.isNotEmpty ? row.driverName : '—')
            : uiTr(context, 'لم يُعيَّن'),
      ),
      if (row.durationMinutes > 0)
        (uiTr(context, 'المدة'), _durationLabel(row.durationMinutes)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminUi.brandTeal.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.5)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: theme.alternate,
                ),
              _summaryItem(context, items[i].$1, items[i].$2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.labelSmall.override(
            fontFamily: theme.labelSmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.labelSmallIsCustom,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            fontWeight: FontWeight.w600,
            useGoogleFonts: !theme.bodyMediumIsCustom,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Entity cards
// ---------------------------------------------------------------------------

class AdminBookingDetailsCustomerCard extends StatelessWidget {
  const AdminBookingDetailsCustomerCard({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    final row = view.row;
    final phone = AdminBookingDetailsView.formatPhone(row.customerPhone);

    return AdminBookingDetailsSectionCard(
      title: uiTr(context, 'معلومات العميل'),
      trailing: view.customerRef != null
          ? TextButton.icon(
              onPressed: () => context.pushNamed(
                DriverProfileWidget.routeName,
                queryParameters: {
                  'iduser': serializeParam(
                    view.customerRef,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(uiTr(context, 'عرض ملف العميل')),
            )
          : null,
      children: [
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'الاسم'),
          value: row.customerName,
          icon: Icons.person_outline_rounded,
        ),
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'الهاتف'),
          value: phone,
          icon: Icons.phone_outlined,
          isLtr: phone != '—',
          onCopy: row.customerPhone.isNotEmpty
              ? () => Clipboard.setData(
                    ClipboardData(text: row.customerPhone),
                  )
              : null,
        ),
        if (row.city.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'مدينة الحجز'),
            value: row.city,
            icon: Icons.location_city_outlined,
          ),
      ],
    );
  }
}

class AdminBookingDetailsDriverCard extends StatelessWidget {
  const AdminBookingDetailsDriverCard({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final row = view.row;

    if (!view.hasDriver) {
      return AdminBookingDetailsSectionCard(
        title: uiTr(context, 'المندوب'),
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining_outlined,
                  size: 20, color: theme.secondaryText),
              const SizedBox(width: 8),
              Text(
                uiTr(context, 'لم يتم تعيين مندوب بعد'),
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.bodyMediumIsCustom,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final phone = AdminBookingDetailsView.formatPhone(row.driverPhone);

    return AdminBookingDetailsSectionCard(
      title: uiTr(context, 'بيانات المندوب'),
      trailing: view.driverRef != null
          ? TextButton.icon(
              onPressed: () => context.pushNamed(
                DriverProfileWidget.routeName,
                queryParameters: {
                  'iduser': serializeParam(
                    view.driverRef,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(uiTr(context, 'عرض ملف المندوب')),
            )
          : null,
      children: [
        Row(
          children: [
            ProfilePhotoImage(
              photoUrl: row.order.imgMndob,
              size: 44,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _dash(row.driverName),
                style: theme.titleSmall.override(
                  fontFamily: theme.titleSmallFamily,
                  fontWeight: FontWeight.w600,
                  useGoogleFonts: !theme.titleSmallIsCustom,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'الهاتف'),
          value: phone,
          icon: Icons.phone_outlined,
          isLtr: phone != '—',
        ),
        if (row.vehicleLabel.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'المركبة'),
            value: row.vehicleLabel,
            icon: Icons.directions_car_outlined,
          ),
        if (row.plateLabel.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'اللوحة'),
            value: row.plateLabel,
            icon: Icons.pin_outlined,
            isLtr: true,
          ),
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'الحالة'),
          value: row.statusLabel,
          icon: Icons.info_outline_rounded,
        ),
      ],
    );
  }
}

class AdminBookingDetailsTripCard extends StatelessWidget {
  const AdminBookingDetailsTripCard({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    final row = view.row;
    final data = row.order.snapshotData;
    final passengers = data['passengers'] ?? data['num_passengers'];

    return AdminBookingDetailsSectionCard(
      title: uiTr(context, 'تفاصيل الرحلة'),
      children: [
        if (view.tripTypeLabel.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'نوع الرحلة'),
            value: view.tripTypeLabel,
          ),
        if (row.vehicleLabel.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'نوع المركبة'),
            value: row.vehicleLabel,
          ),
        if (row.durationMinutes > 0)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'مدة الرحلة'),
            value: _durationLabel(row.durationMinutes),
          ),
        if (passengers != null && passengers.toString() != '0')
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'عدد الركاب'),
            value: passengers.toString(),
          ),
        if (row.city.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'مدينة الحجز'),
            value: row.city,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Payment
// ---------------------------------------------------------------------------

class AdminBookingDetailsPaymentCard extends StatelessWidget {
  const AdminBookingDetailsPaymentCard({
    super.key,
    required this.view,
    this.onRefund,
    this.refundSubmitting = false,
  });

  final AdminBookingDetailsView view;
  final VoidCallback? onRefund;
  final bool refundSubmitting;

  Color _paymentStatusColor(BuildContext context) {
    switch (OrderStatusHelper.statusOf(view.row.order)) {
      case OrderPaymentStatus.paid:
        return FlutterFlowTheme.of(context).success;
      case OrderPaymentStatus.canceled:
        return FlutterFlowTheme.of(context).error;
      case OrderPaymentStatus.pending:
        return FlutterFlowTheme.of(context).warning;
      case OrderPaymentStatus.unknown:
        return FlutterFlowTheme.of(context).alternate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final row = view.row;
    final sym = AdminCurrency.asFormatPrefix(row.currencySymbol);
    final gatewayId = row.order.paymentGatewayOrderId;

    return AdminBookingDetailsSectionCard(
      title: uiTr(context, 'تفاصيل الدفع'),
      children: [
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'طريقة الدفع'),
          value: row.paymentLabel,
        ),
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'حالة الدفع'),
          value: view.paymentStatusLabel,
          valueWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _paymentStatusColor(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              view.paymentStatusLabel,
              style: theme.labelMedium.override(
                fontFamily: theme.labelMediumFamily,
                color: _paymentStatusColor(context),
                fontWeight: FontWeight.w600,
                useGoogleFonts: !theme.labelMediumIsCustom,
              ),
            ),
          ),
        ),
        if (gatewayId.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'مرجع الدفع'),
            value: gatewayId,
            isLtr: true,
          ),
        const Divider(height: 14),
        if (row.amount > 0)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'إجمالي الرحلة'),
            value: AdminBookingDetailsView.money(row.amount, sym),
            emphasizeValue: true,
          ),
        if (row.commission > 0)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'رسوم التطبيق'),
            value: AdminBookingDetailsView.money(row.commission, sym),
          ),
        if (row.driverNet != null)
          AdminBookingDetailsKvRow(
            label: row.driverNetIsDerived
                ? uiTr(context, 'صافي المندوب (مشتق)')
                : uiTr(context, 'صافي المندوب'),
            value: AdminBookingDetailsView.money(row.driverNet!, sym),
          )
        else
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'صافي المندوب'),
            value: '—',
          ),
        if (view.showVat)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'الضريبة'),
            value: AdminBookingDetailsView.money(
              row.order.totalVat.toDouble(),
              sym,
            ),
          ),
        if (view.showDiscount)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'الخصم'),
            value: AdminBookingDetailsView.money(view.discountAmount, sym),
          ),
        if (onRefund != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonal(
              onPressed: refundSubmitting ? null : onRefund,
              child: Text(
                refundSubmitting
                    ? uiTr(context, 'جاري التحميل')
                    : uiTr(context, 'استرداد'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cancellation
// ---------------------------------------------------------------------------

class AdminBookingDetailsCancellationCard extends StatelessWidget {
  const AdminBookingDetailsCancellationCard({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    final row = view.row;
    if (view.row.statusTone != AdminBookingStatusTone.canceled &&
        view.row.statusTone != AdminBookingStatusTone.expired) {
      return const SizedBox.shrink();
    }

    final title = view.row.statusTone == AdminBookingStatusTone.expired
        ? uiTr(context, 'انتهت صلاحية الحجز')
        : uiTr(context, 'حالة الإلغاء');

    return AdminBookingDetailsSectionCard(
      title: title,
      children: [
        if (view.cancellationByLabel.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'تم الإلغاء بواسطة'),
            value: view.cancellationByLabel,
          ),
        if (view.cancellationReason.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'سبب الإلغاء'),
            value: view.cancellationReason,
          ),
        if (row.cancelledAt != null)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'وقت الإلغاء'),
            value: dateTimeFormat(
              'd/M/y – HH:mm',
              row.cancelledAt,
              locale: 'ar',
            ),
          )
        else if (row.expiresAt != null &&
            view.row.statusTone == AdminBookingStatusTone.expired)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'وقت الانتهاء'),
            value: dateTimeFormat(
              'd/M/y – HH:mm',
              row.expiresAt,
              locale: 'ar',
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Route / map
// ---------------------------------------------------------------------------

class AdminBookingDetailsRouteSection extends StatelessWidget {
  const AdminBookingDetailsRouteSection({
    super.key,
    required this.view,
    required this.mapLocation,
    required this.googleMapsController,
    required this.googleMapsCenter,
    required this.onCameraIdle,
  });

  final AdminBookingDetailsView view;
  final LatLng? mapLocation;
  final Completer<GoogleMapController> googleMapsController;
  final LatLng? googleMapsCenter;
  final void Function(LatLng) onCameraIdle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final row = view.row;

    return AdminBookingDetailsSectionCard(
      title: uiTr(context, 'مسار الرحلة'),
      children: [
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'نقطة الالتقاء'),
          value: row.pickupLabel,
          icon: Icons.trip_origin_rounded,
        ),
        if (view.pickupCity.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'مدينة الالتقاء'),
            value: view.pickupCity,
          ),
        if (view.pickupCoords.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'الإحداثيات'),
            value: view.pickupCoords,
            isLtr: true,
          ),
        const SizedBox(height: 6),
        AdminBookingDetailsKvRow(
          label: uiTr(context, 'الوجهة'),
          value: row.destinationLabel,
          icon: Icons.place_outlined,
        ),
        if (view.destinationCity.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'مدينة الوجهة'),
            value: view.destinationCity,
          ),
        if (view.destinationCoords.isNotEmpty)
          AdminBookingDetailsKvRow(
            label: uiTr(context, 'الإحداثيات'),
            value: view.destinationCoords,
            isLtr: true,
          ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
          child: SizedBox(
            height: 300,
            child: mapLocation != null &&
                    AdminLocationService.isValidLocation(mapLocation!)
                ? FlutterFlowGoogleMap(
                    controller: googleMapsController,
                    onCameraIdle: onCameraIdle,
                    initialLocation: googleMapsCenter ?? mapLocation!,
                    markers: [
                      FlutterFlowMarker(
                        mapLocation!.serialize(),
                        mapLocation!,
                      ),
                    ],
                    markerColor: GoogleMarkerColor.violet,
                    mapType: MapType.hybrid,
                    style: GoogleMapStyle.standard,
                    initialZoom: 14.0,
                    allowInteraction: true,
                    allowZoom: true,
                    showZoomControls: true,
                    showLocation: true,
                    showCompass: false,
                    showMapToolbar: false,
                    showTraffic: false,
                    centerMapOnMarkerTap: true,
                    mapTakesGesturePreference: false,
                  )
                : ColoredBox(
                    color: theme.accent1,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined,
                              size: 36, color: theme.primary),
                          const SizedBox(height: 6),
                          Text(
                            uiTr(context, 'موقع الحجز غير متوفر'),
                            style: theme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline + technical
// ---------------------------------------------------------------------------

class AdminBookingDetailsTimeline extends StatelessWidget {
  const AdminBookingDetailsTimeline({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    if (view.timeline.isEmpty) return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);

    return AdminBookingDetailsSectionCard(
      title: uiTr(context, 'سجل الرحلة'),
      children: [
        for (var i = 0; i < view.timeline.length; i++)
          _TimelineRow(
            event: view.timeline[i],
            isLast: i == view.timeline.length - 1,
            theme: theme,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isLast,
    required this.theme,
  });

  final AdminBookingTimelineEvent event;
  final bool isLast;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AdminUi.brandTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.alternate,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      fontWeight: FontWeight.w600,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateTimeFormat(
                      'd/M/y · HH:mm',
                      event.at,
                      locale: 'ar',
                    ),
                    style: theme.labelSmall.override(
                      fontFamily: theme.labelSmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.labelSmallIsCustom,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminBookingDetailsTechnicalPanel extends StatelessWidget {
  const AdminBookingDetailsTechnicalPanel({super.key, required this.view});

  final AdminBookingDetailsView view;

  @override
  Widget build(BuildContext context) {
    final fields = view.technicalFields();
    if (fields.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          uiTr(context, 'معلومات تقنية'),
          style: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily:
                    FlutterFlowTheme.of(context).titleSmallFamily,
                fontWeight: FontWeight.w600,
                useGoogleFonts:
                    !FlutterFlowTheme.of(context).titleSmallIsCustom,
              ),
        ),
        children: fields.entries
            .map(
              (e) => AdminBookingDetailsKvRow(
                label: e.key,
                value: e.value,
                isLtr: true,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class AdminBookingDetailsSkeleton extends StatelessWidget {
  const AdminBookingDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: theme.alternate.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return AdminSafeScrollBody(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bar(double.infinity, 72),
          const SizedBox(height: 12),
          bar(double.infinity, 48),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: bar(double.infinity, 160)),
              const SizedBox(width: 12),
              Expanded(child: bar(double.infinity, 160)),
            ],
          ),
        ],
      ),
    );
  }
}
