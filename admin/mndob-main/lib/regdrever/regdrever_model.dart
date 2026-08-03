import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/list_type_car_widget.dart';
import '/components/villmndob_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'regdrever_widget.dart' show RegdreverWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegdreverModel extends FlutterFlowModel<RegdreverWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  // State field(s) for IDnumber widget.
  FocusNode? iDnumberFocusNode;
  TextEditingController? iDnumberTextController;
  String? Function(BuildContext, String?)? iDnumberTextControllerValidator;
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
  // State field(s) for typecar widget.
  FocusNode? typecarFocusNode;
  TextEditingController? typecarTextController;
  String? Function(BuildContext, String?)? typecarTextControllerValidator;
  // State field(s) for model widget.
  FocusNode? modelFocusNode;
  TextEditingController? modelTextController;
  String? Function(BuildContext, String?)? modelTextControllerValidator;
  // State field(s) for plat widget.
  FocusNode? platFocusNode;
  TextEditingController? platTextController;
  String? Function(BuildContext, String?)? platTextControllerValidator;
  // State field(s) for workcity widget.
  FocusNode? workcityFocusNode;
  TextEditingController? workcityTextController;
  String? Function(BuildContext, String?)? workcityTextControllerValidator;
  // State field(s) for cartype widget.
  FocusNode? cartypeFocusNode;
  TextEditingController? cartypeTextController;
  String? Function(BuildContext, String?)? cartypeTextControllerValidator;
  bool isDataUploading_uploadDataLbm = false;
  FFUploadedFile uploadedLocalFile_uploadDataLbm =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataLbm = '';

  bool isDataUploading_uploadData1k33 = false;
  FFUploadedFile uploadedLocalFile_uploadData1k33 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData1k33 = '';

  // Stores action output result for [Backend Call - API (what)] action in Button widget.
  ApiCallResponse? apiResult60p;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    iDnumberFocusNode?.dispose();
    iDnumberTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    mobilFocusNode?.dispose();
    mobilTextController?.dispose();

    passFocusNode?.dispose();
    passTextController?.dispose();

    cpassFocusNode?.dispose();
    cpassTextController?.dispose();

    typecarFocusNode?.dispose();
    typecarTextController?.dispose();

    modelFocusNode?.dispose();
    modelTextController?.dispose();

    platFocusNode?.dispose();
    platTextController?.dispose();

    workcityFocusNode?.dispose();
    workcityTextController?.dispose();

    cartypeFocusNode?.dispose();
    cartypeTextController?.dispose();
  }
}
