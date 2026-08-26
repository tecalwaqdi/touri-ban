import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/backend/schema/order_record.dart';
import '/core/toury_car_marker.dart';
import '/core/toury_directions_service.dart';
import '/core/toury_maps_config.dart';
import '/core/toury_navigation_service.dart';
import '/core/toury_order_meta.dart';
import '/design_system/colors/ds_color_scales.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// خريطة تتبع المندوب: سيارة متحركة + مسار طرق + كاميرا ذكية.
class TouryTripTrackingMap extends StatefulWidget {
  const TouryTripTrackingMap({
    super.key,
    required this.order,
    this.height = 420,
    this.showNavigationButton = true,
  });

  final OrderRecord order;
  final double height;
  final bool showNavigationButton;

  @override
  State<TouryTripTrackingMap> createState() => _TouryTripTrackingMapState();
}

class _TouryTripTrackingMapState extends State<TouryTripTrackingMap>
    with SingleTickerProviderStateMixin {
  static const _markerAnimDuration = Duration(milliseconds: 1400);

  final _controller = Completer<gmaps.GoogleMapController>();

  List<LatLng>? _roadPoints;
  Set<gmaps.Polyline> _polylines = const <gmaps.Polyline>{};
  bool _loadingRoute = false;
  bool _routeApproximate = false;
  int? _routeDurationSeconds;
  int? _routeDistanceMeters;
  String? _routeKey;
  String? _destinationKey;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteFetchAt;

  /// Auto-fit runs once; afterwards the camera belongs to follow mode / user.
  bool _hasFittedOnce = false;

  late final AnimationController _markerAnim;
  LatLng? _displayDriver;
  LatLng? _animFrom;
  LatLng? _animTo;
  double _displayHeading = 0;
  double _headingFrom = 0;
  double _headingTo = 0;

  bool _loadingIcons = false;
  gmaps.BitmapDescriptor? _carIcon;
  gmaps.BitmapDescriptor? _pickupIcon;
  gmaps.BitmapDescriptor? _stopIcon;
  gmaps.BitmapDescriptor? _dropoffIcon;

  /// Camera auto-follows the car until the user pans/zooms manually.
  bool _followDriver = true;
  bool _programmaticCameraMove = false;
  LatLng? _lastFollowedPosition;

  @override
  void initState() {
    super.initState();
    _markerAnim = AnimationController(
      vsync: this,
      duration: _markerAnimDuration,
    )..addListener(_onMarkerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncDriverMarker(animate: false);
      unawaited(_syncRoute());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_loadMarkerIcons());
  }

  @override
  void dispose() {
    _markerAnim
      ..removeListener(_onMarkerTick)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TouryTripTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDriverMarker(animate: true);
    unawaited(_syncRoute());
  }

  Future<void> _loadMarkerIcons() async {
    if (_carIcon != null || _loadingIcons) return;
    _loadingIcons = true;
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3.0;
    final scheme = Theme.of(context).colorScheme;

    final results = await Future.wait<gmaps.BitmapDescriptor>([
      TouryMapMarkers.car(
        body: scheme.primary,
        glass: const Color(0xFF10243B),
        pixelRatio: ratio,
      ),
      TouryMapMarkers.dot(
        color: const Color(0xFF16A34A),
        icon: Icons.my_location_rounded,
        pixelRatio: ratio,
      ),
      TouryMapMarkers.dot(
        color: const Color(0xFFEA580C),
        icon: Icons.flag_rounded,
        pixelRatio: ratio,
      ),
      TouryMapMarkers.dot(
        color: const Color(0xFFDC2626),
        icon: Icons.place_rounded,
        pixelRatio: ratio,
      ),
    ]);

    _loadingIcons = false;
    if (!mounted) return;
    setState(() {
      _carIcon = results[0];
      _pickupIcon = results[1];
      _stopIcon = results[2];
      _dropoffIcon = results[3];
    });
  }

  void _onMarkerTick() {
    if (_animFrom == null || _animTo == null) return;
    final t = Curves.easeInOutCubic.transform(_markerAnim.value);
    setState(() {
      _displayDriver = LatLng(
        _animFrom!.latitude + (_animTo!.latitude - _animFrom!.latitude) * t,
        _animFrom!.longitude + (_animTo!.longitude - _animFrom!.longitude) * t,
      );
      _displayHeading = touryLerpHeading(_headingFrom, _headingTo, t);
    });
  }

  void _syncDriverMarker({required bool animate}) {
    final next = widget.order.driverLivePosition;
    if (next == null) return;

    final reported = widget.order.driverHeading;
    final double nextHeading;
    if (reported != null && reported.isFinite && reported != 0) {
      nextHeading = touryNormalizeHeading(reported);
    } else if (_displayDriver != null &&
        TouryDirectionsService.distanceMeters(_displayDriver!, next) >= 5) {
      nextHeading = touryBearingDegrees(
        _displayDriver!.latitude,
        _displayDriver!.longitude,
        next.latitude,
        next.longitude,
      );
    } else {
      nextHeading = _displayHeading;
    }

    if (!animate || _displayDriver == null) {
      _displayDriver = next;
      _displayHeading = nextHeading;
      _headingFrom = nextHeading;
      _headingTo = nextHeading;
      unawaited(_followCamera(next));
      return;
    }

    // Sub-2m GPS noise must not restart the animation (visible jitter).
    if (TouryDirectionsService.distanceMeters(_displayDriver!, next) < 2) {
      _displayDriver = next;
      return;
    }

    _animFrom = _displayDriver;
    _animTo = next;
    _headingFrom = _displayHeading;
    _headingTo = nextHeading;
    _markerAnim.forward(from: 0);
    unawaited(_followCamera(next));
  }

  Future<void> _followCamera(LatLng target) async {
    if (!_followDriver || !_controller.isCompleted) return;
    if (_lastFollowedPosition != null &&
        TouryDirectionsService.distanceMeters(_lastFollowedPosition!, target) <
            8) {
      return;
    }
    _lastFollowedPosition = target;
    final map = await _controller.future;
    if (!mounted) return;
    _programmaticCameraMove = true;
    await map.animateCamera(
      gmaps.CameraUpdate.newLatLng(target.toGoogleMaps()),
    );
  }

  Future<void> _recenterOnDriver() async {
    final driver = _displayDriver ?? widget.order.driverLivePosition;
    if (driver == null || !_controller.isCompleted) return;
    setState(() => _followDriver = true);
    _lastFollowedPosition = driver;
    final map = await _controller.future;
    if (!mounted) return;
    _programmaticCameraMove = true;
    await map.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: driver.toGoogleMaps(), zoom: 16),
      ),
    );
  }

  Future<void> _fitWholeTrip() async {
    final points = _roadPoints ?? widget.order.trackingRouteWaypoints();
    if (points.length < 2) return;
    setState(() => _followDriver = false);
    await _fitBounds(points);
  }

  Future<void> _syncRoute() async {
    final waypoints = widget.order.trackingRouteWaypoints();
    if (waypoints.length < 2) {
      if (_roadPoints != null && mounted) {
        setState(() {
          _roadPoints = null;
          _polylines = const <gmaps.Polyline>{};
        });
      }
      return;
    }

    final key = TouryDirectionsService.routeKey(waypoints);
    if (key == _routeKey) return;
    final destinationKey = TouryDirectionsService.routeKey(waypoints.sublist(1));
    final now = DateTime.now();
    final recentlyFetched = _lastRouteFetchAt != null &&
        now.difference(_lastRouteFetchAt!) < const Duration(seconds: 20);
    final originMoved = _lastRouteOrigin == null
        ? double.infinity
        : TouryDirectionsService.distanceMeters(
            _lastRouteOrigin!,
            waypoints.first,
          );
    if (_destinationKey == destinationKey && recentlyFetched && originMoved < 50) {
      return;
    }
    _routeKey = key;
    _destinationKey = destinationKey;
    _lastRouteOrigin = waypoints.first;
    _lastRouteFetchAt = now;
    setState(() => _loadingRoute = true);

    final route = await TouryDirectionsService.fetchRoadRouteResult(
      waypoints,
      language: context.locale.toString(),
      region: 'sa',
      optimal: true,
    );
    if (!mounted) return;

    final List<LatLng> resolved;
    if (route != null && route.points.length >= 2) {
      resolved = route.points;
      _routeApproximate = route.approximate || !route.trafficAware;
      _routeDurationSeconds = route.durationSeconds;
      _routeDistanceMeters = route.distanceMeters;
    } else {
      resolved = waypoints;
      _routeApproximate = true;
    }

    setState(() {
      _loadingRoute = false;
      _roadPoints = resolved;
      _polylines = _buildPolylines(resolved);
    });

    final firstFit = !_hasFittedOnce;
    if (resolved.length >= 2 && _controller.isCompleted && firstFit) {
      _hasFittedOnce = true;
      await _fitBounds(resolved);
    }
  }

  Set<gmaps.Polyline> _buildPolylines(List<LatLng> points) {
    if (points.length < 2) return const <gmaps.Polyline>{};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coords = points.map((p) => p.toGoogleMaps()).toList(growable: false);
    return {
      // Casing underneath gives the route a premium, readable edge.
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('trip_route_casing'),
        points: coords,
        color: isDark ? const Color(0xCC0B1220) : Colors.white,
        width: 11,
        zIndex: 0,
        startCap: gmaps.Cap.roundCap,
        endCap: gmaps.Cap.roundCap,
      ),
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('trip_route'),
        points: coords,
        color: isDark ? DsPrimaryScale.shade400 : DsPrimaryScale.shade600,
        width: 6,
        zIndex: 1,
        startCap: gmaps.Cap.roundCap,
        endCap: gmaps.Cap.roundCap,
      ),
    };
  }

  Future<void> _fitBounds(List<LatLng> points) async {
    if (points.isEmpty || !_controller.isCompleted) return;
    final map = await _controller.future;
    _programmaticCameraMove = true;
    if (points.length == 1) {
      await map.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(points.first.toGoogleMaps(), 15),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    await map.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(
        gmaps.LatLngBounds(
          southwest: gmaps.LatLng(minLat, minLng),
          northeast: gmaps.LatLng(maxLat, maxLng),
        ),
        64,
      ),
    );
  }

  Set<gmaps.Marker> _buildMarkers(OrderRecord order, LatLng? driver) {
    final markers = <gmaps.Marker>{};

    if (driver != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('driver'),
          position: driver.toGoogleMaps(),
          rotation: _displayHeading,
          flat: true,
          zIndexInt: 3,
          anchor: const Offset(0.5, 0.5),
          icon: _carIcon ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueAzure,
              ),
          infoWindow: gmaps.InfoWindow(
            title: order.naimMndobText.isNotEmpty
                ? order.naimMndobText
                : 'map_driver'.tr(),
          ),
        ),
      );
    }

    final pickup = order.customerPickup;
    if (pickup != null) {
      markers.add(_pin(
        id: 'pickup',
        point: pickup,
        icon: _pickupIcon,
        fallbackHue: gmaps.BitmapDescriptor.hueGreen,
        title: 'map_pickup'.tr(),
      ));
    }

    final stops = order.intermediateStops();
    for (var i = 0; i < stops.length; i++) {
      markers.add(_pin(
        id: 'stop_$i',
        point: stops[i],
        icon: _stopIcon,
        fallbackHue: gmaps.BitmapDescriptor.hueOrange,
        title: 'map_destination_n'.tr(namedArgs: {'n': '${i + 1}'}),
      ));
    }

    final destination = order.tripDestination;
    if (destination != null) {
      markers.add(_pin(
        id: 'dropoff',
        point: destination,
        icon: _dropoffIcon,
        fallbackHue: gmaps.BitmapDescriptor.hueRed,
        title: 'map_destination'.tr(),
      ));
    }

    return markers;
  }

  gmaps.Marker _pin({
    required String id,
    required LatLng point,
    required gmaps.BitmapDescriptor? icon,
    required double fallbackHue,
    required String title,
  }) {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(id),
      position: point.toGoogleMaps(),
      anchor: icon == null ? const Offset(0.5, 1.0) : const Offset(0.5, 0.5),
      icon: icon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(fallbackHue),
      infoWindow: gmaps.InfoWindow(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final driver = _displayDriver ?? order.driverLivePosition;
    final pickup = order.customerPickup;
    final destination = order.tripDestination;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        driver ?? pickup ?? destination ?? TouryMapsConfig.defaultCenter;

    final liveEtaMin = order.etaMinutes;
    final routeEtaMin = (_routeDurationSeconds ?? 0) <= 0
        ? 0
        : ((_routeDurationSeconds!) / 60).ceil();
    final shownEtaMin = liveEtaMin > 0 ? liveEtaMin : routeEtaMin;
    final distKm = order.distanceRemainingMeters > 0
        ? order.distanceRemainingMeters / 1000.0
        : (_routeDistanceMeters ?? 0) / 1000.0;
    final etaApproximate =
        order.etaApproximate || _routeApproximate || liveEtaMin <= 0;

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          gmaps.GoogleMap(
            onMapCreated: (controller) async {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              await controller.setMapStyle(
                googleMapStyleStrings[
                    isDark ? GoogleMapStyle.dark : GoogleMapStyle.standard],
              );
              final route = _roadPoints ?? order.trackingRouteWaypoints();
              if (route.length >= 2 && !_hasFittedOnce) {
                _hasFittedOnce = true;
                await _fitBounds(route);
              }
            },
            onCameraMoveStarted: () {
              // Programmatic animations also fire this — only a real gesture
              // should break follow mode.
              if (_programmaticCameraMove) return;
              if (_followDriver) setState(() => _followDriver = false);
            },
            onCameraIdle: () => _programmaticCameraMove = false,
            initialCameraPosition: gmaps.CameraPosition(
              target: initial.toGoogleMaps(),
              zoom: 14.5,
            ),
            markers: _buildMarkers(order, driver),
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 72, top: 8),
            trafficEnabled: true,
          ),
          if (_loadingRoute)
            PositionedDirectional(
              top: 12,
              start: 12,
              child: _MapBadge(
                icon: Icons.route_rounded,
                label: 'map_calculating_route'.tr(),
              ),
            ),
          if (shownEtaMin > 0 || distKm > 0)
            PositionedDirectional(
              top: 12,
              end: 12,
              child: _MapBadge(
                icon: Icons.schedule_rounded,
                highlight: true,
                label: [
                  if (shownEtaMin > 0)
                    'map_eta_minutes'.tr(
                      namedArgs: {'minutes': shownEtaMin.toString()},
                    ),
                  if (distKm > 0)
                    '${distKm.toStringAsFixed(1)} ${'map_km'.tr()}',
                  if (shownEtaMin > 0 && etaApproximate) 'map_eta_estimated'.tr(),
                ].join(' · '),
              ),
            ),
          PositionedDirectional(
            end: 12,
            bottom: widget.showNavigationButton ? 72 : 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (driver != null)
                  _MapFab(
                    icon: _followDriver
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    tooltip: 'map_center_on_driver'.tr(),
                    active: _followDriver,
                    onTap: _recenterOnDriver,
                  ),
                const SizedBox(height: 8),
                _MapFab(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'map_fit_trip'.tr(),
                  onTap: _fitWholeTrip,
                ),
              ],
            ),
          ),
          if (widget.showNavigationButton)
            PositionedDirectional(
              start: 12,
              end: 12,
              bottom: 12,
              child: _ActionButton(
                icon: Icons.navigation_rounded,
                label: 'map_open_google_maps'.tr(),
                onTap: () => TouryNavigationService.openGoogleMapsNavigation(
                  origin: driver,
                  destination: destination ?? pickup ?? initial,
                  localeKey: TouryNavigationService.localeForContext(context),
                  destinationTitle: 'map_trip_destination'.tr(),
                  waypoints: pickup != null &&
                          destination != null &&
                          pickup != destination
                      ? [pickup]
                      : const [],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({
    required this.label,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final IconData? icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = highlight ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primary
            : theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? theme.colorScheme.primary : theme.colorScheme.surface,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 21,
              color: active
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
