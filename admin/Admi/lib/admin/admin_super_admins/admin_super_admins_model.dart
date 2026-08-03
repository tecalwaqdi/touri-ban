import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_super_admins_widget.dart' show AdminSuperAdminsWidget;
import 'package:flutter/material.dart';

class AdminSuperAdminsModel extends FlutterFlowModel<AdminSuperAdminsWidget> {
  late Menu2Model menu2Model;
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

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
