import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/core/driver_design_system.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';
import '/core/toury_maps_config.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// خريطة تسجيل المندوب — تلتقط الموقع الفعلي وتسمح بتحريك الدبوس.
class DriverRegLocationMap extends StatefulWidget {
  const DriverRegLocationMap({
    super.key,
    required this.location,
    required this.onLocationChanged,
  });

  final LatLng? location;
  final ValueChanged<LatLng> onLocationChanged;

  @override
  State<DriverRegLocationMap> createState() => _DriverRegLocationMapState();
}

class _DriverRegLocationMapState extends State<DriverRegLocationMap> {
  final Completer<gmaps.GoogleMapController> _controller = Completer();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(force: true));
  }

  Future<void> _locate({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = await getCurrentUserLocation(
        defaultLocation: const LatLng(0, 0),
      );
      if (!TouryMapsConfig.isUsableCoordinate(loc)) {
        throw Exception('invalid');
      }
      widget.onLocationChanged(loc);
      if (_controller.isCompleted) {
        final map = await _controller.future;
        await map.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(
            gmaps.LatLng(loc.latitude, loc.longitude),
            15,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = driverTr(
          context,
          'Enable location to continue registration',
        );
      });
      if (force && mounted) {
        await DriverDialogs.showAlert(
          context,
          title: driverTr(context, 'Location'),
          message: driverTr(
            context,
            'Enable GPS and allow location access so we can place you on the map',
          ),
          type: DriverMessageType.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final center = TouryMapsConfig.resolveLocation(widget.location);
    final hasGps = TouryMapsConfig.isUsableCoordinate(widget.location);

    return DsCard(
      elevated: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DsSpacing.sm,
              DsSpacing.sm,
              DsSpacing.sm,
              DsSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(Icons.my_location, color: colors.primaryStrong),
                DsSpacing.gapXs,
                Expanded(
                  child: Text(
                    driverTr(context, 'Your current location'),
                    style: typography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primaryStrong,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: driverTr(context, 'Refresh location'),
                  onPressed: _loading ? null : () => _locate(force: true),
                  icon: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(colors.primary),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DsSpacing.sm,
              0,
              DsSpacing.sm,
              DsSpacing.xs,
            ),
            child: Text(
              driverTr(
                context,
                'Move the map to adjust your position. Orders will match by this live location.',
              ),
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterFlowGoogleMap(
                  controller: _controller,
                  initialLocation: center,
                  initialZoom: hasGps ? 15 : TouryMapsConfig.defaultZoom,
                  allowInteraction: true,
                  allowZoom: true,
                  showZoomControls: false,
                  showCompass: false,
                  showMapToolbar: false,
                  showTraffic: false,
                  showLocation: true,
                  mapTakesGesturePreference: true,
                  centerMapOnMarkerTap: false,
                  markers: const [],
                  onCameraIdle: (latLng) {
                    if (!TouryMapsConfig.isUsableCoordinate(latLng)) return;
                    if (!hasGps && !_loading) return;
                    if (!hasGps) return;
                    widget.onLocationChanged(latLng);
                  },
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 28),
                      child: Icon(
                        Icons.location_on,
                        size: 42,
                        color: DriverBrand.partnerRed,
                      ),
                    ),
                  ),
                ),
                if (_error != null)
                  Positioned(
                    left: DsSpacing.xs,
                    right: DsSpacing.xs,
                    bottom: DsSpacing.xs,
                    child: Material(
                      color: colors.error.withValues(alpha: 0.92),
                      borderRadius: DsRadius.small,
                      child: Padding(
                        padding: DsSpacing.cardPadding,
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: typography.labelSmall.copyWith(
                            color: colors.onError,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasGps)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DsSpacing.sm,
                DsSpacing.xs,
                DsSpacing.sm,
                DsSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colors.success, size: 18),
                  DsSpacing.gapXs,
                  Expanded(
                    child: Text(
                      '${widget.location!.latitude.toStringAsFixed(5)}, '
                      '${widget.location!.longitude.toStringAsFixed(5)}',
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
