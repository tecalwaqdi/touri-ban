import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'map_suggesta_new_place_widget.dart' show MapSuggestaNewPlaceWidget;
import 'package:flutter/material.dart';

class MapSuggestaNewPlaceModel
    extends FlutterFlowModel<MapSuggestaNewPlaceWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
