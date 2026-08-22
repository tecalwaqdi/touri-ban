import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_settlement_receipt_widget.dart' show AdminSettlementReceiptWidget;
import 'package:flutter/material.dart';

class AdminSettlementReceiptModel
    extends FlutterFlowModel<AdminSettlementReceiptWidget> {
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
