
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
    textController3 ??= TextEditingController(
      text: record.hasVatPercent() ? record.vatPercent.toString() : '',
    );
    textController4 ??=
        TextEditingController(text: record.appCommissionPercent.toString());
    textControllerCurrencyCode ??=
        TextEditingController(text: record.currencyCode);
    textControllerCurrencySymbol ??=
        TextEditingController(text: record.currencySymbol);
    final fx = record.snapshotData['local_units_per_sar'];
    textControllerFx ??= TextEditingController(
      text: fx == null ? '' : fx.toString(),
    );
    switchValue ??= record.acctev;
    for (final lang in geoLocales) {
      geoNameControllers[lang] ??= TextEditingController(
        text: record.namesI18n[lang] ?? '',
      );
    }
    cashEnabled ??= record.snapshotData['cash_enabled'] != false;
    onlinePaymentEnabled ??=
        record.snapshotData['online_payment_enabled'] != false;
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
  FocusNode? textFieldFocusNodeCurrencyCode;
  TextEditingController? textControllerCurrencyCode;
  FocusNode? textFieldFocusNodeCurrencySymbol;
  TextEditingController? textControllerCurrencySymbol;
  // State field(s) for Switch widget.
  bool? switchValue;
  bool? cashEnabled;
  bool? onlinePaymentEnabled;
  FocusNode? textFieldFocusNodeFx;
  TextEditingController? textControllerFx;
  static const geoLocales = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];
  final geoNameControllers = <String, TextEditingController>{};

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

    textFieldFocusNodeCurrencyCode?.dispose();
    textControllerCurrencyCode?.dispose();

    textFieldFocusNodeCurrencySymbol?.dispose();
    textControllerCurrencySymbol?.dispose();
    textFieldFocusNodeFx?.dispose();
    textControllerFx?.dispose();
    for (final controller in geoNameControllers.values) {
      controller.dispose();
    }
  }
}
