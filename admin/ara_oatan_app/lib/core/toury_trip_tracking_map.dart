import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/backend/schema/order_record.dart';
import '/core/toury_directions_service.dart';
import '/core/toury_maps_config.dart';
import '/core/toury_navigation_service.dart';
import '/core/toury_order_meta.dart';
import '/design_system/colors/ds_color_scales.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// خريطة تتبع المندوب مع مسار طرق وزر Google Maps.
class TouryTripTrackingMap extends StatefulWidget {
  const TouryTripTrackingMap({
    super.key,
    required this.order,
    this.height = 420,
  });

  final OrderRecord order;
  final double height;

  @override
  State<TouryTripTrackingMap> createState() => _TouryTripTrackingMapState();
}

class _TouryTripTrackingMapState extends State<TouryTripTrackingMap> {
  final _controller = Completer<gmaps.GoogleMapController>();
  List<LatLng>? _roadPoints;
  bool _loadingRoute = false;
  String? _routeKey;
  String? _destinationKey;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteFetchAt;

  @override
  void didUpdateWidget(covariant TouryTripTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRoute();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRoute());
  }

  Future<void> _syncRoute() async {
    final waypoints = widget.order.trackingRouteWaypoints();
    if (waypoints.length < 2) {
      if (_roadPoints != null) setState(() => _roadPoints = null);
      return;
    }

    final key = TouryDirectionsService.routeKey(waypoints);
    if (key == _routeKey) return;
    final destinationKey = TouryDirectionsService.routeKey(
      waypoints.sublist(1),
    );
    final now = DateTime.now();
    final recentlyFetched = _lastRouteFetchAt != null &&
        now.difference(_lastRouteFetchAt!) < const Duration(seconds: 15);
    final originMoved = _lastRouteOrigin == null
        ? double.infinity
        : TouryDirectionsService.distanceMeters(
            _lastRouteOrigin!,
            waypoints.first,
          );
    if (_destinationKey == destinationKey &&
        recentlyFetched &&
        originMoved < 35) {
      return;
    }
    _routeKey = key;
    _destinationKey = destinationKey;
    _lastRouteOrigin = waypoints.first;
    _lastRouteFetchAt = now;
    setState(() => _loadingRoute = true);

    final route = await TouryDirectionsService.fetchRoadRoute(
      waypoints,
      language: context.locale.toString(),
      region: 'sa',
    );
    if (!mounted) return;
    setState(() {
      _loadingRoute = false;
      _roadPoints = route ?? waypoints;
    });

    final visible = _roadPoints ?? waypoints;
    if (visible.length >= 2 && _controller.isCompleted) {
      await _fitBounds(visible);
    }
  }

  Future<void> _fitBounds(List<LatLng> points) async {
    if (points.isEmpty || !_controller.isCompleted) return;
    final map = await _controller.future;
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
        48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final driver = order.driverLivePosition;
    final pickup = order.customerPickup;
    final destination = order.tripDestination;
    final waypoints = order.trackingRouteWaypoints();
    final visibleRoute = _roadPoints ?? waypoints;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        driver ?? pickup ?? destination ?? TouryMapsConfig.defaultCenter;

    final markers = <gmaps.Marker>{};
    if (driver != null) {
      markers.add(_marker(
        id: 'driver',
        point: driver,
        hue: gmaps.BitmapDescriptor.hueAzure,
        title: order.naimMndobText.isNotEmpty
            ? order.naimMndobText
            : 'map_driver'.tr(),
      ));
    }
    if (pickup != null) {
      markers.add(_marker(
        id: 'pickup',
        point: pickup,
        hue: gmaps.BitmapDescriptor.hueGreen,
        title: 'map_pickup'.tr(),
      ));
    }
    final stops = order.intermediateStops();
    for (var i = 0; i < stops.length; i++) {
      markers.add(_marker(
        id: 'stop_$i',
        point: stops[i],
        hue: gmaps.BitmapDescriptor.hueOrange,
        title: 'map_destination_n'.tr(namedArgs: {'n': '${i + 1}'}),
      ));
    }
    if (destination != null) {
      markers.add(_marker(
        id: 'dropoff',
        point: destination,
        hue: gmaps.BitmapDescriptor.hueRed,
        title: 'map_destination'.tr(),
      ));
    }

    final routeColor =
        isDark ? DsPrimaryScale.shade400 : DsPrimaryScale.shade600;
    final polylines = visibleRoute.length >= 2
        ? {
            gmaps.Polyline(
              polylineId: const gmaps.PolylineId('trip_route'),
              points: visibleRoute.map((p) => p.toGoogleMaps()).toList(),
              color: routeColor,
              width: 4,
            ),
          }
        : <gmaps.Polyline>{};

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          gmaps.GoogleMap(
            onMapCreated: (controller) async {
              _controller.complete(controller);
              await controller.setMapStyle(
                googleMapStyleStrings[
                    isDark ? GoogleMapStyle.dark : GoogleMapStyle.standard],
              );
              if (visibleRoute.length >= 2) {
                await _fitBounds(visibleRoute);
              }
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: initial.toGoogleMaps(),
              zoom: 14,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            trafficEnabled: true,
          ),
          if (_loadingRoute)
            Positioned(
              top: 12,
              left: 12,
              child: _MapBadge(label: 'map_calculating_route'.tr()),
            ),
          if (order.etaMinutes > 0)
            Positioned(
              top: 12,
              right: 12,
              child: _MapBadge(
                label: 'map_eta_minutes'.tr(
                  namedArgs: {'minutes': order.etaMinutes.toString()},
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.navigation_rounded,
                    label: 'map_open_google_maps'.tr(),
                    onTap: () =>
                        TouryNavigationService.openGoogleMapsNavigation(
                      origin: driver,
                      destination: destination ?? pickup ?? initial,
                      localeKey:
                          TouryNavigationService.localeForContext(context),
                      destinationTitle: 'map_trip_destination'.tr(),
                      waypoints: pickup != null &&
                              destination != null &&
                              pickup != destination
                          ? [pickup]
                          : const [],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.my_location,
                  label: 'map_driver'.tr(),
                  onTap: () async {
                    if (driver != null) await _fitBounds([driver]);
                  },
                ),
              ],
            ),
          ),
        ],
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

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
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
      color: theme.colorScheme.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF00897B)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
