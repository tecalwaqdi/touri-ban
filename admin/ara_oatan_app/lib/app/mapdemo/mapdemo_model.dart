import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'mapdemo_widget.dart' show MapdemoWidget;
import 'package:flutter/material.dart';

class MapdemoModel extends FlutterFlowModel<MapdemoWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = const FFPlace();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
