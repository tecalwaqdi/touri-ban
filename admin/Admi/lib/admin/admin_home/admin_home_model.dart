import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admin_home_widget.dart' show AdminHomeWidget;
import 'package:flutter/material.dart';

class AdminHomeModel extends FlutterFlowModel<AdminHomeWidget> {
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
