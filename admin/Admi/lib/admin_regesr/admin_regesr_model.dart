import '/flutter_flow/flutter_flow_util.dart';
import 'admin_regesr_widget.dart' show AdminRegesrWidget;
import 'package:flutter/material.dart';

class AdminRegesrModel extends FlutterFlowModel<AdminRegesrWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for naim widget.
  FocusNode? naimFocusNode;
  TextEditingController? naimTextController;
  String? Function(BuildContext, String?)? naimTextControllerValidator;
  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for pass widget.
  FocusNode? passFocusNode;
  TextEditingController? passTextController;
  late bool passVisibility;
  String? Function(BuildContext, String?)? passTextControllerValidator;
  // State field(s) for cPass widget.
  FocusNode? cPassFocusNode;
  TextEditingController? cPassTextController;
  late bool cPassVisibility;
  String? Function(BuildContext, String?)? cPassTextControllerValidator;

  @override
  void initState(BuildContext context) {
    passVisibility = false;
    cPassVisibility = false;
  }

  @override
  void dispose() {
    naimFocusNode?.dispose();
    naimTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    passFocusNode?.dispose();
    passTextController?.dispose();

    cPassFocusNode?.dispose();
    cPassTextController?.dispose();
  }
}
