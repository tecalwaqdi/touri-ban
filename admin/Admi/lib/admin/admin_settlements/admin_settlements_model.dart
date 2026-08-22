import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_settlements_widget.dart' show AdminSettlementsWidget;
import 'package:flutter/material.dart';

class AdminSettlementsModel extends FlutterFlowModel<AdminSettlementsWidget> {
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
