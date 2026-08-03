import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'addressadd_widget.dart' show AddressaddWidget;
import 'package:flutter/material.dart';

class AddressaddModel extends FlutterFlowModel<AddressaddWidget> {
  ///  Local state fields for this page.

  DocumentReference? idvill;

  LatLng? loceshn;

  String? fullAdress;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Stores action output result for [Backend Call - API (PENmdenh)] action in addressadd widget.
  ApiCallResponse? apiResultvcc;
  // Stores action output result for [Firestore Query - Query a collection] action in addressadd widget.
  VillagesRecord? villCobe;
  // State field(s) for tilet widget.
  FocusNode? tiletFocusNode;
  TextEditingController? tiletTextController;
  String? Function(BuildContext, String?)? tiletTextControllerValidator;
  String? _tiletTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'o7ypkxe8' /* Field is required */,
      );
    }

    return null;
  }

  // Stores action output result for [Backend Call - API (PENmdenh)] action in Buttonx widget.
  ApiCallResponse? apiResultvccCopy2;
  // Stores action output result for [Firestore Query - Query a collection] action in Buttonx widget.
  VillagesRecord? villCobe2;
  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // Stores action output result for [Backend Call - API (PENmdenh)] action in Button widget.
  ApiCallResponse? aPIsend;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  VillagesRecord? villasend;
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  AdressuserRecord? adressnow;

  @override
  void initState(BuildContext context) {
    tiletTextControllerValidator = _tiletTextControllerValidator;
  }

  @override
  void dispose() {
    tiletFocusNode?.dispose();
    tiletTextController?.dispose();
  }
}
