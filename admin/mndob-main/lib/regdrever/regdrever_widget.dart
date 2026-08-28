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
import '/components/driver_reg_location_section.dart';
import '/components/list_type_car_widget.dart';
import '/core/driver_auth_errors.dart';
import '/core/driver_auth_validation_service.dart';
import '/core/driver_country_resolver.dart';
import '/core/driver_country_service.dart';
import '/core/driver_market_readiness_resolver.dart';
import '/core/driver_document_requirements.dart';
import '/core/driver_operational_eligibility_resolver.dart';
import '/core/driver_registration_preflight.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/core/driver_email_verification_service.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_document_upload_service.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_location_catalog_service.dart';
import '/core/driver_phone_number_service.dart';
import '/core/driver_registration_draft.dart';
import '/core/driver_registration_location_state.dart';
import '/core/driver_registration_submission_service.dart';
import '/core/driver_registration_validators.dart';
import '/core/driver_session_router.dart';
import '/core/driver_verify_panels.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
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
  bool _countryRequirementsResolved = false;
  DriverMarketReadiness? _marketReadiness;
  List<DriverDocumentRequirement> _countryDocReqs = const [];
  DateTime? _licenseExpiry;
  DateTime? _vehicleRegExpiry;
  DateTime? _nationalIdExpiry;
  DateTime? _insuranceExpiry;
  String _insuranceUrl = '';
  String _insuranceStoragePath = '';
  SelectedFile? _pendingInsurance;
  bool _uploadingInsurance = false;
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
    if (draft.licenseImageUrl.isNotEmpty &&
        !draft.licenseImageUrl.startsWith('pending://')) {
      _licenseUrl = draft.licenseImageUrl;
    }
    if (draft.insuranceImageUrl.isNotEmpty &&
        !draft.insuranceImageUrl.startsWith('pending://')) {
      _insuranceUrl = draft.insuranceImageUrl;
    }
    _licenseExpiry = DateTime.tryParse(draft.licenseExpiryIso);
    _vehicleRegExpiry = DateTime.tryParse(draft.vehicleRegExpiryIso);
    _nationalIdExpiry = DateTime.tryParse(draft.nationalIdExpiryIso);
    _insuranceExpiry = DateTime.tryParse(draft.insuranceExpiryIso);
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
    if (draft.vehicleTypePath.trim().isNotEmpty) {
      final typeRef = DriverLocationCatalogService.refFromPath(
        draft.vehicleTypePath,
      );
      if (typeRef != null) {
        FFAppState().MNDOBTYPECARrev = typeRef;
        FFAppState().textTypeCar = draft.vehicleTypeText;
      }
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
      vehicleTypePath: FFAppState().MNDOBTYPECARrev?.path ?? '',
      vehicleTypeText: FFAppState().textTypeCar,
      licenseImageUrl: _licenseUrl,
      licenseExpiryIso: _licenseExpiry?.toIso8601String() ?? '',
      vehicleRegExpiryIso: _vehicleRegExpiry?.toIso8601String() ?? '',
      nationalIdExpiryIso: _nationalIdExpiry?.toIso8601String() ?? '',
      insuranceExpiryIso: _insuranceExpiry?.toIso8601String() ?? '',
      insuranceImageUrl: _insuranceUrl,
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

  Future<void> _applyRegLocation(LatLng loc) async {
    final prevIso = _regLocation == null
        ? null
        : TouryCountryRegistry.isoFromCoordinates(_regLocation!);
    setState(() {
      _regLocation = loc;
      final iso = TouryCountryRegistry.isoFromCoordinates(loc);
      if (iso != null && iso != prevIso) {
        cityController.text = '';
        FFAppState().mdenh = null;
        FFAppState().naimmdenh = '';
        FFAppState().villmndoBREV = null;
        FFAppState().textvill = '';
      }
    });
    unawaited(_persistDraft());
    final iso = TouryCountryRegistry.isoFromCoordinates(loc);
    if (iso == null || iso == prevIso) return;
    final countries = await DriverCountryService.listActiveCountries();
    final match = countries
        .where(
          (c) => DriverCountryService.isoOfCountry(c) == iso,
        )
        .firstOrNull;
    if (match != null) {
      await DriverCountryService.applyCountry(FFAppState(), match);
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
  }

  Future<void> _promptSelectLocation() async {
    final open = await DriverDialogs.showConfirm(
      context,
      title: t('Location'),
      message: t('Please select your location to continue'),
      confirmLabel: t('Select location'),
      cancelLabel: t('Cancel'),
      type: DriverMessageType.warning,
    );
    if (!open || !mounted) return;
    final picked = await openDriverRegLocationPicker(
      context,
      initialLocation: _regLocation,
      countryIso2: TouryCountryRegistry.normalizeIso(FFAppState().dolh?.id),
    );
    if (picked != null && mounted) {
      await _applyRegLocation(picked);
    }
  }

  Future<void> _goTo(int step) async {
    setState(() => _step = step);
    if (step >= 2) {
      unawaited(_refreshCountryRequirements());
    }
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
      final loc = DriverRegistrationLocationInput(
        selectedPosition: _regLocation,
        hasCountry: FFAppState().dolh != null,
        hasRegion: FFAppState().mdenh != null,
        hasCity: FFAppState().villmndoBREV != null,
      ).validate();
      if (!loc.isValid) {
        if (loc.field == 'location') {
          await _promptSelectLocation();
        } else {
          await DriverDialogs.showAlert(
            context,
            title: t('Location'),
            message: t(loc.errorKey!),
            type: DriverMessageType.warning,
          );
        }
        return;
      }
      await _refreshCountryRequirements();
      final marketMsg = _marketNotReadyMessage();
      if (marketMsg != null) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: marketMsg,
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
        if (vehicle.field == 'vehicleType') {
          final openPicker = await DriverDialogs.showConfirm(
            context,
            title: t('Error'),
            message: t('Please select vehicle type'),
            confirmLabel: t('Select vehicle type'),
            cancelLabel: t('Cancel'),
            type: DriverMessageType.warning,
          );
          if (openPicker) await _pickVehicleType();
          return;
        }
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
      await _refreshCountryRequirements();
      final preflight = _buildPreflight();
      final expiryBlockers = preflight.blockers
          .where(
            (b) =>
                b.reasonCode == 'REQUIRED_EXPIRY_MISSING' ||
                b.reasonCode == 'DOCUMENT_EXPIRED',
          )
          .toList();
      if (expiryBlockers.isNotEmpty) {
        final msg = expiryBlockers.length == 1
            ? t(expiryBlockers.first.messageKey)
            : '${t('Please complete the following')}:\n${expiryBlockers.map((b) => '• ${t(b.messageKey)}').join('\n')}';
        final fix = await DriverDialogs.showConfirm(
          context,
          title: t('Error'),
          message: msg,
          confirmLabel: t('Add expiry date'),
          cancelLabel: t('Cancel'),
          type: DriverMessageType.warning,
        );
        if (fix && mounted) {
          final type = expiryBlockers.first.documentType;
          if (type.isNotEmpty) await _pickDocExpiry(type);
        }
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

  bool _isUploadReady({
    required String url,
    String storagePath = '',
    SelectedFile? pending,
  }) {
    if (pending != null && pending.bytes.isNotEmpty) return true;
    final path = storagePath.trim();
    if (path.startsWith('users/') && !path.contains('..')) return true;
    final trimmed = url.trim();
    if (trimmed.startsWith('pending://')) return false;
    return trimmed.startsWith('https://');
  }

  bool _hasRequiredDocumentUploads() {
    return _isUploadReady(
          url: _model.uploadedFileUrl_uploadDataLbm,
          storagePath: _photoStoragePath,
          pending: _pendingPhoto,
        ) &&
        _isUploadReady(
          url: _model.uploadedFileUrl_uploadData1k33,
          storagePath: _idStoragePath,
          pending: _pendingIdDoc,
        ) &&
        _isUploadReady(
          url: _carImageUrl,
          storagePath: _carStoragePath,
          pending: _pendingCarPhoto,
        ) &&
        _isUploadReady(
          url: _licenseUrl,
          storagePath: _licenseStoragePath,
          pending: _pendingLicense,
        );
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
    final locationIso = _regLocation != null
        ? TouryCountryRegistry.isoFromCoordinates(_regLocation!)
        : null;
    final resolvedCountry = DriverCountryResolver.resolveRegistrationCountry(
      dolh: FFAppState().dolh,
      locationIso2: locationIso,
    );
    if (resolvedCountry == null) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t('Please select a country'),
        type: DriverMessageType.warning,
      );
      return;
    }
    await _refreshCountryRequirements();
    final countryReqs =
        await DriverDocumentRequirementResolver.resolveForCountryRef(
      resolvedCountry,
    );
    if (countryReqs.isEmpty) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t(
          'Country registration requirements could not be loaded. Please try again later or contact support.',
        ),
        type: DriverMessageType.warning,
      );
      return;
    }
    if (FFAppState().dolh?.path != resolvedCountry.path) {
      FFAppState().update(() {
        FFAppState().dolh = resolvedCountry;
      });
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
    final preflightBeforeSubmit = _buildPreflight();
    final expiryBeforeSubmit = preflightBeforeSubmit.blockers
        .where(
          (b) =>
              b.reasonCode == 'REQUIRED_EXPIRY_MISSING' ||
              b.reasonCode == 'DOCUMENT_EXPIRED',
        )
        .toList();
    if (expiryBeforeSubmit.isNotEmpty) {
      final msg = expiryBeforeSubmit.length == 1
          ? t(expiryBeforeSubmit.first.messageKey)
          : '${t('Please complete the following')}:\n${expiryBeforeSubmit.map((b) => '• ${t(b.messageKey)}').join('\n')}';
      final fix = await DriverDialogs.showConfirm(
        context,
        title: t('Error'),
        message: msg,
        confirmLabel: t('Add expiry date'),
        cancelLabel: t('Cancel'),
        type: DriverMessageType.warning,
      );
      if (fix && mounted) {
        await _goTo(2);
        final type = expiryBeforeSubmit.first.documentType;
        if (type.isNotEmpty) await _pickDocExpiry(type);
      }
      return;
    }
    if (_uploadingPhoto ||
        _uploadingId ||
        _uploadingCar ||
        _uploadingGuide ||
        _uploadingLicense ||
        _uploadingInsurance) {
      await DriverDialogs.showAlert(
        context,
        title: t('Please wait'),
        message: t('Document upload is still in progress'),
        type: DriverMessageType.warning,
      );
      return;
    }

    final emailOk =
        await DriverEmailVerificationService.reloadRefreshTokenAndCheckVerified();
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
        licenseImageUrl: _licenseUrl,
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
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'pending_review',
          'reviewStatus': 'pending_review',
          'documentVersion': 1,
          if (_nationalIdExpiry != null)
            'expiryDate': Timestamp.fromDate(_nationalIdExpiry!.toUtc()),
        },
        'doc_vehicle_registration': {
          'documentType': 'vehicle_registration',
          if (_carStoragePath.isEmpty && _carImageUrl.isNotEmpty)
            'url': _carImageUrl,
          'storagePath': _carStoragePath,
          'uploadedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'pending_review',
          'reviewStatus': 'pending_review',
          'documentVersion': 1,
          if (_vehicleRegExpiry != null)
            'expiryDate': Timestamp.fromDate(_vehicleRegExpiry!.toUtc()),
        },
        'doc_driver_license': {
          'documentType': 'driver_license',
          if (_licenseStoragePath.isEmpty && _licenseUrl.isNotEmpty)
            'url': _licenseUrl,
          'storagePath': _licenseStoragePath,
          'uploadedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'pending_review',
          'reviewStatus': 'pending_review',
          'documentVersion': 1,
          if (_licenseExpiry != null)
            'expiryDate': Timestamp.fromDate(_licenseExpiry!.toUtc()),
        },
        if (_filePresentForType('vehicleInsurance'))
          'doc_vehicle_insurance': {
            'documentType': 'vehicle_insurance',
            if (_insuranceStoragePath.isEmpty && _insuranceUrl.isNotEmpty)
              'url': _insuranceUrl,
            'storagePath': _insuranceStoragePath,
            'uploadedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'status': 'pending_review',
            'reviewStatus': 'pending_review',
            'documentVersion': 1,
            if (_insuranceExpiry != null)
              'expiryDate': Timestamp.fromDate(_insuranceExpiry!.toUtc()),
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

      if (!mounted) return;
      // Leave registration immediately — do not remain on Step 4.
      context.goNamed(DriverPendingApprovalWidget.routeName);
      return;
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
    final locationIso = _regLocation != null
        ? TouryCountryRegistry.isoFromCoordinates(_regLocation!)
        : null;
    final countryRef = DriverCountryResolver.resolveRegistrationCountry(
      dolh: FFAppState().dolh,
      locationIso2: locationIso,
    );
    final countryIso = DriverCountryResolver.resolveRegistrationIso(
      dolh: FFAppState().dolh,
      locationIso2: locationIso,
    );
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.dsColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: ListTypeCarWidget(
          idNumber: idNumberController.text,
          countryRef: countryRef,
          countryIso2: countryIso,
          onSelected: () => unawaited(_persistDraft()),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _refreshCountryRequirements() async {
    final locationIso = _regLocation != null
        ? TouryCountryRegistry.isoFromCoordinates(_regLocation!)
        : null;
    final countryRef = DriverCountryResolver.resolveRegistrationCountry(
      dolh: FFAppState().dolh,
      locationIso2: locationIso,
    );
    if (countryRef == null) {
      if (mounted) {
        setState(() {
          _countryRequirementsResolved = false;
          _marketReadiness = null;
        });
      }
      debugPrint('DRIVER_COUNTRY_PATH=');
      debugPrint('REQUIREMENTS_ENABLED_COUNT=0');
      return;
    }
    debugPrint('DRIVER_COUNTRY_PATH=${countryRef.path}');
    final readiness = await DriverMarketReadinessResolver.resolveForCountryRef(
      countryRef: countryRef,
      countryIso2: locationIso,
      idNumber: idNumberController.text,
    );
    final reqs = await DriverDocumentRequirementResolver.resolveForCountryRef(
      countryRef,
    );
    if (!mounted) return;
    setState(() {
      _countryRequirementsResolved = reqs.isNotEmpty;
      _countryDocReqs = reqs;
      _marketReadiness = readiness;
    });
    debugPrint('REQUIREMENTS_ENABLED_COUNT=${readiness.enabledRequirementsCount}');
    debugPrint('TYPE_CAR_MARKET_COUNT=${readiness.activeVehicleCount}');
    debugPrint('MARKET_READINESS=${readiness.reasonCode.name}');
    for (final r in reqs) {
      debugPrint(
        'DOC_TYPE=${r.type} REQUIRED=${r.required} EXPIRY_REQUIRED=${r.expiryRequired}',
      );
    }
  }

  DateTime? _expiryForType(String type) {
    switch (type) {
      case 'driverLicense':
        return _licenseExpiry;
      case 'vehicleRegistration':
        return _vehicleRegExpiry;
      case 'nationalId':
        return _nationalIdExpiry;
      case 'vehicleInsurance':
        return _insuranceExpiry;
      default:
        return null;
    }
  }

  void _setExpiryForType(String type, DateTime? value) {
    setState(() {
      switch (type) {
        case 'driverLicense':
          _licenseExpiry = value;
          break;
        case 'vehicleRegistration':
          _vehicleRegExpiry = value;
          break;
        case 'nationalId':
          _nationalIdExpiry = value;
          break;
        case 'vehicleInsurance':
          _insuranceExpiry = value;
          break;
      }
    });
    unawaited(_persistDraft());
  }

  bool _filePresentForType(String type) {
    switch (type) {
      case 'profilePhoto':
        return _isUploadReady(
          url: _model.uploadedFileUrl_uploadDataLbm,
          storagePath: _photoStoragePath,
          pending: _pendingPhoto,
        );
      case 'nationalId':
        return _isUploadReady(
          url: _model.uploadedFileUrl_uploadData1k33,
          storagePath: _idStoragePath,
          pending: _pendingIdDoc,
        );
      case 'vehicleRegistration':
        return _isUploadReady(
          url: _carImageUrl,
          storagePath: _carStoragePath,
          pending: _pendingCarPhoto,
        );
      case 'driverLicense':
        return _isUploadReady(
          url: _licenseUrl,
          storagePath: _licenseStoragePath,
          pending: _pendingLicense,
        );
      case 'vehicleInsurance':
        return _isUploadReady(
          url: _insuranceUrl,
          storagePath: _insuranceStoragePath,
          pending: _pendingInsurance,
        );
      default:
        return false;
    }
  }

  DriverRegistrationPreflightResult _buildPreflight() {
    final fileMap = <String, bool>{};
    final expiryMap = <String, DateTime?>{};
    for (final r in _countryDocReqs) {
      fileMap[r.type] = _filePresentForType(r.type);
      expiryMap[r.type] = _expiryForType(r.type);
    }
    // Fallback baseline when config not yet loaded — still require license/reg expiry.
    final reqs = _countryDocReqs.isNotEmpty
        ? _countryDocReqs
        : DriverDocumentRequirementsRepository.baseline;
    return DriverRegistrationPreflightValidator.evaluate(
      requirements: reqs,
      filePresentByType: fileMap.isNotEmpty
          ? fileMap
          : {
              'profilePhoto': _filePresentForType('profilePhoto'),
              'nationalId': _filePresentForType('nationalId'),
              'vehicleRegistration': _filePresentForType('vehicleRegistration'),
              'driverLicense': _filePresentForType('driverLicense'),
            },
      expiryByType: expiryMap.isNotEmpty
          ? expiryMap
          : {
              'driverLicense': _licenseExpiry,
              'vehicleRegistration': _vehicleRegExpiry,
              'nationalId': _nationalIdExpiry,
              'vehicleInsurance': _insuranceExpiry,
            },
      emailVerified:
          FirebaseAuth.instance.currentUser?.emailVerified == true,
      hasVehicleType: FFAppState().MNDOBTYPECARrev != null &&
          FFAppState().textTypeCar.isNotEmpty,
      hasLocation: TouryMapsConfig.isUsableCoordinate(_regLocation),
      countryConfigReady: _countryRequirementsResolved ||
          _countryDocReqs.isNotEmpty,
    );
  }

  Future<void> _pickDocExpiry(String type) async {
    final now = DateTime.now();
    final initial = _expiryForType(type) ??
        DateTime(now.year + 1, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      helpText: t('Expiry date'),
    );
    if (picked == null || !mounted) return;
    _setExpiryForType(type, picked);
  }

  String? _marketNotReadyMessage() {
    final readiness = _marketReadiness;
    if (readiness == null || readiness.registrationReady) return null;
    switch (readiness.reasonCode) {
      case DriverMarketReadinessReason.missingVehicleCatalog:
        return t(
          'No vehicle types are configured for this country yet. Contact support or try again later.',
        );
      case DriverMarketReadinessReason.missingDriverRequirements:
      case DriverMarketReadinessReason.incomplete:
      case DriverMarketReadinessReason.countryInactive:
      case DriverMarketReadinessReason.countryMissing:
        return t(
          'Driver registration is not available in this country right now.',
        );
      case DriverMarketReadinessReason.ready:
        return null;
    }
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
        _uploadingLicense ||
        _uploadingInsurance) {
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
      if (kind == 'insurance') _uploadingInsurance = true;
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
            _nationalIdExpiry = null;
          } else if (kind == 'guide') {
            _guidePermitUrl = result.previewUrl ?? '';
            _pendingGuidePermit = null;
          } else if (kind == 'license') {
            _licenseUrl = result.previewUrl ?? '';
            _licenseStoragePath = result.storagePath;
            _pendingLicense = null;
            _licenseExpiry = null;
          } else if (kind == 'insurance') {
            _insuranceUrl = result.previewUrl ?? '';
            _insuranceStoragePath = result.storagePath;
            _pendingInsurance = null;
            _insuranceExpiry = null;
          } else {
            _carImageUrl = result.previewUrl ?? '';
            _carStoragePath = result.storagePath;
            _pendingCarPhoto = null;
            _vehicleRegExpiry = null;
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
            _nationalIdExpiry = null;
          } else if (kind == 'guide') {
            _pendingGuidePermit = file;
            _guidePermitUrl = 'pending://guide';
          } else if (kind == 'license') {
            _pendingLicense = file;
            _licenseUrl = 'pending://license';
            _licenseExpiry = null;
          } else if (kind == 'insurance') {
            _pendingInsurance = file;
            _insuranceUrl = 'pending://insurance';
            _insuranceExpiry = null;
          } else {
            _pendingCarPhoto = file;
            _carImageUrl = 'pending://car';
            _vehicleRegExpiry = null;
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
          _uploadingInsurance = false;
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
    if (_pendingInsurance != null ||
        _insuranceUrl.isNotEmpty ||
        _insuranceStoragePath.isNotEmpty) {
      await flushOne(
        pending: _pendingInsurance,
        currentUrl: _insuranceUrl,
        assign: (url, path) {
          _insuranceUrl = url;
          _insuranceStoragePath = path;
        },
        clearPending: () => _pendingInsurance = null,
      );
    }
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
                if (_marketNotReadyMessage() != null && _step >= 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: DsInformationCard(
                      title: t('Error'),
                      message: _marketNotReadyMessage()!,
                      tone: DsInfoTone.warning,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
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
                        countryIso2:
                            TouryCountryRegistry.normalizeIso(FFAppState().dolh?.id),
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
                          await _applyRegLocation(loc);
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
                        documentRequirements: _countryDocReqs.isNotEmpty
                            ? _countryDocReqs
                            : DriverDocumentRequirementsRepository.baseline,
                        licenseExpiry: _licenseExpiry,
                        vehicleRegExpiry: _vehicleRegExpiry,
                        nationalIdExpiry: _nationalIdExpiry,
                        insuranceExpiry: _insuranceExpiry,
                        insuranceUrl: _insuranceUrl,
                        uploadingInsurance: _uploadingInsurance,
                        onUploadInsurance: () =>
                            _uploadDoc(kind: 'insurance'),
                        onPickExpiry: _pickDocExpiry,
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
                        licenseExpiry: _licenseExpiry,
                        vehicleRegExpiry: _vehicleRegExpiry,
                        documentRequirements: _countryDocReqs,
                        preflightReady: _buildPreflight().isReady,
                        remainingRequirements:
                            _buildPreflight().remainingCount,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DsButton.primary(
                              label: _step == _totalSteps - 1
                                  ? t('Submit Application')
                                  : t('Next'),
                              expanded: true,
                              loading: _submitting,
                              enabled: !_submitting &&
                                  (_step != _totalSteps - 1 ||
                                      _buildPreflight().isReady),
                              onPressed: _next,
                            ),
                            if (_step == _totalSteps - 1 &&
                                !_buildPreflight().isReady) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${t('Remaining requirements')}: ${_buildPreflight().remainingCount}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 12,
                                  color: context.dsColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final blockers = _buildPreflight().blockers;
                                  if (blockers.isEmpty) return;
                                  final first = blockers.first;
                                  if (first.step == 2) {
                                    await _goTo(2);
                                    if (first.documentType.isNotEmpty &&
                                        first.reasonCode ==
                                            'REQUIRED_EXPIRY_MISSING') {
                                      await _pickDocExpiry(first.documentType);
                                    }
                                  } else {
                                    await _goTo(first.step);
                                  }
                                },
                                child: Text(
                                  t('View requirements'),
                                  style: const TextStyle(fontFamily: 'cairo'),
                                ),
                              ),
                            ],
                          ],
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
    this.countryIso2,
  });

  final String Function(String) t;
  final LatLng? location;
  final TextEditingController cityController;
  final FocusNode cityFocusNode;
  final ValueChanged<String> onCityChanged;
  final VoidCallback onCascadeChanged;
  final ValueChanged<LatLng> onLocationChanged;
  final String? countryIso2;

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
        DriverRegLocationSection(
          t: t,
          location: location,
          countryIso2: countryIso2,
          onLocationSelected: onLocationChanged,
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
    required this.documentRequirements,
    required this.licenseExpiry,
    required this.vehicleRegExpiry,
    required this.nationalIdExpiry,
    required this.insuranceExpiry,
    required this.insuranceUrl,
    required this.uploadingInsurance,
    required this.onUploadInsurance,
    required this.onPickExpiry,
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
  final List<DriverDocumentRequirement> documentRequirements;
  final DateTime? licenseExpiry;
  final DateTime? vehicleRegExpiry;
  final DateTime? nationalIdExpiry;
  final DateTime? insuranceExpiry;
  final String insuranceUrl;
  final bool uploadingInsurance;
  final VoidCallback onUploadInsurance;
  final Future<void> Function(String type) onPickExpiry;
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
                        : context.dsColors.primary,
                    width: selectedType.isEmpty ? 1 : 2)),
            child: Row(children: [
              Icon(Icons.category_outlined, color: context.dsColors.primaryStrong),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Select vehicle type'),
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: context.dsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      selectedType.isEmpty
                          ? t('Tap to choose from catalog')
                          : selectedType,
                      style: const TextStyle(
                          fontFamily: 'cairo', fontWeight: FontWeight.w700)),
                ],
              )),
              Icon(Icons.expand_more, color: context.dsColors.primaryStrong),
            ]),
          ),
        ),
        const SizedBox(height: 16),
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
        ..._buildDocumentCards(context),
      ],
    );
  }

  List<Widget> _buildDocumentCards(BuildContext context) {
    final reqs = documentRequirements.isNotEmpty
        ? documentRequirements
        : DriverDocumentRequirementsRepository.baseline;
    DateTime? expiryOf(String type) {
      switch (type) {
        case 'driverLicense':
          return licenseExpiry;
        case 'vehicleRegistration':
          return vehicleRegExpiry;
        case 'nationalId':
          return nationalIdExpiry;
        case 'vehicleInsurance':
          return insuranceExpiry;
        default:
          return null;
      }
    }

    String urlOf(String type) {
      switch (type) {
        case 'profilePhoto':
          return photoUrl;
        case 'nationalId':
          return idUrl;
        case 'vehicleRegistration':
          return carUrl;
        case 'driverLicense':
          return licenseUrl;
        case 'vehicleInsurance':
          return insuranceUrl;
        default:
          return '';
      }
    }

    bool loadingOf(String type) {
      switch (type) {
        case 'profilePhoto':
          return uploadingPhoto;
        case 'nationalId':
          return uploadingId;
        case 'vehicleRegistration':
          return uploadingCar;
        case 'driverLicense':
          return uploadingLicense;
        case 'vehicleInsurance':
          return uploadingInsurance;
        default:
          return false;
      }
    }

    VoidCallback? onUploadOf(String type) {
      switch (type) {
        case 'profilePhoto':
          return onUploadPhoto;
        case 'nationalId':
          return onUploadId;
        case 'vehicleRegistration':
          return onUploadCar;
        case 'driverLicense':
          return onUploadLicense;
        case 'vehicleInsurance':
          return onUploadInsurance;
        default:
          return null;
      }
    }

    return [
      for (final req in reqs)
        _RegDocumentCard(
          t: t,
          title: t(DriverRegistrationPreflightValidator.titleKeyForType(req.type)),
          requiredLabel: req.required ? t('Required') : t('Optional'),
          url: urlOf(req.type),
          loading: loadingOf(req.type),
          expiryRequired: req.expiryRequired,
          expiryDate: expiryOf(req.type),
          onUpload: onUploadOf(req.type) ?? () {},
          onPickExpiry: () => onPickExpiry(req.type),
        ),
    ];
  }
}

class _RegDocumentCard extends StatelessWidget {
  const _RegDocumentCard({
    required this.t,
    required this.title,
    required this.requiredLabel,
    required this.url,
    required this.loading,
    required this.expiryRequired,
    required this.expiryDate,
    required this.onUpload,
    required this.onPickExpiry,
  });

  final String Function(String) t;
  final String title;
  final String requiredLabel;
  final String url;
  final bool loading;
  final bool expiryRequired;
  final DateTime? expiryDate;
  final VoidCallback onUpload;
  final VoidCallback onPickExpiry;

  @override
  Widget build(BuildContext context) {
    final pending = url.startsWith('pending://');
    final fileOk = url.startsWith('https://') || pending;
    final status = DriverRegistrationPreflightValidator.documentStatus(
      filePresent: fileOk && !pending ? url.startsWith('https://') : pending,
      expiryRequired: expiryRequired,
      expiryDate: expiryDate,
    );
    // Treat pending local selection as file present for UI status.
    final effectiveStatus = (!fileOk)
        ? DriverRegDocUiStatus.missing
        : (pending && expiryRequired && expiryDate == null)
            ? DriverRegDocUiStatus.uploadedIncomplete
            : (pending && !expiryRequired)
                ? DriverRegDocUiStatus.ready
                : status;
    final expired = DriverRegistrationPreflightValidator.isExpiryExpired(expiryDate);

    String statusText;
    Color statusColor;
    switch (effectiveStatus) {
      case DriverRegDocUiStatus.missing:
        statusText = t('Missing');
        statusColor = context.dsColors.error;
        break;
      case DriverRegDocUiStatus.uploadedIncomplete:
        statusText = expired
            ? t('This document has expired. Please upload a valid document.')
            : t('Document uploaded — expiry date required');
        statusColor = context.dsColors.warning;
        break;
      case DriverRegDocUiStatus.ready:
        statusText = pending
            ? '${t('Selected')}'
            : t('Uploaded');
        statusColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dsColors.card,
        borderRadius: DsRadius.medium,
        border: Border.all(
          color: effectiveStatus == DriverRegDocUiStatus.uploadedIncomplete
              ? context.dsColors.warning
              : context.dsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                requiredLabel,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: context.dsColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onUpload,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      fileOk ? Icons.check_circle : Icons.upload_file,
                      color: fileOk
                          ? Colors.green
                          : context.dsColors.primaryStrong,
                    ),
              label: Text(
                fileOk ? t('Replace document') : t('Upload document'),
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${t('Status')}: $statusText',
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: statusColor,
            ),
          ),
          if (expiryRequired) ...[
            const SizedBox(height: 10),
            Text(
              '${t('Expiry date')} *',
              style: TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.dsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: onPickExpiry,
              borderRadius: DsRadius.medium,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: DsRadius.medium,
                  border: Border.all(
                    color: expiryDate == null
                        ? context.dsColors.warning
                        : context.dsColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: context.dsColors.primaryStrong),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        expiryDate == null
                            ? t('Select expiry date')
                            : '${expiryDate!.day.toString().padLeft(2, '0')} / ${expiryDate!.month.toString().padLeft(2, '0')} / ${expiryDate!.year}',
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.w700,
                          color: expiryDate == null
                              ? context.dsColors.textSecondary
                              : context.dsColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
    this.licenseExpiry,
    this.vehicleRegExpiry,
    this.documentRequirements = const [],
    this.preflightReady = true,
    this.remainingRequirements = 0,
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
  final DateTime? licenseExpiry;
  final DateTime? vehicleRegExpiry;
  final List<DriverDocumentRequirement> documentRequirements;
  final bool preflightReady;
  final int remainingRequirements;

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
          _docReviewStatus(
            uploaded: vehicleRegOk,
            expiryRequired: documentRequirements.any(
              (r) => r.type == 'vehicleRegistration' && r.expiryRequired,
            ),
            expiry: vehicleRegExpiry,
          ),
        ),
        if (vehicleRegOk && vehicleRegExpiry != null)
          _row(
            t('Vehicle registration expiry'),
            '${vehicleRegExpiry!.day.toString().padLeft(2, '0')} / ${vehicleRegExpiry!.month.toString().padLeft(2, '0')} / ${vehicleRegExpiry!.year}',
          ),
        _row(
          t('Driver license'),
          _docReviewStatus(
            uploaded: licenseOk,
            expiryRequired: documentRequirements.any(
              (r) => r.type == 'driverLicense' && r.expiryRequired,
            ),
            expiry: licenseExpiry,
          ),
        ),
        if (licenseOk && licenseExpiry != null)
          _row(
            t('Driver license expiry'),
            '${licenseExpiry!.day.toString().padLeft(2, '0')} / ${licenseExpiry!.month.toString().padLeft(2, '0')} / ${licenseExpiry!.year}',
          ),
        TextButton(onPressed: onEditVehicle, child: Text(t('Edit'))),
        const SizedBox(height: 12),
        Text(
          preflightReady
              ? t('Ready to submit')
              : '${t('Registration incomplete')} ($remainingRequirements)',
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.w700,
            color: preflightReady ? Colors.green : Colors.orange.shade800,
          ),
        ),
      ],
    );
  }

  String _docReviewStatus({
    required bool uploaded,
    required bool expiryRequired,
    required DateTime? expiry,
  }) {
    if (!uploaded) return t('Missing');
    if (expiryRequired && expiry == null) {
      return t('Document uploaded — expiry date required');
    }
    return t('Ready');
  }
}
