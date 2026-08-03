import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'map_model.dart';
export 'map_model.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({
    super.key,
    required this.idmap,
  });

  final LatLng? idmap;

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final _googleMapMarker = widget.idmap;
      return FlutterFlowGoogleMap(
        controller: _model.googleMapsController,
        onCameraIdle: (latLng) =>
            safeSetState(() => _model.googleMapsCenter = latLng),
        initialLocation: _model.googleMapsCenter ??= widget.idmap!,
        markers: [
          if (_googleMapMarker != null)
            FlutterFlowMarker(
              _googleMapMarker.serialize(),
              _googleMapMarker,
            ),
        ],
        markerColor: GoogleMarkerColor.violet,
        mapType: MapType.normal,
        style: GoogleMapStyle.standard,
        initialZoom: 14.0,
        allowInteraction: true,
        allowZoom: true,
        showZoomControls: true,
        showLocation: true,
        showCompass: true,
        showMapToolbar: true,
        showTraffic: true,
        centerMapOnMarkerTap: true,
      );
    });
  }
}
