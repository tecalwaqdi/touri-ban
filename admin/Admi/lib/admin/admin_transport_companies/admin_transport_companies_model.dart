import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_transport_companies_widget.dart'
    show AdminTransportCompaniesWidget;
import 'package:flutter/material.dart';

class AdminTransportCompaniesModel
    extends FlutterFlowModel<AdminTransportCompaniesWidget> {
  late Menu2Model menu2Model;

  TextEditingController? textController;
  FocusNode? textFieldFocusNode;

  @override
  void initState(BuildContext context) {
    menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    menu2Model.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
