import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'toury_custom_place_widget.dart' show TouryCustomPlaceWidget;
import 'package:flutter/material.dart';

class TouryCustomPlaceModel extends FlutterFlowModel<TouryCustomPlaceWidget> {
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  FFPlace placePickerValue = const FFPlace();
  final nameController = TextEditingController();
  final nameFocusNode = FocusNode();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameController.dispose();
    nameFocusNode.dispose();
  }
}
