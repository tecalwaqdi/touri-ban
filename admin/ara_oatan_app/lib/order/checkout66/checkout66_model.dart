import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'checkout66_widget.dart' show Checkout66Widget;
import 'package:flutter/material.dart';

class Checkout66Model extends FlutterFlowModel<Checkout66Widget> {
  ///  Local state fields for this page.

  String? msegAi;

  int? nmndob = 0;

  bool? iszero = false;

  int? yes = 1;

  String? vill = '/villages/ehkTdtHEvhsBM49LXV7C';

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (PENmdenh)] action in ListTile widget.
  ApiCallResponse? apiResultvcchome2Copy33;
  // Stores action output result for [Firestore Query - Query a collection] action in ListTile widget.
  VillagesRecord? vil;
  DateTime? datePicked;
  // State field(s) for CountController widget.
  int? countControllerValue;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (Myser)] action in Button widget.
  ApiCallResponse? apiResultr5n;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  int? conOrder;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  SettingsRecord? ngl;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  List<UserRecord>? mnadebList;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  int? mnadebListcon;
  // Stores action output result for [Backend Call - API (watc)] action in Button widget.
  ApiCallResponse? apiResultdy8;
  // Stores action output result for [Firestore Query - Query a collection] action in Button2 widget.
  int? conOrder2;
  // Stores action output result for [Firestore Query - Query a collection] action in Button2 widget.
  SettingsRecord? ngl2;
  // Stores action output result for [Firestore Query - Query a collection] action in Button2 widget.
  List<UserRecord>? mnadebList2;
  // Stores action output result for [Firestore Query - Query a collection] action in Button2 widget.
  int? mnadebListcon2;
  // Stores action output result for [Backend Call - API (watc)] action in Button2 widget.
  ApiCallResponse? apiResultdy88;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
