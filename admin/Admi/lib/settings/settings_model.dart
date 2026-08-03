
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'settings_widget.dart' show SettingsWidget;
import 'package:flutter/material.dart';

class SettingsModel extends FlutterFlowModel<SettingsWidget> {
  late Menu2Model menu2Model;

  final formKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();

  TextEditingController? nameTextController;
  FocusNode? nameFocusNode;
  TextEditingController? emailTextController;
  FocusNode? emailFocusNode;
  TextEditingController? phoneTextController;
  FocusNode? phoneFocusNode;
  TextEditingController? photoUrlTextController;
  FocusNode? photoUrlFocusNode;
  TextEditingController? newPasswordTextController;
  FocusNode? newPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  FocusNode? confirmPasswordFocusNode;

  bool isSavingProfile = false;
  bool isSavingPassword = false;
  bool isUploadingPhoto = false;
  FFUploadedFile uploadedLocalPhoto =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedPhotoUrl = '';
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool profileLoaded = false;

  @override
  void initState(BuildContext context) {
    menu2Model = createModel(context, () => Menu2Model());

    nameTextController ??= TextEditingController();
    nameFocusNode ??= FocusNode();
    emailTextController ??= TextEditingController();
    emailFocusNode ??= FocusNode();
    phoneTextController ??= TextEditingController();
    phoneFocusNode ??= FocusNode();
    photoUrlTextController ??= TextEditingController();
    photoUrlFocusNode ??= FocusNode();
    newPasswordTextController ??= TextEditingController();
    newPasswordFocusNode ??= FocusNode();
    confirmPasswordTextController ??= TextEditingController();
    confirmPasswordFocusNode ??= FocusNode();
  }

  void loadProfileFromUser() {
    final user = currentUserDocument;
    if (user != null) {
      applyUserProfile(user, force: true);
      return;
    }
    if (profileLoaded) {
      return;
    }
    nameTextController?.text = currentUserDisplayName;
    emailTextController?.text = currentUserEmail;
    phoneTextController?.text = currentPhoneNumber;
    photoUrlTextController?.text = currentUserPhoto;
    uploadedPhotoUrl = currentUserPhoto;
    profileLoaded = true;
  }

  void applyUserProfile(UserRecord user, {bool force = false}) {
    if (!profileLoaded || force) {
      nameTextController?.text = user.displayName;
      emailTextController?.text = user.email;
      phoneTextController?.text = user.phoneNumber;
      profileLoaded = true;
    }

    final photo = user.photoUrl;
    if (photo.isEmpty) {
      return;
    }
    if (!force &&
        (isUploadingPhoto ||
            (uploadedLocalPhoto.bytes != null &&
                uploadedLocalPhoto.bytes!.isNotEmpty))) {
      return;
    }
    photoUrlTextController?.text = photo;
    uploadedPhotoUrl = photo;
  }

  @override
  void dispose() {
    menu2Model.dispose();
    nameFocusNode?.dispose();
    nameTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    phoneFocusNode?.dispose();
    phoneTextController?.dispose();
    photoUrlFocusNode?.dispose();
    photoUrlTextController?.dispose();
    newPasswordFocusNode?.dispose();
    newPasswordTextController?.dispose();
    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }
}

String get currentPhoneNumber =>
    valueOrDefault(currentUserDocument?.phoneNumber, '');
