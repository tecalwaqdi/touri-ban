import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_account1_shrek_widget.dart' show CreateAccount1ShrekWidget;
import 'package:flutter/material.dart';

class CreateAccount1ShrekModel
    extends FlutterFlowModel<CreateAccount1ShrekWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for emailAddress3 widget.
  FocusNode? emailAddress3FocusNode;
  TextEditingController? emailAddress3TextController;
  String? Function(BuildContext, String?)? emailAddress3TextControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  // State field(s) for passwordConfirm widget.
  FocusNode? passwordConfirmFocusNode;
  TextEditingController? passwordConfirmTextController;
  late bool passwordConfirmVisibility;
  String? Function(BuildContext, String?)?
      passwordConfirmTextControllerValidator;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    passwordConfirmVisibility = false;
  }

  @override
  void dispose() {
    emailAddress3FocusNode?.dispose();
    emailAddress3TextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();
  }
}
