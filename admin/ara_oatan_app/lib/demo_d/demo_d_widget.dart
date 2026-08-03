import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/core/app_ux_widgets.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_geo_aliases.dart';
import '/core/toury_geo_display.dart';
import '/core/toury_google_map_panel.dart';
import '/core/toury_location_service.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'demo_d_model.dart';
export 'demo_d_model.dart';

class DemoDWidget extends StatefulWidget {
  const DemoDWidget({
    super.key,
    bool? isSpeed,
  }) : isSpeed = isSpeed ?? true;

  final bool isSpeed;

  static String routeName = 'demoD';
  static String routePath = '/BookingOption';

  @override
  State<DemoDWidget> createState() => _DemoDWidgetState();
}

class _DemoDWidgetState extends State<DemoDWidget>
    with TickerProviderStateMixin {
  late DemoDModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  bool _countrySyncInProgress = false;
  bool _countryMismatchHandled = false;
  bool _outsideCoverage = false;
  bool _outsideCoverageMessageShown = false;
  Timer? _mapGeocodeDebounce;
  LatLng? _lastGeocodedMapCenter;

  /// UI-only flags driving the Design System loading affordances.
  bool _locating = false;
  bool _navigating = false;

  // Reserved for future map-shell fallbacks (never Makkah).
  // ignore: unused_field
  static const LatLng _neutralMapShell = LatLng(20.0, 0.0);

  void _applyOutsideCoverageState() {
    _outsideCoverage = true;
    _model.dolh = '';
    _model.mdenh = '';
    _model.dol = null;
    _model.resolvedCountry = null;
    _model.resolvedVillage = null;
    FFAppState().naimdolh = '';
    FFAppState().dolh = null;
    FFAppState().naimvillatext = '';
    FFAppState().naimmdenh = '';
    FFAppState().villtextnow = '';
    FFAppState().villa = null;
    FFAppState().villnow = null;
    FFAppState().mdenh = null;
    FFAppState().vil = null;
    FFAppState().AllowBooking = false;
    safeSetState(() {});
  }

  String get _currentCountryLabel {
    if (_outsideCoverage) return '';
    final fromModel = _model.dolh;
    if (fromModel != null && fromModel.trim().isNotEmpty) {
      return fromModel;
    }
    final fromState = FFAppState().naimdolh;
    if (fromState.trim().isNotEmpty) {
      return fromState;
    }
    return 'dialog_location_required'.tr();
  }

  String get _currentCityLabel {
    if (_outsideCoverage) return '';
    if (widget.isSpeed) {
      final fromModel = _model.mdenh;
      if (fromModel != null && fromModel.trim().isNotEmpty) {
        return fromModel;
      }
    }
    final fromState = FFAppState().naimvillatext;
    if (fromState.trim().isNotEmpty) {
      return fromState;
    }
    if (widget.isSpeed) {
      return 'dialog_location_required'.tr();
    }
    return '';
  }

  Future<void> _syncCountryFromGps({bool redirectOnMismatch = true}) async {
    if (_countrySyncInProgress) return;
    // Don't fight the user while they are on another route (country/region pickers).
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (TouryLocationService.manualCountryLock) return;
    _countrySyncInProgress = true;
    try {
      final result = await TouryLocationService.syncCountryFromGps(
        storedCountryName: FFAppState().naimdolh,
        storedCountryRef: FFAppState().dolh,
        storedCityName: FFAppState().naimvillatext,
        storedCityCoords: FFAppState().latlngvill,
      );
      if (!mounted) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
      if (TouryLocationService.manualCountryLock) return;

      if (!result.gpsResolved) {
        return;
      }

      if (result.isOutsideCoverage) {
        _applyOutsideCoverageState();
        if (!_outsideCoverageMessageShown) {
          _outsideCoverageMessageShown = true;
          await TouryDialogs.showOutsideCoverage(context);
        }
        return;
      }

      _outsideCoverage = false;
      FFAppState().AllowBooking = true;

      if (result.resolved != null &&
          (result.wasCorrected ||
              result.wasCityCorrected ||
              _model.dolh == null ||
              _model.dolh!.isEmpty ||
              FFAppState().naimvillatext.trim().isEmpty ||
              FFAppState().villa == null)) {
        await _bindResolvedLocation(result.resolved!);
      }

      if (result.needsManualSelection &&
          redirectOnMismatch &&
          !_countryMismatchHandled) {
        _countryMismatchHandled = true;
        await TouryDialogs.showCountryMismatch(context);
        if (!mounted) return;
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
        context.pushNamed(LISTCountriesWidget.routeName);
      }
    } catch (e, st) {
      debugPrint('_syncCountryFromGps: $e\n$st');
    } finally {
      _countrySyncInProgress = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DemoDModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().paymentInProgress == true) {
        context.pushNamed(
          PaymentConfirmWidget.routeName,
          queryParameters: {
            'fromWebView': serializeParam(
              false,
              ParamType.bool,
            ),
          }.withoutNulls,
        );
        return;
      }
      tourySyncBookingFlags();
      unawaited(_syncCountryFromGps().whenComplete(() {
        if (mounted) safeSetState(() {});
      }));
    });
  }

  @override
  void dispose() {
    _mapGeocodeDebounce?.cancel();
    _model.dispose();

    super.dispose();
  }

  bool _mapMovedEnough(LatLng next) {
    final prev = _lastGeocodedMapCenter;
    if (prev == null) return true;
    final dLat = (next.latitude - prev.latitude).abs();
    final dLng = (next.longitude - prev.longitude).abs();
    return dLat > 0.00045 || dLng > 0.00045;
  }

  void _onMapCameraIdle(LatLng latLng) {
    _model.googleMapsCenter = latLng;
    _model.loceshn = LatLng(latLng.latitude, latLng.longitude);
    if (!_mapMovedEnough(latLng)) return;
    // While the user is picking a foreign country manually, don't let map
    // geocoding wipe that selection from a background/hidden DemoD map.
    if (TouryLocationService.manualCountryLock &&
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }

    _mapGeocodeDebounce?.cancel();
    _mapGeocodeDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      _lastGeocodedMapCenter = latLng;
      await _resolveLocationBindingFrom(_model.loceshn!);
      if (mounted) safeSetState(() {});
    });
  }

  Future<bool> _bindResolvedLocation(TouryResolvedLocation resolved) async {
    if (resolved.position == null) {
      return false;
    }
    if (resolved.isOutsideCoverage) {
      if (TouryLocationService.manualCountryLock) return false;
      _applyOutsideCoverageState();
      return false;
    }
    if (TouryLocationService.manualCountryLock) {
      final lockedIso =
          TouryCountryRegistry.normalizeIso(FFAppState().dolh?.id) ??
              TouryCountryRegistry.normalizeIso(FFAppState().naimdolh);
      final resolvedIso = resolved.countryIso2 ??
          TouryCountryRegistry.normalizeIso(resolved.country?.isoCode) ??
          TouryCountryRegistry.normalizeIso(resolved.country?.reference.id) ??
          TouryCountryRegistry.normalizeIso(resolved.countryName);
      if (lockedIso != null &&
          resolvedIso != null &&
          lockedIso != resolvedIso) {
        return false;
      }
    }
    _outsideCoverage = false;
    FFAppState().AllowBooking = true;
    _model.loceshn = resolved.position;
    _model.googleMapsCenter = resolved.position;
    _model.dolh = resolved.country?.naim ?? resolved.countryName;
    _model.mdenh = resolved.villageName;
    _model.adress = resolved.fullAddress;
    _model.resolvedVillage = resolved.village;
    _model.resolvedCountry = resolved.country;
    _model.dol = resolved.country;
    _model.lastResolved = resolved;
    // Always apply via location service so display names follow UI locale
    // (never force Arabic `.naim` into ky/ru/en chrome).
    if (resolved.country != null ||
        resolved.village != null ||
        (resolved.cityName != null && resolved.cityName!.isNotEmpty)) {
      TouryLocationService.applyResolvedToAppState(resolved);
    } else if (resolved.countryName != null &&
        resolved.countryName!.isNotEmpty) {
      TouryLocationService.applyResolvedToAppState(resolved);
    }
    FFAppState().LOceshtoaddAdress = resolved.coordinatesString;
    FFAppState().IsLnstantAddress = true;
    if (resolved.village != null) {
      TouryFirestoreCache.prefetchMkanFirstPage(resolved.village!.reference);
    }
    unawaited(_animateMapTo(resolved.position!));
    safeSetState(() {});
    return resolved.success ||
        resolved.country != null ||
        (resolved.countryName != null && resolved.countryName!.isNotEmpty);
  }

  Future<void> _animateMapTo(LatLng target) async {
    try {
      if (!_model.googleMapsController.isCompleted) return;
      final controller = await _model.googleMapsController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          target.toGoogleMaps(),
          15,
        ),
      );
    } catch (e) {
      debugPrint('_animateMapTo: $e');
    }
  }

  Future<bool> _resolveLocationBindingFrom(LatLng position) async {
    final resolved =
        await TouryLocationService.resolveFromCoordinates(position);
    if (resolved.isOutsideCoverage) {
      if (TouryLocationService.manualCountryLock) return false;
      _applyOutsideCoverageState();
      if (mounted && !_outsideCoverageMessageShown) {
        _outsideCoverageMessageShown = true;
        await TouryDialogs.showOutsideCoverage(context);
      }
      return false;
    }
    return _bindResolvedLocation(resolved);
  }

  /// ربط الدولة والمدينة قبل الانتقال لقائمة الوجهات أو الدفع.
  Future<bool> _bindVillageCountryForNext() async {
    if (!widget.isSpeed) {
      return touryHasPersistedLocation();
    }

    _model.mdenhVill ??= _model.resolvedVillage;
    _model.dol ??= _model.resolvedCountry;

    if (_model.mdenhVill == null) {
      final coords = _model.loceshn ?? _model.googleMapsCenter;
      if (coords != null) {
        final resolved =
            await TouryLocationService.resolveFromCoordinates(coords);
        _model.mdenhVill ??= resolved.village;
        _model.dol ??= resolved.country;
        _model.dolh ??= resolved.countryName;
        _model.mdenh ??= resolved.villageName;
        _model.adress ??= resolved.fullAddress;
      }
    }

    final lookups = <Future<void>>[];
    if (_model.mdenhVill == null &&
        _model.mdenh != null &&
        _model.mdenh!.isNotEmpty) {
      lookups.add(
        TouryFirestoreCache.villageByNameOnce(_model.mdenh!).then((v) {
          _model.mdenhVill ??= v;
        }),
      );
    }
    if (_model.dol == null &&
        _model.dolh != null &&
        _model.dolh!.isNotEmpty) {
      lookups.add(
        TouryFirestoreCache.countryByNameOnce(_model.dolh!).then((c) {
          _model.dol ??= c;
        }),
      );
    }
    if (lookups.isNotEmpty) {
      await Future.wait(lookups);
    }

    if (_model.mdenhVill == null || _model.dol == null) {
      return touryHasPersistedLocation();
    }

    return _commitLocationToAppState();
  }

  bool _canSkipLocationFetch() {
    if (!widget.isSpeed) return touryHasPersistedLocation();
    if (_model.resolvedVillage != null && _model.resolvedCountry != null) {
      return true;
    }
    if (_model.mdenhVill != null && _model.dol != null) return true;
    if (FFAppState().villa != null && FFAppState().dolh != null) return true;
    return false;
  }

  bool _commitLocationToAppState() {
    if (_model.mdenhVill == null || _model.dol == null) {
      return touryHasPersistedLocation();
    }

    final villageRef = _model.mdenhVill!.reference;

    FFAppState().dolh = _model.dol?.reference;
    FFAppState().naimdolh = touryLocalizedCountryLabel(_model.dol!);
    FFAppState().villnow = villageRef;
    FFAppState().villtextnow = touryLocalizedVillageLabel(_model.mdenhVill!);
    FFAppState().addcart = 0;
    FFAppState().cartmkss = [];
    FFAppState().cartPriceSummary = [];
    FFAppState().saatcar = 0;
    FFAppState().totalsaat = 0;
    FFAppState().addhors = 0;
    FFAppState().totalsaatandcar = 0;
    FFAppState().srtypecar = 0;
    FFAppState().typecarRev = null;
    FFAppState().tebycar = '';
    FFAppState().notcar = '';
    FFAppState().imgDolh = _model.dol!.img;
    FFAppState().msegAi = '';
    FFAppState().textallAlmdn = '';
    FFAppState().totalApp = 0.0;
    FFAppState().TOTALmndob = 0.0;
    FFAppState().vat = _model.dol!.vat.toDouble();
    FFAppState().totalAllNew = 0.0;
    FFAppState().VatDolh = _model.dol!.vat;
    FFAppState().isVat = _model.dol!.isvat;
    FFAppState().RMZCurrency = _model.dol!.currencySymbol;
    FFAppState().totalapp2 = 0;
    FFAppState().totalAllNow2 = 0;
    FFAppState().vat2 = 0;
    FFAppState().TOTALmndob2 = 0;
    FFAppState().fulltextSchedule = '';
    FFAppState().Minimumhours = 0;
    FFAppState().mkan = [];
    FFAppState().villa = touryCanonicalVillageRef(villageRef);
    FFAppState().latlngvill = _model.mdenhVill?.latLing;
    FFAppState().mdenh = _model.mdenhVill?.cities;
    FFAppState().vil = touryCanonicalVillageRef(villageRef);
    FFAppState().naimmdenh =
        touryLocalizedCityCiteLabel(_model.mdenhVill!);
    FFAppState().naimvillatext =
        touryLocalizedVillageLabel(_model.mdenhVill!);
    FFAppState().AdressTelet = _model.mdenh ?? '';
    FFAppState().fullAdress = _model.adress ?? '';
    FFAppState().payth = '';
    FFAppState().mkanuserorder = _model.googleMapsCenter;
    FFAppState().akrLoceshn = FFAppState().mkanuserorder;
    FFAppState().AllowBooking = true;

    FFAppState().update(() {});
    TouryFirestoreCache.prefetchMkanFirstPage(villageRef);
    return true;
  }

  Future<void> _openManualCountryPicker() async {
    if (!mounted) return;
    context.pushNamed(LISTCountriesWidget.routeName);
  }

  /// Locate GPS, bind country/city, return success. Shows typed error + manual option.
  Future<bool> _locateAndBind({bool showErrorDialog = true}) async {
    // Explicit "use my location" overrides a previous manual country pick.
    TouryLocationService.manualCountryLock = false;
    TouryLocationFailure? failure;
    LatLng? loc;
    try {
      loc = await TouryLocationService.getHighAccuracyPosition();
    } catch (e) {
      failure = TouryLocationService.classifyException(e);
      debugPrint('_locateAndBind GPS: $e');
    }

    if (loc == null) {
      if (showErrorDialog && mounted) {
        final manual = await TouryDialogs.showLocationError(
          context,
          failure: failure ?? TouryLocationFailure.timeout,
        );
        if (manual) await _openManualCountryPicker();
      }
      return false;
    }

    final bound = await _resolveLocationBindingFrom(loc);
    if (!bound) {
      final last = _model.lastResolved;
      if (showErrorDialog && mounted) {
        final manual = await TouryDialogs.showLocationError(
          context,
          message: last?.errorMessage,
          failure: last?.failure ?? TouryLocationFailure.noMatchingCity,
        );
        if (manual) await _openManualCountryPicker();
      }
      return false;
    }

    currentUserLocationValue = loc;
    await _syncCountryFromGps(redirectOnMismatch: false);
    return true;
  }

  Future<void> _handleNextTap() async {
    if (_model.idd == null) {
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: 'dialog_select_trip_or_location'.tr(),
        type: TouryMessageType.error,
      );
      return;
    }

    if (_model.idd == 1) {
      await _openLandmarksInstantly();
      return;
    }

    _model.mdenhVill ??= _model.resolvedVillage;
    _model.dol ??= _model.resolvedCountry;

    var locationReady = false;
    if (_canSkipLocationFetch()) {
      locationReady = _commitLocationToAppState();
    }
    if (!locationReady) {
      locationReady = await _bindVillageCountryForNext();
    }
    if (!locationReady) {
      locationReady = await _locateAndBind();
      if (locationReady) {
        locationReady = _commitLocationToAppState() ||
            await _bindVillageCountryForNext();
      }
    }
    if (!locationReady) {
      return;
    }

    FFAppState().IsLnstantAddress = widget.isSpeed;
    FFAppState().payth = '';
    FFAppState().fulltextSchedule = '';
    FFAppState().totalKM = 0.0;
    tourySyncBookingFlags();

    FFAppState().cartmkss = [];
    FFAppState().addcart = 0;
    FFAppState().mkan = [];
    FFAppState().update(() {});
    touryPrepareCheckoutState();

    if (!mounted) return;
    context.pushNamed(Checkout66Widget.routeName);
  }

  DocumentReference? _resolveVillageRefForNavigation() {
    _model.mdenhVill ??= _model.resolvedVillage;
    return _model.mdenhVill?.reference ?? FFAppState().villa ?? FFAppState().villnow;
  }

  void _pushLandmarksList(DocumentReference villageRef) {
    final canonical = touryCanonicalVillageRef(villageRef);
    TouryFirestoreCache.prefetchMkanFirstPage(canonical);
    FFAppState().villa = canonical;
    FFAppState().vil ??= canonical;
    FFAppState().cartmkss = [];
    FFAppState().addcart = 0;
    FFAppState().mkan = [];
    FFAppState().IsLnstantAddress = widget.isSpeed;
    FFAppState().payth = '';
    FFAppState().fulltextSchedule = '';
    FFAppState().totalKM = 0.0;

    if (!mounted) return;
    context.pushNamed(
      ListViWidget.routeName,
      queryParameters: {
        'cite': serializeParam(
          canonical,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _completeLocationAfterLandmarksNav() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _model.mdenhVill ??= _model.resolvedVillage;
    _model.dol ??= _model.resolvedCountry;

    if (_canSkipLocationFetch()) {
      _commitLocationToAppState();
    } else {
      await _bindVillageCountryForNext();
    }
    tourySyncBookingFlags();
  }

  Future<void> _openLandmarksInstantly() async {
    var villageRef = _resolveVillageRefForNavigation();

    if (villageRef != null) {
      _pushLandmarksList(villageRef);
      unawaited(_completeLocationAfterLandmarksNav());
      return;
    }

    var locationReady = await _bindVillageCountryForNext();
    if (!locationReady) {
      locationReady = await _locateAndBind();
      if (locationReady) {
        locationReady = await _bindVillageCountryForNext();
      }
    }
    if (!locationReady) {
      return;
    }

    villageRef = _resolveVillageRefForNavigation();
    if (villageRef == null) {
      if (!mounted) return;
      final manual = await TouryDialogs.showLocationError(
        context,
        failure: TouryLocationFailure.noMatchingCity,
      );
      if (manual) await _openManualCountryPicker();
      return;
    }

    _pushLandmarksList(villageRef);
    unawaited(_completeLocationAfterLandmarksNav());
  }

  Future<bool> _resolveCurrentLocationBinding() async {
    final resolved = await TouryLocationService.resolveCurrentLocation();
    if (!resolved.success || resolved.position == null) {
      if (mounted) {
        await TouryDialogs.showLocationError(
          context,
          message: resolved.errorMessage,
          failure: resolved.failure,
        );
      }
      return false;
    }
    currentUserLocationValue = resolved.position;
    return _bindResolvedLocation(resolved);
  }

  void _setLocating(bool value) {
    if (!mounted) return;
    safeSetState(() {
      _locating = value;
    });
  }

  /// Trip type 1 — the traveller builds their own route.
  Future<void> _selectOwnRoute() async {
    _model.idd = 1;
    _model.viewINFO = true;
    safeSetState(() {});
    _model.textTypePrent = 'ux_pick_location_next_hint'.tr();
    safeSetState(() {});
    FFAppState().typeHgz = 1;
    FFAppState().DriverGuideState = false;
    safeSetState(() {});
    _setLocating(true);
    final ok = await _locateAndBind();
    if (!ok) {
      FFAppState().AllowBooking = false;
    }
    _setLocating(false);
    safeSetState(() {});
  }

  /// Trip type 2 — the driver guide leads the tour.
  Future<void> _selectDriverGuide() async {
    _model.idd = 2;
    _model.viewINFO = true;
    safeSetState(() {});
    _model.textTypePrent = 'ux_driver_guide_location_hint'.tr();
    safeSetState(() {});
    FFAppState().typeHgz = 2;
    FFAppState().DriverGuideState = true;
    safeSetState(() {});
    _setLocating(true);
    final ok = await _locateAndBind();
    if (!ok) {
      FFAppState().AllowBooking = false;
    }
    _setLocating(false);
    safeSetState(() {});
  }

  Future<void> _useCurrentLocation() async {
    _setLocating(true);
    final ok = await _locateAndBind();
    if (!ok) {
      _setLocating(false);
      safeSetState(() {});
      return;
    }
    if (_model.loceshn != null) {
      await _model.googleMapsController.future.then(
        (c) => c.animateCamera(
          CameraUpdate.newLatLng(_model.loceshn!.toGoogleMaps()),
        ),
      );
    }
    _setLocating(false);
    safeSetState(() {});
  }

  Future<void> _changeCountryManual() async {
    final confirmDialogResponse =
        await TouryDialogs.confirmChangeCountry(context);
    if (confirmDialogResponse) {
      FFAppState().IsLnstantAddress = false;
      safeSetState(() {});

      context.pushNamed(LISTCountriesWidget.routeName);
    }
  }

  Future<void> _changeCountryInstant() async {
    final confirmDialogResponse =
        await TouryDialogs.confirmChangeCountry(context);
    if (confirmDialogResponse) {
      FFAppState().IsLnstantAddress = false;
      safeSetState(() {});

      context.pushNamed(AldolWidget.routeName);
    }
  }

  Future<void> _changeCityManual() async {
    final confirmDialogResponse = await TouryDialogs.confirmChangeCity(context);
    if (confirmDialogResponse) {
      FFAppState().IsLnstantAddress = false;
      safeSetState(() {});

      context.pushNamed(ListWidget.routeName);
    }
  }

  Future<void> _changeCityInstant() async {
    final confirmDialogResponse = await TouryDialogs.confirmChangeCity(context);
    if (confirmDialogResponse) {
      FFAppState().IsLnstantAddress = false;
      safeSetState(() {});
      _model.villCITE = await queryVillagesRecordOnce(
        queryBuilder: (villagesRecord) => villagesRecord.where(
          'naim',
          isEqualTo: _model.mdenh,
        ),
        singleRecord: true,
      ).then((s) => s.firstOrNull);
      FFAppState().mdenh = _model.villCITE?.cities;
      FFAppState().naimdolh = 'country_saudi'.tr();
      FFAppState().naimmdenh = _model.villCITE!.naimciteText;
      safeSetState(() {});

      context.pushNamed(ListWidget.routeName);
    }

    safeSetState(() {});
  }

  Future<void> _onNextPressed() async {
    if (_navigating) return;
    safeSetState(() {
      _navigating = true;
    });
    try {
      await _handleNextTap();
    } finally {
      if (mounted) {
        safeSetState(() {
          _navigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.select<FFAppState, int>(
      (s) => Object.hash(
        s.naimdolh,
        s.naimvillatext,
        s.naimmdenh,
        s.AllowBooking,
        s.addcart,
        s.typeHgz,
        s.mkan.length,
      ),
    );

    final brightness = Theme.of(context).brightness;
    final dsTheme =
        brightness == Brightness.dark ? DsTheme.dark() : DsTheme.light();

    return Theme(
      data: dsTheme,
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: Scaffold(
                key: scaffoldKey,
                resizeToAvoidBottomInset: false,
                backgroundColor: colors.scaffold,
                appBar: DsAppBar(
                  centerTitle: false,
                  titleWidget: _AppBarTitle(
                    subtitle:
                        _model.idd == null ? null : 'ux_step_location'.tr(),
                  ),
                ),
                body: SafeArea(
                  top: true,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: _buildContent(context),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: PointerInterceptor(
                          child: _buildBottomBar(context),
                        ),
                      ),
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

  Widget _buildContent(BuildContext context) {
    final showAddressBlock = widget.isSpeed == true && _model.idd != null;
    final showInfoBlock = _model.viewINFO == true;
    final showMap = (widget.isSpeed != false) && (_model.viewINFO == true);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.md,
        DsSpacing.md,
        TouryLayout.scrollPaddingAboveBottomButton(context) + DsSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DsFadeSlide(
            child: _buildStepsHeader(context),
          ),
          const SizedBox(height: DsSpacing.md),
          DsFadeSlide(
            delay: DsDurations.instant,
            child: _buildTripTypeSection(context),
          ),
          if (_model.idd != null) ...[
            const SizedBox(height: DsSpacing.md),
            DsFadeSlide(
              delay: DsDurations.fast,
              child: _buildSelectionHints(context),
            ),
          ],
          if (showAddressBlock || showInfoBlock) ...[
            const SizedBox(height: DsSpacing.md),
            DsFadeSlide(
              delay: DsDurations.fast,
              child: _buildLocationSection(
                context,
                showAddressBlock: showAddressBlock,
                showInfoBlock: showInfoBlock,
              ),
            ),
          ],
          if (showMap) ...[
            const SizedBox(height: DsSpacing.md),
            DsFadeSlide(
              delay: DsDurations.normal,
              child: _buildMapSection(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsHeader(BuildContext context) {
    final colors = context.dsColors;

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TouryBookingStepBar(
            currentStep: _model.idd == null ? 1 : 2,
            compact: true,
          ),
          const SizedBox(height: DsSpacing.sm),
          Container(height: 1, color: colors.divider),
          const SizedBox(height: DsSpacing.sm),
          TouryHelpBanner(
            message: 'ux_choose_trip_hint'.tr(),
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeSection(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: DsSpacing.xxs,
            right: DsSpacing.xxs,
            bottom: DsSpacing.xs,
          ),
          child: Text(
            'ux_step_trip_type'.tr(),
            style: typography.labelLarge.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        _TripTypeCard(
          icon: DsIcons.map,
          title: 'Select My Own Tour Route'.tr(),
          description: 'ux_custom_route_desc'.tr(),
          selected: _model.idd == 1,
          busy: _locating && _model.idd == 1,
          onTap: _selectOwnRoute,
        ),
        const SizedBox(height: DsSpacing.sm),
        _TripTypeCard(
          icon: Icons.drive_eta_rounded,
          title: 'Get Help from the Driver Guide'.tr(),
          description: 'ux_driver_guide_desc'.tr(),
          selected: _model.idd == 2,
          busy: _locating && _model.idd == 2,
          onTap: _selectDriverGuide,
        ),
      ],
    );
  }

  Widget _buildSelectionHints(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final hint = _model.textTypePrent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hint != null && hint.isNotEmpty) ...[
          TouryHelpBanner(
            message: hint,
            icon: Icons.touch_app_rounded,
            tone: TouryBannerTone.success,
          ),
          const SizedBox(height: DsSpacing.xs),
        ],
        Text(
          'Outside your city prices are agreed upon with the captain'.tr(),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: typography.bodySmall.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(
    BuildContext context, {
    required bool showAddressBlock,
    required bool showInfoBlock,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final requiredLabel = 'dialog_location_required'.tr();
    final countryLabel = _currentCountryLabel;
    final cityLabel = _currentCityLabel;

    final canChangeCountryManual = !_outsideCoverage && countryLabel.isNotEmpty;
    final canChangeCountryInstant =
        !_outsideCoverage && countryLabel != requiredLabel;
    final canChangeCityInstant = !_outsideCoverage &&
        cityLabel.isNotEmpty &&
        cityLabel != requiredLabel;

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showInfoBlock && _outsideCoverage) ...[
            TouryHelpBanner(
              message: 'dialog_outside_coverage_msg'.tr(),
              icon: Icons.public_off_rounded,
              tone: TouryBannerTone.warning,
              compact: true,
            ),
            const SizedBox(height: DsSpacing.md),
          ],
          if (showAddressBlock) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBubble(
                  icon: DsIcons.location,
                  tone: _outsideCoverage ? colors.warning : colors.primary,
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ux_step_location'.tr(),
                        style: typography.labelMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xxs),
                      Text(
                        valueOrDefault<String>(
                          _model.adress,
                          requiredLabel,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DsButton.outlined(
                label: 'My current location'.tr(),
                icon: DsIcons.location,
                size: DsButtonSize.sm,
                loading: _locating,
                onPressed: _useCurrentLocation,
              ),
            ),
          ],
          if (showInfoBlock) ...[
            if (showAddressBlock) ...[
              const SizedBox(height: DsSpacing.md),
              Container(height: 1, color: colors.divider),
              const SizedBox(height: DsSpacing.md),
            ],
            if (widget.isSpeed == false)
              _LocationField(
                icon: Icons.public_rounded,
                label: 'Current Country'.tr(),
                value: countryLabel,
                placeholder: requiredLabel,
                onChange: canChangeCountryManual ? _changeCountryManual : null,
              ),
            if (widget.isSpeed == true)
              _LocationField(
                icon: Icons.public_rounded,
                label: 'Current Country'.tr(),
                value: countryLabel,
                placeholder: requiredLabel,
                onChange:
                    canChangeCountryInstant ? _changeCountryInstant : null,
              ),
            const SizedBox(height: DsSpacing.sm),
            if (widget.isSpeed == false)
              _LocationField(
                icon: Icons.location_city_rounded,
                label: 'Current City'.tr(),
                value: cityLabel,
                placeholder: requiredLabel,
                onChange: _changeCityManual,
              ),
            if (widget.isSpeed == true)
              _LocationField(
                icon: Icons.location_city_rounded,
                label: 'Current City'.tr(),
                value: cityLabel,
                placeholder: requiredLabel,
                onChange: canChangeCityInstant ? _changeCityInstant : null,
              ),
          ],
          if (_locating) ...[
            const SizedBox(height: DsSpacing.md),
            const DsLoading(size: 22),
          ],
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    final colors = context.dsColors;
    final isDark = context.dsIsDark;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: DsRadius.large,
        border: Border.all(color: colors.border.withValues(alpha: 0.9)),
        boxShadow: DsShadows.card(dark: isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: TouryMapPanel(
        controller: _model.googleMapsController,
        onCameraIdle: _onMapCameraIdle,
        initialLocation: _model.googleMapsCenter ?? _model.loceshn,
        countryIso2: TouryCountryRegistry.normalizeIso(
                _model.resolvedCountry?.isoCode) ??
            TouryCountryRegistry.normalizeIso(
                _model.resolvedCountry?.reference.id) ??
            TouryCountryRegistry.normalizeIso(FFAppState().dolh?.id),
        height: TouryLayout.mapPanelHeight(context),
        initialZoom: 16,
        borderRadius: DsRadius.lg,
        showCenterPin: true,
        showMyLocation: true,
        showZoomControls: true,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final colors = context.dsColors;
    final isDark = context.dsIsDark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.sm + TouryLayout.bottomActionGap(context),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: DsRadius.xlRadius),
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: DsShadows.bottomSheet(dark: isDark),
      ),
      child: DsButton(
        label: 'Next'.tr(),
        variant: DsButtonVariant.primary,
        size: DsButtonSize.lg,
        expanded: true,
        loading: _navigating,
        trailing: Icon(
          Icons.arrow_forward_rounded,
          size: DsConstants.iconSm,
          color: colors.onPrimary,
        ),
        onPressed: _onNextPressed,
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ux_booking_steps'.tr(),
          style: typography.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: typography.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _TripTypeCard extends StatelessWidget {
  const _TripTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;

    final foreground = selected ? colors.onPrimary : colors.textPrimary;
    final mutedForeground = selected
        ? colors.onPrimary.withValues(alpha: 0.82)
        : colors.textSecondary;

    return DsPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DsDurations.normal,
        curve: DsCurves.emphasized,
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.sm,
          vertical: DsSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? null : colors.card,
          gradient: selected
              ? LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [colors.primary, colors.primaryStrong],
                )
              : null,
          borderRadius: DsRadius.large,
          border: Border.all(
            color: selected
                ? colors.primaryStrong.withValues(alpha: 0.45)
                : colors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? DsShadows.primaryGlow(dark: isDark)
              : DsShadows.soft(dark: isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? colors.onPrimary.withValues(alpha: 0.18)
                    : colors.primarySoft,
                borderRadius: DsRadius.medium,
              ),
              child: Icon(
                icon,
                size: DsConstants.iconMd,
                color: selected ? colors.onPrimary : colors.primary,
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleSmall.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodySmall.copyWith(
                      color: mutedForeground,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DsSpacing.xs),
            SizedBox(
              width: DsConstants.iconMd,
              height: DsConstants.iconMd,
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(foreground),
                      ),
                    )
                  : Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      size: DsConstants.iconMd,
                      color: selected ? colors.onPrimary : colors.iconMuted,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    this.onChange,
  });

  final IconData icon;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final hasValue = value.trim().isNotEmpty && value != placeholder;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IconBubble(
          icon: icon,
          tone: hasValue ? colors.primary : colors.iconMuted,
        ),
        const SizedBox(width: DsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: typography.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: DsSpacing.xxs),
              Text(
                hasValue ? value : placeholder,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.bodyMedium.copyWith(
                  color: hasValue ? colors.textPrimary : colors.hint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onChange != null) ...[
          const SizedBox(width: DsSpacing.xs),
          DsButton.text(
            label: 'Change'.tr(),
            icon: DsIcons.edit,
            size: DsButtonSize.sm,
            onPressed: onChange,
          ),
        ],
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: DsRadius.medium,
      ),
      child: Icon(icon, size: DsConstants.iconSm, color: tone),
    );
  }
}
