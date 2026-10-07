import '/core/driver_online_state.dart';
import '/core/driver_order_match.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_geo_display.dart';
import '/core/driver_i18n_text.dart';
import '/core/driver_ux_widgets.dart';
import '/core/driver_work_area_resolver.dart';
import '/design_system/design_system.dart';
import '/components/driver_available_order_card.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/driver_trip_service.dart';
import '/index.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'now_model.dart';
export 'now_model.dart';

/// Create a "New Orders" page in FlutterFlow for a service provider app.
///
/// Each order item in the list should include the following:
///
/// A circular user image (avatar).
///
/// The user's name.
///
/// Number of requested hours (e.g., "Hours: 4").
///
/// Number of requested destinations (e.g., "Destinations: 2").
///
/// Total earnings for the order (e.g., "$150").
///
/// Date and time of the order (e.g., "April 28, 2025 - 2:30 PM").
///
/// A green "Accept" button aligned to the right or bottom of each item.
///
/// Use card-style list items with proper spacing, a clean layout, and mobile
/// responsiveness. Ensure the green "Accept" button is clearly visible and
/// styled to attract attention. The UI should be optimized for mobile and
/// support both Android and iOS platforms.
class NowWidget extends StatefulWidget {
  const NowWidget({super.key});

  static String routeName = 'Now';
  static String routePath = '/neworder';

  @override
  State<NowWidget> createState() => _NowWidgetState();
}

class _NowWidgetState extends State<NowWidget> with TickerProviderStateMixin {
  late NowModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NowModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await DriverOrderMatch.ensureDriverCountry();
      // Soft-heal: busy banner with no live trip (or lost revOrder).
      final looksBusy = valueOrDefault<bool>(
            currentUserDocument?.mndonNewacc, false) ==
          true;
      if (looksBusy || FFAppState().revOrder != null) {
        await DriverTripService.reconcileBusyState();
        if (mounted) safeSetState(() {});
      }
      try {
        currentUserLocationValue = await getCurrentUserLocation(
          defaultLocation: const LatLng(0.0, 0.0),
        );
        if (currentUserLocationValue != null &&
            currentUserLocationValue!.latitude == 0 &&
            currentUserLocationValue!.longitude == 0) {
          currentUserLocationValue = currentUserDocument?.loceshnMndobNow;
        }
      } catch (_) {
        currentUserLocationValue = currentUserDocument?.loceshnMndobNow;
      }
      if (currentUserLocationValue != null) {
        await DriverWorkAreaResolver.refreshFromGps(
          position: currentUserLocationValue,
          gpsUpdatedAt: DateTime.now(),
        );
      } else {
        await DriverWorkAreaResolver.applyRegistrationFallback();
      }
      if (mounted) safeSetState(() {});
      _model.ngl = await querySettingsRecordOnce(
        queryBuilder: (settingsRecord) => settingsRecord.where(
          'id',
          isEqualTo: 1,
        ),
        singleRecord: true,
      ).then((s) => s.firstOrNull);
      if ((_model.ngl?.ngl == false) &&
          (valueOrDefault(currentUserDocument?.nameCar, '') == null ||
              valueOrDefault(currentUserDocument?.nameCar, '') == '')) {
        if (!mounted) return;
        await DriverDialogs.showAlert(
          context,
          title: driverTr(context, 'Update vehicle info'),
          message: driverTr(context, 'Update vehicle info to accept orders'),
          type: DriverMessageType.warning,
          confirmLabel: driverTr(context, 'Update'),
        );

        if (mounted) context.pushNamed(ProfileUpdatePageWidget.routeName);
      }
    });

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.bounceOut,
            delay: 0.0.ms,
            duration: 930.0.ms,
            begin: const Offset(-29.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _searchingPanel({
    required bool isOnline,
    VoidCallback? onGoOnline,
  }) {
    final cached = currentUserDocument?.mndobVillText ?? '';
    final ref = DriverWorkAreaResolver.workVillageRef();
    if (ref == null) {
      return DriverSearchingOrdersPanel(
        areaName: driverSearchingAreaLabel(
          localeKey: driverActiveContentLocaleKey(),
          cachedText: cached,
        ),
        isOnline: isOnline,
        onGoOnline: onGoOnline,
      );
    }
    return StreamBuilder<VillagesRecord>(
      stream: VillagesRecord.getDocument(ref),
      builder: (context, snap) {
        final record = snap.data;
        return DriverSearchingOrdersPanel(
          areaName: driverSearchingAreaLabel(
            localeKey: driverActiveContentLocaleKey(),
            namesI18n: record?.namesI18n ?? const {},
            legacyNaim: record?.naim ?? '',
            cachedText: cached,
          ),
          isOnline: isOnline,
          onGoOnline: onGoOnline,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return AuthUserStreamWidget(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: context.dsColors.scaffold,
            appBar: DriverMainAppBar(
              title: FFLocalizations.of(context).getText(
                '604z4t02' /* New requests */,
              ),
            ),
            body: SafeArea(
              top: true,
              child: StreamBuilder<List<SettingsRecord>>(
                stream: querySettingsRecord(
                  queryBuilder: (settingsRecord) => settingsRecord.where(
                    'id',
                    isEqualTo: 1,
                  ),
                  singleRecord: true,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData &&
                      !snapshot.hasError) {
                    return const Center(child: DsLoading());
                  }
                  // Settings doc is optional — continue even if missing/error.
                  List<SettingsRecord> columnSettingsRecordList =
                      snapshot.data ?? const <SettingsRecord>[];
                  final columnSettingsRecord =
                      columnSettingsRecordList.isNotEmpty
                          ? columnSettingsRecordList.first
                          : null;

                  return SingleChildScrollView(
                    child: DriverContentWidth(
                      child: DriverPagePadding(
                        top: DsSpacing.sm,
                        bottom: DsSpacing.lg,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (DriverOnlineState.showInactiveBanner)
                              DsCard(
                                margin: const EdgeInsets.only(
                                  bottom: DsSpacing.md,
                                ),
                                color: context.dsColors.card,
                                child: Text(
                                  driverTr(
                                    context,
                                    DriverOnlineState.isApproved
                                        ? 'To receive orders, activate online mode now.'
                                        : 'This account is inactive. For further assistance, please contact customer support.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style:
                                      context.dsTypography.bodyMedium.copyWith(
                                    color: context.dsColors.error,
                                  ),
                                ),
                              ),
                            if (valueOrDefault<bool>(
                                    currentUserDocument?.mndonNewacc, false) ==
                                true)
                              DsCard(
                                margin: const EdgeInsets.only(
                                  bottom: DsSpacing.md,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'blsrkk80' /* You cannot view new orders until you complete the current order */,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: context.dsTypography.bodyMedium
                                          .copyWith(
                                        color: context.dsColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    DsSpacing.gapSm,
                                    DsButton.primary(
                                      label:
                                          FFLocalizations.of(context).getText(
                                        'vzhycrvb' /* View order */,
                                      ),
                                      icon: Icons.receipt_long_rounded,
                                      enabled: FFAppState().revOrder != null,
                                      onPressed: FFAppState().revOrder == null
                                          ? null
                                          : () async {
                                              context.pushNamed(
                                                TfaselOrserWidget.routeName,
                                                queryParameters: {
                                                  'id': serializeParam(
                                                    FFAppState().revOrder,
                                                    ParamType.DocumentReference,
                                                  ),
                                                },
                                              );
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            // Offline: CTA to go online. Online: StreamBuilder owns
                            // searching / empty / error / list (avoid stacking both).
                            if (!DriverOnlineState.canReceiveOrders &&
                                (valueOrDefault<bool>(
                                        currentUserDocument?.mndonNewacc,
                                        false) ==
                                    false))
                              _searchingPanel(
                                isOnline: false,
                                onGoOnline: () async {
                                  final result =
                                      await DriverOnlineState.goOnline();
                                  if (!result.ok && context.mounted) {
                                    await DriverDialogs.showAlert(
                                      context,
                                      title: driverTr(context, 'Error'),
                                      message: driverTrOrFallback(context, result.message, 'Something went wrong. Please try again.'),
                                      type: DriverMessageType.error,
                                    );
                                  }
                                  if (mounted) safeSetState(() {});
                                },
                              ),
                            if (DriverOnlineState.canReceiveOrders)
                              StreamBuilder<List<OrderRecord>>(
                                stream: queryOrderRecord(
                                  queryBuilder: DriverOrderMatch.queryBuilder(),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    final err = snapshot.error;
                                    final detail = err is FirebaseException
                                        ? '${err.code}'
                                        : err.toString();
                                    return DriverEmptyState(
                                      title: driverTr(context, 'Error'),
                                      message:
                                          '${driverTr(context, 'Something went wrong. Please try again.')}\n($detail)',
                                      icon: Icons.cloud_off_rounded,
                                      actionLabel: driverTr(context, 'Retry'),
                                      onAction: () => safeSetState(() {}),
                                    );
                                  }
                                  if (!snapshot.hasData) {
                                    return _searchingPanel(isOnline: true);
                                  }
                                  List<OrderRecord> listViewOrderRecordList =
                                      DriverOrderMatch.rankForDriver(
                                    snapshot.data!,
                                    driverCityOrVillage:
                                        currentUserDocument?.mndobVill,
                                    driverPosition: currentUserLocationValue ??
                                        currentUserDocument?.loceshnMndobNow,
                                  );

                                  if (listViewOrderRecordList.isEmpty) {
                                    return _searchingPanel(isOnline: true);
                                  }

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    primary: false,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount: listViewOrderRecordList.length,
                                    itemBuilder: (context, listViewIndex) {
                                      final listViewOrderRecord =
                                          listViewOrderRecordList[listViewIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: DriverAvailableOrderCard(
                                          order: listViewOrderRecord,
                                          driverLocation:
                                              currentUserLocationValue ??
                                                  currentUserDocument
                                                      ?.loceshnMndobNow,
                                          onTap: () async {
                                            context.pushNamed(
                                              TfaselOrserWidget.routeName,
                                              queryParameters: {
                                                'id': serializeParam(
                                                  listViewOrderRecord.reference,
                                                  ParamType.DocumentReference,
                                                ),
                                              }.withoutNulls,
                                            );
                                          },
                                          onAccept: () => _acceptAvailableOrder(
                                            listViewOrderRecord,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptAvailableOrder(OrderRecord order) async {
    currentUserLocationValue = await getCurrentUserLocation(
      defaultLocation: const LatLng(0.0, 0.0),
    );
    if (!mounted) return;
    final confirmed = await DriverDialogs.showConfirm(
      context,
      title: driverTr(context, 'Confirm acceptance'),
      message: driverTr(
        context,
        'Are you sure you want to accept this order?',
      ),
      confirmLabel: driverTr(context, 'Confirm acceptance'),
      cancelLabel: driverTr(context, 'No'),
    );
    if (!confirmed || !mounted) return;

    currentUserLocationValue = await getCurrentUserLocation(
      defaultLocation: const LatLng(0.0, 0.0),
    );
    _model.soundPlayer ??= AudioPlayer();
    if (_model.soundPlayer!.playing) {
      await _model.soundPlayer!.stop();
    }
    _model.soundPlayer!.setVolume(1.0);
    _model.soundPlayer!
        .setAsset('assets/audios/835880__matustrm__completed.wav')
        .then((_) => _model.soundPlayer!.play());

    final acceptResult = await DriverTripService.acceptOrder(
      order: order,
      driverLocation: currentUserLocationValue,
      onStateChanged: () => safeSetState(() {}),
    );
    if (!acceptResult.ok) {
      if (!mounted) return;
      await DriverDialogs.showAlert(
        context,
        title: driverTr(context, 'Unable to accept'),
        message: acceptResult.message ??
            driverTr(
              context,
              'Could not update the booking. Please try again.',
            ),
        type: DriverMessageType.error,
      );
      return;
    }
    if (!mounted) return;
    await context.pushNamed(
      TfaselOrserWidget.routeName,
      queryParameters: {
        'id': serializeParam(
          order.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }
}
