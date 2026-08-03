import '/flutter_flow/flutter_flow_util.dart';
import 'add_yser_widget.dart' show AddYserWidget;
import 'package:flutter/material.dart';

class AddYserModel extends FlutterFlowModel<AddYserWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for pass widget.
  FocusNode? passFocusNode;
  TextEditingController? passTextController;
  late bool passVisibility;
  String? Function(BuildContext, String?)? passTextControllerValidator;
  // State field(s) for cpass widget.
  FocusNode? cpassFocusNode;
  TextEditingController? cpassTextController;
  late bool cpassVisibility;
  String? Function(BuildContext, String?)? cpassTextControllerValidator;

  @override
  void initState(BuildContext context) {
    passVisibility = false;
    cpassVisibility = false;
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController1?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    passFocusNode?.dispose();
    passTextController?.dispose();

    cpassFocusNode?.dispose();
    cpassTextController?.dispose();
  }
}
