import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

import '/core/toury_polyline.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'mmaapp_widget.dart' show MmaappWidget;
import 'package:flutter/material.dart';
import 'dart:async';
import '/flutter_flow/flutter_flow_model.dart';

class MmaappModel extends FlutterFlowModel<MmaappWidget> {
  
  
  
   List<LatLng> routePoints = [];
  List<LatLng> polylinePoints = [];
  
  void updatePolyline(String encodedPolyline) {
    polylinePoints = TouryPolyline.decode(encodedPolyline, precision: 5);
  }
  /// State fields for Google Map
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  /// 🗺️ نقاط المسار (Polyline)

  @override
  void initState(BuildContext context) {
    routePoints = [];
  }

 maps.GoogleMapController? mapController;
  
  @override
  void dispose() {
    mapController?.dispose();
  }
}