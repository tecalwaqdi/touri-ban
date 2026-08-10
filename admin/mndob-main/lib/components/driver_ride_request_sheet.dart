import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/schema/order_record.dart';
import '/core/driver_async_guard.dart';
import '/core/driver_country_service.dart';
import '/core/driver_design_system.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/core/driver_ux_widgets.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

typedef DriverRideAcceptCallback = Future<void> Function(OrderRecord order);
typedef DriverRideRejectCallback = void Function(OrderRecord order);

/// بطاقة طلب رحلة جديد مع قبول / رفض — بهوية توري.
class DriverRideRequestSheet extends StatefulWidget {
  const DriverRideRequestSheet({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    this.autoRejectAfter = const Duration(seconds: 30),
  });

  final OrderRecord order;
  final DriverRideAcceptCallback onAccept;
  final DriverRideRejectCallback onReject;
  final Duration autoRejectAfter;

  static Future<void> show(
    BuildContext context, {
    required OrderRecord order,
    required DriverRideAcceptCallback onAccept,
    required DriverRideRejectCallback onReject,
    Duration autoRejectAfter = const Duration(seconds: 30),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => DriverRideRequestSheet(
        order: order,
        onAccept: onAccept,
        onReject: onReject,
        autoRejectAfter: autoRejectAfter,
      ),
    );
  }

  @override
  State<DriverRideRequestSheet> createState() => _DriverRideRequestSheetState();
}

class _DriverRideRequestSheetState extends State<DriverRideRequestSheet> {
  Timer? _deadline;
  int _secondsLeft = 30;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.autoRejectAfter.inSeconds.clamp(5, 120);
    _deadline = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _closing) return;
      if (_secondsLeft <= 1) {
        _reject();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _deadline?.cancel();
    super.dispose();
  }

  void _reject() {
    if (_closing) return;
    _closing = true;
    _deadline?.cancel();
    if (mounted) Navigator.pop(context);
    widget.onReject(widget.order);
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

    return DsCard(
      margin: const EdgeInsets.all(DsSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.lg,
        DsSpacing.md,
        DsSpacing.lg,
        DsSpacing.xl,
      ),
      elevated: true,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.sm,
                vertical: DsSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: DriverBrand.softGradient,
                borderRadius: DsRadius.medium,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: DriverBrand.partnerRed,
                    ),
                  ),
                  DsSpacing.gapSm,
                  Expanded(
                    child: Text(
                      driverTr(context, 'New ride request'),
                      style: typography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primaryStrong,
                      ),
                    ),
                  ),
                  Text(
                    '${_secondsLeft}s',
                    style: typography.labelLarge.copyWith(
                      color: DriverBrand.partnerRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            DsSpacing.gapSm,
            _line(
              context,
              driverTr(context, 'Customer'),
              order.naimUserText,
            ),
            _line(
              context,
              driverTr(context, 'Pickup point'),
              order.pickupLabel(),
            ),
            _line(
              context,
              driverTr(context, 'Destination'),
              order.destinationLabel(),
            ),
            _line(
              context,
              driverTr(context, 'Estimated fare'),
              '${order.total} $_currency',
            ),
            _line(context, driverTr(context, 'Payment method'), payment),
            _line(
              context,
              driverTr(context, 'Trip type'),
              driverTr(context, order.tripTypeLabelKey()),
            ),
            if (order.luggageEstimate.isNotEmpty)
              _line(
                context,
                driverTr(context, 'Luggage'),
                driverTr(context, order.luggageLabelKey()),
              ),
            if (DriverPaymentLabels.isCash(order.paymentMethod)) ...[
              DsSpacing.gapXs,
              DsInformationCard(
                title: driverTr(context, 'Cash payment'),
                message: driverTrNamed(context, 'Cash payment wallet notice', {
                  'amount': DriverWalletRules.minCashWalletBalance
                      .toStringAsFixed(0),
                }),
                tone: DsInfoTone.warning,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
            DsSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: DsButton.danger(
                    label: driverTr(context, 'Reject'),
                    onPressed: _reject,
                    expanded: true,
                  ),
                ),
                DsSpacing.gapSm,
                Expanded(
                  child: DriverGradientButton(
                    label: driverTr(context, 'Accept'),
                    icon: Icons.check_circle_rounded,
                    onPressed: () async {
                      await driverRunGuarded(context, () async {
                        final gate =
                            await DriverTripService.validateWalletForAccept(
                          order: order,
                        );
                        if (!gate.ok) {
                          if (context.mounted) {
                            await DriverDialogs.showAlert(
                              context,
                              title: driverTr(context, 'Insufficient balance'),
                              message: gate.message ?? '',
                              type: DriverMessageType.warning,
                            );
                          }
                          return;
                        }
                        _closing = true;
                        _deadline?.cancel();
                        if (context.mounted) Navigator.pop(context);
                        await widget.onAccept(order);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String k, String v) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              k,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            flex: 3,
            child: Text(
              v,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
}
