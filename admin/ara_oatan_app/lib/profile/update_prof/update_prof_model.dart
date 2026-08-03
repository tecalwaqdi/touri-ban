import '/flutter_flow/flutter_flow_util.dart';
import 'update_prof_widget.dart' show UpdateProfWidget;
import 'package:flutter/material.dart';

class UpdateProfModel extends FlutterFlowModel<UpdateProfWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataMcff1 = false;
  FFUploadedFile uploadedLocalFile_uploadDataMcff1 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataMcff1 = '';

  bool isDataUploading_uploadDataMcff = false;
  FFUploadedFile uploadedLocalFile_uploadDataMcff =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataMcff = '';

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;

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
  }
}
