import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_add_partner_widget.dart' show AdminAddPartnerWidget;
import 'package:flutter/material.dart';

class AdminAddPartnerModel extends FlutterFlowModel<AdminAddPartnerWidget> {
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;

  FocusNode? descriptionFocusNode;
  TextEditingController? descriptionTextController;

  FocusNode? phoneFocusNode;
  TextEditingController? phoneTextController;

  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;

  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  bool passwordVisibility = false;

  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  bool confirmPasswordVisibility = false;

  bool isDataUploading_mainImage = false;
  FFUploadedFile uploadedLocalFile_mainImage =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_mainImage = '';

  bool isDataUploading_secondImage = false;
  FFUploadedFile uploadedLocalFile_secondImage =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_secondImage = '';

  FFPlace placePickerValue = FFPlace();
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  bool activeValue = true;
  double ratingValue = 0.0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();
    descriptionFocusNode?.dispose();
    descriptionTextController?.dispose();
    phoneFocusNode?.dispose();
    phoneTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }
}
