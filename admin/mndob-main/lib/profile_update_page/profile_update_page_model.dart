import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'profile_update_page_widget.dart' show ProfileUpdatePageWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileUpdatePageModel extends FlutterFlowModel<ProfileUpdatePageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading_uploadData8h7 = false;
  FFUploadedFile uploadedLocalFile_uploadData8h7 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData8h7 = '';

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for nameCar widget.
  FocusNode? nameCarFocusNode;
  TextEditingController? nameCarTextController;
  String? Function(BuildContext, String?)? nameCarTextControllerValidator;
  // State field(s) for model widget.
  FocusNode? modelFocusNode;
  TextEditingController? modelTextController;
  String? Function(BuildContext, String?)? modelTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    nameCarFocusNode?.dispose();
    nameCarTextController?.dispose();

    modelFocusNode?.dispose();
    modelTextController?.dispose();
  }
}
