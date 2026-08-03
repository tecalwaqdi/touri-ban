import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'home22_dashboard_widget.dart' show Home22DashboardWidget;
import 'package:flutter/material.dart';

class Home22DashboardModel extends FlutterFlowModel<Home22DashboardWidget> {
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
