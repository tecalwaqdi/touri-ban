
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'edet_dolh_widget.dart' show EdetDolhWidget;
import 'package:flutter/material.dart';

class EdetDolhModel extends FlutterFlowModel<EdetDolhWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataX8m = false;
  FFUploadedFile uploadedLocalFile_uploadDataX8m =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataX8m = '';
  bool recordInitialized = false;

  void bindCountriesRecord(CountriesRecord record) {
    if (recordInitialized) {
      return;
    }
    textController1 ??= TextEditingController(text: record.naim);
    textController2 ??= TextEditingController(text: record.osf);
    textController3 ??=
        TextEditingController(text: record.vatPercent.toString());
    textController4 ??=
        TextEditingController(text: record.appCommissionPercent.toString());
    switchValue ??= record.acctev;
    uploadedFileUrl_uploadDataX8m = record.img;
    recordInitialized = true;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  // State field(s) for Switch widget.
  bool? switchValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();
  }
}
