import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_vill_widget.dart' show AddVillWidget;
import 'package:flutter/material.dart';

class AddVillModel extends FlutterFlowModel<AddVillWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataWt55 = false;
  FFUploadedFile uploadedLocalFile_uploadDataWt55 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataWt55 = '';

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
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
  }
}
