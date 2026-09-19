import 'package:easy_localization/easy_localization.dart';
import 'package:ara_oatan_app/components/mmaapp_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/toury_location_service.dart';
import '/core/toury_polyline.dart';
import '/core/toury_route_metrics.dart';
import '/core/toury_distance_format.dart';
import '/core/toury_directions_service.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_landmark_cart.dart';
import '/core/toury_navigation_service.dart';
import '/backend/schema/structs/amakn_costm_struct.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:intl/intl.dart';
import '/auth/firebase_auth/auth_util.dart';

class MmaappWidget extends StatefulWidget {
  final Function(double, double)? onCalculationComplete;

  const MmaappWidget({
    super.key,
    this.onCalculationComplete,
  });

  @override
  State<MmaappWidget> createState() => _MmaappWidgetState();
}

class _MmaappWidgetState extends State<MmaappWidget> {
  late MmaappModel _model;
  LatLng? routeOrigin;

  double totalDistanceKm = 0;
  double totalTimeMinutes = 0;
  bool isLoading = true;
  String? errorMessage;

  // For Google Maps markers and polylines
  Set<maps.Marker> markers = {};
  Set<maps.Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MmaappModel());

    () async {
      // Pull fresh Admin pins before drawing the route.
      await touryRefreshCartLandmarkLocations();
      if (!mounted) return;
      LatLng? origin = touryResolveTripRouteOrigin();
      origin ??= await TouryLocationService.getUserPositionOrNull();
      if (!mounted) return;
      safeSetState(() {
        routeOrigin = origin;
        if (origin != null) {
          _calculateRouteWithOSRM();
        } else {
          isLoading = false;
          errorMessage = 'dialog_location_error'.tr();
        }
      });
    }();
  }

  /// 🗺️ Get driving distance and time from OSRM API
  Future<void> _calculateRouteWithOSRM() async {
    final origin = routeOrigin ?? touryResolveTripRouteOrigin();
    if (origin == null || FFAppState().cartmkss.isEmpty) {
      safeSetState(() {
        isLoading = false;
        if (FFAppState().cartmkss.isEmpty) {
          errorMessage = 'map_no_valid_destinations'.tr();
        }
      });
      return;
    }

    try {
      final validation = touryValidateRoutePoints(
        origin: origin,
        destinations: FFAppState().cartmkss.map((e) => e.loceshn),
        selectedAreaCenter: FFAppState().latlngvill,
      );
      if (!validation.canRoute) {
        safeSetState(() {
          isLoading = false;
          errorMessage =
              (validation.errorKey ?? 'map_no_valid_destinations').tr();
        });
        return;
      }
      final destinations = validation.points.skip(1).toList();

      if (loggedIn) {
        final googleRoute = await TouryDirectionsService.fetchRoadRouteResult(
          validation.points,
          language: context.locale.toString(),
          region: 'sa',
          optimal: true,
        );
        if (googleRoute != null &&
            googleRoute.distanceMeters > 0 &&
            googleRoute.durationSeconds > 0) {
          totalDistanceKm =
              touryMetersToKm(googleRoute.distanceMeters.toDouble());
          totalTimeMinutes = googleRoute.durationSeconds / 60.0;
          if (touryRoadMetricsArePlausible(
            distanceKm: totalDistanceKm,
            durationSeconds: googleRoute.durationSeconds.toDouble(),
            points: validation.points,
          )) {
            FFAppState().update(() {
              FFAppState().osrmTotalTime = totalTimeMinutes;
              FFAppState().osrmTotalDistance = totalDistanceKm;
              FFAppState().osrmCalculationTime = DateTime.now();
            });
            widget.onCalculationComplete?.call(totalTimeMinutes, totalDistanceKm);
            final List<maps.LatLng> polylinePoints;
            if (googleRoute.points.isNotEmpty) {
              polylinePoints = googleRoute.points
                  .map((p) => maps.LatLng(p.latitude, p.longitude))
                  .toList();
            } else if (googleRoute.encodedPolyline.isNotEmpty) {
              polylinePoints = _decodePolyline(googleRoute.encodedPolyline);
            } else {
              polylinePoints = validation.points
                  .map((p) => maps.LatLng(p.latitude, p.longitude))
                  .toList();
            }
            _createMarkers(destinations);
            _createPolyline(polylinePoints);
            safeSetState(() {
              isLoading = false;
              errorMessage = validation.rejectedCount == 0
                  ? null
                  : 'map_invalid_destinations'.tr(
                      namedArgs: {'count': '${validation.rejectedCount}'},
                    );
            });
            return;
          }
        }
      }

      // Build coordinates string for OSRM: "lon,lat;lon,lat;..."
      final coordinates = validation.points
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      // OSRM API URL with waypoints optimization
      String url =
          'https://router.project-osrm.org/route/v1/driving/$coordinates?'
          'overview=full&' // Get full polyline
          'geometries=polyline&' // precision-5 encoded polyline
          'steps=false&' // Don't need step-by-step instructions
          'annotations=true&' // Get distance and duration annotations
          'alternatives=false'; // Don't need alternative routes

      print('OSRM URL: $url'); // For debugging

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok') {
          final route = data['routes'][0];

          // Get total distance in meters → store as kilometers
          final distanceMeters = TouryPolyline.asDouble(route['distance']);
          totalDistanceKm = touryMetersToKm(distanceMeters);

          // Get total duration in seconds
          final durationSeconds = TouryPolyline.asDouble(route['duration']);
          if (!touryRoadMetricsArePlausible(
            distanceKm: totalDistanceKm,
            durationSeconds: durationSeconds,
            points: validation.points,
          )) {
            _calculateStraightLineDistance(validation);
            return;
          }
          totalTimeMinutes = durationSeconds / 60;

          // Store in FFAppState for use in other widgets
          FFAppState().update(() {
            FFAppState().osrmTotalTime = totalTimeMinutes;
            FFAppState().osrmTotalDistance = totalDistanceKm;
            FFAppState().osrmCalculationTime = DateTime.now();
          });
          widget.onCalculationComplete?.call(totalTimeMinutes, totalDistanceKm);

          // Get polyline for map route
          final geometry = route['geometry'];
          final polylinePoints = _decodePolyline(geometry);

          // Create markers
          _createMarkers(destinations);

          // Create polyline
          _createPolyline(polylinePoints);

          safeSetState(() {
            isLoading = false;
            errorMessage = validation.rejectedCount == 0
                ? null
                : 'map_invalid_destinations'.tr(
                    namedArgs: {'count': '${validation.rejectedCount}'},
                  );
          });
        } else {
          // Fallback to straight-line calculation
          _calculateStraightLineDistance(validation);
        }
      } else {
        // Fallback to straight-line calculation
        _calculateStraightLineDistance(validation);
      }
    } catch (e) {
      print('Error fetching OSRM route: $e');
      // Fallback to straight-line calculation
      final validation = touryValidateRoutePoints(
        origin: routeOrigin,
        destinations: FFAppState().cartmkss.map((e) => e.loceshn),
        selectedAreaCenter: FFAppState().latlngvill,
      );
      _calculateStraightLineDistance(validation);
    }
  }

  /// 📏 Create markers for the map
  void _createMarkers(List<LatLng> destinations) {
    markers.clear();

    markers.add(
      maps.Marker(
        markerId: const maps.MarkerId('start'),
        position: maps.LatLng(
          routeOrigin!.latitude,
          routeOrigin!.longitude,
        ),
        icon: maps.BitmapDescriptor.defaultMarkerWithHue(
            maps.BitmapDescriptor.hueGreen),
        infoWindow: maps.InfoWindow(title: 'pickup_location_label'.tr()),
      ),
    );

    final cart = FFAppState().cartmkss;
    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      final cartItem = _cartItemForPoint(dest, cart);
      final title = (cartItem?.displayLabel.isNotEmpty ?? false)
          ? cartItem!.displayLabel
          : 'map_destination_n'.tr(namedArgs: {'n': '${i + 1}'});
      final snippet = cartItem?.address.trim().isNotEmpty == true
          ? cartItem!.address.trim()
          : '${dest.latitude.toStringAsFixed(5)}, ${dest.longitude.toStringAsFixed(5)}';
      markers.add(
        maps.Marker(
          markerId: maps.MarkerId('dest_$i'),
          position: maps.LatLng(dest.latitude, dest.longitude),
          icon: maps.BitmapDescriptor.defaultMarkerWithHue(
              maps.BitmapDescriptor.hueRed),
          infoWindow: maps.InfoWindow(title: title, snippet: snippet),
        ),
      );
    }
  }

  AmaknCostmStruct? _cartItemForPoint(
    LatLng point,
    List<AmaknCostmStruct> cart,
  ) {
    for (final item in cart) {
      final loc = item.loceshn;
      if (loc == null) continue;
      if ((loc.latitude - point.latitude).abs() < 1e-5 &&
          (loc.longitude - point.longitude).abs() < 1e-5) {
        return item;
      }
    }
    if (cart.length == 1 && cart.first.loceshn != null) {
      return cart.first;
    }
    return null;
  }

  Future<void> _openInGoogleMaps() async {
    final stops = FFAppState()
        .cartmkss
        .map((e) => e.loceshn)
        .whereType<LatLng>()
        .toList(growable: false);
    if (stops.isEmpty) return;
    final destination = stops.last;
    final waypoints = stops.length > 1 ? stops.sublist(0, stops.length - 1) : const <LatLng>[];
    final title = FFAppState().cartmkss.isNotEmpty
        ? FFAppState().cartmkss.last.displayLabel
        : 'map_trip_destination'.tr();
    await TouryNavigationService.openGoogleMapsNavigation(
      origin: routeOrigin,
      destination: destination,
      waypoints: waypoints,
      localeKey: TouryNavigationService.localeForContext(context),
      destinationTitle: title,
    );
  }

  /// 🛣️ Create polyline for the route
  void _createPolyline(List<maps.LatLng> points) {
    polylines.clear();

    polylines.add(
      maps.Polyline(
        polylineId: maps.PolylineId('route'),
        points: points,
        color: DsPrimaryScale.shade500,
        width: 4,
        startCap: maps.Cap.roundCap,
        endCap: maps.Cap.roundCap,
        jointType: maps.JointType.round,
      ),
    );
  }

  /// 🔤 Decode polyline string to LatLng points
  List<maps.LatLng> _decodePolyline(String encoded) {
    return TouryPolyline.decode(encoded, precision: 5)
        .map((p) => maps.LatLng(p.latitude, p.longitude))
        .toList();
  }

  /// 📏 Fallback when live road APIs fail.
  /// Prefer existing checkout SoT (`osrmTotal*`) so map sheet never shows
  /// different km/min than قائمة رحلاتي for the same booking.
  void _calculateStraightLineDistance([TouryRouteValidation? prepared]) {
    final validation = prepared ??
        touryValidateRoutePoints(
          origin: routeOrigin,
          destinations: FFAppState().cartmkss.map((e) => e.loceshn),
          selectedAreaCenter: FFAppState().latlngvill,
        );
    if (!validation.canRoute) {
      safeSetState(() {
        isLoading = false;
        errorMessage =
            (validation.errorKey ?? 'map_no_valid_destinations').tr();
      });
      return;
    }
    final destinations = validation.points.skip(1).toList();
    final cachedKm = FFAppState().osrmTotalDistance;
    final cachedMin = FFAppState().osrmTotalTime;
    final hasCheckoutSot = cachedKm > 0 && cachedMin > 0;
    if (hasCheckoutSot) {
      totalDistanceKm = cachedKm;
      totalTimeMinutes = cachedMin;
    } else {
      final estimate = touryEstimateRoute(validation.points);
      totalDistanceKm = estimate.distanceKm;
      totalTimeMinutes = estimate.durationHours * 60;
      FFAppState().update(() {
        FFAppState().osrmTotalTime = totalTimeMinutes;
        FFAppState().osrmTotalDistance = totalDistanceKm;
        FFAppState().osrmCalculationTime = DateTime.now();
      });
    }

    _createMarkers(destinations);
    // Straight segments keep fitBounds useful when polyline decode is missing.
    _createPolyline(
      validation.points
          .map((p) => maps.LatLng(p.latitude, p.longitude))
          .toList(),
    );

    safeSetState(() {
      isLoading = false;
      if (validation.rejectedCount > 0) {
        errorMessage = 'map_invalid_destinations'.tr(
          namedArgs: {'count': '${validation.rejectedCount}'},
        );
      } else if (hasCheckoutSot) {
        // Numbers match checkout; warn only that live road redraw failed.
        errorMessage = 'map_route_fallback'.tr();
      } else {
        errorMessage = 'map_route_fallback'.tr();
      }
    });
  }

  /// 🔄 Retry calculation
  Future<void> _retryCalculation() async {
    safeSetState(() {
      isLoading = true;
      errorMessage = null;
    });
    await touryRefreshCartLandmarkLocations();
    if (!mounted) return;
    LatLng? origin = touryResolveTripRouteOrigin();
    origin ??= await TouryLocationService.getUserPositionOrNull();
    if (!mounted) return;
    routeOrigin = origin;
    await _calculateRouteWithOSRM();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;
    final typography = context.dsTypography;

    if (routeOrigin == null) {
      return Container(
        color: colors.scaffold,
        child: Stack(
          children: [
            DsLoading(
              size: 50,
              message: 'map_locating'.tr(),
            ),
            PositionedDirectional(
              top: DsSpacing.sm,
              end: DsSpacing.sm,
              child: DsIconButton(
                icon: DsIcons.close,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
      children: [
        /// رأس الورقة: عنوان + إغلاق
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            DsSpacing.sm,
            DsSpacing.xs,
            DsSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsetsDirectional.only(end: DsSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: Text(
                  'booking_view_route'.tr(),
                  style: typography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DsIconButton(
                icon: DsIcons.close,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),

        /// 🗺️ الخريطة مع المسار
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: colors.surface,
          ),
          child: Stack(
            children: [
              _buildGoogleMap(),

              if (isLoading)
                Container(
                  color: colors.scrim,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(colors.onPrimary),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        Text(
                          'map_calculating_route'.tr(),
                          style: typography.titleSmall.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              PositionedDirectional(
                start: DsSpacing.sm,
                end: DsSpacing.sm,
                bottom: DsSpacing.sm,
                child: Material(
                  color: colors.primary,
                  borderRadius: DsRadius.medium,
                  elevation: 3,
                  child: InkWell(
                    borderRadius: DsRadius.medium,
                    onTap: isLoading ? null : _openInGoogleMaps,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.md,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: colors.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: DsSpacing.xs),
                          Flexible(
                            child: Text(
                              'map_open_google_maps'.tr(),
                              style: typography.titleSmall.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              PositionedDirectional(
                top: DsSpacing.sm,
                end: DsSpacing.sm,
                child: Material(
                  color: colors.surface.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: DsIconButton(
                    icon: DsIcons.close,
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 📊 الوجهات + المسافة/الوقت
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DsSpacing.md,
              DsSpacing.sm,
              DsSpacing.md,
              DsSpacing.md,
            ),
            children: [
              if (errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DsSpacing.sm),
                  margin: const EdgeInsets.only(bottom: DsSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.warningContainer,
                    borderRadius: DsRadius.small,
                    border: Border.all(color: colors.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 20, color: colors.warning),
                      const SizedBox(width: DsSpacing.xs),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: typography.bodySmall.copyWith(
                            color: DsWarningScale.shade700,
                          ),
                        ),
                      ),
                      DsIconButton(
                        icon: Icons.refresh,
                        foreground: colors.warning,
                        size: 18,
                        onPressed: _retryCalculation,
                      ),
                    ],
                  ),
                ),

              Text(
                'map_destination'.tr(),
                style: typography.titleSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
              ..._buildDestinationCards(colors, typography),
              const SizedBox(height: DsSpacing.md),
              DsCard(
                elevated: true,
                bordered: false,
                padding: const EdgeInsets.all(DsSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCompactMetric(
                        icon: Icons.route_rounded,
                        label: 'map_distance_label'.tr(),
                        value: isLoading
                            ? '…'
                            : (totalDistanceKm <= 0
                                ? 'ux_not_available'.tr()
                                : '${_formatNumber(totalDistanceKm, digits: 1)} ${'unit_km'.tr()}'),
                        color: DsInfoScale.shade700,
                      ),
                    ),
                    Container(width: 1, height: 44, color: colors.divider),
                    Expanded(
                      child: _buildCompactMetric(
                        icon: Icons.schedule_rounded,
                        label: 'map_estimated_time'.tr(),
                        value: isLoading
                            ? '…'
                            : (totalTimeMinutes <= 0
                                ? 'ux_not_available'.tr()
                                : _formatDuration(totalTimeMinutes)),
                        color: DsSuccessScale.shade700,
                      ),
                    ),
                    Container(width: 1, height: 44, color: colors.divider),
                    Expanded(
                      child: _buildCompactMetric(
                        icon: Icons.place_rounded,
                        label: 'map_stops_count'.tr(),
                        value: FFAppState().cartmkss.length.toString(),
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  List<Widget> _buildDestinationCards(
    DsColors colors,
    DsTypography typography,
  ) {
    final items = FFAppState().cartmkss;
    if (items.isEmpty) {
      return [
        Text(
          'map_no_valid_destinations'.tr(),
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      ];
    }
    return [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : DsSpacing.sm),
          child: DsCard(
            elevated: false,
            bordered: true,
            padding: const EdgeInsets.all(DsSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: DsRadius.medium,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: typography.titleSmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].displayLabel.isNotEmpty
                            ? items[i].displayLabel
                            : 'map_destination_n'.tr(namedArgs: {'n': '${i + 1}'}),
                        style: typography.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (items[i].textivill.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          items[i].textivill.trim(),
                          style: typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        items[i].loceshn == null
                            ? 'map_location_unavailable'.tr()
                            : '${'map_coordinates'.tr()}: ${items[i].loceshn!.latitude.toStringAsFixed(6)}, ${items[i].loceshn!.longitude.toStringAsFixed(6)}',
                        style: typography.labelSmall.copyWith(
                          color: colors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'map_open_google_maps'.tr(),
                  onPressed: items[i].loceshn == null
                      ? null
                      : () => TouryNavigationService.openGoogleMapsNavigation(
                            origin: routeOrigin,
                            destination: items[i].loceshn!,
                            localeKey:
                                TouryNavigationService.localeForContext(context),
                            destinationTitle: items[i].displayLabel,
                          ),
                  icon: Icon(Icons.directions_rounded, color: colors.primary),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildCompactMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xs),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.labelSmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// 🗺️ Build Google Map widget
  Widget _buildGoogleMap() {
    return maps.GoogleMap(
      mapType: maps.MapType.normal,
      initialCameraPosition: maps.CameraPosition(
        target: maps.LatLng(
          routeOrigin!.latitude,
          routeOrigin!.longitude,
        ),
        zoom: 14,
      ),
      onMapCreated: (maps.GoogleMapController controller) {
        _model.mapController = controller;
        // Fit map to markers after a delay
        Future.delayed(Duration(milliseconds: 500), () {
          _fitMapToMarkers();
        });
      },
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      trafficEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }

  /// 🗺️ Fit map to show all markers
  Future<void> _fitMapToMarkers() async {
    if (markers.isEmpty) return;

    final bounds = _calculateBounds();
    final cameraUpdate = maps.CameraUpdate.newLatLngBounds(bounds, 50);

    try {
      await _model.mapController?.animateCamera(cameraUpdate);
    } catch (e) {
      // Sometimes bounds calculation fails if markers are too close
      print('Error fitting map: $e');
    }
  }

  /// 📐 Calculate bounds from markers
  maps.LatLngBounds _calculateBounds() {
    if (markers.isEmpty) {
      return maps.LatLngBounds(
        southwest: maps.LatLng(0, 0),
        northeast: maps.LatLng(0, 0),
      );
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    // Add a little padding
    final padding = 0.01;
    return maps.LatLngBounds(
      southwest: maps.LatLng(minLat - padding, minLng - padding),
      northeast: maps.LatLng(maxLat + padding, maxLng + padding),
    );
  }

  /// ⏱️ Format duration to readable string
  String _formatDuration(double minutes) {
    if (minutes < 60) {
      return '${_formatNumber(minutes.round())} ${'unit_minute'.tr()}';
    } else {
      int hours = (minutes / 60).floor();
      int remainingMinutes = (minutes % 60).round();
      if (remainingMinutes == 0) {
        return '${_formatNumber(hours)} ${'unit_hour'.tr()}';
      } else {
        return 'duration_hours_minutes'.tr(namedArgs: {
          'hours': _formatNumber(hours),
          'minutes': _formatNumber(remainingMinutes),
        });
      }
    }
  }

  String _formatNumber(num value, {int? digits}) {
    final formatter = NumberFormat.decimalPattern(context.locale.toString());
    if (digits != null) {
      formatter.minimumFractionDigits = digits;
      formatter.maximumFractionDigits = digits;
    }
    return formatter.format(value);
  }
}
