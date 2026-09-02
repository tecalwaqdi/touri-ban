import 'package:flutter/material.dart';

import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminNotificationsModel extends FlutterFlowModel {
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
