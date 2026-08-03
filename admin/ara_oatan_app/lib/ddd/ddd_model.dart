import '/flutter_flow/flutter_flow_util.dart';
import 'ddd_widget.dart' show DddWidget;
import 'package:flutter/material.dart';

class DddModel extends FlutterFlowModel<DddWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
