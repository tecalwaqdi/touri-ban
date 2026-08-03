import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'list22_task_overview_responsive_widget.dart'
    show List22TaskOverviewResponsiveWidget;
import 'package:flutter/material.dart';

class List22TaskOverviewResponsiveModel
    extends FlutterFlowModel<List22TaskOverviewResponsiveWidget> {
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
