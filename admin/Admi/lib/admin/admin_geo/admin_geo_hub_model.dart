import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_geo_hub_widget.dart' show AdminGeoHubWidget;
import 'package:flutter/material.dart';

class AdminGeoHubModel extends FlutterFlowModel<AdminGeoHubWidget> {
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
