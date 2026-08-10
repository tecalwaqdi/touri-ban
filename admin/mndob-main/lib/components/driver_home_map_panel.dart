import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_country_service.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';
import '/core/driver_online_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/core/driver_order_meta.dart';
import '/core/driver_order_match.dart';
import '/core/driver_order_heatmap_service.dart';
import '/core/driver_live_route_controller.dart';
import '/core/driver_map_utils.dart';
import '/core/driver_navigation_service.dart';
import '/core/toury_maps_config.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// لوحة الخريطة في الرئيسية: موقع المندوب، الرحلة النشطة، واختصارات سريعة.
class DriverHomeMapPanel extends StatelessWidget {
  const DriverHomeMapPanel({
    super.key,
    required this.googleMapsController,
    required this.onCenterChanged,
    this.initialCenter,
    this.settingsRecord,
  });

  final Completer<gmaps.GoogleMapController> googleMapsController;
  final ValueChanged<LatLng> onCenterChanged;
  final LatLng? initialCenter;
  final SettingsRecord? settingsRecord;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;
    final mapHeight = MediaQuery.sizeOf(context).height * 0.46;
    final mapStyle =
        isDark ? GoogleMapStyle.dark : GoogleMapStyle.standard;

    return AuthUserStreamWidget(
      builder: (context) {
        final revOrder = context.watch<FFAppState>().revOrder;
        final isOnline = DriverOnlineState.isMarkedOnline;
        final hasActiveTrip = revOrder != null;

        final LatLng driverLoc = TouryMapsConfig.resolveLocation(
          currentUserDocument?.loceshnMndobNow ?? initialCenter,
          countryIso2: DriverCountryService.currentIso2(),
        );

        if (revOrder != null) {
          return StreamBuilder<OrderRecord>(
            stream: OrderRecord.getDocument(revOrder),
            builder: (context, orderSnap) {
              final live = orderSnap.data?.driverLivePosition;
              final loc = live ?? driverLoc;
              return _buildShell(
                context,
                colors,
                typography,
                isDark,
                mapStyle,
                mapHeight,
                loc,
                isOnline,
                hasActiveTrip,
                revOrder,
              );
            },
          );
        }

        return _buildShell(
          context,
          colors,
          typography,
          isDark,
          mapStyle,
          mapHeight,
          driverLoc,
          isOnline,
          hasActiveTrip,
          null,
        );
      },
    );
  }

  Widget _buildShell(
    BuildContext context,
    DsColors colors,
    DsTypography typography,
    bool isDark,
    GoogleMapStyle mapStyle,
    double mapHeight,
    LatLng driverLoc,
    bool isOnline,
    bool hasActiveTrip,
    DocumentReference? revOrder,
  ) {
    return SizedBox(
      height: mapHeight,
      width: double.infinity,
      child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: DsRadius.xlRadius,
              bottomRight: DsRadius.xlRadius,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _HomeMapLayer(
                  controller: googleMapsController,
                  driverLocation: driverLoc,
                  mapStyle: mapStyle,
                  onCenterChanged: onCenterChanged,
                  initialCenter: initialCenter ?? driverLoc,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: isDark ? 0.55 : 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DsSpacing.md,
                          DsSpacing.xs,
                          DsSpacing.md,
                          DsSpacing.lg,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverTrNamed(
                                      context,
                                      'Welcome, {name}',
                                      {'name': currentUserDisplayName},
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.headlineSmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    valueOrDefault(
                                      currentUserDocument?.mndobVillText,
                                      driverTr(context, 'Work area'),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.bodySmall.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusChip(
                              label: isOnline
                                  ? driverTr(context, 'Online')
                                  : driverTr(context, 'Offline'),
                              isActive: isOnline,
                              onTap: () async {
                                if (!DriverOnlineState.isApproved) {
                                  await DriverDialogs.showAlert(
                                    context,
                                    title: driverTr(context, 'Account status'),
                                    message: driverTr(
                                      context,
                                      'Your account is waiting for admin approval before going online.',
                                    ),
                                    type: DriverMessageType.warning,
                                  );
                                  return;
                                }
                                if (isOnline) {
                                  final ok = await DriverDialogs.showConfirm(
                                    context,
                                    title: driverTr(context, 'Go Offline'),
                                    message: driverTr(
                                      context,
                                      'Stop receiving new requests? Active trips will continue.',
                                    ),
                                  );
                                  if (ok != true) return;
                                  await DriverOnlineState.goOffline(
                                    hasActiveTrip: hasActiveTrip,
                                  );
                                } else {
                                  final result =
                                      await DriverOnlineState.goOnline();
                                  if (!result.ok && context.mounted) {
                                    await DriverDialogs.showAlert(
                                      context,
                                      title: driverTr(context, 'Error'),
                                      message: driverTr(
                                        context,
                                        result.message ??
                                            'Something went wrong. Please try again.',
                                      ),
                                      type: DriverMessageType.error,
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasActiveTrip)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 72,
                    left: DsSpacing.md,
                    right: DsSpacing.md,
                    child: _ActiveTripBanner(),
                  ),
                Positioned(
                  left: DsSpacing.md,
                  right: DsSpacing.md,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.list_alt_rounded,
                          label: driverTr(context, 'Available orders'),
                          color: colors.primary,
                          onTap: () =>
                              context.pushNamed(NowWidget.routeName),
                        ),
                      ),
                      const SizedBox(width: DsSpacing.xs),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.account_balance_wallet_outlined,
                          label: driverTr(context, 'Wallet'),
                          color: colors.primaryStrong,
                          onTap: () => context
                              .pushNamed(DriverWalletWidget.routeName),
                        ),
                      ),
                      const SizedBox(width: DsSpacing.xs),
                      Material(
                        color: colors.card.withValues(alpha: 0.95),
                        borderRadius: DsRadius.medium,
                        elevation: 0,
                        shadowColor: colors.shadow,
                        child: Tooltip(
                          message: 'Recenter map',
                          child: Semantics(
                            button: true,
                            label: 'Recenter map',
                            child: InkWell(
                              borderRadius: DsRadius.medium,
                              onTap: () => _recenterMap(
                                googleMapsController,
                                driverLoc,
                              ),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(
                                  Icons.my_location_rounded,
                                  color: colors.primaryStrong,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  static Future<void> _recenterMap(
    Completer<gmaps.GoogleMapController> controller,
    LatLng location,
  ) async {
    final map = await controller.future;
    await map.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(location.toGoogleMaps(), 15),
    );
  }
}

class _HomeMapLayer extends StatefulWidget {
  const _HomeMapLayer({
    required this.controller,
    required this.driverLocation,
    required this.mapStyle,
    required this.onCenterChanged,
    required this.initialCenter,
  });

  final Completer<gmaps.GoogleMapController> controller;
  final LatLng driverLocation;
  final GoogleMapStyle mapStyle;
  final ValueChanged<LatLng> onCenterChanged;
  final LatLng initialCenter;

  @override
  State<_HomeMapLayer> createState() => _HomeMapLayerState();
}

class _HomeMapLayerState extends State<_HomeMapLayer> {
  final _routeCtrl = DriverLiveRouteController();
  bool _didFitRoadRoute = false;
  bool _showHeatmap = true;
  gmaps.LatLng? _mapCenter;
  double _zoom = 14;
  String? _lastRouteFp;

  @override
  void didUpdateWidget(covariant _HomeMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved = DriverMapUtils.distanceKm(
          oldWidget.driverLocation,
          widget.driverLocation,
        ) ??
        0;
    if (moved > 0.08) {
      unawaited(_animateToDriver());
    }
  }

  Future<void> _animateToDriver() async {
    if (!widget.controller.isCompleted) return;
    final map = await widget.controller.future;
    await map.animateCamera(
      gmaps.CameraUpdate.newLatLng(widget.driverLocation.toGoogleMaps()),
    );
  }

  Future<void> _changeZoom(double delta) async {
    if (!widget.controller.isCompleted) return;
    final map = await widget.controller.future;
    _zoom = (_zoom + delta).clamp(10.0, 19.0);
    await map.animateCamera(gmaps.CameraUpdate.zoomTo(_zoom));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _routeCtrl.reset();
    super.dispose();
  }

  List<LatLng> _routeWaypoints(OrderRecord? order) =>
      order?.routeWaypoints(driverOverride: widget.driverLocation) ??
      [widget.driverLocation];

  void _syncRoute(List<LatLng> waypoints) {
    final fp = waypoints
        .map((p) =>
            '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}')
        .join('|');
    if (fp == _lastRouteFp) return;
    _lastRouteFp = fp;

    // Never call setState synchronously from build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (waypoints.length < 2) {
        if (_routeCtrl.roadPoints != null || _routeCtrl.failed) {
          _routeCtrl.reset();
          _didFitRoadRoute = false;
          setState(() {});
        }
        return;
      }

      unawaited(_routeCtrl.sync(waypoints, onChanged: () async {
        if (!mounted) return;
        setState(() {});
        if (_routeCtrl.roadPoints != null && !_didFitRoadRoute) {
          _didFitRoadRoute = true;
          await DriverMapUtils.fitBounds(
            widget.controller,
            _routeCtrl.roadPoints!,
          );
        }
      }));
    });
  }

  Set<gmaps.Marker> _buildMarkers(BuildContext context, OrderRecord? order) {
    final markers = <gmaps.Marker>{};
    markers.add(
      gmaps.Marker(
        markerId: const gmaps.MarkerId('driver'),
        position: widget.driverLocation.toGoogleMaps(),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueAzure,
        ),
        infoWindow: gmaps.InfoWindow(
          title: driverTr(context, 'Your location'),
        ),
        onTap: () => _animateToDriver(),
      ),
    );
    if (order != null) {
      final pickup = order.customerPickup;
      final dest = order.tripDestination;
      if (pickup != null) {
        markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId('pickup'),
            position: pickup.toGoogleMaps(),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueGreen,
            ),
            infoWindow: gmaps.InfoWindow(
              title: driverTr(context, 'Pickup point'),
              snippet: order.pickupLabel(),
            ),
            onTap: () => context.pushNamed(
              TfaselOrserWidget.routeName,
              queryParameters: {
                'id': serializeParam(
                  order.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            ),
          ),
        );
      }
      // Intermediate stops (ordered landmarks).
      final stops = order.listAmakn;
      for (var i = 0; i < stops.length; i++) {
        final loc = stops[i].hasLoceshn() ? stops[i].loceshn : null;
        if (loc == null) continue;
        if (pickup != null &&
            (loc.latitude - pickup.latitude).abs() < 1e-5 &&
            (loc.longitude - pickup.longitude).abs() < 1e-5) {
          continue;
        }
        if (dest != null &&
            (loc.latitude - dest.latitude).abs() < 1e-5 &&
            (loc.longitude - dest.longitude).abs() < 1e-5) {
          continue;
        }
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('stop_$i'),
            position: loc.toGoogleMaps(),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueOrange,
            ),
            infoWindow: gmaps.InfoWindow(
              title: '${driverTr(context, 'Stop')} ${i + 1}',
              snippet: stops[i].naim.isNotEmpty
                  ? stops[i].naim
                  : stops[i].address,
            ),
          ),
        );
      }
      if (dest != null) {
        markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId('dropoff'),
            position: dest.toGoogleMaps(),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueRed,
            ),
            infoWindow: gmaps.InfoWindow(
              title: driverTr(context, 'Destination'),
              snippet: order.destinationLabel(),
            ),
            onTap: () => context.pushNamed(
              TfaselOrserWidget.routeName,
              queryParameters: {
                'id': serializeParam(
                  order.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            ),
          ),
        );
      }
    }
    return markers;
  }

  Widget _buildMap(
    OrderRecord? order, {
    Set<gmaps.Circle> circles = const {},
    int demandCount = 0,
  }) {
    final routeWaypoints = _routeWaypoints(order);
    _syncRoute(routeWaypoints);
    final visibleRoute = _routeCtrl.roadPoints ?? routeWaypoints;
    final polylines = visibleRoute.length >= 2
        ? {
            gmaps.Polyline(
              polylineId: const gmaps.PolylineId('home_route'),
              points: visibleRoute.map((p) => p.toGoogleMaps()).toList(),
              color: context.dsColors.primary,
              width: 4,
            ),
          }
        : <gmaps.Polyline>{};

    return Stack(
      fit: StackFit.expand,
      children: [
        gmaps.GoogleMap(
          onMapCreated: (controller) async {
            widget.controller.complete(controller);
            await DriverMapUtils.fitBounds(widget.controller, visibleRoute);
          },
          onCameraIdle: () {
            if (_mapCenter != null) {
              widget.onCenterChanged(_mapCenter!.toLatLng());
            }
          },
          onCameraMove: (position) {
            _mapCenter = position.target;
            _zoom = position.zoom;
          },
          style: googleMapStyleStrings[widget.mapStyle],
          initialCameraPosition: gmaps.CameraPosition(
            target: widget.initialCenter.toGoogleMaps(),
            zoom: _zoom,
          ),
          markers: _buildMarkers(context, order),
          polylines: polylines,
          circles: circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          trafficEnabled: true,
          gestureRecognizers: const {
            Factory<OneSequenceGestureRecognizer>(
              EagerGestureRecognizer.new,
            ),
          },
        ),
        if (order != null && routeWaypoints.length >= 2)
          Positioned(
            top: 8,
            right: 8,
            child: _HomeRoutePill(
              isRoadRoute: _routeCtrl.roadPoints != null,
              failed: _routeCtrl.failed,
              loading: _routeCtrl.loading,
            ),
          ),
        if (order == null)
          Positioned(
            top: 8,
            right: 8,
            child: _HeatmapToggle(
              enabled: _showHeatmap,
              count: demandCount,
              onTap: () => setState(() => _showHeatmap = !_showHeatmap),
            ),
          ),
        if (order == null && _showHeatmap && demandCount > 0)
          Positioned(
            top: 8,
            left: 8,
            child: _DemandPill(count: demandCount),
          ),
        Positioned(
          right: 12,
          bottom: 16,
          child: Column(
            children: [
              _MapZoomButton(
                icon: Icons.add_rounded,
                tooltip: driverTr(context, 'Zoom in'),
                onTap: () => _changeZoom(1),
              ),
              const SizedBox(height: 8),
              _MapZoomButton(
                icon: Icons.remove_rounded,
                tooltip: driverTr(context, 'Zoom out'),
                onTap: () => _changeZoom(-1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final revOrder = context.watch<FFAppState>().revOrder;
    if (revOrder != null) {
      return StreamBuilder<OrderRecord>(
        stream: OrderRecord.getDocument(revOrder),
        builder: (context, snapshot) => _buildMap(snapshot.data),
      );
    }

    return AuthUserStreamWidget(
      builder: (context) {
        final car = currentUserDocument?.mndobTypeCar;
        if (car == null) {
          return _buildMap(null);
        }

        return StreamBuilder<List<OrderRecord>>(
          stream: queryOrderRecord(
            queryBuilder: DriverOrderMatch.queryBuilder(typeCarRef: car),
          ),
          builder: (context, snapshot) {
            final orders = DriverOrderMatch.rankForDriver(
              snapshot.data ?? [],
              driverCityOrVillage: currentUserDocument?.mndobVill,
              driverCityRef: FFAppState().mdenh,
            );
            final cells = DriverOrderHeatmapService.cluster(orders);
            final circles = _showHeatmap
                ? DriverOrderHeatmapService.toCircles(cells)
                : <gmaps.Circle>{};
            return _buildMap(
              null,
              circles: circles,
              demandCount: orders.length,
            );
          },
        );
      },
    );
  }
}

class _DemandPill extends StatelessWidget {
  const _DemandPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryStrong.withValues(alpha: 0.9),
        borderRadius: DsRadius.small,
      ),
      child: Text(
        '$count ${driverTr(context, 'Nearby orders')}',
        style: typography.labelSmall.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeatmapToggle extends StatelessWidget {
  const _HeatmapToggle({
    required this.enabled,
    required this.count,
    required this.onTap,
  });

  final bool enabled;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Material(
      color: colors.card.withValues(alpha: 0.92),
      borderRadius: DsRadius.pill,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.whatshot_rounded : Icons.whatshot_outlined,
                size: 16,
                color: enabled ? colors.primaryStrong : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                enabled
                    ? driverTr(context, 'Heat map')
                    : driverTr(context, 'Map view'),
                style: typography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primaryStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeRoutePill extends StatelessWidget {
  const _HomeRoutePill({
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
        ? driverTr(context, 'Road route')
        : failed
            ? driverTr(context, 'Approximate route')
            : loading
                ? driverTr(context, 'Loading route...')
                : '';
    if (label.isEmpty) return const SizedBox.shrink();

    final color = isRoadRoute
        ? colors.success
        : failed
            ? colors.warning
            : colors.primaryStrong;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: DsRadius.small,
      ),
      child: Text(
        label,
        style: typography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? colors.success.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: DsRadius.pill,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.white : colors.warning,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: typography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = context.dsTypography;
    return Material(
      color: color.withValues(alpha: 0.92),
      borderRadius: DsRadius.medium,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.15, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }
}

class _MapZoomButton extends StatelessWidget {
  const _MapZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    return Material(
      color: colors.card.withValues(alpha: 0.94),
      borderRadius: DsRadius.medium,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: colors.primaryStrong, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ActiveTripBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final revOrder = context.watch<FFAppState>().revOrder!;
    return StreamBuilder<OrderRecord>(
      stream: OrderRecord.getDocument(revOrder),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final order = snapshot.data!;
        return Material(
          color: colors.primaryStrong.withValues(alpha: 0.92),
          borderRadius: DsRadius.medium,
          elevation: 0,
          child: InkWell(
            borderRadius: DsRadius.medium,
            onTap: () => context.pushNamed(
              TfaselOrserWidget.routeName,
              queryParameters: {
                'id': serializeParam(
                  order.reference,
                  ParamType.DocumentReference,
                ),
              }.withoutNulls,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.local_taxi_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverTr(context, 'Active trip'),
                          style: typography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          order.halhText.isNotEmpty
                              ? order.halhText
                              : driverTr(context, 'Tap to follow trip'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: driverTr(context, 'Open in Google Maps'),
                    onPressed: () {
                      final pts = order.routeWaypoints();
                      unawaited(
                        DriverNavigationService.openOrderRoute(
                          waypoints: pts,
                          orderRef: order.reference,
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions_rounded,
                        color: Colors.white),
                  ),
                  const Icon(Icons.chevron_left_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
