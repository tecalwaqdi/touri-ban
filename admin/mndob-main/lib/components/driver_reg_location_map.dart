import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/core/driver_design_system.dart';
import '/core/driver_dialogs.dart';
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

class _DriverRegLocationMapState extends State<DriverRegLocationMap>
    with WidgetsBindingObserver {
  final Completer<gmaps.GoogleMapController> _controller = Completer();
  bool _loading = true;
  bool _locateInFlight = false;
  String? _error;
  LatLng? _lastIdleCenter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.future.then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _flushIdleCenter());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(force: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshGpsDiagnostics();
      if (!TouryMapsConfig.isUsableCoordinate(widget.location)) {
        _flushIdleCenter();
      }
    }
  }

  void _commitCenter(LatLng latLng) {
    if (!TouryMapsConfig.isUsableCoordinate(latLng)) return;
    _lastIdleCenter = latLng;
    widget.onLocationChanged(latLng);
  }

  void _flushIdleCenter() {
    final center = _lastIdleCenter;
    if (center != null) {
      _commitCenter(center);
      return;
    }
    unawaited(_syncVisibleMapCenter());
  }

  Future<void> _syncVisibleMapCenter() async {
    if (!_controller.isCompleted || !mounted) return;
    try {
      final map = await _controller.future;
      final bounds = await map.getVisibleRegion();
      final latLng = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      if (TouryMapsConfig.isUsableCoordinate(latLng)) {
        _commitCenter(latLng);
      }
    } catch (_) {}
  }

  Future<String> _gpsFailureMessage() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return driverTr(
        context,
        'Turn on Location Services on your device to use GPS',
      );
    }
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return driverTr(
        context,
        'Allow this app to access your location in Settings',
      );
    }
    if (permission == LocationPermission.denied) {
      return driverTr(
        context,
        'Allow this app to access your location to use GPS',
      );
    }
    return driverTr(
      context,
      'Enable GPS and allow location access so we can place you on the map',
    );
  }

  Future<void> _refreshGpsDiagnostics() async {
    if (!mounted) return;
    if (TouryMapsConfig.isUsableCoordinate(widget.location)) {
      if (_error != null) setState(() => _error = null);
      return;
    }
    final message = await _gpsFailureMessage();
    if (mounted && _error != message) {
      setState(() => _error = message);
    }
  }

  Future<void> _locate({bool force = false}) async {
    if (!mounted || _locateInFlight) return;
    _locateInFlight = true;
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
      _commitCenter(loc);
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
      final message = await _gpsFailureMessage();
      if (!mounted) return;
      setState(() => _error = message);
      if (force && mounted) {
        await DriverDialogs.showAlert(
          context,
          title: driverTr(context, 'Location'),
          message: message,
          type: DriverMessageType.warning,
        );
      }
    } finally {
      _locateInFlight = false;
      if (mounted) {
        setState(() => _loading = false);
        _flushIdleCenter();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final center = TouryMapsConfig.resolveLocation(widget.location);
    final hasSelected = TouryMapsConfig.isUsableCoordinate(widget.location);

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
                'Move the map to set your position. You can place the pin manually if GPS is unavailable.',
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
                  initialZoom: hasSelected ? 15 : TouryMapsConfig.defaultZoom,
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
                    _lastIdleCenter = latLng;
                    if (!_loading) {
                      _commitCenter(latLng);
                    }
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
                if (_error != null && !hasSelected)
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
          if (hasSelected)
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
