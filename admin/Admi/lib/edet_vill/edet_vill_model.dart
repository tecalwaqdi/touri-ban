
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'edet_vill_widget.dart' show EdetVillWidget;
import 'package:flutter/material.dart';

class EdetVillModel extends FlutterFlowModel<EdetVillWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataWt5 = false;
  FFUploadedFile uploadedLocalFile_uploadDataWt5 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataWt5 = '';
  bool recordInitialized = false;
  bool labelsLoaded = false;
  String? countryLabel;
  String? regionLabel;
  static const geoLocales = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];
  final geoNameControllers = <String, TextEditingController>{};

  void bindVillagesRecord(VillagesRecord record) {
    if (recordInitialized) {
      return;
    }
    textController1 ??= TextEditingController(text: record.naim);
    textController2 ??= TextEditingController(text: record.osf);
    for (final lang in geoLocales) {
      geoNameControllers[lang] ??=
          TextEditingController(text: record.namesI18n[lang] ?? '');
    }
    switchValue ??= record.acctev;
    uploadedFileUrl_uploadDataWt5 = record.img;
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
    for (final controller in geoNameControllers.values) {
      controller.dispose();
    }
  }
}
