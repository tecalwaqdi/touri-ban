import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'edetressadd_widget.dart' show EdetressaddWidget;
import 'package:flutter/material.dart';

class EdetressaddModel extends FlutterFlowModel<EdetressaddWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for tilet widget.
  FocusNode? tiletFocusNode;
  TextEditingController? tiletTextController;
  String? Function(BuildContext, String?)? tiletTextControllerValidator;
  String? _tiletTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'khov9ge0' /* Field is required */,
      );
    }

    return null;
  }

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

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
