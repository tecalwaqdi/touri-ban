import '/flutter_flow/flutter_flow_util.dart';
import 'admin_add_super_admin_widget.dart' show AdminAddSuperAdminWidget;
import 'package:flutter/material.dart';

class AdminAddSuperAdminModel extends FlutterFlowModel<AdminAddSuperAdminWidget> {
  final formKey = GlobalKey<FormState>();

  TextEditingController? nameTextController;
  FocusNode? nameFocusNode;
  TextEditingController? phoneTextController;
  FocusNode? phoneFocusNode;
  TextEditingController? emailTextController;
  FocusNode? emailFocusNode;
  TextEditingController? passwordTextController;
  FocusNode? passwordFocusNode;
  TextEditingController? confirmPasswordTextController;
  FocusNode? confirmPasswordFocusNode;

  bool activeValue = true;
  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameTextController?.dispose();
    nameFocusNode?.dispose();
    phoneTextController?.dispose();
    phoneFocusNode?.dispose();
    emailTextController?.dispose();
    emailFocusNode?.dispose();
    passwordTextController?.dispose();
    passwordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
    confirmPasswordFocusNode?.dispose();
  }
}
