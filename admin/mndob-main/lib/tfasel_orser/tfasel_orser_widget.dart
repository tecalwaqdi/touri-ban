import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/components/review_screen_widget.dart';
import '/components/taim_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/core/driver_map_actions.dart';
import '/components/driver_trip_actions_card.dart';
import '/components/driver_trip_details_banner.dart';
import '/core/toury_system_status_codes.dart';
import '/components/driver_trip_map_panel.dart';
import '/components/driver_trip_plan_panel.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/core/driver_country_service.dart';
import '/core/driver_i18n.dart';
import '/core/toury_country_registry.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_navigation_service.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_trip_wake_scope.dart';
import '/core/driver_trip_service.dart';
import '/core/driver_payment_labels.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:styled_divider/styled_divider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tfasel_orser_model.dart';
export 'tfasel_orser_model.dart';

class TfaselOrserWidget extends StatefulWidget {
  const TfaselOrserWidget({
    super.key,
    required this.id,
  });

  final DocumentReference? id;

  static String routeName = 'TfaselOrser';
  static String routePath = '/tfaselOrser';

  @override
  State<TfaselOrserWidget> createState() => _TfaselOrserWidgetState();
}

class _TfaselOrserWidgetState extends State<TfaselOrserWidget>
    with TickerProviderStateMixin {
  late TfaselOrserModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  final animationsMap = <String, AnimationInfo>{};
  String? _destFingerprint;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TfaselOrserModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.isnot = false;
      safeSetState(() {});
    });

    animationsMap.addAll({
      'rowOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(-2.0, 1.0),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(1.0, 1.0),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          RotateEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 60.0),
            end: Offset(0.0, 0.0),
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

    final orderRef = widget.id;
    if (orderRef == null) {
      return Scaffold(
        backgroundColor: context.dsColors.scaffold,
        appBar: AppBar(
          backgroundColor: context.dsColors.primary,
          title: Text(
            driverTr(context, 'Error'),
            style: context.dsTypography.titleMedium.copyWith(
              color: context.dsColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              driverTr(context, 'Something went wrong. Please try again.'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<OrderRecord>(
      stream: OrderRecord.getDocument(orderRef),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: context.dsColors.scaffold,
            appBar: AppBar(
              backgroundColor: context.dsColors.primary,
              title: Text(
                driverTr(context, 'Error'),
                style: context.dsTypography.titleMedium.copyWith(
                  color: context.dsColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      driverTr(
                        context,
                        'Something went wrong. Please try again.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    DsButton.primary(
                      label: driverTr(context, 'Retry'),
                      onPressed: () => safeSetState(() {}),
                      expanded: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: context.dsColors.scaffold,
            body: const Center(child: DsLoading()),
          );
        }

        final tfaselOrserOrderRecord = snapshot.data!;

        void onDestinationMaybeChanged(OrderRecord order) {
          final fp = order.destinationsFingerprint();
          if (_destFingerprint == null) {
            _destFingerprint = fp;
            return;
          }
          if (_destFingerprint != fp && mounted) {
            _destFingerprint = fp;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    driverTr(
                      context,
                      'Destination updated by customer — review the route and details.',
                    ),
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            });
          }
        }

        onDestinationMaybeChanged(tfaselOrserOrderRecord);

        final keepAwake = DriverTripService.isActiveTripForCurrentDriver(
            tfaselOrserOrderRecord);

        return DriverTripWakeScope(
          enabled: keepAwake,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: context.dsColors.scaffold,
              appBar: AppBar(
                backgroundColor: context.dsColors.primary,
                automaticallyImplyLeading: true,
                iconTheme: IconThemeData(color: context.dsColors.onPrimary),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverTr(context, 'Order details'),
                      style: context.dsTypography.titleMedium.copyWith(
                        color: context.dsColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      () {
                        final statusKey =
                            TourySystemStatusCodes.displayHalhKeyForCode(
                          DriverTripActionGates.codeOf(
                            tfaselOrserOrderRecord.snapshotData,
                            tfaselOrserOrderRecord.halhText,
                          ),
                        );
                        final statusLabel = statusKey.isEmpty
                            ? tfaselOrserOrderRecord.halhText
                            : driverTr(context, statusKey);
                        return '# ${tfaselOrserOrderRecord.iDorder} · $statusLabel';
                      }(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.dsTypography.bodySmall.copyWith(
                        color:
                            context.dsColors.onPrimary.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                actions: [],
                centerTitle: false,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              body: SafeArea(
                top: true,
                // Single stream only (outer). Nested getDocument listen was
                // blanking the body on permission-denied while AppBar still
                // showed cached title.
                child: Builder(
                  builder: (context) {
                    final columnOrderRecord = tfaselOrserOrderRecord;

                    return ColoredBox(
                      color: context.dsColors.scaffold,
                      child: DriverContentWidth(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              DriverTripDetailsBanner(
                                order: columnOrderRecord,
                                showArrivalButton: false,
                                onArrived: () => safeSetState(() {}),
                              ),
                              DriverTripActionsCard(
                                order: columnOrderRecord,
                                onChanged: () => safeSetState(() {}),
                              ),
                              AuthUserStreamWidget(
                                builder: (context) => DriverTripMapPanel(
                                  order: columnOrderRecord,
                                  driverLocation:
                                      columnOrderRecord.driverLivePosition ??
                                          currentUserDocument?.loceshnMndobNow,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  DsSpacing.md,
                                  DsSpacing.xs,
                                  DsSpacing.md,
                                  DsSpacing.xxs,
                                ),
                                child: DsButton.primary(
                                  label: driverTr(
                                      context, 'Open route in Google Maps'),
                                  icon: Icons.directions_rounded,
                                  expanded: true,
                                  size: DsButtonSize.lg,
                                  onPressed: () {
                                    final loc = currentUserLocationValue ??
                                        columnOrderRecord.driverLivePosition;
                                    DriverNavigationService.openOrderRoute(
                                      waypoints:
                                          columnOrderRecord.routeWaypoints(
                                        driverOverride: loc,
                                      ),
                                      driverOrigin: loc,
                                      orderRef: columnOrderRecord.reference,
                                    );
                                  },
                                ),
                              ),
                              DriverTripPlanPanel(order: columnOrderRecord),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: context.dsColors.card,
                                    borderRadius: DsRadius.large,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if ((columnOrderRecord.halhText ==
                                                'مكتمل') &&
                                            (columnOrderRecord.mndobUser ==
                                                currentUserReference))
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            child: Material(
                                              color: Colors.transparent,
                                              elevation: 2.0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: DsRadius.large,
                                              ),
                                              child: Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: context.dsColors.card,
                                                  borderRadius: DsRadius.large,
                                                ),
                                                child: Visibility(
                                                  visible: columnOrderRecord
                                                          .halhText ==
                                                      'مكتمل',
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                16.0,
                                                                16.0,
                                                                16.0,
                                                                16.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            '9xb7o9cv' /* Trip Status */,
                                                          ),
                                                          style: context
                                                              .dsTypography
                                                              .titleMedium
                                                              .copyWith(
                                                            color: context
                                                                .dsColors
                                                                .textPrimary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Container(
                                                              width: 120.0,
                                                              height: 120.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: context
                                                                    .dsColors
                                                                    .primarySoft,
                                                                shape: BoxShape
                                                                    .circle,
                                                                border:
                                                                    Border.all(
                                                                  color: context
                                                                      .dsColors
                                                                      .primary,
                                                                  width: 2.0,
                                                                ),
                                                              ),
                                                              child: Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        16.0,
                                                                        16.0,
                                                                        16.0,
                                                                        16.0),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .check_circle_outline,
                                                                      color: context
                                                                          .dsColors
                                                                          .primary,
                                                                      size:
                                                                          40.0,
                                                                    ),
                                                                    Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        '5o8uxjyd' /* Completed */,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: context
                                                                          .dsTypography
                                                                          .bodyLarge
                                                                          .copyWith(
                                                                        color: context
                                                                            .dsColors
                                                                            .primary,
                                                                      ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      height:
                                                                          8.0)),
                                                                ),
                                                              ),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 16.0)),
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 12.0)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (DriverTripActionGates.isCompletedListItem(
                                                DriverTripActionGates.codeOf(
                                                  columnOrderRecord.snapshotData,
                                                  columnOrderRecord.halhText,
                                                ),
                                                columnOrderRecord.halhText,
                                              ) &&
                                            (columnOrderRecord.mndobUser ==
                                                currentUserReference) &&
                                            (columnOrderRecord
                                                    .reviewMndobsend ==
                                                false))
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              DsButton.primary(
                                                label:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  '2tfu4awd' /* Customer Rating */,
                                                ),
                                                icon:
                                                    Icons.rate_review_outlined,
                                                onPressed: () async {
                                                  await showModalBottomSheet(
                                                    isScrollControlled: true,
                                                    backgroundColor: context
                                                        .dsColors.surface,
                                                    context: context,
                                                    builder: (context) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          FocusScope.of(context)
                                                              .unfocus();
                                                          FocusManager.instance
                                                              .primaryFocus
                                                              ?.unfocus();
                                                        },
                                                        child: Padding(
                                                          padding: MediaQuery
                                                              .viewInsetsOf(
                                                                  context),
                                                          child: Container(
                                                            height: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .height *
                                                                0.77,
                                                            child:
                                                                ReviewScreenWidget(
                                                              revClent:
                                                                  columnOrderRecord
                                                                      .user,
                                                              imgUser:
                                                                  columnOrderRecord
                                                                      .imgProfileClent,
                                                              naim: columnOrderRecord
                                                                  .naimUserText,
                                                              idOrder: orderRef,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ).then((value) =>
                                                      safeSetState(() {}));
                                                },
                                              ),
                                            ].divide(SizedBox(width: 8.0)),
                                          ),
                                        if ((columnOrderRecord.halhOrderMndob ==
                                                HalhOrder.Accepted) &&
                                            (columnOrderRecord.mndobUser ==
                                                currentUserReference))
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 7.0, 0.0, 0.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  width: 60.0,
                                                  height: 60.0,
                                                  decoration: BoxDecoration(
                                                    color: context
                                                        .dsColors.primarySoft,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30.0),
                                                      child: Image(
                                                        image: (columnOrderRecord
                                                                        .imgProfileClent !=
                                                                    null &&
                                                                columnOrderRecord
                                                                    .imgProfileClent!
                                                                    .isNotEmpty)
                                                            ? NetworkImage(
                                                                columnOrderRecord
                                                                    .imgProfileClent!)
                                                            : const AssetImage(
                                                                    'assets/images/logo.png')
                                                                as ImageProvider,
                                                        fit: BoxFit.cover,
                                                      )),
                                                ),
                                                Flexible(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: StyledDivider(
                                                          color: context
                                                              .dsColors
                                                              .textPrimary,
                                                          lineStyle:
                                                              DividerLineStyle
                                                                  .dotted,
                                                        ),
                                                      ),
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              columnOrderRecord
                                                                  .naimUserText,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 30,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () {
                                                              DriverMapActions
                                                                  .focusLocationHint(
                                                                context,
                                                                columnOrderRecord
                                                                    .lokeshn,
                                                                title: driverTr(
                                                                    context,
                                                                    'Customer location on map'),
                                                              );
                                                            },
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .location_on_sharp,
                                                                  color: context
                                                                      .dsColors
                                                                      .success,
                                                                  size: 25.0,
                                                                ),
                                                                const SizedBox(
                                                                    width: 6),
                                                                Text(
                                                                  driverTr(
                                                                      context,
                                                                      'Location'),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: context
                                                                      .dsTypography
                                                                      .bodyMedium
                                                                      .copyWith(
                                                                    color: context
                                                                        .dsColors
                                                                        .success,
                                                                    fontSize:
                                                                        18.0,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if ((columnOrderRecord
                                                                  .halhText ==
                                                              'مقبول') &&
                                                          (columnOrderRecord
                                                                  .mndobUser ==
                                                              currentUserReference))
                                                        const SizedBox(
                                                            height: 10),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                'qyrydpsi' /* The customer is currently wait... */,
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: context
                                                                  .dsTypography
                                                                  .bodyMedium
                                                                  .copyWith(
                                                                color: context
                                                                    .dsColors
                                                                    .textSecondary,
                                                                fontSize: 10.0,
                                                              ),
                                                            ).animateOnPageLoad(
                                                                animationsMap[
                                                                    'textOnPageLoadAnimation1']!),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ).animateOnPageLoad(
                                                          animationsMap[
                                                              'rowOnPageLoadAnimation']!),
                                                      if (columnOrderRecord
                                                              .halhOrderMndob ==
                                                          HalhOrder.Accepted)
                                                        InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            await launchUrl(Uri(
                                                              scheme: 'tel',
                                                              path:
                                                                  '0${columnOrderRecord.phoneNumper.toString()}',
                                                            ));
                                                          },
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Icon(
                                                                Icons.phone,
                                                                color: context
                                                                    .dsColors
                                                                    .textSecondary,
                                                                size: 16.0,
                                                              ),
                                                              InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap:
                                                                    () async {
                                                                  await launchUrl(
                                                                      Uri(
                                                                    scheme:
                                                                        'tel',
                                                                    path:
                                                                        '0${columnOrderRecord.phoneNumper.toString()}',
                                                                  ));
                                                                },
                                                                child: Text(
                                                                  '0${columnOrderRecord.phoneNumper.toString()}',
                                                                  style: context
                                                                      .dsTypography
                                                                      .bodyMedium
                                                                      .copyWith(
                                                                    color: context
                                                                        .dsColors
                                                                        .textSecondary,
                                                                  ),
                                                                ),
                                                              ),
                                                            ].divide(SizedBox(
                                                                width: 8.0)),
                                                          ),
                                                        ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          FutureBuilder<int>(
                                                            future:
                                                                queryChatRecordCount(
                                                              queryBuilder:
                                                                  (chatRecord) =>
                                                                      chatRecord
                                                                          .where(
                                                                            'idorder',
                                                                            isEqualTo:
                                                                                columnOrderRecord.reference,
                                                                          )
                                                                          .where(
                                                                            'user1',
                                                                            isNotEqualTo:
                                                                                currentUserReference,
                                                                          ),
                                                            ),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                  .hasError) {
                                                                return const SizedBox
                                                                    .shrink();
                                                              }
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return Center(
                                                                  child:
                                                                      SizedBox(
                                                                    width: 50.0,
                                                                    height:
                                                                        50.0,
                                                                    child:
                                                                        SpinKitPulse(
                                                                      color: context
                                                                          .dsColors
                                                                          .primary,
                                                                      size:
                                                                          50.0,
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                              int rowCount =
                                                                  snapshot
                                                                      .data!;

                                                              return InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap:
                                                                    () async {
                                                                  context
                                                                      .pushNamed(
                                                                    ChatWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'idorder':
                                                                          serializeParam(
                                                                        columnOrderRecord
                                                                            .reference,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                      'phoneClent':
                                                                          serializeParam(
                                                                        columnOrderRecord
                                                                            .phoneNumper,
                                                                        ParamType
                                                                            .int,
                                                                      ),
                                                                      'iduserclent':
                                                                          serializeParam(
                                                                        columnOrderRecord
                                                                            .user,
                                                                        ParamType
                                                                            .DocumentReference,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .chat,
                                                                      color: context
                                                                          .dsColors
                                                                          .textSecondary,
                                                                      size:
                                                                          16.0,
                                                                    ),
                                                                    Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'go8b77km' /* Chat */,
                                                                      ),
                                                                      style: context
                                                                          .dsTypography
                                                                          .bodyMedium
                                                                          .copyWith(
                                                                        color: context
                                                                            .dsColors
                                                                            .textPrimary,
                                                                      ),
                                                                    ),
                                                                    if (rowCount >=
                                                                        1)
                                                                      Align(
                                                                        alignment: AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                        child:
                                                                            Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              0.0,
                                                                              0.0,
                                                                              0.0,
                                                                              4.0),
                                                                          child:
                                                                              Text(
                                                                            rowCount.toString(),
                                                                            style:
                                                                                context.dsTypography.bodyMedium.copyWith(
                                                                              color: context.dsColors.error,
                                                                            ),
                                                                          ).animateOnPageLoad(animationsMap['textOnPageLoadAnimation2']!),
                                                                        ),
                                                                      ),
                                                                  ].divide(SizedBox(
                                                                      width:
                                                                          8.0)),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: StyledDivider(
                                                          color: context
                                                              .dsColors
                                                              .textPrimary,
                                                          lineStyle:
                                                              DividerLineStyle
                                                                  .dotted,
                                                        ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(height: 4.0)),
                                                  ),
                                                ),
                                              ].divide(SizedBox(width: 16.0)),
                                            ),
                                          ),
                                        // Legacy action row replaced by DriverTripActionsCard.
                                        if (false)
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 11.0, 0.0, 11.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (DriverTripActionGates
                                                        .canCancel(
                                                      DriverTripActionGates
                                                          .codeOf(
                                                        columnOrderRecord
                                                            .snapshotData,
                                                        columnOrderRecord
                                                            .halhText,
                                                      ),
                                                      columnOrderRecord
                                                          .halhText,
                                                    ) &&
                                                    DriverTripActionGates
                                                        .isAssignedToCurrentDriver(
                                                      columnOrderRecord
                                                          .mndobUser,
                                                    ))
                                                  Expanded(
                                                    child: DsButton.danger(
                                                      label: FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'ar2aaxne' /* Cancel Order */,
                                                      ),
                                                      icon: Icons.cancel,
                                                      expanded: true,
                                                      onPressed: () async {
                                                        currentUserLocationValue =
                                                            await getCurrentUserLocation(
                                                                defaultLocation:
                                                                    LatLng(0.0,
                                                                        0.0));
                                                        var confirmDialogResponse =
                                                            await showDialog<
                                                                    bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (alertDialogContext) {
                                                                    return AlertDialog(
                                                                      title:
                                                                          Text(
                                                                        driverTr(
                                                                          context,
                                                                          'Confirm cancel',
                                                                        ),
                                                                      ),
                                                                      content:
                                                                          Text(
                                                                        driverTr(
                                                                          context,
                                                                          'Are you sure you want to cancel this request?',
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              false),
                                                                          child:
                                                                              Text(
                                                                            driverTr(
                                                                              context,
                                                                              'No',
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              true),
                                                                          child:
                                                                              Text(
                                                                            driverTr(
                                                                              context,
                                                                              'Confirm',
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ) ??
                                                                false;
                                                        if (confirmDialogResponse) {
                                                          final result =
                                                              await DriverTripService
                                                                  .cancelTrip(
                                                            order:
                                                                columnOrderRecord,
                                                            driverLocation:
                                                                currentUserLocationValue,
                                                          );
                                                          if (!result.ok &&
                                                              context.mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  driverTr(
                                                                    context,
                                                                    result.message ??
                                                                        'Something went wrong. Please try again.',
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                            return;
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                if (columnOrderRecord
                                                        .halhText ==
                                                    'بإنتظار قبول المندوب')
                                                  Expanded(
                                                    child: DsButton.primary(
                                                      label: FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'hctr02e1' /* Accept Order */,
                                                      ),
                                                      expanded: true,
                                                      onPressed: () async {
                                                        currentUserLocationValue =
                                                            await getCurrentUserLocation(
                                                                defaultLocation:
                                                                    LatLng(0.0,
                                                                        0.0));
                                                        var confirmDialogResponse =
                                                            await showDialog<
                                                                    bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (alertDialogContext) {
                                                                    return AlertDialog(
                                                                      title: Text(driverTr(
                                                                          context,
                                                                          'Confirm acceptance')),
                                                                      content: Text(driverTr(
                                                                          context,
                                                                          'Are you sure you want to accept this order?')),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              false),
                                                                          child: Text(driverTr(
                                                                              context,
                                                                              'No')),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              true),
                                                                          child: Text(driverTr(
                                                                              context,
                                                                              'Confirm acceptance')),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ) ??
                                                                false;
                                                        if (confirmDialogResponse) {
                                                          final acceptResult =
                                                              await DriverTripService
                                                                  .acceptOrder(
                                                            order:
                                                                columnOrderRecord,
                                                            driverLocation:
                                                                currentUserLocationValue,
                                                            onStateChanged: () =>
                                                                safeSetState(
                                                                    () {}),
                                                          );
                                                          if (!acceptResult
                                                              .ok) {
                                                            if (acceptResult
                                                                        .message !=
                                                                    null &&
                                                                context
                                                                    .mounted) {
                                                              await showDialog(
                                                                context:
                                                                    context,
                                                                builder: (c) =>
                                                                    AlertDialog(
                                                                  title: Text(
                                                                    driverTr(
                                                                      context,
                                                                      'Could not accept',
                                                                    ),
                                                                  ),
                                                                  content: Text(
                                                                      acceptResult
                                                                          .message!),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.pop(c),
                                                                      child:
                                                                          Text(
                                                                        driverTr(
                                                                          context,
                                                                          'OK',
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                            return;
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                if (DriverTripActionGates
                                                        .canStart(
                                                      DriverTripActionGates
                                                          .codeOf(
                                                        columnOrderRecord
                                                            .snapshotData,
                                                        columnOrderRecord
                                                            .halhText,
                                                      ),
                                                      columnOrderRecord
                                                          .halhText,
                                                    ) &&
                                                    DriverTripActionGates
                                                        .isAssignedToCurrentDriver(
                                                      columnOrderRecord
                                                          .mndobUser,
                                                    ))
                                                  Expanded(
                                                    child: DsButton.success(
                                                      label: FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '5iq2its3' /* Start Trip */,
                                                      ),
                                                      icon: Icons.timer,
                                                      expanded: true,
                                                      size: DsButtonSize.lg,
                                                      onPressed: () async {
                                                        currentUserLocationValue =
                                                            await getCurrentUserLocation(
                                                                defaultLocation:
                                                                    LatLng(0.0,
                                                                        0.0));
                                                        var confirmDialogResponse =
                                                            await showDialog<
                                                                    bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (alertDialogContext) {
                                                                    return AlertDialog(
                                                                      title: Text(driverTr(
                                                                          context,
                                                                          'Are you sure you want to start this trip?')),
                                                                      content: Text(driverTr(
                                                                          context,
                                                                          'Please confirm you have reached the customer before starting.')),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              false),
                                                                          child: Text(driverTr(
                                                                              context,
                                                                              'No')),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              true),
                                                                          child: Text(driverTr(
                                                                              context,
                                                                              'Confirm start')),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ) ??
                                                                false;
                                                        if (confirmDialogResponse) {
                                                          await DriverTripService
                                                              .startTrip(
                                                            order:
                                                                columnOrderRecord,
                                                            driverLocation:
                                                                currentUserLocationValue,
                                                          );
                                                          if (columnOrderRecord
                                                                  .totalTaim >
                                                              0) {
                                                            await orderRef
                                                                .update(
                                                                    createOrderRecordData(
                                                              endTime: functions
                                                                  .calculateEndTime(
                                                                      getCurrentTimestamp,
                                                                      columnOrderRecord
                                                                          .totalTaim),
                                                            ));
                                                            FFAppState()
                                                                    .EndDate =
                                                                functions.calculateEndTime(
                                                                    getCurrentTimestamp,
                                                                    columnOrderRecord
                                                                        .totalTaim);
                                                          }
                                                          FFAppState()
                                                                  .startTime =
                                                              getCurrentTimestamp;
                                                          FFAppState()
                                                              .update(() {});
                                                          final customerRef =
                                                              columnOrderRecord
                                                                  .user;
                                                          if (customerRef !=
                                                              null) {
                                                            triggerPushNotification(
                                                              notificationTitle:
                                                                  driverTr(
                                                                      context,
                                                                      'Start trip'),
                                                              notificationText:
                                                                  driverTrNamed(
                                                                context,
                                                                'Trip started with driver: {name}',
                                                                {
                                                                  'name':
                                                                      currentUserDisplayName,
                                                                },
                                                              ),
                                                              userRefs: [
                                                                customerRef
                                                              ],
                                                              initialPageName:
                                                                  'tfasel_order',
                                                              parameterData: {
                                                                'idorder':
                                                                    columnOrderRecord
                                                                        .reference,
                                                              },
                                                            );
                                                          }
                                                          _model
                                                              .timer1Controller
                                                              .onResetTimer();

                                                          _model
                                                              .timer1Controller
                                                              .onStartTimer();
                                                          _model.soundPlayer1 ??=
                                                              AudioPlayer();
                                                          if (_model
                                                              .soundPlayer1!
                                                              .playing) {
                                                            await _model
                                                                .soundPlayer1!
                                                                .stop();
                                                          }
                                                          _model.soundPlayer1!
                                                              .setVolume(1.0);
                                                          _model.soundPlayer1!
                                                              .setAsset(
                                                                  'assets/audios/835880__matustrm__completed.wav')
                                                              .then((_) => _model
                                                                  .soundPlayer1!
                                                                  .play());

                                                          await showModalBottomSheet(
                                                            isScrollControlled:
                                                                true,
                                                            backgroundColor:
                                                                context.dsColors
                                                                    .surface,
                                                            barrierColor:
                                                                context.dsColors
                                                                    .surface,
                                                            context: context,
                                                            builder: (context) {
                                                              return GestureDetector(
                                                                onTap: () {
                                                                  FocusScope.of(
                                                                          context)
                                                                      .unfocus();
                                                                  FocusManager
                                                                      .instance
                                                                      .primaryFocus
                                                                      ?.unfocus();
                                                                },
                                                                child: Padding(
                                                                  padding: MediaQuery
                                                                      .viewInsetsOf(
                                                                          context),
                                                                  child:
                                                                      Container(
                                                                    height: MediaQuery.sizeOf(context)
                                                                            .height *
                                                                        0.35,
                                                                    child:
                                                                        TaimWidget(),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ).then((value) =>
                                                              safeSetState(
                                                                  () {}));
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                if (DriverTripService
                                                        .canCompleteTrip(
                                                      order: columnOrderRecord,
                                                      driverLocation:
                                                          currentUserDocument
                                                              ?.loceshnMndobNow,
                                                    ) &&
                                                    DriverTripActionGates
                                                        .isAssignedToCurrentDriver(
                                                      columnOrderRecord
                                                          .mndobUser,
                                                    ))
                                                  Expanded(
                                                    child: DsButton.success(
                                                      label: FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'nbagog2e' /* End Trip */,
                                                      ),
                                                      icon: Icons.clear_rounded,
                                                      expanded: true,
                                                      onPressed: () async {
                                                        currentUserLocationValue =
                                                            await getCurrentUserLocation(
                                                                defaultLocation:
                                                                    LatLng(0.0,
                                                                        0.0));
                                                        var confirmDialogResponse =
                                                            await showDialog<
                                                                    bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (alertDialogContext) {
                                                                    return AlertDialog(
                                                                      title: Text(driverTr(
                                                                          context,
                                                                          'Confirm')),
                                                                      content: Text(driverTr(
                                                                          context,
                                                                          'Are you sure this trip is completed?')),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              false),
                                                                          child: Text(driverTr(
                                                                              context,
                                                                              'No')),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              alertDialogContext,
                                                                              true),
                                                                          child: Text(driverTr(
                                                                              context,
                                                                              'Yes')),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ) ??
                                                                false;
                                                        if (confirmDialogResponse) {
                                                          try {
                                                            await DriverTripService
                                                                .completeTrip(
                                                              order:
                                                                  columnOrderRecord,
                                                              driverLocation:
                                                                  currentUserLocationValue,
                                                            );
                                                            if (DriverPaymentLabels
                                                                    .isCash(
                                                                  columnOrderRecord
                                                                      .paymentMethod,
                                                                ) &&
                                                                context
                                                                    .mounted) {
                                                              final confirmCash =
                                                                  await showDialog<
                                                                          bool>(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (alertDialogContext) {
                                                                          return AlertDialog(
                                                                            title:
                                                                                Text(driverTr(context, 'Confirm cash received')),
                                                                            content:
                                                                                Text(driverTr(context, 'Confirm you collected cash from the customer?')),
                                                                            actions: [
                                                                              TextButton(
                                                                                onPressed: () => Navigator.pop(alertDialogContext, false),
                                                                                child: Text(driverTr(context, 'Later')),
                                                                              ),
                                                                              TextButton(
                                                                                onPressed: () => Navigator.pop(alertDialogContext, true),
                                                                                child: Text(driverTr(context, 'Confirm')),
                                                                              ),
                                                                            ],
                                                                          );
                                                                        },
                                                                      ) ??
                                                                      false;
                                                              if (confirmCash) {
                                                                await DriverTripService
                                                                    .confirmCashCollection(
                                                                  order:
                                                                      columnOrderRecord,
                                                                );
                                                              }
                                                            }
                                                          } catch (e) {
                                                            if (context
                                                                .mounted) {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    driverTr(
                                                                      context,
                                                                      e is StateError
                                                                          ? DriverTripService.messageForCode(
                                                                              e.message)
                                                                          : 'Something went wrong. Please try again.',
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                            return;
                                                          }
                                                          _model.soundPlayer2 ??=
                                                              AudioPlayer();
                                                          if (_model
                                                              .soundPlayer2!
                                                              .playing) {
                                                            await _model
                                                                .soundPlayer2!
                                                                .stop();
                                                          }
                                                          _model.soundPlayer2!
                                                              .setVolume(1.0);
                                                          _model.soundPlayer2!
                                                              .setAsset(
                                                                  'assets/audios/634082__aj_heels__videocallend.wav')
                                                              .then((_) => _model
                                                                  .soundPlayer2!
                                                                  .play());

                                                          await actions
                                                              .stopTracking();

                                                          await currentUserReference!
                                                              .update(
                                                                  createUserRecordData(
                                                            totalApp: valueOrDefault(
                                                                    currentUserDocument
                                                                        ?.totalApp,
                                                                    0) +
                                                                columnOrderRecord
                                                                    .totalMndob +
                                                                columnOrderRecord
                                                                    .totalVat,
                                                            mndonNewacc: false,
                                                            totalMndob2: valueOrDefault(
                                                                    currentUserDocument
                                                                        ?.totalMndob2,
                                                                    0.0) +
                                                                columnOrderRecord
                                                                    .totalMndob2,
                                                          ));

                                                          context.pushNamed(
                                                              HomeWidget
                                                                  .routeName);

                                                          _model
                                                              .timer1Controller
                                                              .onStopTimer();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                              ].divide(SizedBox(width: 8.0)),
                                            ),
                                          ),
                                        Container(
                                          width: double.infinity,
                                          height: 39.96,
                                          decoration: BoxDecoration(
                                            color: context.dsColors.surface,
                                          ),
                                          child: Visibility(
                                            visible: (columnOrderRecord
                                                        .halhText ==
                                                    'تم البدء في الرحلة') &&
                                                (columnOrderRecord.mndobUser ==
                                                    currentUserReference),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    '3kxnmb46' /* Trip Notes */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textPrimary,
                                                  ),
                                                ),
                                                if (_model.isnot == true)
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            1.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  10.0,
                                                                  0.0,
                                                                  10.0,
                                                                  0.0),
                                                      child: InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          _model.isnot = false;
                                                          safeSetState(() {});
                                                        },
                                                        child: Icon(
                                                          Icons.arrow_drop_up,
                                                          color: context
                                                              .dsColors
                                                              .textPrimary,
                                                          size: 24.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (_model.isnot == false)
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            1.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  10.0,
                                                                  0.0,
                                                                  10.0,
                                                                  0.0),
                                                      child: InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          _model.isnot = true;
                                                          safeSetState(() {});
                                                        },
                                                        child: Icon(
                                                          Icons.arrow_drop_down,
                                                          color: context
                                                              .dsColors
                                                              .textPrimary,
                                                          size: 24.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if ((columnOrderRecord.halhText ==
                                                'تم البدء في الرحلة') &&
                                            (columnOrderRecord.mndobUser ==
                                                currentUserReference) &&
                                            (_model.isnot == true))
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              '2sxecdzz' /* If the customer does not arriv... */,
                                            ),
                                            style: context
                                                .dsTypography.bodyMedium
                                                .copyWith(
                                              color:
                                                  context.dsColors.textPrimary,
                                              fontSize: 10.0,
                                            ),
                                          ),
                                        if (((columnOrderRecord.halhText ==
                                                    'تم البدء في الرحلة') ||
                                                (columnOrderRecord.halhText ==
                                                    'مكتمل')) &&
                                            (columnOrderRecord.mndobUser ==
                                                currentUserReference))
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 0.0),
                                            child: Container(
                                              width: double.infinity,
                                              height: 276.84,
                                              decoration: BoxDecoration(
                                                color: context.dsColors.card,
                                                borderRadius: DsRadius.large,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 16.0, 16.0, 0.0),
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
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      4.0,
                                                                      7.0,
                                                                      4.0,
                                                                      0.0),
                                                          child: Icon(
                                                            Icons.timer_sharp,
                                                            color: context
                                                                .dsColors
                                                                .primary,
                                                            size: 16.0,
                                                          ),
                                                        ),
                                                        Text(
                                                          driverTrNamed(
                                                              context,
                                                              'Trip time for {hours} hours',
                                                              {
                                                                'hours': columnOrderRecord
                                                                    .totalTaim
                                                                    .toString()
                                                              }),
                                                          style: context
                                                              .dsTypography
                                                              .titleMedium
                                                              .copyWith(
                                                            color: context
                                                                .dsColors
                                                                .textPrimary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (currentUserEmail == '1')
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              await showModalBottomSheet(
                                                                isScrollControlled:
                                                                    true,
                                                                backgroundColor:
                                                                    context
                                                                        .dsColors
                                                                        .surface,
                                                                enableDrag:
                                                                    false,
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return GestureDetector(
                                                                    onTap: () {
                                                                      FocusScope.of(
                                                                              context)
                                                                          .unfocus();
                                                                      FocusManager
                                                                          .instance
                                                                          .primaryFocus
                                                                          ?.unfocus();
                                                                    },
                                                                    child:
                                                                        Padding(
                                                                      padding: MediaQuery
                                                                          .viewInsetsOf(
                                                                              context),
                                                                      child:
                                                                          Container(
                                                                        height: MediaQuery.sizeOf(context).height *
                                                                            0.88,
                                                                        child:
                                                                            TaimWidget(),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ).then((value) =>
                                                                  safeSetState(
                                                                      () {}));
                                                            },
                                                            child: Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                'vpvtpd0h' /* Time Remaining: */,
                                                              ),
                                                              style: context
                                                                  .dsTypography
                                                                  .bodyMedium,
                                                            ),
                                                          ),
                                                          FlutterFlowTimer(
                                                            initialTime: getCurrentTimestamp
                                                                        .millisecondsSinceEpoch <
                                                                    FFAppState()
                                                                        .EndDate!
                                                                        .millisecondsSinceEpoch
                                                                ? functions.calculateRemainingMs(
                                                                    getCurrentTimestamp,
                                                                    FFAppState()
                                                                        .EndDate!)
                                                                : 0,
                                                            getDisplayTime: (value) =>
                                                                StopWatchTimer
                                                                    .getDisplayTime(
                                                                        value,
                                                                        milliSecond:
                                                                            false),
                                                            controller: _model
                                                                .timer1Controller,
                                                            updateStateInterval:
                                                                Duration(
                                                                    milliseconds:
                                                                        1000),
                                                            onChanged: (value,
                                                                displayTime,
                                                                shouldUpdate) {
                                                              _model.timer1Milliseconds =
                                                                  value;
                                                              _model.timer1Value =
                                                                  displayTime;
                                                              if (shouldUpdate)
                                                                safeSetState(
                                                                    () {});
                                                            },
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: context
                                                                .dsTypography
                                                                .headlineSmall,
                                                          ),
                                                          AlignedTooltip(
                                                            content: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(4.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  '1jlut7ry' /* Update Time */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: context
                                                                    .dsTypography
                                                                    .bodyLarge,
                                                              ),
                                                            ),
                                                            offset: 4.0,
                                                            preferredDirection:
                                                                AxisDirection
                                                                    .down,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            backgroundColor:
                                                                context.dsColors
                                                                    .surface,
                                                            elevation: 4.0,
                                                            tailBaseWidth: 24.0,
                                                            tailLength: 12.0,
                                                            waitDuration:
                                                                Duration(
                                                                    milliseconds:
                                                                        100),
                                                            showDuration:
                                                                Duration(
                                                                    milliseconds:
                                                                        1500),
                                                            triggerMode:
                                                                TooltipTriggerMode
                                                                    .tap,
                                                            child: InkWell(
                                                              splashColor: Colors
                                                                  .transparent,
                                                              focusColor: Colors
                                                                  .transparent,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              highlightColor:
                                                                  Colors
                                                                      .transparent,
                                                              onTap: () async {
                                                                _model
                                                                    .timer1Controller
                                                                    .onStartTimer();
                                                              },
                                                              child: Icon(
                                                                Icons
                                                                    .update_sharp,
                                                                color: context
                                                                    .dsColors
                                                                    .primary,
                                                                size: 22.0,
                                                              ),
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    if (columnOrderRecord
                                                            .halhText ==
                                                        'مكتمل')
                                                      Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        11.0,
                                                                        8.0,
                                                                        11.0,
                                                                        0.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        '7atk16av' /* Start Time */,
                                                                      ),
                                                                      style: context
                                                                          .dsTypography
                                                                          .bodyMedium
                                                                          .copyWith(
                                                                        color: context
                                                                            .dsColors
                                                                            .textSecondary,
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children:
                                                                          [
                                                                        Icon(
                                                                          Icons
                                                                              .timer_outlined,
                                                                          color: context
                                                                              .dsColors
                                                                              .success,
                                                                          size:
                                                                              13.0,
                                                                        ),
                                                                        Text(
                                                                          dateTimeFormat(
                                                                            "d/M/y",
                                                                            (tfaselOrserOrderRecord.start ?? getCurrentTimestamp),
                                                                            locale:
                                                                                FFLocalizations.of(context).languageCode,
                                                                          ),
                                                                          style: context
                                                                              .dsTypography
                                                                              .bodyLarge
                                                                              .copyWith(
                                                                            color:
                                                                                context.dsColors.success,
                                                                            fontSize:
                                                                                12.0,
                                                                          ),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 8.0)),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      height:
                                                                          4.0)),
                                                                ),
                                                                Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'q5anstiz' /* End Time */,
                                                                      ),
                                                                      style: context
                                                                          .dsTypography
                                                                          .bodyMedium
                                                                          .copyWith(
                                                                        color: context
                                                                            .dsColors
                                                                            .textSecondary,
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children:
                                                                          [
                                                                        Icon(
                                                                          Icons
                                                                              .timer_off_outlined,
                                                                          color: context
                                                                              .dsColors
                                                                              .error,
                                                                          size:
                                                                              13.0,
                                                                        ),
                                                                        Text(
                                                                          dateTimeFormat(
                                                                            "d/M/y",
                                                                            (tfaselOrserOrderRecord.endTime ?? getCurrentTimestamp),
                                                                            locale:
                                                                                FFLocalizations.of(context).languageCode,
                                                                          ),
                                                                          style: context
                                                                              .dsTypography
                                                                              .bodyLarge
                                                                              .copyWith(
                                                                            color:
                                                                                context.dsColors.error,
                                                                            fontSize:
                                                                                12.0,
                                                                          ),
                                                                        ),
                                                                      ].divide(SizedBox(
                                                                              width: 8.0)),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      height:
                                                                          4.0)),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            width:
                                                                double.infinity,
                                                            height: 100.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: context
                                                                  .dsColors
                                                                  .surface,
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          11.0,
                                                                          0.0,
                                                                          11.0,
                                                                          0.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'da1x0lkt' /* Start Time */,
                                                                        ),
                                                                        style: context
                                                                            .dsTypography
                                                                            .bodyMedium
                                                                            .copyWith(
                                                                          color: context
                                                                              .dsColors
                                                                              .textSecondary,
                                                                        ),
                                                                      ),
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children:
                                                                            [
                                                                          Icon(
                                                                            Icons.timer_outlined,
                                                                            color:
                                                                                context.dsColors.success,
                                                                            size:
                                                                                13.0,
                                                                          ),
                                                                          Text(
                                                                            dateTimeFormat(
                                                                              "jm",
                                                                              (tfaselOrserOrderRecord.start ?? getCurrentTimestamp),
                                                                              locale: FFLocalizations.of(context).languageCode,
                                                                            ),
                                                                            style:
                                                                                context.dsTypography.bodyLarge.copyWith(
                                                                              color: context.dsColors.success,
                                                                              fontSize: 12.0,
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 8.0)),
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        height:
                                                                            4.0)),
                                                                  ),
                                                                  Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'uo3qzmy7' /* End Time */,
                                                                        ),
                                                                        style: context
                                                                            .dsTypography
                                                                            .bodyMedium
                                                                            .copyWith(
                                                                          color: context
                                                                              .dsColors
                                                                              .textSecondary,
                                                                        ),
                                                                      ),
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children:
                                                                            [
                                                                          Icon(
                                                                            Icons.timer_off_outlined,
                                                                            color:
                                                                                context.dsColors.error,
                                                                            size:
                                                                                13.0,
                                                                          ),
                                                                          Text(
                                                                            dateTimeFormat(
                                                                              "jm",
                                                                              (tfaselOrserOrderRecord.endTime ?? getCurrentTimestamp),
                                                                              locale: FFLocalizations.of(context).languageCode,
                                                                            ),
                                                                            style:
                                                                                context.dsTypography.bodyLarge.copyWith(
                                                                              color: context.dsColors.error,
                                                                              fontSize: 12.0,
                                                                            ),
                                                                          ),
                                                                        ].divide(SizedBox(width: 8.0)),
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        height:
                                                                            4.0)),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    if (columnOrderRecord
                                                            .halhText !=
                                                        'مكتمل')
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          AlignedTooltip(
                                                            content: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(4.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'vlbi1eee' /* Update Time */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: context
                                                                    .dsTypography
                                                                    .bodyLarge,
                                                              ),
                                                            ),
                                                            offset: 4.0,
                                                            preferredDirection:
                                                                AxisDirection
                                                                    .down,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            backgroundColor:
                                                                context.dsColors
                                                                    .surface,
                                                            elevation: 4.0,
                                                            tailBaseWidth: 24.0,
                                                            tailLength: 12.0,
                                                            waitDuration:
                                                                Duration(
                                                                    milliseconds:
                                                                        100),
                                                            showDuration:
                                                                Duration(
                                                                    milliseconds:
                                                                        1500),
                                                            triggerMode:
                                                                TooltipTriggerMode
                                                                    .tap,
                                                            child: Icon(
                                                              Icons
                                                                  .update_sharp,
                                                              color: context
                                                                  .dsColors
                                                                  .textPrimary,
                                                              size: 17.0,
                                                            ),
                                                          ),
                                                          Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'xafw6vd4' /* Trip ends at: */,
                                                            ),
                                                            style: context
                                                                .dsTypography
                                                                .bodyMedium,
                                                          ),
                                                          Text(
                                                            dateTimeFormat(
                                                              "jms",
                                                              FFAppState()
                                                                  .EndDate,
                                                              locale: FFLocalizations
                                                                      .of(context)
                                                                  .languageCode,
                                                            ),
                                                            style: context
                                                                .dsTypography
                                                                .bodyMedium
                                                                .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    if (columnOrderRecord
                                                            .halhText !=
                                                        'مكتمل')
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    8.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            SizedBox(
                                                              width: MediaQuery
                                                                          .sizeOf(
                                                                              context)
                                                                      .width *
                                                                  0.386,
                                                              child: DsButton
                                                                  .outlined(
                                                                label: FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'i7kt4eiw' /* وقت الرحلة */,
                                                                ),
                                                                icon: Icons
                                                                    .timer_sharp,
                                                                onPressed:
                                                                    () async {
                                                                  _model.soundPlayer3 ??=
                                                                      AudioPlayer();
                                                                  if (_model
                                                                      .soundPlayer3!
                                                                      .playing) {
                                                                    await _model
                                                                        .soundPlayer3!
                                                                        .stop();
                                                                  }
                                                                  _model
                                                                      .soundPlayer3!
                                                                      .setVolume(
                                                                          1.0);
                                                                  _model
                                                                      .soundPlayer3!
                                                                      .setAsset(
                                                                          'assets/audios/835880__matustrm__completed.wav')
                                                                      .then((_) => _model
                                                                          .soundPlayer3!
                                                                          .play());

                                                                  await showModalBottomSheet(
                                                                    isScrollControlled:
                                                                        true,
                                                                    backgroundColor: context
                                                                        .dsColors
                                                                        .surface,
                                                                    barrierColor: context
                                                                        .dsColors
                                                                        .surface,
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) {
                                                                      return GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          FocusScope.of(context)
                                                                              .unfocus();
                                                                          FocusManager
                                                                              .instance
                                                                              .primaryFocus
                                                                              ?.unfocus();
                                                                        },
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              MediaQuery.viewInsetsOf(context),
                                                                          child:
                                                                              Container(
                                                                            height:
                                                                                MediaQuery.sizeOf(context).height * 0.45,
                                                                            child:
                                                                                TaimWidget(),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ).then((value) =>
                                                                      safeSetState(
                                                                          () {}));
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ].divide(
                                                      SizedBox(height: 12.0)),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ].divide(SizedBox(height: 12.0)),
                                    ),
                                  ),
                                ),
                              ),
                              // Legacy Stops card replaced by DriverTripPlanPanel.
                              if (false)
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 7.0, 16.0, 0.0),
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: 2.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: DsRadius.large,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: context.dsColors.card,
                                        borderRadius: DsRadius.large,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 9.0,
                                                                0.0, 0.0),
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'lv9mwjf6' /* Stops */,
                                                      ),
                                                      style: context
                                                          .dsTypography
                                                          .titleMedium
                                                          .copyWith(
                                                        color: context.dsColors
                                                            .textPrimary,
                                                        fontSize: 14.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 9.0,
                                                                0.0, 0.0),
                                                    child: Icon(
                                                      Icons.map_outlined,
                                                      color: context
                                                          .dsColors.textPrimary,
                                                      size: 11.0,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(5.0, 9.0,
                                                                5.0, 0.0),
                                                    child: Text(
                                                      driverTrNamed(
                                                          context,
                                                          '{count} places for {hours} hours',
                                                          {
                                                            'count':
                                                                columnOrderRecord
                                                                    .addCartNumer
                                                                    .toString(),
                                                            'hours':
                                                                columnOrderRecord
                                                                    .totalTaim
                                                                    .toString(),
                                                          }),
                                                      style: context
                                                          .dsTypography
                                                          .titleMedium
                                                          .copyWith(
                                                        color: context.dsColors
                                                            .textPrimary,
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if ((columnOrderRecord
                                                          .mndobUser ==
                                                      currentUserReference) &&
                                                  (columnOrderRecord.halhText !=
                                                      'ملغي'))
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          8.0, 8.0, 8.0, 8.0),
                                                  child: Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: context
                                                          .dsColors.primarySoft,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                      border: Border.all(
                                                        color: context
                                                            .dsColors.border,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(12.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
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
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'cjuivl12' /*  to Customer Location */,
                                                                  ),
                                                                  style: context
                                                                      .dsTypography
                                                                      .bodyLarge
                                                                      .copyWith(
                                                                    color: context
                                                                        .dsColors
                                                                        .textPrimary,
                                                                    fontSize:
                                                                        12.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  height: 4.0)),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 88.78,
                                                            child: DsButton
                                                                .outlined(
                                                              label: FFLocalizations
                                                                      .of(context)
                                                                  .getText(
                                                                'xajvgc9v' /*  Map */,
                                                              ),
                                                              icon: Icons
                                                                  .maps_home_work,
                                                              onPressed: () {
                                                                DriverMapActions
                                                                    .focusLocationHint(
                                                                  context,
                                                                  columnOrderRecord
                                                                      .lokeshn,
                                                                  title: driverTr(
                                                                      context,
                                                                      'Customer location on map'),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Builder(
                                                builder: (context) {
                                                  final mkan = columnOrderRecord
                                                      .listAmakn
                                                      .toList();

                                                  return ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    primary: false,
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount: mkan.length,
                                                    itemBuilder:
                                                        (context, mkanIndex) {
                                                      final mkanItem =
                                                          mkan[mkanIndex];
                                                      return Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    8.0,
                                                                    8.0,
                                                                    8.0,
                                                                    8.0),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: context
                                                                .dsColors
                                                                .primarySoft,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            border: Border.all(
                                                              color: context
                                                                  .dsColors
                                                                  .border,
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    12.0),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
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
                                                                        driverTrNamed(
                                                                            context,
                                                                            'Go to {name}',
                                                                            {
                                                                              'name': mkanItem.naim
                                                                            }),
                                                                        style: context
                                                                            .dsTypography
                                                                            .bodyLarge
                                                                            .copyWith(
                                                                          color: context
                                                                              .dsColors
                                                                              .textPrimary,
                                                                          fontSize:
                                                                              12.0,
                                                                        ),
                                                                      ),
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children: [
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                7.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                SizedBox(
                                                                              width: 90.2,
                                                                              child: DsButton.outlined(
                                                                                label: FFLocalizations.of(context).getText(
                                                                                  'a7x02i9c' /* Site Visited */,
                                                                                ),
                                                                                onPressed: () async {
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text(
                                                                                        driverTr(context, 'Visit confirmed'),
                                                                                        style: TextStyle(
                                                                                          fontFamily: 'cairo',
                                                                                          color: context.dsColors.surface,
                                                                                        ),
                                                                                      ),
                                                                                      duration: Duration(milliseconds: 4000),
                                                                                      backgroundColor: context.dsColors.primary,
                                                                                    ),
                                                                                  );
                                                                                },
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        height:
                                                                            4.0)),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 99.88,
                                                                  child: DsButton
                                                                      .outlined(
                                                                    label: FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      '8pdc6fff' /*  Map */,
                                                                    ),
                                                                    icon: Icons
                                                                        .place_sharp,
                                                                    onPressed:
                                                                        () {
                                                                      DriverMapActions
                                                                          .focusLocationHint(
                                                                        context,
                                                                        mkanItem
                                                                            .loceshn,
                                                                        title: driverTrNamed(
                                                                            context,
                                                                            'Destination: {name}',
                                                                            {
                                                                              'name': mkanItem.naim
                                                                            }),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  width: 8.0)),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              if ((columnOrderRecord
                                                          .mndobUser ==
                                                      currentUserReference) &&
                                                  (columnOrderRecord.halhText !=
                                                      'ملغي'))
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          8.0, 8.0, 8.0, 8.0),
                                                  child: Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: context
                                                          .dsColors.primarySoft,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                      border: Border.all(
                                                        color: context
                                                            .dsColors.border,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(12.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
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
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    '9ufh7ltr' /* Return to Customer Location */,
                                                                  ),
                                                                  style: context
                                                                      .dsTypography
                                                                      .bodyLarge
                                                                      .copyWith(
                                                                    color: context
                                                                        .dsColors
                                                                        .textPrimary,
                                                                    fontSize:
                                                                        12.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  height: 4.0)),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 93.16,
                                                            child: DsButton
                                                                .outlined(
                                                              label: FFLocalizations
                                                                      .of(context)
                                                                  .getText(
                                                                'zxky4qxq' /*  Map */,
                                                              ),
                                                              icon: Icons
                                                                  .maps_home_work,
                                                              onPressed: () {
                                                                DriverMapActions
                                                                    .focusLocationHint(
                                                                  context,
                                                                  columnOrderRecord
                                                                      .lokeshn,
                                                                  title: driverTr(
                                                                      context,
                                                                      'Customer location on map'),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ].divide(SizedBox(height: 12.0)),
                                          ),
                                        ].divide(SizedBox(height: 12.0)),
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 4.0, 16.0, 0.0),
                                child: Material(
                                  color: Colors.transparent,
                                  elevation: 2.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: DsRadius.large,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: context.dsColors.card,
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 4.0,
                                          color: Color(0x33000000),
                                          offset: Offset(
                                            0.0,
                                            2.0,
                                          ),
                                        )
                                      ],
                                      borderRadius: DsRadius.large,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 7.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '8pbcsylb' /* Order Information */,
                                              ),
                                              style: context
                                                  .dsTypography.titleMedium
                                                  .copyWith(
                                                color: context
                                                    .dsColors.textPrimary,
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        5.0, 0.0, 5.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'zssd5l9x' /* Name: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                columnOrderRecord.naimUserText,
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color:
                                                      context.dsColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        5.0, 0.0, 5.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'yci4wt1i' /* Order Number: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                columnOrderRecord.iDorder,
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color:
                                                      context.dsColors.primary,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        3.0, 0.0, 6.0, 4.0),
                                                child: InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    await Clipboard.setData(
                                                        ClipboardData(
                                                            text:
                                                                columnOrderRecord
                                                                    .iDorder));
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          driverTr(context,
                                                              'Order ID copied'),
                                                          style: TextStyle(
                                                            fontFamily: 'cairo',
                                                            color: context
                                                                .dsColors
                                                                .scaffold,
                                                          ),
                                                        ),
                                                        duration: Duration(
                                                            milliseconds: 900),
                                                        backgroundColor: context
                                                            .dsColors.primary,
                                                      ),
                                                    );
                                                  },
                                                  child: Icon(
                                                    Icons.copy_all,
                                                    color: context
                                                        .dsColors.textPrimary,
                                                    size: 17.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        5.0, 0.0, 5.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'ewgx1exv' /* Vehicle Type: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                valueOrDefault<String>(
                                                  columnOrderRecord.nameCar,
                                                  driverTr(context,
                                                      'No driver assigned'),
                                                ),
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color:
                                                      context.dsColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        5.0, 0.0, 5.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'may2r116' /* Order Status: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                columnOrderRecord.halhText,
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color:
                                                      context.dsColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'flsiz002' /* Order Date: */,
                                                ),
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color: context
                                                      .dsColors.textSecondary,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        5.0, 0.0, 5.0, 0.0),
                                                child: Text(
                                                  dateTimeFormat(
                                                    "relative",
                                                    columnOrderRecord
                                                        .dataOrder!,
                                                    locale: FFLocalizations.of(
                                                            context)
                                                        .languageCode,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '4tq5mxgb' /* Total Hours: */,
                                                ),
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color: context
                                                      .dsColors.textSecondary,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        5.0, 0.0, 5.0, 0.0),
                                                child: Text(
                                                  driverTrNamed(context,
                                                      '{hours} hours', {
                                                    'hours': columnOrderRecord
                                                        .totalTaim
                                                        .toString(),
                                                  }),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            thickness: 1.0,
                                            color: context.dsColors.textPrimary,
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        6.0, 0.0, 6.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'bimoowfd' /* Payment Method: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                DriverPaymentLabels.label(
                                                  columnOrderRecord
                                                      .paymentMethod,
                                                  fallbackRaw: columnOrderRecord
                                                      .paymentMethod?.name,
                                                  context: context,
                                                ),
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color:
                                                      context.dsColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        6.0, 0.0, 6.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'n44ki8x4' /* Total Trip Amount: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formatNumber(
                                                  columnOrderRecord.total,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.automatic,
                                                  currency: TouryCountryRegistry
                                                      .currencySymbol(
                                                          DriverCountryService
                                                              .currentIso2()),
                                                ),
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color:
                                                      context.dsColors.success,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        6.0, 0.0, 6.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    '8xz5r4u1' /* Earnings: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formatNumber(
                                                  columnOrderRecord.totalMndob2,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.automatic,
                                                  currency: TouryCountryRegistry
                                                      .currencySymbol(
                                                          DriverCountryService
                                                              .currentIso2()),
                                                ),
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color:
                                                      context.dsColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        6.0, 0.0, 6.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    '87c453o4' /* App Commission & Taxes: */,
                                                  ),
                                                  style: context
                                                      .dsTypography.bodyMedium
                                                      .copyWith(
                                                    color: context
                                                        .dsColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formatNumber(
                                                  columnOrderRecord.totalApp +
                                                      columnOrderRecord
                                                          .totalVat,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.automatic,
                                                  currency: TouryCountryRegistry
                                                      .currencySymbol(
                                                          DriverCountryService
                                                              .currentIso2()),
                                                ),
                                                style: context
                                                    .dsTypography.bodyMedium
                                                    .copyWith(
                                                  color: context.dsColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (columnOrderRecord
                                                  .halhOrderMndob ==
                                              HalhOrder.Accepted)
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 12.0, 16.0, 0.0),
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  await launchURL(
                                                      'https://wa.me/message/LHEPTGBXGS7UJ1');
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        context.dsColors.card,
                                                    borderRadius:
                                                        DsRadius.large,
                                                    border: Border.all(
                                                      color: context
                                                          .dsColors.border,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      8.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Icon(
                                                            Icons
                                                                .contact_support_outlined,
                                                            color: context
                                                                .dsColors
                                                                .textPrimary,
                                                            size: 15.0,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      11.0,
                                                                      0.0,
                                                                      11.0,
                                                                      0.0),
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'zci7ub2x' /* Have a problem? Contact us dir... */,
                                                            ),
                                                            style: context
                                                                .dsTypography
                                                                .bodyMedium
                                                                .copyWith(
                                                              fontSize: 12.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ).animateOnPageLoad(animationsMap[
                                                  'containerOnPageLoadAnimation']!),
                                            ),
                                        ].divide(SizedBox(height: 12.0)),
                                      ),
                                    ),
                                  ),
                                ),
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
          ),
        );
      },
    );
  }
}
