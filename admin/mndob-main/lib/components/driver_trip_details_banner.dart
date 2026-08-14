import 'dart:async';

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/order_record.dart';
import '/core/driver_country_service.dart';
import '/core/driver_i18n.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';

/// Trip info banner: payment, type, luggage, waiting, ETA, vehicle, driver.
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

  String get _currency {
    final iso = DriverCountryService.currentIso2();
    return TouryCountryRegistry.currencySymbol(iso);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final order = widget.order;
    final payment =
        DriverPaymentLabels.label(order.paymentMethod, context: context);
    final payStatusKey = DriverPaymentStatusMapper.displayKey(
      DriverPaymentStatusMapper.normalizeStatus(order),
    );
    final payStatus = driverTr(context, payStatusKey);
    final tripType = driverTr(context, order.tripTypeLabelKey());
    final fare = order.total;
    final fareText = (fare.isNaN || fare.isInfinite)
        ? '—'
        : '${fare.toStringAsFixed(fare.truncateToDouble() == fare ? 0 : 2)} $_currency';
    final luggage = order.luggageEstimate.isEmpty
        ? ''
        : driverTr(context, order.luggageLabelKey());
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (rating != null)
                      Text(
                        driverTrNamed(context, 'Rating: {value}', {
                          'value': '${rating.toStringAsFixed(1)} ★',
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: _chip(
                  context,
                  payment,
                  DriverPaymentLabels.isCash(order.paymentMethod)
                      ? colors.success
                      : colors.primary,
                ),
              ),
            ],
          ),
          DsSpacing.gapSm,
          _row(context, driverTr(context, 'Customer'), order.naimUserText),
          _row(
            context,
            driverTr(context, 'Pickup point'),
            order.pickupLabel(),
          ),
          _row(
            context,
            driverTr(context, 'Destination'),
            order.destinationLabel(),
          ),
          _row(
            context,
            driverTr(context, 'Estimated fare'),
            fareText,
          ),
          _row(
            context,
            driverTr(context, 'Payment status'),
            payStatus,
          ),
          _row(context, driverTr(context, 'Trip type'), tripType),
          if (luggage.isNotEmpty)
            _row(context, driverTr(context, 'Luggage'), luggage),
          _row(
            context,
            driverTr(context, 'Vehicle'),
            '${valueOrDefault(currentUserDocument?.textTypeCarMndob, order.cartext)} · ${valueOrDefault(currentUserDocument?.nameCar, order.nameCar)} · ${valueOrDefault(currentUserDocument?.modelCar, order.modelCar)} · ${valueOrDefault(currentUserDocument?.mdenhAml, '—')} · ${valueOrDefault(currentUserDocument?.numberLohhCar, '—')}',
          ),
          if (order.etaSeconds > 0 || order.distanceRemainingMeters > 0) ...[
            Divider(height: DsSpacing.md, color: colors.divider),
            _row(
              context,
              driverTr(context, 'Remaining distance'),
              distKm >= 1
                  ? driverTrNamed(context, '{km} km', {
                      'km': distKm.toStringAsFixed(1),
                    })
                  : driverTrNamed(context, '{m} m', {
                      'm': '${order.distanceRemainingMeters.round()}',
                    }),
            ),
            _row(
              context,
              driverTr(context, 'ETA'),
              () {
                final approx = order.snapshotData['etaApproximate'] == true;
                final base = driverTrNamed(
                  context,
                  '{min} min',
                  {'min': '$etaMin'},
                );
                final suffix = approx
                    ? ' (${driverTr(context, 'estimated')})'
                    : ' (${driverTr(context, 'based on traffic')})';
                return '$base$suffix';
              }(),
            ),
          ],
          if (order.halhText == DriverTripHalh.driverArrived ||
              order.waitingStartedAt != null) ...[
            Divider(height: DsSpacing.md, color: colors.divider),
            _row(context, driverTr(context, 'Waiting time'), waitingText),
            if (order.waitingCharges > 0)
              _row(
                context,
                driverTr(context, 'Waiting charges'),
                '${order.waitingCharges.toStringAsFixed(2)} $_currency',
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
              label: driverTr(context, 'Confirm arrival to customer'),
              icon: Icons.place,
              onPressed: () async {
                final loc = await getCurrentUserLocation(
                  defaultLocation: const LatLng(0, 0),
                  cached: true,
                ).timeout(
                  const Duration(seconds: 6),
                  onTimeout: () => const LatLng(0, 0),
                );
                await DriverTripService.markDriverArrived(
                  orderRef: order.reference,
                  driverLocation: loc,
                  customerRef: order.user,
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
            width: 118,
            child: Text(
              label,
              style: typography.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: typography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    final typography = context.dsTypography;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: DsRadius.pill,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: typography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
