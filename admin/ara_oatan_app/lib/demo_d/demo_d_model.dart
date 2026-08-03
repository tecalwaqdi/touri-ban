import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/core/toury_location_service.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'demo_d_widget.dart' show DemoDWidget;
import 'package:flutter/material.dart';

class DemoDModel extends FlutterFlowModel<DemoDWidget> {
  ///  Local state fields for this page.
  /// idd
  int? idd;

  String? dolh;

  String? mdenh;

  String? adress;

  LatLng? loceshn;

  String? dolhAPI;

  bool isloceshSpeed = true;

  bool? viewINFO;

  String? textTypePrent;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (PENmdenh)] action in Container widget.
  ApiCallResponse? apiResultvcchome2Copy3;
  // Stores action output result for [Backend Call - API (PENmdenh)] action in Container widget.
  ApiCallResponse? apiResultvcchome2Copy4;
  // Stores action output result for [Backend Call - API (PENmdenh)] action in Button widget.
  ApiCallResponse? apiResultvcchome2Copy;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  VillagesRecord? villCITE;
  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // Stores action output result for [Firestore Query - Query a collection] action in Stack widget.
  VillagesRecord? mdenhVill;
  // Stores action output result for [Firestore Query - Query a collection] action in Stack widget.
  CountriesRecord? dol;
  VillagesRecord? resolvedVillage;
  CountriesRecord? resolvedCountry;
  TouryResolvedLocation? lastResolved;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
