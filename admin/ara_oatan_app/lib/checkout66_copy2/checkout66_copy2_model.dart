import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'checkout66_copy2_widget.dart' show Checkout66Copy2Widget;
import 'package:flutter/material.dart';

class Checkout66Copy2Model extends FlutterFlowModel<Checkout66Copy2Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for CountController widget.
  int? countControllerValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
