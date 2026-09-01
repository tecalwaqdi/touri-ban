import 'package:flutter/material.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/backend/schema/order_record.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact lifecycle / finance facts for booking details (admin-only labels).
class AdminBookingDetailsExtras extends StatelessWidget {
  const AdminBookingDetailsExtras({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final row = AdminBookingRow.fromOrder(order);

    final timeline = <(String, DateTime?)>[
      (uiTr(context, 'إنشاء الحجز'), row.createdAt),
      (uiTr(context, 'قبول المندوب'), row.acceptedAt),
      (uiTr(context, 'الوصول'), row.arrivedAt),
      (uiTr(context, 'بدء الرحلة'), row.startedAt),
      (uiTr(context, 'الاكتمال'), row.completedAt),
      (uiTr(context, 'الإلغاء'), row.cancelledAt),
      (uiTr(context, 'انتهاء الصلاحية'), row.expiresAt),
    ].where((e) => e.$2 != null).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AdminUi.cardDecoration(context, elevated: false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  uiTr(context, 'ملخص تشغيلي'),
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
                const SizedBox(height: 10),
                _kv(context, uiTr(context, 'الحالة'),
                    row.statusLabel.isEmpty ? '—' : row.statusLabel),
                _kv(
                  context,
                  uiTr(context, 'نقطة الانطلاق'),
                  row.pickupLabel.isEmpty ? '—' : row.pickupLabel,
                ),
                _kv(
                  context,
                  uiTr(context, 'الوجهة'),
                  row.destinationLabel.isEmpty ? '—' : row.destinationLabel,
                ),
                if (row.landmarksLabel.isNotEmpty)
                  _kv(context, uiTr(context, 'المعالم'), row.landmarksLabel),
                _kv(
                  context,
                  uiTr(context, 'نوع السيارة'),
                  row.vehicleLabel.isEmpty ? '—' : row.vehicleLabel,
                ),
                if (row.plateLabel.isNotEmpty)
                  _kv(context, uiTr(context, 'لوحة السيارة'), row.plateLabel),
                _kv(
                  context,
                  uiTr(context, 'مدة الحجز'),
                  row.durationMinutes > 0
                      ? '${row.durationMinutes} ${uiTr(context, 'دقيقة')}'
                      : '—',
                ),
                _kv(
                  context,
                  uiTr(context, 'المبلغ'),
                  row.amount > 0
                      ? '${row.amount.toStringAsFixed(2)} ${row.currencySymbol}'
                      : '—',
                ),
                _kv(
                  context,
                  uiTr(context, 'عمولة الشركة'),
                  row.commission > 0
                      ? '${row.commission.toStringAsFixed(2)} ${row.currencySymbol}'
                      : '—',
                ),
                _kv(
                  context,
                  row.driverNetIsDerived
                      ? uiTr(context, 'صافي المندوب (مشتق)')
                      : uiTr(context, 'صافي المندوب'),
                  row.driverNetLabel,
                ),
                _kv(
                  context,
                  uiTr(context, 'الدفع'),
                  row.paymentLabel.isEmpty ? '—' : row.paymentLabel,
                ),
              ],
            ),
          ),
          if (timeline.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AdminUi.cardDecoration(context, elevated: false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    uiTr(context, 'التوقيتات'),
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w700,
                      useGoogleFonts: !theme.titleSmallIsCustom,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...timeline.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.$1,
                              style: theme.bodySmall.override(
                                fontFamily: theme.bodySmallFamily,
                                color: theme.secondaryText,
                                useGoogleFonts: !theme.bodySmallIsCustom,
                              ),
                            ),
                          ),
                          Text(
                            dateTimeFormat(
                              'd/M/y – HH:mm',
                              e.$2,
                              locale: 'ar',
                            ),
                            style: theme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              k,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodySmallIsCustom,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: theme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
