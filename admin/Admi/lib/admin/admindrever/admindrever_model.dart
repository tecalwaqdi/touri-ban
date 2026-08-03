import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admindrever_widget.dart' show AdmindreverWidget;
import 'package:flutter/material.dart';

class AdmindreverModel extends FlutterFlowModel<AdmindreverWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Menu2 component.
  late Menu2Model menu2Model;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    menu2Model.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
