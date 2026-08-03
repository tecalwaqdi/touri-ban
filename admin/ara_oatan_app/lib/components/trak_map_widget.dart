import '/backend/backend.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'trak_map_model.dart';
export 'trak_map_model.dart';

class TrakMapWidget extends StatefulWidget {
  const TrakMapWidget({
    super.key,
    required this.userMndon,
  });

  final DocumentReference? userMndon;

  @override
  State<TrakMapWidget> createState() => _TrakMapWidgetState();
}

class _TrakMapWidgetState extends State<TrakMapWidget> {
  late TrakMapModel _model;

  LatLng? currentUserLocationValue;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrakMapModel());

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
    final colors = context.dsColors;

    if (currentUserLocationValue == null) {
      return Container(
        color: colors.scaffold,
        child: const DsLoading(size: 50),
      );
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(widget.userMndon!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return const Center(
            child: DsLoading(size: 50),
          );
        }

        final stackUserRecord = snapshot.data!;

        return Stack(
          children: [
            Builder(builder: (context) {
              final googleMapMarker = stackUserRecord.loceshnMndobNow;
              return FlutterFlowGoogleMap(
                controller: _model.googleMapsController,
                onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                initialLocation: _model.googleMapsCenter ??=
                    currentUserLocationValue!,
                markers: [
                  if (googleMapMarker != null)
                    FlutterFlowMarker(
                      googleMapMarker.serialize(),
                      googleMapMarker,
                    ),
                ],
                markerColor: GoogleMarkerColor.blue,
                mapType: MapType.hybrid,
                style: GoogleMapStyle.standard,
                initialZoom: 14.0,
                allowInteraction: true,
                allowZoom: true,
                showZoomControls: true,
                showLocation: true,
                showCompass: false,
                showMapToolbar: true,
                showTraffic: false,
                centerMapOnMarkerTap: true,
                mapTakesGesturePreference: false,
              );
            }),
            PointerInterceptor(
              intercepting: isWeb,
              child: Stack(
                children: [
                  Align(
                    alignment: const AlignmentDirectional(1.0, -1.0),
                    child: DsIconButton(
                      icon: Icons.close_sharp,
                      foreground: colors.textSecondary,
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
