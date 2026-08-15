import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '/backend/schema/order_record.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/custom_code/actions/start_tracking_and_update_firebase.dart';
import '/design_system/design_system.dart';

/// Compact indicator shown on active-trip screens so drivers (and App Review)
/// can see that live location sharing is on for this trip only.
class DriverLiveTrackingBanner extends StatefulWidget {
  const DriverLiveTrackingBanner({super.key, required this.order});

  final OrderRecord order;

  @override
  State<DriverLiveTrackingBanner> createState() =>
      _DriverLiveTrackingBannerState();
}

class _DriverLiveTrackingBannerState extends State<DriverLiveTrackingBanner> {
  String? _shownMessage;

  @override
  void initState() {
    super.initState();
    tripTrackingUserMessage.addListener(_onTrackingMessage);
  }

  @override
  void dispose() {
    tripTrackingUserMessage.removeListener(_onTrackingMessage);
    super.dispose();
  }

  void _onTrackingMessage() {
    final msg = tripTrackingUserMessage.value;
    if (!mounted || msg == null || msg == _shownMessage) return;
    _shownMessage = msg;
    DriverDialogs.showSnackBar(
      context,
      driverTr(context, msg),
      type: DriverMessageType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = DriverTripService.isActiveTripForCurrentDriver(widget.order) ||
        DriverTripHalh.isActiveTrip(widget.order.halhText);
    if (!active) return const SizedBox.shrink();

    final colors = context.dsColors;
    final typography = context.dsTypography;

    return ValueListenableBuilder<bool>(
      valueListenable: tripBackgroundTrackingActive,
      builder: (context, sharing, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.sm,
            DsSpacing.xxs,
            DsSpacing.sm,
            DsSpacing.xxs,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.sm,
              vertical: DsSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: sharing
                  ? colors.primarySoft
                  : colors.warning.withValues(alpha: 0.12),
              borderRadius: DsRadius.medium,
              border: Border.all(
                color: sharing
                    ? colors.primary.withValues(alpha: 0.35)
                    : colors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  sharing
                      ? Icons.my_location_rounded
                      : Icons.location_searching,
                  size: 18,
                  color: sharing ? colors.primary : colors.warning,
                ),
                DsSpacing.gapSm,
                Expanded(
                  child: Text(
                    sharing
                        ? driverTr(
                            context,
                            'Live tracking active — sharing your location during this trip',
                          )
                        : driverTr(
                            context,
                            'Trip active — enable Always location for background updates',
                          ),
                    style: typography.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                if (!sharing)
                  TextButton(
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                    },
                    child: Text(
                      driverTr(context, 'Settings'),
                      style: typography.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
