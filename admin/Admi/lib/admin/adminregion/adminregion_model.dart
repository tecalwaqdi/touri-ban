import '/backend/backend.dart';
import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'adminregion_widget.dart' show AdminregionWidget;
import 'package:flutter/material.dart';

class AdminregionModel extends FlutterFlowModel<AdminregionWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Menu2 component.
  late Menu2Model menu2Model;
  List<CitiesRecord> simpleSearchResults = [];
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
