import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_pag_widget.dart' show HomePagWidget;
import 'package:flutter/material.dart';

class HomePagModel extends FlutterFlowModel<HomePagWidget> {
  ///  Local state fields for this page.

  String? text;

  int? conMndob = 0;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for emailAddress-login widget.
  FocusNode? emailAddressLoginFocusNode;
  TextEditingController? emailAddressLoginTextController;
  String? Function(BuildContext, String?)?
      emailAddressLoginTextControllerValidator;
  // State field(s) for password-login widget.
  FocusNode? passwordLoginFocusNode;
  TextEditingController? passwordLoginTextController;
  late bool passwordLoginVisibility;
  String? Function(BuildContext, String?)? passwordLoginTextControllerValidator;
  // State field(s) for naim widget.
  FocusNode? naimFocusNode;
  TextEditingController? naimTextController;
  String? Function(BuildContext, String?)? naimTextControllerValidator;
  String? _naimTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '9a3ya2v4' /* Full Name is required */,
      );
    }

    return null;
  }

  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  String? _emailTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'gha9dvwa' /* Email Address is required */,
      );
    }

    return null;
  }

  // State field(s) for pass widget.
  FocusNode? passFocusNode;
  TextEditingController? passTextController;
  late bool passVisibility;
  String? Function(BuildContext, String?)? passTextControllerValidator;
  String? _passTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '9msrqa94' /* Password is required */,
      );
    }

    return null;
  }

  // State field(s) for confpass widget.
  FocusNode? confpassFocusNode;
  TextEditingController? confpassTextController;
  late bool confpassVisibility;
  String? Function(BuildContext, String?)? confpassTextControllerValidator;
  String? _confpassTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '9e1cewpc' /* Confirm Password is required */,
      );
    }

    return null;
  }

  // State field(s) for Switch widget.
  bool? switchValue;

  @override
  void initState(BuildContext context) {
    passwordLoginVisibility = false;
    naimTextControllerValidator = _naimTextControllerValidator;
    emailTextControllerValidator = _emailTextControllerValidator;
    passVisibility = false;
    passTextControllerValidator = _passTextControllerValidator;
    confpassVisibility = false;
    confpassTextControllerValidator = _confpassTextControllerValidator;
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    emailAddressLoginFocusNode?.dispose();
    emailAddressLoginTextController?.dispose();

    passwordLoginFocusNode?.dispose();
    passwordLoginTextController?.dispose();

    naimFocusNode?.dispose();
    naimTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    passFocusNode?.dispose();
    passTextController?.dispose();

    confpassFocusNode?.dispose();
    confpassTextController?.dispose();
  }
}
