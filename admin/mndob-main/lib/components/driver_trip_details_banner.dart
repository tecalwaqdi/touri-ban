import 'dart:async';

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/order_record.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';

/// شريط معلومات الرحلة: الدفع، النوع، الأمتعة، الانتظار، ETA، المركبة، المندوب.
class DriverTripDetailsBanner extends StatefulWidget {
  const DriverTripDetailsBanner({
    super.key,
    required this.order,
    this.onArrived,
    this.showArrivalButton = true,
  });

  final OrderRecord order;
  final VoidCallback? onArrived;
  final bool showArrivalButton;

  @override
  State<DriverTripDetailsBanner> createState() =>
      _DriverTripDetailsBannerState();
}

class _DriverTripDetailsBannerState extends State<DriverTripDetailsBanner> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.order.halhText == DriverTripHalh.driverArrived ||
          widget.order.waitingStartedAt != null) {
        setState(() {});
        unawaited(DriverTripService.persistWaitingCharges(widget.order));
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final order = widget.order;
    final payment = DriverPaymentLabels.label(order.paymentMethod);
    final waiting = DriverTripService.waitingDuration(order);
    final waitingText =
        '${waiting.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(waiting.inSeconds % 60).toString().padLeft(2, '0')}';
    final etaMin = (order.etaSeconds / 60).ceil();
    final distKm = order.distanceRemainingMeters / 1000;
    final rating = functions.averageRating(
      (currentUserDocument?.reteng.toList() ?? []).toList(),
    );

    return DsCard(
      margin: const EdgeInsets.fromLTRB(
        DsSpacing.sm,
        DsSpacing.xs,
        DsSpacing.sm,
        DsSpacing.xxs,
      ),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primarySoft,
                backgroundImage: currentUserPhoto.isNotEmpty
                    ? NetworkImage(currentUserPhoto)
                    : null,
                child: currentUserPhoto.isEmpty
                    ? Icon(Icons.person, size: 22, color: colors.primary)
                    : null,
              ),
              DsSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUserDisplayName,
                      style: typography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (rating != null)
                      Text(
                        'التقييم: ${rating.toStringAsFixed(1)} ★',
                        style: typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              _chip(
                context,
                payment,
                DriverPaymentLabels.isCash(order.paymentMethod)
                    ? colors.success
                    : colors.primary,
              ),
            ],
          ),
          DsSpacing.gapSm,
          _row(context, 'العميل', order.naimUserText),
          _row(context, 'نقطة الالتقاط', order.pickupLabel()),
          _row(context, 'الوجهة', order.destinationLabel()),
          _row(context, 'الأجرة التقديرية', '${order.total} ر.س'),
          _row(context, 'نوع الرحلة', order.tripTypeLabel()),
          if (order.luggageEstimate.isNotEmpty)
            _row(context, 'الأمتعة', order.luggageLabel()),
          _row(
            context,
            'المركبة',
            '${valueOrDefault(currentUserDocument?.textTypeCarMndob, order.cartext)} · ${valueOrDefault(currentUserDocument?.nameCar, order.nameCar)} · ${valueOrDefault(currentUserDocument?.modelCar, order.modelCar)} · ${valueOrDefault(currentUserDocument?.mdenhAml, '—')} · ${valueOrDefault(currentUserDocument?.numberLohhCar, '—')}',
          ),
          if (order.etaSeconds > 0 || order.distanceRemainingMeters > 0) ...[
            Divider(height: DsSpacing.md, color: colors.divider),
            _row(
              context,
              'المسافة المتبقية',
              distKm >= 1
                  ? '${distKm.toStringAsFixed(1)} كم'
                  : '${order.distanceRemainingMeters.round()} م',
            ),
            _row(context, 'وقت الوصول التقديري', '$etaMin دقيقة'),
          ],
          if (order.halhText == DriverTripHalh.driverArrived ||
              order.waitingStartedAt != null) ...[
            Divider(height: DsSpacing.md, color: colors.divider),
            _row(context, 'وقت الانتظار', waitingText),
            if (order.waitingCharges > 0)
              _row(
                context,
                'رسوم الانتظار',
                '${order.waitingCharges.toStringAsFixed(2)} ر.س',
              ),
          ],
          if (widget.showArrivalButton &&
              order.mndobUser?.path == currentUserReference?.path &&
              (order.halhText == DriverTripHalh.accepted ||
                  (order.snapshotData['status_code'] ?? '') ==
                      'driver_assigned' ||
                  (order.snapshotData['status_code'] ?? '') ==
                      'driver_arriving')) ...[
            DsSpacing.gapSm,
            DsButton.primary(
              label: 'تأكيد الوصول للعميل',
              icon: Icons.place,
              onPressed: () async {
                final loc = await getCurrentUserLocation(
                  defaultLocation: const LatLng(0, 0),
                );
                await DriverTripService.markDriverArrived(
                  orderRef: order.reference,
                  driverLocation: loc,
                );
                widget.onArrived?.call();
              },
              expanded: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: typography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: DsSpacing.chipPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: DsRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: DsTypography.fontFamily,
        ),
      ),
    );
  }
}
