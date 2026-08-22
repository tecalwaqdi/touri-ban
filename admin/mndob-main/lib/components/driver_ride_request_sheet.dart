import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/schema/order_record.dart';
import '/core/driver_country_service.dart';
import '/core/driver_design_system.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_order_match.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_pickup_eta_cache.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/core/driver_ux_widgets.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

typedef DriverRideAcceptCallback = Future<DriverWalletGateResult> Function(
  OrderRecord order,
);
typedef DriverRideRejectCallback = void Function(OrderRecord order);

/// بطاقة طلب رحلة جديد مع قبول / رفض — بهوية توري.
class DriverRideRequestSheet extends StatefulWidget {
  const DriverRideRequestSheet({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    this.driverPosition,
    this.autoRejectAfter = const Duration(seconds: 30),
  });

  final OrderRecord order;
  final DriverRideAcceptCallback onAccept;
  final DriverRideRejectCallback onReject;
  final LatLng? driverPosition;
  final Duration autoRejectAfter;

  static Future<bool?> show(
    BuildContext context, {
    required OrderRecord order,
    required DriverRideAcceptCallback onAccept,
    required DriverRideRejectCallback onReject,
    LatLng? driverPosition,
    Duration autoRejectAfter = const Duration(seconds: 30),
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => DriverRideRequestSheet(
        order: order,
        onAccept: onAccept,
        onReject: onReject,
        driverPosition: driverPosition,
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
  bool _accepting = false;
  double? _distanceKm;
  int? _etaMinutes;
  bool _etaApproximate = true;
  bool _metricsLoading = true;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.autoRejectAfter.inSeconds.clamp(5, 120);
    _deadline = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _closing || _accepting) return;
      if (_secondsLeft <= 1) {
        _reject();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
    unawaited(_loadMetrics());
  }

  @override
  void dispose() {
    _deadline?.cancel();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    final order = widget.order;
    final driver = widget.driverPosition ?? DriverOrderMatch.driverLivePosition();
    final pickup = DriverOrderMatch.pickupOf(order);
    final haversineKm = DriverOrderMatch.distanceKm(order, driver);

    DriverPickupEta? eta;
    try {
      eta = await DriverPickupEtaCache.forPickup(
        orderId: order.reference.id,
        driver: driver,
        pickup: pickup,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      eta = null;
    }

    if (!mounted) return;
    setState(() {
      if (eta != null && eta.distanceMeters > 0) {
        _distanceKm = eta.distanceKm;
        _etaMinutes = eta.durationMinutes;
        _etaApproximate = eta.approximate;
      } else if (haversineKm != null) {
        _distanceKm = haversineKm;
        // Rough city estimate ~28 km/h when Routes CF unavailable.
        _etaMinutes = (haversineKm / 28.0 * 60.0).ceil().clamp(1, 180);
        _etaApproximate = true;
      } else {
        _distanceKm = null;
        _etaMinutes = null;
      }
      _metricsLoading = false;
    });
  }

  void _reject() {
    if (_closing || _accepting) return;
    _closing = true;
    _deadline?.cancel();
    if (mounted) Navigator.pop(context, false);
    widget.onReject(widget.order);
  }

  void _resumeOfferTimer() {
    _deadline?.cancel();
    if (!mounted || _closing) return;
    setState(() {
      _accepting = false;
      _secondsLeft = widget.autoRejectAfter.inSeconds.clamp(5, 120);
      _deadline = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _closing || _accepting) return;
        if (_secondsLeft <= 1) {
          _reject();
          return;
        }
        setState(() => _secondsLeft -= 1);
      });
    });
  }

  Future<void> _accept() async {
    if (_closing || _accepting) return;
    setState(() => _accepting = true);
    _deadline?.cancel();

    final order = widget.order;
    try {
      // Single official accept path (wallet + CF/txn) — no pre-check delay.
      final result = await widget.onAccept(order);
      if (!mounted) return;
      if (!result.ok) {
        final isWallet = result.code == 'DRIVER_WALLET_INSUFFICIENT' ||
            result.code == 'insufficient-wallet';
        await DriverDialogs.showAlert(
          context,
          title: driverTr(
            context,
            isWallet ? 'Insufficient balance' : 'Unable to accept',
          ),
          message: _userFacingMessage(result),
          type: isWallet ? DriverMessageType.warning : DriverMessageType.error,
        );
        _resumeOfferTimer();
        return;
      }

      _closing = true;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      await DriverDialogs.showAlert(
        context,
        title: driverTr(context, 'Unable to accept'),
        message: driverTr(
          context,
          DriverTripService.messageForCode('BOOKING_ASSIGNMENT_FAILED'),
        ),
        type: DriverMessageType.error,
      );
      _resumeOfferTimer();
    }
  }

  String _userFacingMessage(DriverWalletGateResult result) {
    final code = (result.code ?? '').trim();
    final msg = (result.message ?? '').trim();
    if (_looksTechnical(msg)) {
      return driverTr(
        context,
        DriverTripService.messageForCode(
          code.isEmpty ? 'BOOKING_ASSIGNMENT_FAILED' : code,
        ),
      );
    }
    if (msg.isNotEmpty) {
      // Already localized Arabic/English phrases from acceptOrder.
      final viaKey = driverTr(context, msg);
      return viaKey;
    }
    return driverTr(
      context,
      DriverTripService.messageForCode(
        code.isEmpty ? 'BOOKING_ASSIGNMENT_FAILED' : code,
      ),
    );
  }

  bool _looksTechnical(String msg) {
    if (msg.isEmpty) return true;
    final upper = msg.toUpperCase();
    return upper == 'INTERNAL' ||
        upper.contains('STACK') ||
        upper.contains('EXCEPTION') ||
        upper.contains('FIREBASE') ||
        RegExp(r'^[A-Z0-9_:-]+$').hasMatch(msg);
  }

  String get _currency {
    final iso = DriverCountryService.currentIso2();
    return TouryCountryRegistry.currencySymbol(iso);
  }

  String? get _tripDistanceLabel {
    final meters = widget.order.plannedDistanceMeters;
    if (meters <= 0) return null;
    if (meters >= 1000) {
      return driverTrNamed(context, '{km} km', {
        'km': (meters / 1000).toStringAsFixed(1),
      });
    }
    return driverTrNamed(context, '{m} m', {
      'm': meters.round().toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final order = widget.order;
    final payment =
        DriverPaymentLabels.label(order.paymentMethod, context: context);
    final fare = order.total;
    final fareText = (fare.isNaN || fare.isInfinite)
        ? '—'
        : '${fare.toStringAsFixed(fare.truncateToDouble() == fare ? 0 : 2)} $_currency';
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DsFadeSlide(
      offset: const Offset(0, 0.06),
      duration: DsDurations.emphasis,
      child: DsCard(
        margin: EdgeInsets.fromLTRB(
          DsSpacing.sm,
          DsSpacing.sm,
          DsSpacing.sm,
          DsSpacing.sm + bottomInset,
        ),
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.lg,
          DsSpacing.md,
          DsSpacing.lg,
          DsSpacing.lg,
        ),
        elevated: true,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          width: 44,
                          height: 44,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primaryStrong,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DsSpacing.sm,
                            vertical: DsSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: DsRadius.pill,
                          ),
                          child: Text(
                            '${_secondsLeft}s',
                            style: typography.labelLarge.copyWith(
                              color: DriverBrand.partnerRed,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DsSpacing.gapMd,
                  _heroBlock(
                    context,
                    icon: Icons.trip_origin_rounded,
                    label: driverTr(context, 'Pickup point'),
                    value: order.pickupLabel(),
                    emphasize: true,
                  ),
                  _routeConnector(context),
                  _heroBlock(
                    context,
                    icon: Icons.flag_rounded,
                    label: driverTr(context, 'Destination'),
                    value: order.destinationLabel(),
                    emphasize: true,
                  ),
                  DsSpacing.gapMd,
                  _metricsRow(context),
                  DsSpacing.gapSm,
                  _infoChipRow(
                    context,
                    [
                      (
                        driverTr(context, 'Payment method'),
                        payment,
                      ),
                      (
                        driverTr(context, 'Estimated fare'),
                        fareText,
                      ),
                    ],
                  ),
                  DsSpacing.gapXs,
                  _infoChipRow(
                    context,
                    [
                      (
                        driverTr(context, 'Trip type'),
                        driverTr(context, order.tripTypeLabelKey()),
                      ),
                      if (order.luggageEstimate.isNotEmpty)
                        (
                          driverTr(context, 'Luggage'),
                          driverTr(context, order.luggageLabelKey()),
                        ),
                      if (_tripDistanceLabel != null)
                        (
                          driverTr(context, 'Trip distance'),
                          _tripDistanceLabel!,
                        ),
                    ],
                  ),
                  if (order.naimUserText.trim().isNotEmpty) ...[
                    DsSpacing.gapSm,
                    _line(
                      context,
                      driverTr(context, 'Customer'),
                      order.naimUserText,
                    ),
                  ],
                  if (DriverPaymentLabels.isCash(order.paymentMethod)) ...[
                    DsSpacing.gapSm,
                    DsInformationCard(
                      title: driverTr(context, 'Cash payment'),
                      message: driverTrNamed(
                        context,
                        'Cash payment wallet notice',
                        {
                          'amount': DriverWalletRules.minCashWalletBalance
                              .toStringAsFixed(0),
                        },
                      ),
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
                          onPressed: (_closing || _accepting) ? null : _reject,
                          enabled: !_closing && !_accepting,
                          expanded: true,
                          size: DsButtonSize.lg,
                        ),
                      ),
                      DsSpacing.gapSm,
                      Expanded(
                        flex: 2,
                        child: DriverGradientButton(
                          label: driverTr(context, 'Accept ride'),
                          icon: Icons.check_circle_rounded,
                          loading: _accepting,
                          onPressed:
                              (_closing || _accepting) ? null : _accept,
                          height: 52,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricsRow(BuildContext context) {
    final distanceText = _metricsLoading
        ? '…'
        : (_distanceKm == null
            ? '—'
            : driverTrNamed(context, '{km} km', {
                'km': _distanceKm! >= 10
                    ? _distanceKm!.toStringAsFixed(0)
                    : _distanceKm!.toStringAsFixed(1),
              }));
    final etaText = _metricsLoading
        ? '…'
        : (_etaMinutes == null
            ? '—'
            : driverTrNamed(context, '{min} min', {
                'min': '$_etaMinutes',
              }));

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context,
            icon: Icons.near_me_rounded,
            label: driverTr(context, 'Distance to customer'),
            value: distanceText,
          ),
        ),
        DsSpacing.gapSm,
        Expanded(
          child: _metricCard(
            context,
            icon: Icons.schedule_rounded,
            label: driverTr(context, 'ETA'),
            value: etaText,
            footnote: _etaApproximate && _etaMinutes != null
                ? driverTr(context, 'Approximate')
                : null,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? footnote,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Container(
      padding: const EdgeInsets.all(DsSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primarySoft.withValues(alpha: 0.55),
        borderRadius: DsRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primaryStrong),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(
              footnote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.labelSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroBlock(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.primaryStrong, size: 22),
        DsSpacing.gapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: (emphasize ? typography.titleMedium : typography.bodyLarge)
                    .copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _routeConnector(BuildContext context) {
    final colors = context.dsColors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 10,
        top: 4,
        bottom: 4,
      ),
      child: Container(
        width: 2,
        height: 16,
        color: colors.primary.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _infoChipRow(
    BuildContext context,
    List<(String, String)> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: DsSpacing.xs,
      runSpacing: DsSpacing.xs,
      children: items
          .map(
            (e) => ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.42,
              ),
              child: _miniChip(context, e.$1, e.$2),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _miniChip(BuildContext context, String label, String value) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: DsRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
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
