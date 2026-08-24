import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/driver_reg_location_cascade.dart';
import '/components/driver_reg_location_map.dart';
import '/components/list_type_car_widget.dart';
import '/core/driver_auth_errors.dart';
import '/core/driver_auth_validation_service.dart';
import '/core/driver_country_service.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/core/driver_email_verification_service.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_document_upload_service.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_location_catalog_service.dart';
import '/core/driver_phone_number_service.dart';
import '/core/driver_registration_draft.dart';
import '/core/driver_registration_submission_service.dart';
import '/core/driver_registration_validators.dart';
import '/core/driver_session_router.dart';
import '/core/driver_verify_panels.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'regdrever_model.dart';
export 'regdrever_model.dart';

class RegdreverWidget extends StatefulWidget {
  const RegdreverWidget({super.key});

  static String routeName = 'regdrever';
  static String routePath = '/regdrever';

  @override
  State<RegdreverWidget> createState() => _RegdreverWidgetState();
}

class _RegdreverWidgetState extends State<RegdreverWidget> {
  late RegdreverModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final List<int> allowedModels = [
    for (var y = 2010; y <= DateTime.now().year; y++) y,
  ];

  int _step = 0;
  static const _totalSteps = 4; // account → location → vehicle/docs → review
  LatLng? _regLocation;
  bool _submitting = false;
  bool _showContinueBanner = false;
  bool _uploadingPhoto = false;
  bool _uploadingId = false;
  bool _uploadingCar = false;
  bool _uploadingGuide = false;
  bool _uploadingLicense = false;
  /// null | email — interstitial after account create (Registration V2).
  /// Phone OTP is not used: phone is a required form field only.
  String? _verifyPhase;
  DateTime? _birthDate;
  String _carImageUrl = '';
  String _licenseUrl = '';
  String _photoStoragePath = '';
  String _idStoragePath = '';
  String _carStoragePath = '';
  String _licenseStoragePath = '';
  String _affiliationType = 'independent';
  String _companyPath = '';
  String _companyName = '';
  bool _isTourGuide = false;
  String _guidePermitUrl = '';
  SelectedFile? _pendingPhoto;
  SelectedFile? _pendingIdDoc;
  SelectedFile? _pendingCarPhoto;
  SelectedFile? _pendingGuidePermit;
  SelectedFile? _pendingLicense;
  late TextEditingController makeController;
  late FocusNode makeFocusNode;

  late TextEditingController nameController;
  late FocusNode nameFocusNode;
  late TextEditingController idNumberController;
  late FocusNode idNumberFocusNode;
  late TextEditingController emailController;
  late FocusNode emailFocusNode;
  late TextEditingController mobileController;
  late FocusNode mobileFocusNode;
  late TextEditingController passwordController;
  late FocusNode passwordFocusNode;
  late TextEditingController confirmPasswordController;
  late FocusNode confirmPasswordFocusNode;
  late TextEditingController vehicleNameController;
  late FocusNode vehicleNameFocusNode;
  late TextEditingController modelController;
  late FocusNode modelFocusNode;
  late TextEditingController plateController;
  late FocusNode plateFocusNode;
  late TextEditingController colorController;
  late FocusNode colorFocusNode;
  late TextEditingController seatsController;
  late FocusNode seatsFocusNode;
  late TextEditingController cityController;
  late FocusNode cityFocusNode;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegdreverModel());
    nameController = TextEditingController();
    nameFocusNode = FocusNode();
    idNumberController = TextEditingController();
    idNumberFocusNode = FocusNode();
    emailController = TextEditingController();
    emailFocusNode = FocusNode();
    mobileController = TextEditingController();
    mobileFocusNode = FocusNode();
    passwordController = TextEditingController();
    passwordFocusNode = FocusNode();
    confirmPasswordController = TextEditingController();
    confirmPasswordFocusNode = FocusNode();
    vehicleNameController = TextEditingController();
    vehicleNameFocusNode = FocusNode();
    makeController = TextEditingController();
    makeFocusNode = FocusNode();
    modelController = TextEditingController();
    modelFocusNode = FocusNode();
    plateController = TextEditingController();
    plateFocusNode = FocusNode();
    colorController = TextEditingController();
    colorFocusNode = FocusNode();
    seatsController = TextEditingController(text: '4');
    seatsFocusNode = FocusNode();
    cityController = TextEditingController();
    cityFocusNode = FocusNode();
    idNumberController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _restoreDraft();
      // type_car / countries are readable without guest auth (public catalog rules).
      // Never call signInAnonymously in the driver registration flow.
      await DriverCountryService.primeRegistrationCountry(FFAppState());
      if (mounted) setState(() {});
    });
  }

  Future<void> _restoreDraft() async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final isAnon = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
    if (isAnon) {
      await FirebaseAuth.instance.signOut();
    }

    final existing = currentUserDocument;
    if (existing != null && authUid != null && !isAnon) {
      final life = DriverLifecycleState.resolveFromDocument(existing);
      if (life == DriverLifecycle.pendingApproval ||
          life == DriverLifecycle.changesRequested ||
          life == DriverLifecycle.rejected ||
          life == DriverLifecycle.suspended ||
          DriverSessionRouter.opensHomeShell(life)) {
        await DriverRegistrationDraft.clearForUid(authUid);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/');
        });
        return;
      }
    }

    // Real uid → only that user's draft. No session → guest draft only.
    final draft = await DriverRegistrationDraft.load(
      uid: (authUid != null && !isAnon) ? authUid : null,
    );
    if (draft == null || !mounted) return;
    nameController.text = draft.name;
    idNumberController.text = draft.idNumber;
    emailController.text = draft.email;
    mobileController.text = draft.mobile;
    vehicleNameController.text = draft.vehicleName;
    modelController.text = draft.model;
    plateController.text = draft.plate;
    colorController.text = draft.color;
    seatsController.text = draft.seats.isEmpty ? '4' : draft.seats;
    cityController.text = draft.cityName;
    if (draft.birthDateIso.isNotEmpty) {
      _birthDate = DateTime.tryParse(draft.birthDateIso);
    }
    if (draft.photoUrl.isNotEmpty) {
      _model.uploadedFileUrl_uploadDataLbm = draft.photoUrl;
    }
    if (draft.idImageUrl.isNotEmpty) {
      _model.uploadedFileUrl_uploadData1k33 = draft.idImageUrl;
    }
    _carImageUrl = draft.carImageUrl;
    _affiliationType =
        draft.affiliationType == 'company' ? 'company' : 'independent';
    _companyPath = draft.companyPath;
    _companyName = draft.companyName;
    _isTourGuide = draft.isTourGuide;
    _guidePermitUrl = draft.guidePermitUrl.startsWith('pending://')
        ? ''
        : draft.guidePermitUrl;
    if (draft.photoUrl.startsWith('pending://')) {
      _model.uploadedFileUrl_uploadDataLbm = '';
    }
    if (draft.idImageUrl.startsWith('pending://')) {
      _model.uploadedFileUrl_uploadData1k33 = '';
    }
    if (draft.carImageUrl.startsWith('pending://')) {
      _carImageUrl = '';
    } else if (draft.carImageUrl.isNotEmpty) {
      _carImageUrl = draft.carImageUrl;
    }
    if (draft.lat != null && draft.lng != null) {
      _regLocation = LatLng(draft.lat!, draft.lng!);
    }
    // Restore country from draft ISO before region/city so cascade stays consistent.
    if (draft.countryIso.trim().isNotEmpty) {
      try {
        final countries = await DriverCountryService.listActiveCountries();
        final iso = draft.countryIso.trim().toUpperCase();
        final match = countries.where((c) {
          final id = c.reference.id.toUpperCase();
          return id == iso ||
              id.endsWith('_$iso') ||
              id.contains(iso.toLowerCase());
        }).firstOrNull;
        if (match != null) {
          // Preserve region/city after applyCountry clears them.
          final savedRegion = DriverLocationCatalogService.refFromPath(
            draft.regionPath,
          );
          final savedVillage = DriverLocationCatalogService.refFromPath(
            draft.villagePath,
          );
          final savedRegionName = draft.regionName;
          final savedVillageName =
              draft.villageName.isNotEmpty ? draft.villageName : draft.cityName;
          await DriverCountryService.applyCountry(FFAppState(), match);
          if (savedRegion != null) {
            FFAppState().mdenh = savedRegion;
            FFAppState().naimmdenh = savedRegionName;
          }
          if (savedVillage != null) {
            FFAppState().villmndoBREV = savedVillage;
            FFAppState().textvill = savedVillageName;
          }
        }
      } catch (_) {}
    }
    final regionRef =
        DriverLocationCatalogService.refFromPath(draft.regionPath);
    final villageRef =
        DriverLocationCatalogService.refFromPath(draft.villagePath);
    if (regionRef != null && FFAppState().mdenh == null) {
      FFAppState().mdenh = regionRef;
      FFAppState().naimmdenh = draft.regionName;
    }
    if (villageRef != null && FFAppState().villmndoBREV == null) {
      FFAppState().villmndoBREV = villageRef;
      FFAppState().textvill =
          draft.villageName.isNotEmpty ? draft.villageName : draft.cityName;
      if (cityController.text.trim().isEmpty &&
          FFAppState().textvill.isNotEmpty) {
        cityController.text = FFAppState().textvill;
      }
    }
    _step = draft.step.clamp(0, _totalSteps - 1);
    _showContinueBanner = draft.hasContent || draft.step > 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_step);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_step);
        }
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveAndExit() async {
    await _persistDraft();
    if (!mounted) return;
    await DriverDialogs.showAlert(
      context,
      title: t('Success'),
      message: t('Draft saved. You can continue registration later.'),
      type: DriverMessageType.success,
    );
    if (mounted) await _leaveToLogin(persist: false);
  }

  /// AppBar back: previous step, or leave registration to Login.
  Future<void> _handleAppBarBack() async {
    if (_submitting) return;
    if (_step > 0) {
      _goTo(_step - 1);
      return;
    }
    await _leaveToLogin();
  }

  /// Leave Regdrever → Login. Persist draft, then pop or sign out + AuthGate.
  Future<void> _leaveToLogin({bool persist = true}) async {
    if (persist) {
      try {
        await _persistDraft();
      } catch (e) {
        debugPrint('Regdrever leave draft save failed: $e');
      }
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    // Embedded in AuthGate (no stack) — sign out so gate shows Login.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await authManager.signOut();
      } catch (e) {
        debugPrint('Regdrever leave signOut failed: $e');
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
    }
    if (mounted) context.go('/');
  }

  Future<void> _persistDraft() async {
    final iso = _regLocation != null
        ? (TouryCountryRegistry.isoFromCoordinates(_regLocation!) ?? '')
        : '';
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final isAnon = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
    final forUid = (authUid != null && !isAnon) ? authUid : '';
    final draft = DriverRegistrationDraft(
      step: _step,
      name: nameController.text,
      idNumber: idNumberController.text,
      email: emailController.text.trim().toLowerCase(),
      mobile: mobileController.text,
      vehicleName: vehicleNameController.text,
      model: modelController.text,
      plate: plateController.text,
      lat: _regLocation?.latitude,
      lng: _regLocation?.longitude,
      photoUrl: _model.uploadedFileUrl_uploadDataLbm,
      idImageUrl: _model.uploadedFileUrl_uploadData1k33,
      carImageUrl: _carImageUrl,
      countryIso: iso.isNotEmpty
          ? iso
          : (TouryCountryRegistry.normalizeIso(FFAppState().dolh?.id) ?? ''),
      cityName: cityController.text.trim().isNotEmpty
          ? cityController.text.trim()
          : FFAppState().textvill,
      regionPath: FFAppState().mdenh?.path ?? '',
      regionName: FFAppState().naimmdenh,
      villagePath: FFAppState().villmndoBREV?.path ?? '',
      villageName: FFAppState().textvill,
      color: colorController.text.trim(),
      seats: seatsController.text.trim(),
      birthDateIso: _birthDate?.toIso8601String() ?? '',
      uid: forUid,
      affiliationType: _affiliationType,
      companyPath: _companyPath,
      companyName: _companyName,
      isTourGuide: _isTourGuide,
      guidePermitUrl: _guidePermitUrl,
    );
    await draft.save(forUid: forUid.isEmpty ? null : forUid);
  }

  @override
  void dispose() {
    // If a stale anonymous session somehow exists, drop it — never keep it.
    final guest = FirebaseAuth.instance.currentUser;
    if (guest != null && guest.isAnonymous) {
      FirebaseAuth.instance.signOut().catchError((e) {
        debugPrint('Registration guest cleanup failed: $e');
      });
    }
    _pageController.dispose();
    nameController.dispose();
    nameFocusNode.dispose();
    idNumberController.dispose();
    idNumberFocusNode.dispose();
    emailController.dispose();
    emailFocusNode.dispose();
    mobileController.dispose();
    mobileFocusNode.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    confirmPasswordController.dispose();
    confirmPasswordFocusNode.dispose();
    vehicleNameController.dispose();
    vehicleNameFocusNode.dispose();
    makeController.dispose();
    makeFocusNode.dispose();
    modelController.dispose();
    modelFocusNode.dispose();
    plateController.dispose();
    plateFocusNode.dispose();
    colorController.dispose();
    colorFocusNode.dispose();
    seatsController.dispose();
    seatsFocusNode.dispose();
    cityController.dispose();
    cityFocusNode.dispose();
    _model.dispose();
    super.dispose();
  }

  String t(String key) => driverTr(context, key);

  String? _req(String? value, String fieldKey) {
    if (value == null || value.trim().isEmpty) {
      return driverTrNamed(context, '{field} is required', {
        'field': t(fieldKey),
      });
    }
    return null;
  }

  String? _validateEmail(String? value) {
    return DriverAuthValidationService.validateEmail(value) == null
        ? null
        : t(DriverAuthValidationService.validateEmail(value)!);
  }

  String? _validatePhone(String? value) {
    final req = _req(value, 'Mobile Number');
    if (req != null) return req;
    final isoFromGps = _regLocation == null
        ? null
        : TouryCountryRegistry.isoFromCoordinates(_regLocation!);
    final resolvedIso = isoFromGps ??
        TouryCountryRegistry.normalizeIso(FFAppState().naimdolh) ??
        'SA';
    final e164 = DriverPhoneNumberService.toE164(
      raw: value!,
      iso2: resolvedIso,
    );
    if (e164 == null) {
      final digits = DriverPhoneNumberService.digitsOnly(value);
      if (digits.length < 8 || digits.length > 15) {
        return t('Please enter a valid phone number');
      }
    }
    return null;
  }

  String? _validateIdNumber(String? value) {
    final iso = _regLocation == null
        ? ''
        : (TouryCountryRegistry.isoFromCoordinates(_regLocation!) ?? '');
    final r = DriverIdentityValidator.validate(raw: value, iso2: iso);
    return r.isValid ? null : t(r.errorKey!);
  }

  String? _validateName(String? value) {
    final r = DriverNameValidator.validate(value);
    return r.isValid ? null : t(r.errorKey!);
  }

  String? _validatePassword(String? value) {
    final key = DriverAuthValidationService.validatePassword(value);
    return key == null ? null : t(key);
  }

  String? _validateConfirmPassword(String? value) {
    final key = DriverAuthValidationService.validatePassword(
      value,
      requireConfirm: true,
      confirm: passwordController.text,
    );
    return key == null ? null : t(key);
  }

  String? _validateModel(String? value) {
    final r = DriverVehicleYearValidator.validate(value);
    return r.isValid ? null : t(r.errorKey!);
  }

  String? _validatePlate(String? value) {
    final r = DriverPlateNormalizer.validate(value);
    return r.isValid ? null : t(r.errorKey!);
  }

  Future<void> _goTo(int step) async {
    setState(() => _step = step);
    await _persistDraft();
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      final existing = FirebaseAuth.instance.currentUser;
      final isResubmit = existing != null && !existing.isAnonymous;
      final fields = <String? Function()>[
        () => _validateName(nameController.text),
        () => _validateIdNumber(idNumberController.text),
        () => _validateEmail(emailController.text),
        () => _validatePhone(mobileController.text),
        () {
          final r = DriverBirthDateValidator.validate(_birthDate);
          return r.isValid ? null : t(r.errorKey!);
        },
      ];
      if (!isResubmit) {
        fields.addAll([
          () => _validatePassword(passwordController.text),
          () => _validateConfirmPassword(confirmPasswordController.text),
        ]);
      }
      for (final v in fields) {
        final err = v();
        if (err != null) {
          await DriverDialogs.showAlert(
            context,
            title: t('Error'),
            message: err,
            type: DriverMessageType.warning,
          );
          return;
        }
      }
      // Create email Auth before location so countries/cities/villages
      // catalog queries are allowed (rules require request.auth).
      final ready = await _ensureEmailAccountBeforeLocation();
      if (!ready || !mounted) return;
      await _enterVerificationGatesThenLocation();
      return;
    }
    if (_step == 1) {
      final loc = DriverLocationValidator.validate(
        hasUsableGps: TouryMapsConfig.isUsableCoordinate(_regLocation),
        hasCountry: FFAppState().dolh != null,
        hasRegion: FFAppState().mdenh != null,
        hasCity: FFAppState().villmndoBREV != null,
      );
      if (!loc.isValid) {
        await DriverDialogs.showAlert(
          context,
          title: t('Location'),
          message: t(loc.errorKey!),
          type: DriverMessageType.warning,
        );
        return;
      }
      await _goTo(2);
      return;
    }
    if (_step == 2) {
      final vehicle = DriverVehicleValidator.validate(
        name: vehicleNameController.text,
        year: modelController.text,
        plate: plateController.text,
        seats: seatsController.text,
        color: colorController.text,
        hasType: FFAppState().textTypeCar.isNotEmpty &&
            FFAppState().MNDOBTYPECARrev != null,
      );
      if (!vehicle.isValid) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(vehicle.errorKey!),
          type: DriverMessageType.warning,
        );
        return;
      }
      if (_affiliationType == 'company' && _companyPath.trim().isEmpty) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t('Please select a transport company'),
          type: DriverMessageType.warning,
        );
        return;
      }
      if (!_hasRequiredDocumentUploads()) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(
            'Please upload all required documents before continuing',
          ),
          type: DriverMessageType.warning,
        );
        return;
      }
      if (_isTourGuide &&
          !_isUploadReady(url: _guidePermitUrl, pending: _pendingGuidePermit)) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t('Tour guide permit is required'),
          type: DriverMessageType.warning,
        );
        return;
      }
      await _goTo(3);
      return;
    }
    await _registerDriver();
  }

  /// Registration V2: email verify → personal/location steps (phone is a required field, no OTP).
  Future<void> _enterVerificationGatesThenLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed == null) return;

    if (refreshed.emailVerified != true) {
      if (mounted) setState(() => _verifyPhase = 'email');
      return;
    }
    if (mounted) setState(() => _verifyPhase = null);
    await _goTo(1);
  }

  Future<void> _onEmailVerifiedContinue() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
      return;
    }
    if (mounted) setState(() => _verifyPhase = null);
    await _goTo(1);
  }

  bool _isUploadReady({required String url, SelectedFile? pending}) {
    if (pending != null && pending.bytes.isNotEmpty) return true;
    final trimmed = url.trim();
    if (trimmed.startsWith('pending://')) return false;
    return trimmed.startsWith('https://');
  }

  bool _hasRequiredDocumentUploads() {
    return _isUploadReady(
          url: _model.uploadedFileUrl_uploadDataLbm,
          pending: _pendingPhoto,
        ) &&
        _isUploadReady(
          url: _model.uploadedFileUrl_uploadData1k33,
          pending: _pendingIdDoc,
        ) &&
        _isUploadReady(url: _carImageUrl, pending: _pendingCarPhoto) &&
        _isUploadReady(url: _licenseUrl, pending: _pendingLicense);
  }

  /// Email/password Auth must exist before location step (Firestore catalog).
  Future<bool> _ensureEmailAccountBeforeLocation() async {
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null && !existing.isAnonymous) {
      DriverCountryService.clearCache();
      await DriverCountryService.primeRegistrationCountry(FFAppState());
      return true;
    }

    setState(() => _submitting = true);
    try {
      GoRouter.of(context).prepareAuthEvent();
      if (existing != null && existing.isAnonymous) {
        await FirebaseAuth.instance.signOut();
      }
      if (!mounted) return false;
      final user = await authManager.createAccountWithEmail(
        context,
        emailController.text.trim(),
        passwordController.text,
        ensureUserDoc: false,
      );
      if (user == null || user.uid == null || user.uid!.isEmpty) {
        if (mounted) {
          await DriverDialogs.showAlert(
            context,
            title: t('Error'),
            message: t('Failed to create account. Please try again.'),
            type: DriverMessageType.error,
          );
        }
        return false;
      }
      await DriverRegistrationDraft.migrateGuestToUid(user.uid!);
      DriverCountryService.clearCache();
      await DriverCountryService.primeRegistrationCountry(FFAppState());
      if (mounted) setState(() {});
      return true;
    } on FirebaseAuthException catch (e) {
      DriverAuthErrors.logSafely(e);
      if (mounted) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: DriverAuthErrors.localized(context, e),
          type: DriverMessageType.error,
        );
      }
      return false;
    } catch (e) {
      DriverAuthErrors.logSafely(e);
      if (mounted) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t('Failed to create account. Please try again.'),
          type: DriverMessageType.error,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _registerDriver() async {
    final missing = DriverRegistrationCompletenessValidator.missingKeys(
      name: nameController.text,
      email: emailController.text,
      phone: mobileController.text,
      idNumber: idNumberController.text,
      vehicleName: vehicleNameController.text,
      modelYear: modelController.text,
      plate: plateController.text,
      hasVehicleType: FFAppState().MNDOBTYPECARrev != null &&
          FFAppState().textTypeCar.isNotEmpty,
      hasCountry: FFAppState().dolh != null,
      hasLocation: TouryMapsConfig.isUsableCoordinate(_regLocation),
      hasRegion: FFAppState().mdenh != null,
      hasCity: FFAppState().villmndoBREV != null,
      photoUrl: _model.uploadedFileUrl_uploadDataLbm,
      idImageUrl: _model.uploadedFileUrl_uploadData1k33,
      birthDate: _birthDate,
      seats: DriverSeatCountValidator.parse(seatsController.text),
      color: colorController.text,
      phoneIso2: TouryCountryRegistry.normalizeIso(FFAppState().dolh?.id) ??
          (_regLocation != null
              ? TouryCountryRegistry.isoFromCoordinates(_regLocation!)
              : null),
    );
    if (missing.isNotEmpty) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message:
            '${t('Please complete missing fields')}: ${missing.map(t).join(', ')}',
        type: DriverMessageType.warning,
      );
      return;
    }
    if (_affiliationType == 'company' && _companyPath.trim().isEmpty) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t('Please select a transport company'),
        type: DriverMessageType.warning,
      );
      return;
    }
    if (!_hasRequiredDocumentUploads() ||
        (_isTourGuide &&
            !_isUploadReady(
              url: _guidePermitUrl,
              pending: _pendingGuidePermit,
            ))) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t(
          'Please upload all required documents before continuing',
        ),
        type: DriverMessageType.warning,
      );
      return;
    }
    if (_uploadingPhoto ||
        _uploadingId ||
        _uploadingCar ||
        _uploadingGuide) {
      await DriverDialogs.showAlert(
        context,
        title: t('Please wait'),
        message: t('Document upload is still in progress'),
        type: DriverMessageType.warning,
      );
      return;
    }

    final emailOk =
        await DriverEmailVerificationService.reloadAndCheckVerified();
    if (!emailOk) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t('Please verify your email before submitting'),
        type: DriverMessageType.warning,
      );
      if (mounted) setState(() => _verifyPhase = 'email');
      return;
    }

    setState(() => _submitting = true);
    try {
      GoRouter.of(context).prepareAuthEvent();

      final existingAuth = FirebaseAuth.instance.currentUser;
      final isResubmit = existingAuth != null && !existingAuth.isAnonymous;

      String uid;
      if (isResubmit) {
        uid = existingAuth.uid;
        await _flushPendingUploads(uid);
      } else {
        // Drop guest session so email signup creates a real account cleanly.
        if (existingAuth != null && existingAuth.isAnonymous) {
          await FirebaseAuth.instance.signOut();
        }
        if (!mounted) return;
        final user = await authManager.createAccountWithEmail(
          context,
          emailController.text.trim(),
          passwordController.text,
          ensureUserDoc: false,
        );
        if (!mounted) return;
        if (user == null || user.uid == null || user.uid!.isEmpty) {
          await DriverDialogs.showAlert(
            context,
            title: t('Error'),
            message: t('Failed to create account. Please try again.'),
            type: DriverMessageType.error,
          );
          return;
        }
        uid = user.uid!;

        await DriverRegistrationDraft.migrateGuestToUid(uid);
        await _flushPendingUploads(uid);
      }

      // Never persist pending:// placeholders to Firestore.
      if (!_hasRequiredDocumentUploads() ||
          (_isTourGuide &&
              !_isUploadReady(
                url: _guidePermitUrl,
                pending: _pendingGuidePermit,
              )) ||
          _model.uploadedFileUrl_uploadDataLbm.startsWith('pending://') ||
          _model.uploadedFileUrl_uploadData1k33.startsWith('pending://') ||
          _carImageUrl.startsWith('pending://') ||
          _guidePermitUrl.startsWith('pending://')) {
        if (!mounted) return;
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(
            'Document upload is incomplete. Please re-upload and try again.',
          ),
          type: DriverMessageType.error,
        );
        return;
      }

      final iso = TouryCountryRegistry.isoFromCoordinates(_regLocation!);
      if (iso != null) {
        final countries = await DriverCountryService.listActiveCountries();
        final match = countries
            .where((c) => DriverCountryService.isoOfCountry(c) == iso)
            .firstOrNull;
        // Do not re-apply the same country at submit time: applyCountry
        // intentionally clears the selected region/city and would make a
        // valid review fail with "Region is required".
        if (match != null &&
            FFAppState().dolh?.path != match.reference.path) {
          await DriverCountryService.applyCountry(FFAppState(), match);
        }
      }

      final locationLabel =
          '${_regLocation!.latitude.toStringAsFixed(5)}, ${_regLocation!.longitude.toStringAsFixed(5)}';

      final countryRef = FFAppState().dolh;
      if (countryRef == null) {
        if (!mounted) return;
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(
            'Country could not be detected from GPS. Enable location and try again.',
          ),
          type: DriverMessageType.error,
        );
        return;
      }

      final phoneIso =
          iso ?? TouryCountryRegistry.normalizeIso(FFAppState().dolh?.id);
      if (phoneIso == null || phoneIso.isEmpty) {
        if (!mounted) return;
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t('Please select a country'),
          type: DriverMessageType.error,
        );
        return;
      }
      final phoneE164 = DriverPhoneNumberService.toE164(
            raw: mobileController.text,
            iso2: phoneIso,
          ) ??
          mobileController.text.trim();

      final reviewModel = DriverRegistrationReviewModel(
        uid: uid,
        displayName: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        phoneE164: phoneE164,
        idNumber: idNumberController.text.trim(),
        birthDate: _birthDate,
        countryRef: countryRef,
        regionRef: FFAppState().mdenh,
        villageRef: FFAppState().villmndoBREV,
        regionName: FFAppState().naimmdenh,
        villageName: FFAppState().textvill,
        vehicleTypeRef: FFAppState().MNDOBTYPECARrev,
        vehicleTypeText: FFAppState().textTypeCar,
        vehicleName: vehicleNameController.text.trim(),
        modelYear: modelController.text.trim(),
        plate: plateController.text.trim(),
        color: colorController.text.trim(),
        seats: DriverSeatCountValidator.parse(seatsController.text),
        photoUrl: _model.uploadedFileUrl_uploadDataLbm,
        idImageUrl: _model.uploadedFileUrl_uploadData1k33,
        carImageUrl: _carImageUrl,
        location: _regLocation,
        isResubmit: isResubmit,
        uploadInFlight: _uploadingPhoto ||
            _uploadingId ||
            _uploadingCar ||
            _uploadingGuide,
        affiliationType: _affiliationType,
        companyPath: _companyPath,
        companyName: _companyName,
        isTourGuide: _isTourGuide,
        guidePermitUrl: _guidePermitUrl,
      );

      final profileFields = {
        ...createUserRecordData(
          phoneN: int.tryParse(
            DriverPhoneNumberService.digitsOnly(phoneE164),
          ),
          // ismndob is claimed after create (rules forbid it on create).
          displayName: reviewModel.displayName,
          actevMndob: false,
          ngl: false,
          phoneNumber: phoneE164,
          photoUrl: reviewModel.photoUrl,
          email: reviewModel.email,
          mdenhAml: FFAppState().textTypeCar,
          mndobVill: FFAppState().villmndoBREV,
          createdTime: isResubmit ? null : getCurrentTimestamp,
          carRevMndob: FFAppState().MNDOBTYPECARrev,
          mndobVillText: FFAppState().textvill.isNotEmpty
              ? FFAppState().textvill
              : locationLabel,
          numberLohhCar: DriverPlateNormalizer.normalize(plateController.text),
          imgIdRksh: reviewModel.idImageUrl,
          imgIdCar: _carImageUrl.isEmpty ? null : _carImageUrl,
          driverId: '',
          iDHoyhMNDOB: reviewModel.idNumber,
          mndobTypeCar: FFAppState().MNDOBTYPECARrev,
          ismndom: true,
          mndonNewacc: false,
          textTypeCarMndob: FFAppState().textTypeCar,
          nameCar: reviewModel.vehicleName,
          modelCar: reviewModel.modelYear,
          loceshnMndobNow: _regLocation,
          revDolh: countryRef,
          uid: uid,
          registrationStatus: 'draft',
          rejectionReason: '',
        ),
        'registration_flow_version': 2,
        'vehicle_make': makeController.text.trim(),
        'vehicle_color': colorController.text.trim(),
        'seat_count': DriverSeatCountValidator.parse(seatsController.text),
        'birth_date': _birthDate == null
            ? null
            : Timestamp.fromDate(
                DateTime(
                  _birthDate!.year,
                  _birthDate!.month,
                  _birthDate!.day,
                ),
              ),
        'normalized_plate':
            DriverPlateNormalizer.normalize(plateController.text),
        'doc_national_id': {
          'documentType': 'national_id',
          if (_idStoragePath.isEmpty && reviewModel.idImageUrl.isNotEmpty)
            'url': reviewModel.idImageUrl,
          'storagePath': _idStoragePath,
          'uploadedAt': FieldValue.serverTimestamp(),
          'status': 'uploaded',
        },
        'doc_vehicle_registration': {
          'documentType': 'vehicle_registration',
          if (_carStoragePath.isEmpty && _carImageUrl.isNotEmpty)
            'url': _carImageUrl,
          'storagePath': _carStoragePath,
          'uploadedAt': FieldValue.serverTimestamp(),
          'status': 'uploaded',
        },
        'doc_driver_license': {
          'documentType': 'driver_license',
          if (_licenseStoragePath.isEmpty && _licenseUrl.isNotEmpty)
            'url': _licenseUrl,
          'storagePath': _licenseStoragePath,
          'uploadedAt': FieldValue.serverTimestamp(),
          'status': 'uploaded',
        },
        if (_photoStoragePath.isNotEmpty) 'photo_storage_path': _photoStoragePath,
        if (cityController.text.trim().isNotEmpty)
          'city_display': cityController.text.trim()
        else if (FFAppState().textvill.isNotEmpty)
          'city_display': FFAppState().textvill,
        if (FFAppState().mdenh != null) 'region_ref': FFAppState().mdenh,
        if (FFAppState().naimmdenh.isNotEmpty)
          'region_display': FFAppState().naimmdenh,
        if (reviewModel.affiliationType == 'company' &&
            reviewModel.companyPath.trim().isNotEmpty) ...{
          'transport_company':
              FirebaseFirestore.instance.doc(reviewModel.companyPath.trim()),
          'transport_company_text': reviewModel.companyName.trim(),
        },
      };

      final submit = await DriverRegistrationSubmissionService.submit(
        model: reviewModel,
        profileFields: profileFields,
      );
      if (!submit.success) {
        if (!mounted) return;
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(submit.errorKey ??
              'Could not complete registration. Please try again.'),
          type: DriverMessageType.error,
        );
        return;
      }

      await DriverRegistrationDraft.clear();
      await DriverRegistrationDraft.clearForUid(uid);
      await DriverRegistrationDraft.clearGuest();

      try {
        currentUserDocument =
            await UserRecord.getDocumentOnce(UserRecord.collection.doc(uid));
      } catch (e) {
        debugPrint('Post-registration profile reload failed: $e');
      }

      if (!mounted) return;
      await DriverDialogs.showAlert(
        context,
        title: t('Success'),
        message: t(
          'Registration submitted. Your account is pending admin review.',
        ),
        type: DriverMessageType.success,
      );

      try {
        await WhatCall.call(
          to: phoneE164,
          msg: '''${t('Registration submitted. Your account is pending admin review.')}
${t('Email')}: ${emailController.text.trim().toLowerCase()}
''',
        );
      } catch (e) {
        debugPrint('Registration WhatsApp notify failed: $e');
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      DriverAuthErrors.logSafely(e);
      if (mounted) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: DriverAuthErrors.localized(context, e),
          type: DriverMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickVehicleType() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.dsColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: ListTypeCarWidget(idNumber: idNumberController.text),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
      await _persistDraft();
    }
  }

  Future<void> _uploadDoc({required String kind}) async {
    if (_uploadingPhoto ||
        _uploadingId ||
        _uploadingCar ||
        _uploadingGuide ||
        _uploadingLicense) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isRealUser = uid != null &&
        uid.isNotEmpty &&
        !(FirebaseAuth.instance.currentUser?.isAnonymous ?? true);
    setState(() {
      if (kind == 'photo') _uploadingPhoto = true;
      if (kind == 'id') _uploadingId = true;
      if (kind == 'car') _uploadingCar = true;
      if (kind == 'guide') _uploadingGuide = true;
      if (kind == 'license') _uploadingLicense = true;
    });
    try {
      final selectedMedia = await selectMediaWithSourceBottomSheet(
        context: context,
        allowPhoto: true,
        // Keep picker output inside the authenticated user's Storage root.
        storageFolderPath: isRealUser
            ? DriverDocumentUploadService.storageRootForUid(uid)
            : null,
      );
      if (selectedMedia == null || selectedMedia.isEmpty) {
        // User cancelled picker — no error dialog.
        return;
      }
      if (!mounted) return;
      final file = selectedMedia.first;
      if (!validateFileFormat(file.storagePath, context)) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t('Invalid file format'),
          type: DriverMessageType.warning,
        );
        return;
      }
      final mimeGuess = file.storagePath.toLowerCase().endsWith('.png')
          ? 'image/png'
          : file.storagePath.toLowerCase().endsWith('.webp')
              ? 'image/webp'
              : file.storagePath.toLowerCase().endsWith('.pdf')
                  ? 'application/pdf'
                  : 'image/jpeg';
      final mime = DriverDocumentValidator.validateMime(mimeGuess);
      if (!mime.isValid) {
        if (!mounted) return;
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(mime.errorKey!),
          type: DriverMessageType.warning,
        );
        return;
      }
      final size = DriverDocumentValidator.validateSize(file.bytes.length);
      if (!size.isValid) {
        if (!mounted) return;
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(size.errorKey!),
          type: DriverMessageType.warning,
        );
        return;
      }

      if (isRealUser) {
        final result = await DriverDocumentUploadService.uploadSelectedFile(
          selected: file,
          uid: uid,
        );
        if (!mounted) return;
        if (result == null || result.storagePath.isEmpty) {
          await DriverDialogs.showAlert(
            context,
            title: t('Error'),
            message: t('Could not upload the file. Please try again.'),
            type: DriverMessageType.error,
          );
          return;
        }
        setState(() {
          if (kind == 'photo') {
            _model.uploadedFileUrl_uploadDataLbm = result.previewUrl ?? '';
            _photoStoragePath = result.storagePath;
            _pendingPhoto = null;
          } else if (kind == 'id') {
            _model.uploadedFileUrl_uploadData1k33 = result.previewUrl ?? '';
            _idStoragePath = result.storagePath;
            _pendingIdDoc = null;
          } else if (kind == 'guide') {
            _guidePermitUrl = result.previewUrl ?? '';
            _pendingGuidePermit = null;
          } else if (kind == 'license') {
            _licenseUrl = result.previewUrl ?? '';
            _licenseStoragePath = result.storagePath;
            _pendingLicense = null;
          } else {
            _carImageUrl = result.previewUrl ?? '';
            _carStoragePath = result.storagePath;
            _pendingCarPhoto = null;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t('Document uploaded successfully'),
                style: const TextStyle(fontFamily: 'cairo'),
              ),
            ),
          );
        }
      } else {
        // Defer Storage upload until Auth uid exists (submit).
        setState(() {
          if (kind == 'photo') {
            _pendingPhoto = file;
            _model.uploadedFileUrl_uploadDataLbm = 'pending://photo';
          } else if (kind == 'id') {
            _pendingIdDoc = file;
            _model.uploadedFileUrl_uploadData1k33 = 'pending://id';
          } else if (kind == 'guide') {
            _pendingGuidePermit = file;
            _guidePermitUrl = 'pending://guide';
          } else if (kind == 'license') {
            _pendingLicense = file;
            _licenseUrl = 'pending://license';
          } else {
            _pendingCarPhoto = file;
            _carImageUrl = 'pending://car';
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t('Document selected. It will upload when you submit.'),
                style: const TextStyle(fontFamily: 'cairo'),
              ),
            ),
          );
        }
      }
      await _persistDraft();
    } catch (e) {
      DriverAuthErrors.logSafely(e);
      if (mounted) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: e is StateError
              ? t(e.message)
              : t('Could not upload the file. Please try again.'),
          type: DriverMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
          _uploadingId = false;
          _uploadingCar = false;
          _uploadingGuide = false;
          _uploadingLicense = false;
        });
      }
    }
  }

  Future<void> _flushPendingUploads(String uid) async {
    Future<String> up(SelectedFile f) async {
      final name = f.storagePath.split('/').last;
      final path =
          '${DriverDocumentUploadService.storageRootForUid(uid)}/$name';
      await uploadBytes(path, f.bytes);
      return path;
    }

    Future<void> flushOne({
      required SelectedFile? pending,
      required String currentUrl,
      required void Function(String previewUrl, String storagePath) assign,
      required void Function() clearPending,
    }) async {
      if (pending != null) {
        final storagePath = await up(pending);
        assign('', storagePath);
        clearPending();
        return;
      }
      if (currentUrl.startsWith('pending://')) {
        throw StateError(
          'Document upload is incomplete. Please re-upload and try again.',
        );
      }
    }

    await flushOne(
      pending: _pendingPhoto,
      currentUrl: _model.uploadedFileUrl_uploadDataLbm,
      assign: (url, path) {
        _model.uploadedFileUrl_uploadDataLbm = url;
        _photoStoragePath = path;
      },
      clearPending: () => _pendingPhoto = null,
    );
    await flushOne(
      pending: _pendingIdDoc,
      currentUrl: _model.uploadedFileUrl_uploadData1k33,
      assign: (url, path) {
        _model.uploadedFileUrl_uploadData1k33 = url;
        _idStoragePath = path;
      },
      clearPending: () => _pendingIdDoc = null,
    );
    await flushOne(
      pending: _pendingCarPhoto,
      currentUrl: _carImageUrl,
      assign: (url, path) {
        _carImageUrl = url;
        _carStoragePath = path;
      },
      clearPending: () => _pendingCarPhoto = null,
    );
    await flushOne(
      pending: _pendingLicense,
      currentUrl: _licenseUrl,
      assign: (url, path) {
        _licenseUrl = url;
        _licenseStoragePath = path;
      },
      clearPending: () => _pendingLicense = null,
    );
    if (_isTourGuide ||
        _pendingGuidePermit != null ||
        _guidePermitUrl.isNotEmpty) {
      await flushOne(
        pending: _pendingGuidePermit,
        currentUrl: _guidePermitUrl,
        assign: (url, path) => _guidePermitUrl = url.isNotEmpty ? url : path,
        clearPending: () => _pendingGuidePermit = null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return DsScreenScaffold(
            scaffoldKey: scaffoldKey,
            appBar: DsAppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: t('New Driver Registration'),
              leading: DsIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: t('Back'),
                onPressed: _submitting ? null : _handleAppBarBack,
              ),
              actions: [
                TextButton(
                  onPressed: _submitting ? null : _saveAndExit,
                  child: Text(
                    t('Save and exit'),
                    style: typography.labelLarge.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: DriverFormWidth(
                child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_showContinueBanner)
                      DsInformationCard(
                        title: t('Continue registration'),
                        message: t('Your draft was restored at the last saved step.'),
                        tone: DsInfoTone.info,
                      ),
                if (_verifyPhase == 'email')
                  Expanded(
                    child: DriverEmailVerifyPanel(
                      email: emailController.text.trim(),
                      t: t,
                      onVerified: () {
                        unawaited(_onEmailVerifiedContinue());
                      },
                    ),
                  )
                else ...[
                _StepHeader(step: _step, total: _totalSteps, t: t),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _AccountStep(
                        t: t,
                        nameController: nameController,
                        nameFocusNode: nameFocusNode,
                        idNumberController: idNumberController,
                        idNumberFocusNode: idNumberFocusNode,
                        emailController: emailController,
                        emailFocusNode: emailFocusNode,
                        mobileController: mobileController,
                        mobileFocusNode: mobileFocusNode,
                        passwordController: passwordController,
                        passwordFocusNode: passwordFocusNode,
                        confirmPasswordController: confirmPasswordController,
                        confirmPasswordFocusNode: confirmPasswordFocusNode,
                        birthDate: _birthDate,
                        onPickBirthDate: _pickBirthDate,
                        validateName: _validateName,
                        validateEmail: _validateEmail,
                        validatePhone: _validatePhone,
                        validateId: _validateIdNumber,
                        validatePassword: _validatePassword,
                        validateConfirm: _validateConfirmPassword,
                        req: _req,
                      ),
                      _LocationStep(
                        t: t,
                        location: _regLocation,
                        cityController: cityController,
                        cityFocusNode: cityFocusNode,
                        onCityChanged: (v) {
                          setState(() => cityController.text = v);
                          _persistDraft();
                        },
                        onCascadeChanged: () {
                          if (FFAppState().textvill.isNotEmpty) {
                            cityController.text = FFAppState().textvill;
                          }
                          _persistDraft();
                          if (mounted) setState(() {});
                        },
                        onLocationChanged: (loc) async {
                          final prevIso = _regLocation == null
                              ? null
                              : TouryCountryRegistry.isoFromCoordinates(
                                  _regLocation!,
                                );
                          setState(() {
                            _regLocation = loc;
                            final iso =
                                TouryCountryRegistry.isoFromCoordinates(loc);
                            if (iso != null && iso != prevIso) {
                              cityController.text = '';
                              FFAppState().mdenh = null;
                              FFAppState().naimmdenh = '';
                              FFAppState().villmndoBREV = null;
                              FFAppState().textvill = '';
                            }
                          });
                          final iso =
                              TouryCountryRegistry.isoFromCoordinates(loc);
                          if (iso == null || iso == prevIso) return;
                          final countries =
                              await DriverCountryService.listActiveCountries();
                          final match = countries
                              .where(
                                (c) =>
                                    DriverCountryService.isoOfCountry(c) == iso,
                              )
                              .firstOrNull;
                          if (match != null) {
                            await DriverCountryService.applyCountry(
                              FFAppState(),
                              match,
                            );
                            FFAppState().textTypeCar = '';
                            FFAppState().MNDOBTYPECARrev = null;
                            FFAppState().mdenh = null;
                            FFAppState().naimmdenh = '';
                            FFAppState().villmndoBREV = null;
                            FFAppState().textvill = '';
                            _companyPath = '';
                            _companyName = '';
                            if (mounted) setState(() {});
                          }
                        },
                      ),
                      _VehicleStep(
                        t: t,
                        vehicleNameController: vehicleNameController,
                        vehicleNameFocusNode: vehicleNameFocusNode,
                        makeController: makeController,
                        makeFocusNode: makeFocusNode,
                        modelController: modelController,
                        modelFocusNode: modelFocusNode,
                        plateController: plateController,
                        plateFocusNode: plateFocusNode,
                        colorController: colorController,
                        colorFocusNode: colorFocusNode,
                        seatsController: seatsController,
                        seatsFocusNode: seatsFocusNode,
                        selectedType: FFAppState().textTypeCar,
                        photoUrl: _model.uploadedFileUrl_uploadDataLbm,
                        idUrl: _model.uploadedFileUrl_uploadData1k33,
                        carUrl: _carImageUrl,
                        licenseUrl: _licenseUrl,
                        uploadingPhoto: _uploadingPhoto,
                        uploadingId: _uploadingId,
                        uploadingCar: _uploadingCar,
                        uploadingLicense: _uploadingLicense,
                        onPickType: _pickVehicleType,
                        onUploadPhoto: () => _uploadDoc(kind: 'photo'),
                        onUploadId: () => _uploadDoc(kind: 'id'),
                        onUploadCar: () => _uploadDoc(kind: 'car'),
                        onUploadLicense: () => _uploadDoc(kind: 'license'),
                        validateModel: _validateModel,
                        validatePlate: _validatePlate,
                        req: _req,
                        affiliationType: _affiliationType,
                        companyPath: _companyPath,
                        companyName: _companyName,
                        isTourGuide: _isTourGuide,
                        guidePermitUrl: _guidePermitUrl,
                        uploadingGuide: _uploadingGuide,
                        onAffiliationChanged: (type) {
                          setState(() {
                            _affiliationType = type;
                            if (type != 'company') {
                              _companyPath = '';
                              _companyName = '';
                            }
                          });
                          _persistDraft();
                        },
                        onCompanySelected: (path, name) {
                          setState(() {
                            _companyPath = path;
                            _companyName = name;
                          });
                          _persistDraft();
                        },
                        countryRef: FFAppState().dolh,
                        onTourGuideChanged: (value) {
                          setState(() {
                            _isTourGuide = value;
                            if (!value) {
                              _guidePermitUrl = '';
                              _pendingGuidePermit = null;
                            }
                          });
                          _persistDraft();
                        },
                        onUploadGuidePermit: () => _uploadDoc(kind: 'guide'),
                      ),
                      _ReviewStep(
                        t: t,
                        name: nameController.text,
                        email: emailController.text,
                        phone: mobileController.text,
                        idNumber: idNumberController.text,
                        birthDate: _birthDate,
                        country: FFAppState().naimdolh,
                        region: FFAppState().naimmdenh,
                        city: FFAppState().textvill.isNotEmpty
                            ? FFAppState().textvill
                            : (cityController.text.trim().isEmpty
                                ? FFAppState().naimmdenh
                                : cityController.text.trim()),
                        vehicleType: FFAppState().textTypeCar,
                        vehicleName: vehicleNameController.text,
                        year: modelController.text,
                        plate: plateController.text,
                        color: colorController.text,
                        seats: seatsController.text,
                        emailVerified:
                            FirebaseAuth.instance.currentUser?.emailVerified ==
                                true,
                        phonePresent: mobileController.text.trim().isNotEmpty,
                        photoOk:
                            _model.uploadedFileUrl_uploadDataLbm.isNotEmpty ||
                                _pendingPhoto != null,
                        nationalIdOk:
                            _model.uploadedFileUrl_uploadData1k33.isNotEmpty ||
                                _pendingIdDoc != null,
                        vehicleRegOk: _isUploadReady(
                          url: _carImageUrl,
                          pending: _pendingCarPhoto,
                        ),
                        licenseOk: _isUploadReady(
                          url: _licenseUrl,
                          pending: _pendingLicense,
                        ),
                        affiliationType: _affiliationType,
                        companyName: _companyName,
                        isTourGuide: _isTourGuide,
                        guidePermitOk: _guidePermitUrl.isNotEmpty ||
                            _pendingGuidePermit != null,
                        onEditAccount: () => _goTo(0),
                        onEditLocation: () => _goTo(1),
                        onEditVehicle: () => _goTo(2),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.sm,
                    DsSpacing.md,
                    DsSpacing.md,
                  ),
                  child: Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: DsButton.outlined(
                            label: t('Back'),
                            expanded: true,
                            enabled: !_submitting,
                            onPressed: () => _goTo(_step - 1),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: DsButton.primary(
                          label: _step == _totalSteps - 1
                              ? t('Submit Application')
                              : t('Next'),
                          expanded: true,
                          loading: _submitting,
                          onPressed: _next,
                        ),
                      ),
                    ],
                  ),
                ),
                ], // end else (!verifyPhase)
              ],
            ),
          ),
          ),
        ),
          );
        },
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.total,
    required this.t,
  });

  final int step;
  final int total;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final labels = [
      t('Account'),
      t('Location'),
      t('Vehicle'),
      t('Review'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [context.dsColors.primary.withValues(alpha: 0.18), context.dsColors.primaryStrong.withValues(alpha: 0.10)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            driverTrNamed(context, 'Step {current} of {total}', {
              'current': '${step + 1}',
              'total': '$total',
            }),
            style: TextStyle(
              fontFamily: 'cairo',
              color: context.dsColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(total, (i) {
              final active = i <= step;
              return Expanded(
                child: Container(
                  margin:
                      EdgeInsetsDirectional.only(end: i == total - 1 ? 0 : 6),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? context.dsColors.primaryStrong : context.dsColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            labels[step],
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: context.dsColors.primaryStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontFamily: 'cairo'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: context.dsColors.primaryStrong),
        filled: true,
        fillColor: context.dsColors.card,
        border: OutlineInputBorder(
          borderRadius: DsRadius.medium,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: context.dsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: context.dsColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.t,
    required this.nameController,
    required this.nameFocusNode,
    required this.idNumberController,
    required this.idNumberFocusNode,
    required this.emailController,
    required this.emailFocusNode,
    required this.mobileController,
    required this.mobileFocusNode,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.confirmPasswordController,
    required this.confirmPasswordFocusNode,
    required this.birthDate,
    required this.onPickBirthDate,
    required this.validateName,
    required this.validateEmail,
    required this.validatePhone,
    required this.validateId,
    required this.validatePassword,
    required this.validateConfirm,
    required this.req,
  });

  final String Function(String) t;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final TextEditingController idNumberController;
  final FocusNode idNumberFocusNode;
  final TextEditingController emailController;
  final FocusNode emailFocusNode;
  final TextEditingController mobileController;
  final FocusNode mobileFocusNode;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final TextEditingController confirmPasswordController;
  final FocusNode confirmPasswordFocusNode;
  final DateTime? birthDate;
  final VoidCallback onPickBirthDate;
  final String? Function(String?) validateName;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePhone;
  final String? Function(String?) validateId;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirm;
  final String? Function(String?, String) req;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t('Personal Information'),
            style: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 12),
        _Field(
            controller: nameController,
            focusNode: nameFocusNode,
            label: t('Full Name'),
            icon: Icons.person_outline,
            validator: validateName),
        const SizedBox(height: 12),
        _Field(
            controller: idNumberController,
            focusNode: idNumberFocusNode,
            label: t('ID Number'),
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.text,
            validator: validateId),
        const SizedBox(height: 12),
        InkWell(
          onTap: onPickBirthDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: t('Birth date'),
              prefixIcon:
                  Icon(Icons.cake_outlined, color: context.dsColors.primaryStrong),
              filled: true,
              fillColor: context.dsColors.card,
              border:
                  OutlineInputBorder(borderRadius: DsRadius.medium),
            ),
            child: Text(
              birthDate == null
                  ? t('Select birth date')
                  : '${birthDate!.year.toString().padLeft(4, '0')}-'
                      '${birthDate!.month.toString().padLeft(2, '0')}-'
                      '${birthDate!.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontFamily: 'cairo'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Field(
            controller: emailController,
            focusNode: emailFocusNode,
            label: t('Email Address'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail),
        const SizedBox(height: 12),
        _Field(
            controller: mobileController,
            focusNode: mobileFocusNode,
            label: '${t('Mobile Number')} *',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: '+996 / +966 / +7 / +998',
            validator: validatePhone),
        const SizedBox(height: 12),
        _Field(
            controller: passwordController,
            focusNode: passwordFocusNode,
            label: t('Password'),
            icon: Icons.lock_outline,
            obscureText: true,
            validator: validatePassword),
        const SizedBox(height: 12),
        _Field(
            controller: confirmPasswordController,
            focusNode: confirmPasswordFocusNode,
            label: t('Confirm Password'),
            icon: Icons.lock_outline,
            obscureText: true,
            validator: validateConfirm),
      ],
    );
  }
}

Widget _affiliationChoiceChip({
  required BuildContext context,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: DsRadius.medium,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? context.dsColors.primary.withValues(alpha: 0.12)
              : context.dsColors.card,
          borderRadius: DsRadius.medium,
          border: Border.all(
            color: selected ? context.dsColors.primary : context.dsColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.w700,
            color: selected ? context.dsColors.primaryStrong : context.dsColors.textPrimary,
          ),
        ),
      ),
    ),
  );
}

class _TransportCompanyDropdown extends StatefulWidget {
  const _TransportCompanyDropdown({
    required this.t,
    required this.selectedPath,
    required this.selectedName,
    required this.onSelected,
    this.countryRef,
  });

  final String Function(String) t;
  final String selectedPath;
  final String selectedName;
  final void Function(String path, String name) onSelected;
  final DocumentReference? countryRef;

  @override
  State<_TransportCompanyDropdown> createState() =>
      _TransportCompanyDropdownState();
}

class _TransportCompanyDropdownState extends State<_TransportCompanyDropdown> {
  late Future<List<_CompanyOption>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCompanies();
  }

  @override
  void didUpdateWidget(covariant _TransportCompanyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryRef?.path != widget.countryRef?.path) {
      _future = _loadCompanies();
    }
  }

  static String _companyDisplayName(Map<String, dynamic> data, String id) {
    final naim = (data['naim'] as String?)?.trim() ?? '';
    if (naim.isNotEmpty) return naim;
    final name = (data['name'] as String?)?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final companyName = (data['company_name'] as String?)?.trim() ?? '';
    if (companyName.isNotEmpty) return companyName;
    return id;
  }

  /// Only companies explicitly marked active (schema: `actev`).
  static bool _isActiveCompany(Map<String, dynamic> data) {
    if (data.containsKey('actev')) {
      return data['actev'] == true;
    }
    if (data.containsKey('is_active')) {
      return data['is_active'] == true;
    }
    if (data.containsKey('active')) {
      return data['active'] == true;
    }
    return false;
  }

  static bool _matchesCountry(
    Map<String, dynamic> data,
    DocumentReference? country,
  ) {
    if (country == null) return true;
    final rev = data['Rev_dolh'];
    if (rev is DocumentReference) {
      return rev.path == country.path;
    }
    if (rev is String && rev.isNotEmpty) {
      return rev == country.path || rev.endsWith('/${country.id}');
    }
    return false;
  }

  Future<List<_CompanyOption>> _loadCompanies() async {
    final country = widget.countryRef ?? FFAppState().dolh;
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      if (country != null) {
        snap = await FirebaseFirestore.instance
            .collection('transport_company')
            .where('Rev_dolh', isEqualTo: country)
            .get();
      } else {
        snap = await FirebaseFirestore.instance
            .collection('transport_company')
            .get();
      }
    } catch (_) {
      snap = await FirebaseFirestore.instance
          .collection('transport_company')
          .get();
    }

    final options = <_CompanyOption>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (!_isActiveCompany(data)) continue;
      if (!_matchesCountry(data, country)) continue;
      options.add(
        _CompanyOption(
          path: doc.reference.path,
          name: _companyDisplayName(data, doc.id),
        ),
      );
    }
    options.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return options;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_CompanyOption>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            widget.t('Could not load transport companies'),
            style: TextStyle(
              fontFamily: 'cairo',
              color: Colors.red.shade700,
            ),
          );
        }
        final options = snapshot.data ?? const <_CompanyOption>[];
        if (options.isEmpty) {
          return Text(
            widget.t('No active transport companies found'),
            style: TextStyle(
              fontFamily: 'cairo',
              color: context.dsColors.textSecondary,
            ),
          );
        }
        final paths = options.map((e) => e.path).toSet();
        final value =
            paths.contains(widget.selectedPath) ? widget.selectedPath : null;
        return DropdownButtonFormField<String>(
          key: ValueKey(value ?? 'company-none'),
          initialValue: value,
          decoration: InputDecoration(
            labelText: widget.t('Transport company'),
            prefixIcon: Icon(
              Icons.business_outlined,
              color: context.dsColors.primaryStrong,
            ),
            filled: true,
            fillColor: context.dsColors.card,
            border: OutlineInputBorder(
              borderRadius: DsRadius.medium,
            ),
          ),
          items: options
              .map(
                (c) => DropdownMenuItem(
                  value: c.path,
                  child: Text(
                    c.name,
                    style: const TextStyle(fontFamily: 'cairo'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (path) {
            if (path == null) return;
            final match = options.firstWhere((e) => e.path == path);
            widget.onSelected(match.path, match.name);
          },
        );
      },
    );
  }
}

class _CompanyOption {
  const _CompanyOption({required this.path, required this.name});

  final String path;
  final String name;
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.t,
    required this.location,
    required this.cityController,
    required this.cityFocusNode,
    required this.onCityChanged,
    required this.onCascadeChanged,
    required this.onLocationChanged,
  });

  final String Function(String) t;
  final LatLng? location;
  final TextEditingController cityController;
  final FocusNode cityFocusNode;
  final ValueChanged<String> onCityChanged;
  final VoidCallback onCascadeChanged;
  final ValueChanged<LatLng> onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DriverRegLocationCascade(
          t: t,
          onChanged: onCascadeChanged,
        ),
        const SizedBox(height: 16),
        Text(
          t('Confirm your current location on the map'),
          style: TextStyle(
            fontFamily: 'cairo',
            color: context.dsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        DriverRegLocationMap(
          location: location,
          onLocationChanged: onLocationChanged,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: cityController,
          focusNode: cityFocusNode,
          label: t('City note (optional)'),
          hint: t('Optional display note'),
          icon: Icons.notes_outlined,
          validator: (_) => null,
          onChanged: onCityChanged,
        ),
      ],
    );
  }
}

class _VehicleStep extends StatelessWidget {
  const _VehicleStep({
    required this.t,
    required this.vehicleNameController,
    required this.vehicleNameFocusNode,
    required this.makeController,
    required this.makeFocusNode,
    required this.modelController,
    required this.modelFocusNode,
    required this.plateController,
    required this.plateFocusNode,
    required this.colorController,
    required this.colorFocusNode,
    required this.seatsController,
    required this.seatsFocusNode,
    required this.selectedType,
    required this.photoUrl,
    required this.idUrl,
    required this.carUrl,
    required this.licenseUrl,
    required this.uploadingPhoto,
    required this.uploadingId,
    required this.uploadingCar,
    required this.uploadingLicense,
    required this.onPickType,
    required this.onUploadPhoto,
    required this.onUploadId,
    required this.onUploadCar,
    required this.onUploadLicense,
    required this.validateModel,
    required this.validatePlate,
    required this.req,
    required this.affiliationType,
    required this.companyPath,
    required this.companyName,
    required this.isTourGuide,
    required this.guidePermitUrl,
    required this.uploadingGuide,
    required this.onAffiliationChanged,
    required this.onCompanySelected,
    required this.onTourGuideChanged,
    required this.onUploadGuidePermit,
    this.countryRef,
  });

  final String Function(String) t;
  final TextEditingController vehicleNameController;
  final FocusNode vehicleNameFocusNode;
  final TextEditingController makeController;
  final FocusNode makeFocusNode;
  final TextEditingController modelController;
  final FocusNode modelFocusNode;
  final TextEditingController plateController;
  final FocusNode plateFocusNode;
  final TextEditingController colorController;
  final FocusNode colorFocusNode;
  final TextEditingController seatsController;
  final FocusNode seatsFocusNode;
  final String selectedType;
  final String photoUrl;
  final String idUrl;
  final String carUrl;
  final String licenseUrl;
  final bool uploadingPhoto;
  final bool uploadingId;
  final bool uploadingCar;
  final bool uploadingLicense;
  final VoidCallback onPickType;
  final VoidCallback onUploadPhoto;
  final VoidCallback onUploadId;
  final VoidCallback onUploadCar;
  final VoidCallback onUploadLicense;
  final String? Function(String?) validateModel;
  final String? Function(String?) validatePlate;
  final String? Function(String?, String) req;
  final String affiliationType;
  final String companyPath;
  final String companyName;
  final bool isTourGuide;
  final String guidePermitUrl;
  final bool uploadingGuide;
  final ValueChanged<String> onAffiliationChanged;
  final void Function(String path, String name) onCompanySelected;
  final ValueChanged<bool> onTourGuideChanged;
  final VoidCallback onUploadGuidePermit;
  final DocumentReference? countryRef;

  Widget _docBtn(BuildContext context,
      {required String label,
      required String url,
      required bool loading,
      required VoidCallback onTap}) {
    final pending = url.startsWith('pending://');
    final ok = url.startsWith('https://');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onTap,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  ok
                      ? Icons.check_circle
                      : pending
                          ? Icons.schedule
                          : Icons.upload_file,
                  color: ok
                      ? Colors.green
                      : pending
                          ? Colors.orange
                          : context.dsColors.primaryStrong,
                ),
          label: Text(
            ok
                ? '$label ✓'
                : pending
                    ? '$label (${t('Selected')})'
                    : label,
            style: const TextStyle(fontFamily: 'cairo', fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t('Vehicle Information'),
            style: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 12),
        _Field(
            controller: makeController,
            focusNode: makeFocusNode,
            label: t('Make / Brand'),
            icon: Icons.factory_outlined,
            hint: t('e.g. Toyota'),
            validator: (v) => req(v, 'Make / Brand')),
        const SizedBox(height: 12),
        _Field(
            controller: vehicleNameController,
            focusNode: vehicleNameFocusNode,
            label: t('Vehicle Name'),
            icon: Icons.directions_car_outlined,
            hint: t('e.g. Camry'),
            validator: (v) => req(v, 'Vehicle Name')),
        const SizedBox(height: 12),
        _Field(
            controller: modelController,
            focusNode: modelFocusNode,
            label: t('Vehicle Model'),
            icon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            hint: '2020',
            validator: validateModel,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 12),
        _Field(
            controller: plateController,
            focusNode: plateFocusNode,
            label: t('Plate Number'),
            icon: Icons.confirmation_number_outlined,
            hint: t('License plate number'),
            validator: validatePlate),
        const SizedBox(height: 12),
        _Field(
            controller: colorController,
            focusNode: colorFocusNode,
            label: t('Color'),
            icon: Icons.palette_outlined,
            validator: (v) => req(v, 'Color')),
        const SizedBox(height: 12),
        _Field(
            controller: seatsController,
            focusNode: seatsFocusNode,
            label: t('Seats'),
            icon: Icons.event_seat_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => req(v, 'Seats')),
        const SizedBox(height: 12),
        InkWell(
          onTap: onPickType,
          borderRadius: DsRadius.medium,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: context.dsColors.card,
                borderRadius: DsRadius.medium,
                border: Border.all(
                    color: selectedType.isEmpty
                        ? context.dsColors.border
                        : context.dsColors.primary)),
            child: Row(children: [
              Icon(Icons.category_outlined, color: context.dsColors.primaryStrong),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      selectedType.isEmpty
                          ? t('Select vehicle type')
                          : selectedType,
                      style: const TextStyle(
                          fontFamily: 'cairo', fontWeight: FontWeight.w700))),
              Icon(Icons.expand_more, color: context.dsColors.primaryStrong),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t('Affiliation'),
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _affiliationChoiceChip(
              context: context,
              label: t('تابع لشركة نقل'),
              selected: affiliationType == 'company',
              onTap: () => onAffiliationChanged('company'),
            ),
            const SizedBox(width: 10),
            _affiliationChoiceChip(
              context: context,
              label: t('سائق مستقل'),
              selected: affiliationType != 'company',
              onTap: () => onAffiliationChanged('independent'),
            ),
          ],
        ),
        if (affiliationType == 'company') ...[
          const SizedBox(height: 12),
          _TransportCompanyDropdown(
            t: t,
            selectedPath: companyPath,
            selectedName: companyName,
            countryRef: countryRef,
            onSelected: onCompanySelected,
          ),
        ],
        const SizedBox(height: 20),
        Text(
          t('Tour guide'),
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _affiliationChoiceChip(
              context: context,
              label: t('Yes'),
              selected: isTourGuide,
              onTap: () => onTourGuideChanged(true),
            ),
            const SizedBox(width: 10),
            _affiliationChoiceChip(
              context: context,
              label: t('No'),
              selected: !isTourGuide,
              onTap: () => onTourGuideChanged(false),
            ),
          ],
        ),
        if (isTourGuide) ...[
          const SizedBox(height: 12),
          _docBtn(
            context,
            label: t('Tour guide permit'),
            url: guidePermitUrl,
            loading: uploadingGuide,
            onTap: onUploadGuidePermit,
          ),
        ],
        const SizedBox(height: 16),
        Text(t('Documents'),
            style: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 8),
        _docBtn(context,
            label: t('Profile photo'),
            url: photoUrl,
            loading: uploadingPhoto,
            onTap: onUploadPhoto),
        _docBtn(context,
            label: t('National ID'),
            url: idUrl,
            loading: uploadingId,
            onTap: onUploadId),
        _docBtn(context,
            label: t('Vehicle registration'),
            url: carUrl,
            loading: uploadingCar,
            onTap: onUploadCar),
        _docBtn(context,
            label: t('Driver license'),
            url: licenseUrl,
            loading: uploadingLicense,
            onTap: onUploadLicense),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.t,
    required this.name,
    required this.email,
    required this.phone,
    required this.idNumber,
    required this.birthDate,
    required this.country,
    required this.region,
    required this.city,
    required this.vehicleType,
    required this.vehicleName,
    required this.year,
    required this.plate,
    required this.color,
    required this.seats,
    required this.emailVerified,
    required this.phonePresent,
    required this.photoOk,
    required this.nationalIdOk,
    required this.vehicleRegOk,
    required this.licenseOk,
    required this.affiliationType,
    required this.companyName,
    required this.isTourGuide,
    required this.guidePermitOk,
    required this.onEditAccount,
    required this.onEditLocation,
    required this.onEditVehicle,
  });

  final String Function(String) t;
  final String name,
      email,
      phone,
      idNumber,
      country,
      region,
      city,
      vehicleType,
      vehicleName,
      year,
      plate,
      color,
      seats,
      affiliationType,
      companyName;
  final DateTime? birthDate;
  final bool emailVerified,
      phonePresent,
      photoOk,
      nationalIdOk,
      vehicleRegOk,
      licenseOk,
      isTourGuide,
      guidePermitOk;
  final VoidCallback onEditAccount, onEditLocation, onEditVehicle;

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
              flex: 2,
              child: Text(k,
                  style: const TextStyle(
                      fontFamily: 'cairo', color: Colors.black54))),
          Expanded(
              flex: 3,
              child: Text(v.isEmpty ? '—' : v,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontFamily: 'cairo', fontWeight: FontWeight.w600))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final birth = birthDate == null
        ? '—'
        : '${birthDate!.year.toString().padLeft(4, '0')}-'
            '${birthDate!.month.toString().padLeft(2, '0')}-'
            '${birthDate!.day.toString().padLeft(2, '0')}';
    final affiliationLabel = affiliationType == 'company'
        ? t('تابع لشركة نقل')
        : t('سائق مستقل');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t('Review'),
            style: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        const SizedBox(height: 12),
        _row(t('Full Name'), name),
        _row(t('Email'), email),
        _row(
          t('Email verified'),
          emailVerified ? '${t('Verified')} ✓' : t('Not verified'),
        ),
        _row(t('Phone'), phone),
        _row(
          t('Phone present'),
          phonePresent ? '${t('Added')} ✓' : t('Missing'),
        ),
        _row(t('ID Number'), idNumber),
        _row(t('Birth date'), birth),
        TextButton(onPressed: onEditAccount, child: Text(t('Edit'))),
        const Divider(),
        _row(t('Country'), country),
        _row(t('Region'), region),
        _row(t('City'), city),
        TextButton(onPressed: onEditLocation, child: Text(t('Edit'))),
        const Divider(),
        _row(t('Vehicle Type'), vehicleType),
        _row(t('Make'), vehicleName),
        _row(t('Vehicle year'), year),
        _row(t('Plate Number'), plate),
        _row(t('Color'), color),
        _row(t('Seats'), seats),
        _row(t('Affiliation'), affiliationLabel),
        if (affiliationType == 'company')
          _row(t('Transport company'), companyName),
        _row(t('Tour guide'), isTourGuide ? t('Yes') : t('No')),
        if (isTourGuide)
          _row(
            t('Tour guide permit'),
            guidePermitOk ? t('Uploaded') : t('Missing'),
          ),
        _row(
          t('Profile photo'),
          photoOk ? t('Uploaded') : t('Not provided (optional)'),
        ),
        _row(
          t('National ID'),
          nationalIdOk ? t('Uploaded') : t('Missing'),
        ),
        _row(
          t('Vehicle registration'),
          vehicleRegOk ? t('Uploaded') : t('Missing'),
        ),
        _row(
          t('Driver license'),
          licenseOk ? t('Uploaded') : t('Missing'),
        ),
        TextButton(onPressed: onEditVehicle, child: Text(t('Edit'))),
      ],
    );
  }
}
