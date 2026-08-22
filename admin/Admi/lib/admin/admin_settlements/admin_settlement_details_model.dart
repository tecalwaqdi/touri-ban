import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_settlement_details_widget.dart' show AdminSettlementDetailsWidget;
import 'package:flutter/material.dart';

class AdminSettlementDetailsModel
    extends FlutterFlowModel<AdminSettlementDetailsWidget> {
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
