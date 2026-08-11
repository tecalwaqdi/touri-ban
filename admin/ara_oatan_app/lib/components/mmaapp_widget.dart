import 'package:easy_localization/easy_localization.dart';
import 'package:ara_oatan_app/components/mmaapp_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/toury_location_service.dart';
import '/core/toury_polyline.dart';
import '/core/toury_route_metrics.dart';
import '/core/toury_distance_format.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:intl/intl.dart';

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
  LatLng? currentUserLocationValue;

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

    TouryLocationService.getUserPositionOrNull().then((loc) {
      safeSetState(() {
        currentUserLocationValue = loc;
        if (loc != null) {
          _calculateRouteWithOSRM();
        } else {
          isLoading = false;
          errorMessage = 'dialog_location_error'.tr();
        }
      });
    });
  }

  /// 🗺️ Get driving distance and time from OSRM API
  Future<void> _calculateRouteWithOSRM() async {
    if (currentUserLocationValue == null || FFAppState().cartmkss.isEmpty) {
      safeSetState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final validation = touryValidateRoutePoints(
        origin: currentUserLocationValue,
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

      // Build coordinates string for OSRM: "lon,lat;lon,lat;..."
      final coordinates = [
        '${currentUserLocationValue!.longitude},${currentUserLocationValue!.latitude}',
        ...destinations.map((point) => '${point.longitude},${point.latitude}')
      ].join(';');

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
        origin: currentUserLocationValue,
        destinations: FFAppState().cartmkss.map((e) => e.loceshn),
        selectedAreaCenter: FFAppState().latlngvill,
      );
      _calculateStraightLineDistance(validation);
    }
  }

  /// 📏 Create markers for the map
  void _createMarkers(List<LatLng> destinations) {
    markers.clear();

    // Add start marker
    markers.add(
      maps.Marker(
        markerId: maps.MarkerId('start'),
        position: maps.LatLng(
          currentUserLocationValue!.latitude,
          currentUserLocationValue!.longitude,
        ),
        icon: maps.BitmapDescriptor.defaultMarkerWithHue(
            maps.BitmapDescriptor.hueGreen),
        infoWindow: maps.InfoWindow(title: 'map_your_location'.tr()),
      ),
    );

    // Add destination markers
    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      markers.add(
        maps.Marker(
          markerId: maps.MarkerId('dest_$i'),
          position: maps.LatLng(dest.latitude, dest.longitude),
          icon: maps.BitmapDescriptor.defaultMarkerWithHue(
              maps.BitmapDescriptor.hueRed),
          infoWindow: maps.InfoWindow(
            title: 'map_destination_n'.tr(namedArgs: {'n': '${i + 1}'}),
          ),
        ),
      );
    }
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

  /// 📏 Fallback: Straight-line distance calculation
  void _calculateStraightLineDistance([TouryRouteValidation? prepared]) {
    final validation = prepared ??
        touryValidateRoutePoints(
          origin: currentUserLocationValue,
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
    final estimate = touryEstimateRoute(validation.points);
    totalDistanceKm = estimate.distanceKm;
    totalTimeMinutes = estimate.durationHours * 60;

    // Create markers for fallback too
    _createMarkers(destinations);

    // Store fallback calculation in FFAppState too
    FFAppState().update(() {
      FFAppState().osrmTotalTime = totalTimeMinutes;
      FFAppState().osrmTotalDistance = totalDistanceKm;
      FFAppState().osrmCalculationTime = DateTime.now();
    });

    safeSetState(() {
      isLoading = false;
      errorMessage = validation.rejectedCount == 0
          ? 'map_route_fallback'.tr()
          : 'map_invalid_destinations'.tr(
              namedArgs: {'count': '${validation.rejectedCount}'},
            );
    });
  }

  /// 🔄 Retry calculation
  /// 🔄 Retry calculation
  Future<void> _retryCalculation() async {
    safeSetState(() {
      isLoading = true;
      errorMessage = null;
    });
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

    if (currentUserLocationValue == null) {
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

    return Column(
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
          height: 400,
          decoration: BoxDecoration(
            color: colors.surface,
          ),
          child: Stack(
            children: [
              // Using GoogleMap directly instead of FlutterFlowGoogleMap
              // since we need custom markers and polylines
              _buildGoogleMap(),

              // Loading overlay
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

              // Floating close over the map (easy to tap on full-bleed map)
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

        /// 📊 معلومات المسافة والوقت
        Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: DsCard(
            elevated: true,
            bordered: false,
            padding: const EdgeInsets.all(DsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message if any
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DsSpacing.sm),
                    margin: const EdgeInsets.only(bottom: DsSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.warningContainer,
                      borderRadius: DsRadius.small,
                      border: Border.all(
                        color: colors.warning,
                      ),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.landscape,
                                  size: 20, color: colors.info),
                              const SizedBox(width: DsSpacing.xs),
                              Text(
                                'map_distance_label'.tr(),
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DsSpacing.xxs),
                          Text(
                            '${_formatNumber(totalDistanceKm, digits: 1)} ${'unit_km'.tr()}',
                            style: typography.headlineSmall.copyWith(
                              color: DsInfoScale.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '(${_formatNumber((totalDistanceKm * 1000).round())} ${'unit_meter'.tr()})',
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: colors.divider,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 20, color: colors.success),
                              const SizedBox(width: DsSpacing.xs),
                              Text(
                                'map_estimated_time'.tr(),
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DsSpacing.xxs),
                          Text(
                            _formatDuration(totalTimeMinutes),
                            style: typography.headlineSmall.copyWith(
                              color: DsSuccessScale.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '(${_formatNumber(totalTimeMinutes.round())} ${'unit_minute'.tr()})',
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DsSpacing.md),

                // Route statistics
                Container(
                  padding: const EdgeInsets.all(DsSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: DsRadius.small,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.location_pin,
                        label: 'map_stops_count'.tr(),
                        value: FFAppState().cartmkss.length.toString(),
                        color: colors.primary,
                      ),
                      _buildStatItem(
                        icon: Icons.speed,
                        label: 'map_avg_speed'.tr(),
                        value: totalTimeMinutes > 0
                            ? '${_formatNumber((totalDistanceKm / (totalTimeMinutes / 60)).round())} ${'unit_kmh'.tr()}'
                            : '--',
                        color: colors.warning,
                      ),
                      _buildStatItem(
                        icon: Icons.timeline,
                        label: 'map_calc_type'.tr(),
                        value: errorMessage == null
                            ? 'map_calc_accurate'.tr()
                            : 'map_calc_approximate'.tr(),
                        color: errorMessage == null
                            ? colors.success
                            : colors.warning,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🗺️ Build Google Map widget
  Widget _buildGoogleMap() {
    return maps.GoogleMap(
      mapType: maps.MapType.normal,
      initialCameraPosition: maps.CameraPosition(
        target: maps.LatLng(
          currentUserLocationValue!.latitude,
          currentUserLocationValue!.longitude,
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

  /// 📊 Build stat item widget
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: DsSpacing.xxs),
        Text(
          label,
          style: typography.labelSmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: typography.titleSmall.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
