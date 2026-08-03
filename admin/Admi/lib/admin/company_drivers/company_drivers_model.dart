import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'company_drivers_widget.dart' show CompanyDriversWidget;
import 'package:flutter/material.dart';

class CompanyDriversModel extends FlutterFlowModel<CompanyDriversWidget> {
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
