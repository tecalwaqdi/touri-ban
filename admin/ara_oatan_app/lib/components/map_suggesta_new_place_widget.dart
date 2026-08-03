import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'map_suggesta_new_place_model.dart';
export 'map_suggesta_new_place_model.dart';

/// Map Suggesta New Place
class MapSuggestaNewPlaceWidget extends StatefulWidget {
  const MapSuggestaNewPlaceWidget({super.key});

  @override
  State<MapSuggestaNewPlaceWidget> createState() =>
      _MapSuggestaNewPlaceWidgetState();
}

class _MapSuggestaNewPlaceWidgetState extends State<MapSuggestaNewPlaceWidget> {
  late MapSuggestaNewPlaceModel _model;

  LatLng? currentUserLocationValue;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapSuggestaNewPlaceModel());

    getCurrentUserLocation(
            defaultLocation: const LatLng(0.0, 0.0), cached: true)
        .then((loc) => safeSetState(() => currentUserLocationValue = loc));
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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

    if (currentUserLocationValue == null) {
      return Container(
        color: colors.scaffold,
        child: const DsLoading(size: 50),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.rectangle,
        border: Border.all(
          color: colors.primary,
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: FlutterFlowGoogleMap(
              controller: _model.googleMapsController,
              onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
              initialLocation: _model.googleMapsCenter ??=
                  currentUserLocationValue!,
              markerColor: GoogleMarkerColor.violet,
              mapType: MapType.normal,
              style: GoogleMapStyle.standard,
              initialZoom: 14.0,
              allowInteraction: true,
              allowZoom: true,
              showZoomControls: true,
              showLocation: true,
              showCompass: false,
              showMapToolbar: false,
              showTraffic: true,
              centerMapOnMarkerTap: true,
              mapTakesGesturePreference: false,
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: PointerInterceptor(
              intercepting: isWeb,
              child: Stack(
                children: [
                  Icon(
                    Icons.location_on,
                    color: colors.error,
                    size: 24.0,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(1.0, -1.0),
            child: PointerInterceptor(
              intercepting: isWeb,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        DsSpacing.xs, DsSpacing.xxs, 0.0, 0.0),
                    child: DsIconButton(
                      icon: Icons.close,
                      foreground: colors.textPrimary,
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(0.0, 1.0),
            child: PointerInterceptor(
              intercepting: isWeb,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    0.0, 0.0, 0.0, DsSpacing.xxs),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    FFAppState().mapSuggestaNewPlace =
                        FFAppState().mapSuggestaNewPlace;
                    safeSetState(() {});
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    backgroundColor: colors.surface,
                    side: BorderSide(color: colors.error),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        DsSpacing.md, 0.0, DsSpacing.md, 0.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: DsRadius.small,
                    ),
                  ),
                  icon: const Icon(
                    Icons.location_pin,
                    size: 15.0,
                  ),
                  label: Text(
                    FFLocalizations.of(context).getText(
                      '75ecv7vh' /* Save */,
                    ),
                    style: context.dsTypography.titleSmall.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
