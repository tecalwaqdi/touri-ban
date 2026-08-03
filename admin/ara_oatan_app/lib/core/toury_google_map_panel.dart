import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '/core/app_design_system.dart';
import '/core/app_ux_widgets.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/lat_lng.dart';

/// لوحة خريطة موحّدة — تحميل، دبوس مركزي، وتلميح عند فشل التهيئة.
class TouryMapPanel extends StatefulWidget {
  const TouryMapPanel({
    super.key,
    required this.controller,
    this.initialLocation,
    this.onCameraIdle,
    this.height,
    this.initialZoom = TouryMapsConfig.defaultZoom,
    this.countryIso2,
    this.markers = const [],
    this.markerColor = GoogleMarkerColor.violet,
    this.mapType = MapType.normal,
    this.showCenterPin = true,
    this.showMyLocation = true,
    this.showZoomControls = true,
    this.borderRadius = 16,
    this.mapTakesGesturePreference = true,
  });

  final Completer<GoogleMapController> controller;
  final LatLng? initialLocation;
  final void Function(LatLng)? onCameraIdle;
  final double? height;
  final double initialZoom;
  /// When [initialLocation] is missing, center on this ISO (never SA globally).
  final String? countryIso2;
  final Iterable<FlutterFlowMarker> markers;
  final GoogleMarkerColor markerColor;
  final MapType mapType;
  final bool showCenterPin;
  final bool showMyLocation;
  final bool showZoomControls;
  final double borderRadius;
  final bool mapTakesGesturePreference;

  @override
  State<TouryMapPanel> createState() => _TouryMapPanelState();
}

class _TouryMapPanelState extends State<TouryMapPanel> {
  bool _mapReady = false;
  bool _showConfigHint = false;
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_watchMapReady());
    _readyTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_mapReady) {
        setState(() => _showConfigHint = true);
      }
    });
  }

  Future<void> _watchMapReady() async {
    try {
      await widget.controller.future;
      if (!mounted) return;
      setState(() {
        _mapReady = true;
        _showConfigHint = false;
      });
    } catch (e) {
      debugPrint('TouryMapPanel: map controller error: $e');
      if (mounted) setState(() => _showConfigHint = true);
    }
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    super.dispose();
  }

  GoogleMapStyle _mapStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? GoogleMapStyle.dark : GoogleMapStyle.standard;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final mapHeight = widget.height ?? TouryLayout.mapPanelHeight(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: mapHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlutterFlowGoogleMap(
                controller: widget.controller,
                onCameraIdle: widget.onCameraIdle,
                initialLocation: TouryMapsConfig.resolveLocation(
                  widget.initialLocation,
                  countryIso2: widget.countryIso2,
                ),
                markers: widget.markers,
                markerColor: widget.markerColor,
                mapType: widget.mapType,
                style: _mapStyle(context),
                initialZoom: TouryMapsConfig.resolveZoom(
                  preferred: widget.initialZoom,
                  countryIso2: widget.countryIso2,
                ),
                allowInteraction: true,
                allowZoom: true,
                showZoomControls: widget.showZoomControls,
                showLocation: widget.showMyLocation,
                showCompass: false,
                showMapToolbar: false,
                showTraffic: false,
                centerMapOnMarkerTap: false,
                mapTakesGesturePreference: widget.mapTakesGesturePreference,
              ),
              if (!_mapReady)
                ColoredBox(
                  color: colors.surface.withValues(alpha: 0.92),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: TouryLayout.spinnerSize(context),
                          height: TouryLayout.spinnerSize(context),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'map_locating'.tr(),
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.showCenterPin)
                Center(
                  child: PointerInterceptor(
                    intercepting: kIsWeb,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: TouryBrand.partnerRed,
                        size: TouryLayout.isCompact(context) ? 34 : 40,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showConfigHint)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Material(
                    color: colors.error.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        'map_load_failed'.tr(),
                        textAlign: TextAlign.center,
                        style: typography.bodySmall.copyWith(
                          color: colors.onError,
                          fontSize: 12,
                        ),
                      ),
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
