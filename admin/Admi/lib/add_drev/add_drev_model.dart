import '/flutter_flow/flutter_flow_util.dart';
import 'add_drev_widget.dart' show AddDrevWidget;
import 'package:flutter/material.dart';

class AddDrevModel extends FlutterFlowModel<AddDrevWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;
  bool isLoadingEdit = false;
  bool passVisibility = false;
  bool cpassVisibility = false;

  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for mobil widget.
  FocusNode? mobilFocusNode;
  TextEditingController? mobilTextController;
  String? Function(BuildContext, String?)? mobilTextControllerValidator;
  // State field(s) for pass widget.
  FocusNode? passFocusNode;
  TextEditingController? passTextController;
  String? Function(BuildContext, String?)? passTextControllerValidator;
  // State field(s) for cpass widget.
  FocusNode? cpassFocusNode;
  TextEditingController? cpassTextController;
  String? Function(BuildContext, String?)? cpassTextControllerValidator;
  // State field(s) for cartype widget.
  FocusNode? cartypeFocusNode;
  TextEditingController? cartypeTextController;
  String? Function(BuildContext, String?)? cartypeTextControllerValidator;
  // State field(s) for plat widget.
  FocusNode? platFocusNode;
  TextEditingController? platTextController;
  String? Function(BuildContext, String?)? platTextControllerValidator;
  // State field(s) for workcity widget.
  FocusNode? workcityFocusNode;
  TextEditingController? workcityTextController;
  String? Function(BuildContext, String?)? workcityTextControllerValidator;
  bool isDataUploading_uploadDataLbm = false;
  FFUploadedFile uploadedLocalFile_uploadDataLbm =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataLbm = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    mobilFocusNode?.dispose();
    mobilTextController?.dispose();

    passFocusNode?.dispose();
    passTextController?.dispose();

    cpassFocusNode?.dispose();
    cpassTextController?.dispose();

    cartypeFocusNode?.dispose();
    cartypeTextController?.dispose();

    platFocusNode?.dispose();
    platTextController?.dispose();

    workcityFocusNode?.dispose();
    workcityTextController?.dispose();
  }
}
