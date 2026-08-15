import '/core/driver_country_service.dart';
import '/core/driver_trip_constants.dart';
import '/core/toury_country_registry.dart';
import '/core/driver_online_state.dart';
import '/core/driver_order_match.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_navigation_service.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_ux_widgets.dart';
import '/core/driver_pickup_eta_cache.dart';
import '/design_system/design_system.dart';
import '/core/toury_distance_format.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '/core/driver_i18n.dart';
import '/core/driver_trip_service.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
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
            begin: Offset(-29.0, 0.0),
            end: Offset(0.0, 0.0),
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
                              DriverSearchingOrdersPanel(
                                areaName: valueOrDefault(
                                  currentUserDocument?.mndobVillText,
                                  '',
                                ),
                                isOnline: false,
                                onGoOnline: () async {
                                  final result =
                                      await DriverOnlineState.goOnline();
                                  if (!result.ok && context.mounted) {
                                    await DriverDialogs.showAlert(
                                      context,
                                      title: driverTr(context, 'Error'),
                                      message: driverTr(
                                        context,
                                        result.message ??
                                            'Something went wrong. Please try again.',
                                      ),
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
                                    return DriverSearchingOrdersPanel(
                                      areaName: valueOrDefault(
                                        currentUserDocument?.mndobVillText,
                                        '',
                                      ),
                                      isOnline: true,
                                    );
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
                                    return DriverSearchingOrdersPanel(
                                      areaName: valueOrDefault(
                                        currentUserDocument?.mndobVillText,
                                        '',
                                      ),
                                      isOnline: true,
                                    );
                                  }

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    primary: false,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount: listViewOrderRecordList.length,
                                    itemBuilder: (context, listViewIndex) {
                                      final listViewOrderRecord =
                                          listViewOrderRecordList[
                                              listViewIndex];
                                      return Visibility(
                                        visible: valueOrDefault<bool>(
                                                currentUserDocument
                                                    ?.mndonNewacc,
                                                false) ==
                                            false,
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 8.0),
                                          child: InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              context.pushNamed(
                                                TfaselOrserWidget.routeName,
                                                queryParameters: {
                                                  'id': serializeParam(
                                                    listViewOrderRecord
                                                        .reference,
                                                    ParamType.DocumentReference,
                                                  ),
                                                }.withoutNulls,
                                              );
                                            },
                                            child: DsFadeSlide(
                                              child: DsCard(
                                                elevated: true,
                                                margin: EdgeInsets.zero,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Container(
                                                          width: 60.0,
                                                          height: 60.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: context
                                                                .dsColors
                                                                .primarySoft,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30.0),
                                                            child:
                                                                DriverNetworkImage(
                                                              url: listViewOrderRecord
                                                                  .imgProfileClent,
                                                              width: 60.0,
                                                              height: 60.0,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                listViewOrderRecord
                                                                    .naimUserText,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: context
                                                                    .dsTypography
                                                                    .bodyLarge
                                                                    .copyWith(
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Flexible(
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children:
                                                                          [
                                                                        Icon(
                                                                          Icons
                                                                              .try_sms_star,
                                                                          color: context
                                                                              .dsColors
                                                                              .textSecondary,
                                                                          size:
                                                                              16.0,
                                                                        ),
                                                                        Flexible(
                                                                          child:
                                                                              Text(
                                                                            valueOrDefault<String>(
                                                                              formatNumber(
                                                                                listViewOrderRecord.retengUser,
                                                                                formatType: FormatType.decimal,
                                                                                decimalType: DecimalType.automatic,
                                                                              ),
                                                                              '0',
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style:
                                                                                context.dsTypography.bodySmall.copyWith(color: context.dsColors.textSecondary),
                                                                          ),
                                                                        ),
                                                                        RatingBarIndicator(
                                                                          itemBuilder: (context, index) =>
                                                                              Icon(
                                                                            Icons.star_rounded,
                                                                            color:
                                                                                context.dsColors.primary,
                                                                          ),
                                                                          direction:
                                                                              Axis.horizontal,
                                                                          rating:
                                                                              valueOrDefault<double>(
                                                                            listViewOrderRecord.retengUser,
                                                                            0.0,
                                                                          ),
                                                                          unratedColor: context
                                                                              .dsColors
                                                                              .border,
                                                                          itemCount:
                                                                              5,
                                                                          itemSize:
                                                                              14.0,
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 4.0)),
                                                                    ),
                                                                  ),
                                                                  Flexible(
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children:
                                                                          [
                                                                        Icon(
                                                                          Icons
                                                                              .near_me_rounded,
                                                                          color: context
                                                                              .dsColors
                                                                              .textSecondary,
                                                                          size:
                                                                              16.0,
                                                                        ),
                                                                        Flexible(
                                                                          child:
                                                                              FutureBuilder<DriverPickupEta?>(
                                                                            future: DriverPickupEtaCache.forPickup(
                                                                              orderId: listViewOrderRecord.reference.id,
                                                                              driver: currentUserLocationValue ?? currentUserDocument?.loceshnMndobNow,
                                                                              pickup: listViewOrderRecord.customerPickup,
                                                                            ),
                                                                            builder: (context, snap) {
                                                                              final eta = snap.data;
                                                                              if (eta != null && eta.durationMinutes > 0) {
                                                                                final dist = touryFormatDistanceKm(eta.distanceKm);
                                                                                final trafficNote = eta.approximate
                                                                                    ? driverTr(context, 'est.')
                                                                                    : driverTr(context, 'traffic');
                                                                                return Text(
                                                                                  '$dist · ${eta.durationMinutes} ${driverTr(context, 'min')} ($trafficNote)',
                                                                                  maxLines: 1,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: context.dsTypography.bodySmall.copyWith(
                                                                                    color: context.dsColors.textSecondary,
                                                                                  ),
                                                                                );
                                                                              }
                                                                              final km = DriverOrderMatch.distanceKm(
                                                                                listViewOrderRecord,
                                                                                currentUserLocationValue ?? currentUserDocument?.loceshnMndobNow,
                                                                              );
                                                                              final label = km == null
                                                                                  ? driverTr(context, 'Distance unknown')
                                                                                  : touryFormatDistanceKm(km);
                                                                              return Text(
                                                                                label,
                                                                                maxLines: 1,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                style: context.dsTypography.bodySmall.copyWith(
                                                                                  color: context.dsColors.textSecondary,
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 4.0)),
                                                                    ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        16.0)),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .schedule,
                                                                        color: context
                                                                            .dsColors
                                                                            .textSecondary,
                                                                        size:
                                                                            16.0,
                                                                      ),
                                                                      Text(
                                                                        '${driverTr(context, 'Hours')}: ${listViewOrderRecord.totalTaim.toString()}',
                                                                        style: context
                                                                            .dsTypography
                                                                            .bodySmall
                                                                            .copyWith(color: context.dsColors.textSecondary),
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        width:
                                                                            4.0)),
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .place,
                                                                        color: context
                                                                            .dsColors
                                                                            .textSecondary,
                                                                        size:
                                                                            16.0,
                                                                      ),
                                                                      Text(
                                                                        '${driverTr(context, 'Landmarks')}: ${listViewOrderRecord.addCartNumer.toString()}',
                                                                        style: context
                                                                            .dsTypography
                                                                            .bodySmall
                                                                            .copyWith(color: context.dsColors.textSecondary),
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        width:
                                                                            4.0)),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        16.0)),
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 4.0)),
                                                          ),
                                                        ),
                                                      ].divide(SizedBox(
                                                          width: 12.0)),
                                                    ),
                                                    Divider(
                                                      thickness: 1.0,
                                                      color: context
                                                          .dsColors.border,
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Flexible(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'cyk8dp1h' /* Total Earnings */,
                                                                ),
                                                                style: context
                                                                    .dsTypography
                                                                    .labelMedium,
                                                              ),
                                                              Text(
                                                                formatNumber(
                                                                  listViewOrderRecord
                                                                      .totalMndob2,
                                                                  formatType:
                                                                      FormatType
                                                                          .decimal,
                                                                  decimalType:
                                                                      DecimalType
                                                                          .automatic,
                                                                  currency:
                                                                      ' ${TouryCountryRegistry.currencySymbol(DriverCountryService.currentIso2())} ',
                                                                ),
                                                                style: context
                                                                    .dsTypography
                                                                    .headlineSmall
                                                                    .copyWith(
                                                                  color: context
                                                                      .dsColors
                                                                      .primary,
                                                                ),
                                                              ),
                                                            ].divide(
                                                                const SizedBox(
                                                                    height:
                                                                        4.0)),
                                                          ),
                                                        ),
                                                        DsButton.success(
                                                          label: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            '7om1oakw' /* Accept */,
                                                          ),
                                                          onPressed: () async {
                                                            currentUserLocationValue =
                                                                await getCurrentUserLocation(
                                                                    defaultLocation:
                                                                        LatLng(
                                                                            0.0,
                                                                            0.0));
                                                            var confirmDialogResponse =
                                                                await DriverDialogs
                                                                    .showConfirm(
                                                              context,
                                                              title: driverTr(
                                                                  context,
                                                                  'Confirm acceptance'),
                                                              message: driverTr(
                                                                  context,
                                                                  'Are you sure you want to accept this order?'),
                                                              confirmLabel:
                                                                  driverTr(
                                                                      context,
                                                                      'Confirm acceptance'),
                                                              cancelLabel:
                                                                  driverTr(
                                                                      context,
                                                                      'No'),
                                                            );
                                                            if (confirmDialogResponse) {
                                                              currentUserLocationValue =
                                                                  await getCurrentUserLocation(
                                                                      defaultLocation:
                                                                          LatLng(
                                                                              0.0,
                                                                              0.0));
                                                              _model.soundPlayer ??=
                                                                  AudioPlayer();
                                                              if (_model
                                                                  .soundPlayer!
                                                                  .playing) {
                                                                await _model
                                                                    .soundPlayer!
                                                                    .stop();
                                                              }
                                                              _model
                                                                  .soundPlayer!
                                                                  .setVolume(
                                                                      1.0);
                                                              _model
                                                                  .soundPlayer!
                                                                  .setAsset(
                                                                      'assets/audios/835880__matustrm__completed.wav')
                                                                  .then((_) => _model
                                                                      .soundPlayer!
                                                                      .play());

                                                              final acceptResult =
                                                                  await DriverTripService
                                                                      .acceptOrder(
                                                                order:
                                                                    listViewOrderRecord,
                                                                driverLocation:
                                                                    currentUserLocationValue,
                                                                onStateChanged: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                              );
                                                              if (!acceptResult
                                                                  .ok) {
                                                                if (context
                                                                    .mounted) {
                                                                  await DriverDialogs
                                                                      .showAlert(
                                                                    context,
                                                                    title: driverTr(
                                                                        context,
                                                                        'Unable to accept'),
                                                                    message: acceptResult
                                                                            .message ??
                                                                        driverTr(
                                                                          context,
                                                                          'Could not update the booking. Please try again.',
                                                                        ),
                                                                    type: DriverMessageType
                                                                        .error,
                                                                  );
                                                                }
                                                                return;
                                                              }

                                                              // Stay in-app on trip details first.
                                                              // Google Maps is opened from the details screen button
                                                              // (auto-launch was causing the page to flash away).
                                                              final orderRef =
                                                                  listViewOrderRecord
                                                                      .reference;
                                                              if (!context
                                                                  .mounted) {
                                                                return;
                                                              }
                                                              await context
                                                                  .pushNamed(
                                                                TfaselOrserWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'id':
                                                                      serializeParam(
                                                                    orderRef,
                                                                    ParamType
                                                                        .DocumentReference,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      dateTimeFormat(
                                                        "relative",
                                                        listViewOrderRecord
                                                            .dataOrder!,
                                                        locale:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .languageCode,
                                                      ),
                                                      style: context
                                                          .dsTypography
                                                          .labelSmall
                                                          .copyWith(
                                                        color: context.dsColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ].divide(const SizedBox(
                                                      height: 12.0)),
                                                ),
                                              ),
                                            ),
                                          ).animateOnPageLoad(animationsMap[
                                              'containerOnPageLoadAnimation']!),
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
}
