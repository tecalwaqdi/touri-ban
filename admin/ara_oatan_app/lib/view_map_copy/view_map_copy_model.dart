import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'view_map_copy_widget.dart' show ViewMapCopyWidget;
import 'package:flutter/material.dart';

class ViewMapCopyModel extends FlutterFlowModel<ViewMapCopyWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = const FFPlace();
  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
