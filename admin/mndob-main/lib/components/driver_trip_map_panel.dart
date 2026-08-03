import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/backend/schema/order_record.dart';
import '/core/driver_navigation_service.dart';
import '/core/driver_live_route_controller.dart';
import '/core/driver_map_utils.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_trip_constants.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// خريطة مدمجة داخل شاشة الرحلة مع علامات ومسار طرق حيّ.
class DriverTripMapPanel extends StatefulWidget {
  const DriverTripMapPanel({
    super.key,
    required this.order,
    this.driverLocation,
    this.height = 220,
  });

  final OrderRecord order;
  final LatLng? driverLocation;
  final double height;

  @override
  State<DriverTripMapPanel> createState() => _DriverTripMapPanelState();
}

class _DriverTripMapPanelState extends State<DriverTripMapPanel> {
  final _controller = Completer<gmaps.GoogleMapController>();
  final _routeCtrl = DriverLiveRouteController();
  bool _didFitRoadRoute = false;

  @override
  void dispose() {
    _routeCtrl.reset();
    super.dispose();
  }

  List<LatLng> _routeWaypoints() =>
      widget.order.routeWaypoints(driverOverride: widget.driverLocation);

  void _syncRoute(List<LatLng> waypoints) {
    if (waypoints.length < 2) {
      if (_routeCtrl.roadPoints != null || _routeCtrl.failed) {
        _routeCtrl.reset();
        _didFitRoadRoute = false;
        if (mounted) setState(() {});
      }
      return;
    }

    unawaited(_routeCtrl.sync(waypoints, onChanged: () async {
      if (!mounted) return;
      setState(() {});
      if (_routeCtrl.roadPoints != null && !_didFitRoadRoute) {
        _didFitRoadRoute = true;
        await DriverMapUtils.fitBounds(_controller, _routeCtrl.roadPoints!);
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;
    final mapStyle =
        isDark ? GoogleMapStyle.dark : GoogleMapStyle.standard;
    final customerPickup = widget.order.customerPickup;
    final destination = widget.order.tripDestination;
    final driver = widget.driverLocation ??
        (DriverTripHalh.isActiveTrip(widget.order.halhText)
            ? widget.order.driverLivePosition
            : null);
    final initial =
        driver ?? customerPickup ?? destination ?? const LatLng(33.3152, 44.3661);
    final routeWaypoints = _routeWaypoints();
    _syncRoute(routeWaypoints);

    final markers = <gmaps.Marker>{};
    if (driver != null) {
      markers.add(_marker(
        id: 'driver',
        point: driver,
        hue: gmaps.BitmapDescriptor.hueAzure,
        title: 'موقعك',
      ));
    }
    if (customerPickup != null) {
      markers.add(_marker(
        id: 'pickup',
        point: customerPickup,
        hue: gmaps.BitmapDescriptor.hueGreen,
        title: 'نقطة الالتقاط',
      ));
    }
    if (destination != null) {
      markers.add(_marker(
        id: 'dropoff',
        point: destination,
        hue: gmaps.BitmapDescriptor.hueRed,
        title: 'الوجهة',
      ));
    }

    final visibleRoutePoints = _routeCtrl.roadPoints ?? routeWaypoints;
    final polylines = visibleRoutePoints.length >= 2
        ? {
            gmaps.Polyline(
              polylineId: const gmaps.PolylineId('route'),
              points: visibleRoutePoints.map((p) => p.toGoogleMaps()).toList(),
              color: colors.primary,
              width: 4,
            ),
          }
        : <gmaps.Polyline>{};

    return Container(
      height: widget.height,
      margin: const EdgeInsets.fromLTRB(
        DsSpacing.sm,
        DsSpacing.xxs,
        DsSpacing.sm,
        DsSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: DsRadius.large,
        border: Border.all(color: colors.border),
        boxShadow: DsShadows.card(dark: isDark),
      ),
      child: ClipRRect(
        borderRadius: DsRadius.large,
        child: Stack(
          fit: StackFit.expand,
          children: [
            gmaps.GoogleMap(
              onMapCreated: (controller) async {
                _controller.complete(controller);
                await DriverMapUtils.fitBounds(
                  _controller,
                  visibleRoutePoints,
                );
              },
              style: googleMapStyleStrings[mapStyle],
              initialCameraPosition: gmaps.CameraPosition(
                target: initial.toGoogleMaps(),
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: true,
            ),
            Positioned(
              top: DsSpacing.sm,
              right: DsSpacing.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (destination != null || customerPickup != null)
                    _MapIconButton(
                      icon: Icons.navigation_rounded,
                      tooltip: 'التوجيه في Google Maps',
                      color: colors.primaryStrong,
                      onTap: () => DriverNavigationService.openOrderRoute(
                        waypoints: widget.order.routeWaypoints(
                          driverOverride: driver,
                        ),
                        driverOrigin: driver,
                        orderRef: widget.order.reference,
                      ),
                    ),
                  if (destination != null || customerPickup != null)
                    DsSpacing.gapXs,
                  if (customerPickup != null)
                    _MapIconButton(
                      icon: Icons.trip_origin,
                      tooltip: 'نقطة الالتقاط',
                      onTap: () => DriverMapUtils.fitBounds(
                        _controller,
                        [customerPickup],
                        padding: 80,
                      ),
                    ),
                  if (customerPickup != null && destination != null)
                    DsSpacing.gapXs,
                  if (destination != null)
                    _MapIconButton(
                      icon: Icons.flag_rounded,
                      tooltip: 'الوجهة',
                      onTap: () => DriverMapUtils.fitBounds(
                        _controller,
                        [destination],
                        padding: 80,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: DsSpacing.sm,
              left: DsSpacing.sm,
              child: _MapIconButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: 'توسيط المسار',
                onTap: () => DriverMapUtils.fitBounds(
                  _controller,
                  visibleRoutePoints,
                ),
              ),
            ),
            Positioned(
              bottom: DsSpacing.sm,
              right: DsSpacing.sm,
              child: _RouteStatusPill(
                isRoadRoute: _routeCtrl.roadPoints != null,
                failed: _routeCtrl.failed,
                loading: _routeCtrl.loading,
              ),
            ),
            if (widget.order.etaSeconds > 0)
              Positioned(
                bottom: DsSpacing.sm,
                left: DsSpacing.sm,
                child: Container(
                  padding: DsSpacing.chipPadding,
                  decoration: BoxDecoration(
                    color: colors.primaryStrong.withValues(alpha: 0.9),
                    borderRadius: DsRadius.small,
                  ),
                  child: Text(
                    'ETA ~ ${(widget.order.etaSeconds / 60).ceil()} د',
                    style: typography.labelMedium.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  gmaps.Marker _marker({
    required String id,
    required LatLng point,
    required double hue,
    required String title,
  }) {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(id),
      position: point.toGoogleMaps(),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(hue),
      infoWindow: gmaps.InfoWindow(title: title),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;

    return Material(
      color: colors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: color ?? colors.primaryStrong, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

class _RouteStatusPill extends StatelessWidget {
  const _RouteStatusPill({
    required this.isRoadRoute,
    required this.failed,
    required this.loading,
  });

  final bool isRoadRoute;
  final bool failed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final label = isRoadRoute
        ? 'مسار الطرق'
        : failed
            ? 'مسار تقريبي'
            : loading
                ? 'جاري المسار...'
                : 'مسار تقريبي';
    final color = isRoadRoute
        ? colors.success
        : failed
            ? colors.warning
            : colors.primaryStrong;

    return Container(
      padding: DsSpacing.chipPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: DsRadius.small,
      ),
      child: Text(
        label,
        style: typography.labelMedium.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
