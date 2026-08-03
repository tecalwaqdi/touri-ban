import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admintypecar_widget.dart' show AdmintypecarWidget;
import 'package:flutter/material.dart';

class AdmintypecarModel extends FlutterFlowModel<AdmintypecarWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Menu2 component.
  late Menu2Model menu2Model;

  @override
  void initState(BuildContext context) {
    menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    menu2Model.dispose();
  }
}
