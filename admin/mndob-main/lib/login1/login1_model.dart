import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'login1_widget.dart' show Login1Widget;
import 'package:flutter/material.dart';

class Login1Model extends FlutterFlowModel<Login1Widget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();

  // State field(s) for emailAddress widget.
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  bool isSigningIn = false;
  bool isResettingPassword = false;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    emailAddressTextControllerValidator = _emailValidator;
    passwordTextControllerValidator = _passwordValidator;
  }

  String? _emailValidator(BuildContext context, String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(BuildContext context, String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  void dispose() {
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
  }
}
