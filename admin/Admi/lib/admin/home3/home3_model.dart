import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'home3_widget.dart' show Home3Widget;
import 'package:flutter/material.dart';

class Home3Model extends FlutterFlowModel<Home3Widget> {
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
