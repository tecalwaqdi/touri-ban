import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_profits_widget.dart' show AdminProfitsWidget;
import 'package:flutter/material.dart';

class AdminProfitsModel extends FlutterFlowModel<AdminProfitsWidget> {
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
