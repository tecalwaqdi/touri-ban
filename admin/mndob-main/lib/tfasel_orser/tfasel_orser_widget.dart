import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/components/review_screen_widget.dart';
import '/components/taim_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/core/driver_map_actions.dart';
import '/components/driver_trip_details_banner.dart';
import '/components/driver_trip_map_panel.dart';
import '/components/driver_trip_plan_panel.dart';
import '/core/driver_design_system.dart';
import '/core/driver_i18n.dart';
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
import 'package:google_fonts/google_fonts.dart';
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

    return StreamBuilder<OrderRecord>(
      stream: OrderRecord.getDocument(widget!.id!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              title: Text(driverTr(context, 'Error')),
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
                    FilledButton(
                      onPressed: () => safeSetState(() {}),
                      child: Text(driverTr(context, 'Retry')),
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
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitPulse(
                  color: FlutterFlowTheme.of(context).secondary,
                  size: 50.0,
                ),
              ),
            ),
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
                const SnackBar(
                  content: Text(
                    'تم تحديث الوجهة من قبل العميل — راجع المسار والتفاصيل.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            });
          }
        }

        onDestinationMaybeChanged(tfaselOrserOrderRecord);

        final keepAwake =
            DriverTripService.isActiveTripForCurrentDriver(tfaselOrserOrderRecord);

        return DriverTripWakeScope(
          enabled: keepAwake,
          child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              automaticallyImplyLeading: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل الطلب',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'cairo',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                  ),
                  Text(
                    '# ${tfaselOrserOrderRecord.iDorder} · ${tfaselOrserOrderRecord.halhText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'cairo',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          letterSpacing: 0,
                        ),
                  ),
                ],
              ),
              actions: [],
              centerTitle: false,
              elevation: 0,
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
                    color: DriverBrand.surfaceColor(context),
                    child: SingleChildScrollView(
                      child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        DriverTripDetailsBanner(
                          order: columnOrderRecord,
                          onArrived: () => safeSetState(() {}),
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                final loc = currentUserLocationValue ??
                                    columnOrderRecord.driverLivePosition;
                                DriverNavigationService.openOrderRoute(
                                  waypoints: columnOrderRecord.routeWaypoints(
                                    driverOverride: loc,
                                  ),
                                  driverOrigin: loc,
                                  orderRef: columnOrderRecord.reference,
                                );
                              },
                              icon: const Icon(Icons.directions_rounded),
                              label: const Text('فتح المسار في خرائط جوجل'),
                              style: FilledButton.styleFrom(
                                backgroundColor: DriverBrand.tealDark,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      DriverBrand.radiusSm),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DriverTripPlanPanel(order: columnOrderRecord),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((columnOrderRecord.halhText == 'مكتمل') &&
                                      (columnOrderRecord.mndobUser ==
                                          currentUserReference))
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      child: Material(
                                        color: Colors.transparent,
                                        elevation: 2.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          child: Visibility(
                                            visible:
                                                columnOrderRecord.halhText ==
                                                    'مكتمل',
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 16.0, 16.0, 16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      '9xb7o9cv' /* Trip Status */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMediumFamily,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .titleMediumIsCustom,
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
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .accent4,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            width: 2.0,
                                                          ),
                                                        ),
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
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                size: 40.0,
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
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .override(
                                                                      fontFamily:
                                                                          FlutterFlowTheme.of(context)
                                                                              .bodyLargeFamily,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          !FlutterFlowTheme.of(context)
                                                                              .bodyLargeIsCustom,
                                                                    ),
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 8.0)),
                                                          ),
                                                        ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 16.0)),
                                                  ),
                                                ].divide(
                                                    SizedBox(height: 12.0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if ((columnOrderRecord.halhText == 'مكتمل') &&
                                      (columnOrderRecord.mndobUser ==
                                          currentUserReference) &&
                                      (columnOrderRecord.reviewMndobsend ==
                                          false))
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FFButtonWidget(
                                          onPressed: () async {
                                            await showModalBottomSheet(
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              context: context,
                                              builder: (context) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        MediaQuery.viewInsetsOf(
                                                            context),
                                                    child: Container(
                                                      height: MediaQuery.sizeOf(
                                                                  context)
                                                              .height *
                                                          0.77,
                                                      child: ReviewScreenWidget(
                                                        revClent:
                                                            columnOrderRecord
                                                                .user!,
                                                        imgUser:
                                                            columnOrderRecord
                                                                .imgProfileClent,
                                                        naim: columnOrderRecord
                                                            .naimUserText,
                                                        idOrder: widget!.id!,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).then(
                                                (value) => safeSetState(() {}));
                                          },
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            '2tfu4awd' /* Customer Rating */,
                                          ),
                                          icon: Icon(
                                            Icons.rate_review_outlined,
                                            size: 15.0,
                                          ),
                                          options: FFButtonOptions(
                                            width: 294.9,
                                            height: 45.0,
                                            padding: EdgeInsets.all(8.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            iconColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            color: FlutterFlowTheme.of(context)
                                                .secondary,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      fontFamily:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMediumFamily,
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts:
                                                          !FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMediumIsCustom,
                                                    ),
                                            elevation: 2.0,
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                            ),
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 8.0)),
                                    ),
                                  if ((columnOrderRecord.halhOrderMndob ==
                                          HalhOrder.Accepted) &&
                                      (columnOrderRecord.mndobUser ==
                                          currentUserReference))
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 7.0, 0.0, 0.0),
                                      child:
                                       SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child:
                                         Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 60.0,
                                              height: 60.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .accent1,
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
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 200.0,
                                                  child: StyledDivider(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    lineStyle:
                                                        DividerLineStyle.dotted,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Text(
                                                        columnOrderRecord
                                                            .naimUserText,
                                                        style: TextStyle(
                                                            fontSize: 30)),
                                                    InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () {
                                                        DriverMapActions
                                                            .focusLocationHint(
                                                          context,
                                                          columnOrderRecord
                                                              .lokeshn,
                                                          title:
                                                              'موقع العميل على الخريطة',
                                                        );
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          const SizedBox(
                                                              width: 85),
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
                                                                title:
                                                                    'موقع العميل على الخريطة',
                                                              );
                                                            },
                                                            child: Icon(
                                                              Icons
                                                                  .location_on_sharp,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .success,
                                                              size: 25.0,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                          Text(
                                                            '${columnOrderRecord.naimUserText} موقع ',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'cairo',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .success,
                                                                  fontSize:
                                                                      18.0,
                                                                  letterSpacing:
                                                                      0.0,
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
                                                  const SizedBox(height: 10),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'qyrydpsi' /* The customer is currently wait... */,
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                fontSize: 10.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMediumIsCustom,
                                                              ),
                                                    ).animateOnPageLoad(
                                                        animationsMap[
                                                            'textOnPageLoadAnimation1']!),
                                                  ].divide(
                                                      SizedBox(width: 8.0)),
                                                ).animateOnPageLoad(animationsMap[
                                                    'rowOnPageLoadAnimation']!),
                                                if (columnOrderRecord
                                                        .halhOrderMndob ==
                                                    HalhOrder.Accepted)
                                                  InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      await launchUrl(Uri(
                                                        scheme: 'tel',
                                                        path:
                                                            '0${columnOrderRecord.phoneNumper.toString()}',
                                                      ));
                                                    },
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Icon(
                                                          Icons.phone,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          size: 16.0,
                                                        ),
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
                                                          child: Text(
                                                            '0${columnOrderRecord.phoneNumper.toString()}',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMediumFamily,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMediumIsCustom,
                                                                ),
                                                          ),
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 8.0)),
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
                                                                          columnOrderRecord
                                                                              .reference,
                                                                    )
                                                                    .where(
                                                                      'user1',
                                                                      isNotEqualTo:
                                                                          currentUserReference,
                                                                    ),
                                                      ),
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return Center(
                                                            child: SizedBox(
                                                              width: 50.0,
                                                              height: 50.0,
                                                              child:
                                                                  SpinKitPulse(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondary,
                                                                size: 50.0,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        int rowCount =
                                                            snapshot.data!;
                    
                                                        return InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            context.pushNamed(
                                                              ChatWidget
                                                                  .routeName,
                                                              queryParameters: {
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
                                                                  ParamType.int,
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
                                                                Icons.chat,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                size: 16.0,
                                                              ),
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'go8b77km' /* Chat */,
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          FlutterFlowTheme.of(context)
                                                                              .bodyMediumFamily,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          !FlutterFlowTheme.of(context)
                                                                              .bodyMediumIsCustom,
                                                                    ),
                                                              ),
                                                              if (rowCount >= 1)
                                                                Align(
                                                                  alignment:
                                                                      AlignmentDirectional(
                                                                          0.0,
                                                                          0.0),
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            4.0),
                                                                    child: Text(
                                                                      rowCount
                                                                          .toString(),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).error,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            useGoogleFonts:
                                                                                !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                          ),
                                                                    ).animateOnPageLoad(
                                                                        animationsMap[
                                                                            'textOnPageLoadAnimation2']!),
                                                                  ),
                                                                ),
                                                            ].divide(SizedBox(
                                                                width: 8.0)),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 200.0,
                                                  child: StyledDivider(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    lineStyle:
                                                        DividerLineStyle.dotted,
                                                  ),
                                                ),
                                              ].divide(SizedBox(height: 4.0)),
                                            ),
                                          ].divide(SizedBox(width: 16.0)),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 11.0, 0.0, 11.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
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
                                                    columnOrderRecord.halhText,
                                                  ) &&
                                                  DriverTripActionGates
                                                      .isAssignedToCurrentDriver(
                                                    columnOrderRecord.mndobUser,
                                                  ))
                                                FFButtonWidget(
                                                  onPressed: () async {
                                                    currentUserLocationValue =
                                                        await getCurrentUserLocation(
                                                            defaultLocation:
                                                                LatLng(
                                                                    0.0, 0.0));
                                                    var confirmDialogResponse =
                                                        await showDialog<bool>(
                                                              context: context,
                                                              builder:
                                                                  (alertDialogContext) {
                                                                return AlertDialog(
                                                                  title: Text(
                                                                    driverTr(
                                                                      context,
                                                                      'Confirm cancel',
                                                                    ),
                                                                  ),
                                                                  content: Text(
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
                                                                      child: Text(
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
                                                                      child: Text(
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
                                                        ScaffoldMessenger.of(
                                                                context)
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
                                                  text: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'ar2aaxne' /* Cancel Order */,
                                                  ),
                                                  icon: Icon(
                                                    Icons.cancel,
                                                    size: 15.0,
                                                  ),
                                                  options: FFButtonOptions(
                                                    width: 150.0,
                                                    height: 45.0,
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    iconPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 0.0),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .labelMedium
                                                        .override(
                                                          fontFamily: 'cairo',
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                        ),
                                                    elevation: 2.0,
                                                  ),
                                                ),
                                              if (columnOrderRecord.halhText ==
                                                  'بإنتظار قبول المندوب')
                                                FFButtonWidget(
                                                  onPressed: () async {
                                                    currentUserLocationValue =
                                                        await getCurrentUserLocation(
                                                            defaultLocation:
                                                                LatLng(
                                                                    0.0, 0.0));
                                                    var confirmDialogResponse =
                                                        await showDialog<bool>(
                                                              context: context,
                                                              builder:
                                                                  (alertDialogContext) {
                                                                return AlertDialog(
                                                                  title: Text(
                                                                      'تأكيد القبول'),
                                                                  content: Text(
                                                                      'هل أنت متأكد من قبول هذا الطلب؟'),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(
                                                                          alertDialogContext,
                                                                          false),
                                                                      child: Text(
                                                                          'لا'),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(
                                                                          alertDialogContext,
                                                                          true),
                                                                      child: Text(
                                                                          'تأكيد القبول'),
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
                                                        order: columnOrderRecord,
                                                        driverLocation:
                                                            currentUserLocationValue,
                                                        onStateChanged: () =>
                                                            safeSetState(() {}),
                                                      );
                                                      if (!acceptResult.ok) {
                                                        if (acceptResult
                                                                    .message !=
                                                                null &&
                                                            context.mounted) {
                                                          await showDialog(
                                                            context: context,
                                                            builder: (c) =>
                                                                AlertDialog(
                                                              title: const Text(
                                                                  'تعذّر القبول'),
                                                              content: Text(
                                                                  acceptResult
                                                                      .message!),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          c),
                                                                  child: const Text(
                                                                      'حسناً'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }
                                                        return;
                                                      }
                                                    }
                                                  },
                                                  text: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'hctr02e1' /* Accept Order */,
                                                  ),
                                                  icon: Icon(
                                                    Icons
                                                        .file_download_done_outlined,
                                                    size: 15.0,
                                                  ),
                                                  options: FFButtonOptions(
                                                    width: 150.0,
                                                    height: 45.0,
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    iconPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 0.0),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .labelMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMediumFamily,
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelMediumIsCustom,
                                                        ),
                                                    elevation: 2.0,
                                                  ),
                                                ),
                                            ].divide(SizedBox(width: 8.0)),
                                          ),
                                          if (DriverTripActionGates.canStart(
                                                DriverTripActionGates.codeOf(
                                                  columnOrderRecord.snapshotData,
                                                  columnOrderRecord.halhText,
                                                ),
                                                columnOrderRecord.halhText,
                                              ) &&
                                              DriverTripActionGates
                                                  .isAssignedToCurrentDriver(
                                                columnOrderRecord.mndobUser,
                                              ))
                                            FFButtonWidget(
                                              onPressed: () async {
                                                currentUserLocationValue =
                                                    await getCurrentUserLocation(
                                                        defaultLocation:
                                                            LatLng(0.0, 0.0));
                                                var confirmDialogResponse =
                                                    await showDialog<bool>(
                                                          context: context,
                                                          builder:
                                                              (alertDialogContext) {
                                                            return AlertDialog(
                                                              title: Text(
                                                                  'هل أنت متأكد من بدء هذه الرحلة؟'),
                                                              content: Text(
                                                                  'يرجى التأكد من وصولك إلى موقع العميل قبل تأكيد البدء.'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          alertDialogContext,
                                                                          false),
                                                                  child: Text(
                                                                      'لا'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          alertDialogContext,
                                                                          true),
                                                                  child: Text(
                                                                      'تأكيد البداية'),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ) ??
                                                        false;
                                                if (confirmDialogResponse) {
                                                  await DriverTripService
                                                      .startTrip(
                                                    order: columnOrderRecord,
                                                    driverLocation:
                                                        currentUserLocationValue,
                                                  );
                                                  if (columnOrderRecord
                                                          .totalTaim >
                                                      0) {
                                                    await widget!.id!.update(
                                                        createOrderRecordData(
                                                      endTime: functions
                                                          .calculateEndTime(
                                                              getCurrentTimestamp,
                                                              columnOrderRecord
                                                                  .totalTaim),
                                                    ));
                                                    FFAppState().EndDate =
                                                        functions
                                                            .calculateEndTime(
                                                                getCurrentTimestamp,
                                                                columnOrderRecord
                                                                    .totalTaim);
                                                  }
                                                  FFAppState().startTime =
                                                      getCurrentTimestamp;
                                                  FFAppState().update(() {});
                                                  triggerPushNotification(
                                                    notificationTitle:
                                                        'بدء الرحلة',
                                                    notificationText:
                                                        'تم البدء في الرحلة مع المندوب:  ${currentUserDisplayName}',
                                                    userRefs: [
                                                      columnOrderRecord.user!
                                                    ],
                                                    initialPageName:
                                                        'tfasel_order',
                                                    parameterData: {
                                                      'idorder':
                                                          columnOrderRecord
                                                              .reference,
                                                    },
                                                  );
                                                  _model.timer1Controller
                                                      .onResetTimer();
                    
                                                  _model.timer1Controller
                                                      .onStartTimer();
                                                  _model.soundPlayer1 ??=
                                                      AudioPlayer();
                                                  if (_model
                                                      .soundPlayer1!.playing) {
                                                    await _model.soundPlayer1!
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
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryBackground,
                                                    barrierColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryBackground,
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
                                                                0.35,
                                                            child: TaimWidget(),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ).then((value) =>
                                                      safeSetState(() {}));
                                                }
                                              },
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                '5iq2its3' /* Start Trip */,
                                              ),
                                              icon: Icon(
                                                Icons.timer,
                                                size: 15.0,
                                              ),
                                              options: FFButtonOptions(
                                                width: 185.5,
                                                height: 53.3,
                                                padding: EdgeInsets.all(8.0),
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMediumFamily,
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelMediumIsCustom,
                                                        ),
                                                elevation: 2.0,
                                              ),
                                            ),
                                          if (DriverTripService.canCompleteTrip(
                                                order: columnOrderRecord,
                                                driverLocation:
                                                    currentUserDocument
                                                        ?.loceshnMndobNow,
                                              ) &&
                                              DriverTripActionGates
                                                  .isAssignedToCurrentDriver(
                                                columnOrderRecord.mndobUser,
                                              ))
                                            FFButtonWidget(
                                              onPressed: () async {
                                                currentUserLocationValue =
                                                    await getCurrentUserLocation(
                                                        defaultLocation:
                                                            LatLng(0.0, 0.0));
                                                var confirmDialogResponse =
                                                    await showDialog<bool>(
                                                          context: context,
                                                          builder:
                                                              (alertDialogContext) {
                                                            return AlertDialog(
                                                              title:
                                                                  Text('تأكيد'),
                                                              content: Text(
                                                                  'هل أنت متأكد ان هذه الرحلة مكتملة؟'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          alertDialogContext,
                                                                          false),
                                                                  child: Text(
                                                                      'لا'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          alertDialogContext,
                                                                          true),
                                                                  child: Text(
                                                                      'نعم'),
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
                                                      order: columnOrderRecord,
                                                      driverLocation:
                                                          currentUserLocationValue,
                                                    );
                                                    if (DriverPaymentLabels
                                                            .isCash(
                                                          columnOrderRecord
                                                              .paymentMethod,
                                                        ) &&
                                                        context.mounted) {
                                                      final confirmCash =
                                                          await showDialog<
                                                                  bool>(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (alertDialogContext) {
                                                                  return AlertDialog(
                                                                    title: Text(
                                                                        driverTr(
                                                                            context,
                                                                            'Confirm cash received')),
                                                                    content: Text(
                                                                        driverTr(
                                                                            context,
                                                                            'Confirm you collected cash from the customer?')),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () =>
                                                                            Navigator.pop(alertDialogContext, false),
                                                                        child: Text(
                                                                            driverTr(context, 'Later')),
                                                                      ),
                                                                      TextButton(
                                                                        onPressed: () =>
                                                                            Navigator.pop(alertDialogContext, true),
                                                                        child: Text(
                                                                            driverTr(context, 'Confirm')),
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
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            driverTr(
                                                              context,
                                                              e is StateError
                                                                  ? DriverTripService
                                                                      .messageForCode(
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
                                                      .soundPlayer2!.playing) {
                                                    await _model.soundPlayer2!
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
                    
                                                  await actions.stopTracking();
                    
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
                                                      HomeWidget.routeName);
                    
                                                  _model.timer1Controller
                                                      .onStopTimer();
                                                }
                                              },
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                'nbagog2e' /* End Trip */,
                                              ),
                                              icon: Icon(
                                                Icons.clear_rounded,
                                                size: 15.0,
                                              ),
                                              options: FFButtonOptions(
                                                width: 150.0,
                                                height: 45.0,
                                                padding: EdgeInsets.all(8.0),
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMediumFamily,
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelMediumIsCustom,
                                                        ),
                                                elevation: 2.0,
                                              ),
                                            ),
                                        ].divide(SizedBox(width: 8.0)),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 690.4,
                                    height: 39.96,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                    ),
                                    child: Visibility(
                                      visible: (columnOrderRecord.halhText ==
                                              'تم البدء في الرحلة') &&
                                          (columnOrderRecord.mndobUser ==
                                              currentUserReference),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              '3kxnmb46' /* Trip Notes */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'cairo',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                          if (_model.isnot == true)
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  1.0, 0.0),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        10.0, 0.0, 10.0, 0.0),
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
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    size: 24.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (_model.isnot == false)
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  1.0, 0.0),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        10.0, 0.0, 10.0, 0.0),
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
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
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
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 10.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .bodyMediumIsCustom,
                                          ),
                                    ),
                                  if (((columnOrderRecord.halhText ==
                                              'تم البدء في الرحلة') ||
                                          (columnOrderRecord.halhText ==
                                              'مكتمل')) &&
                                      (columnOrderRecord.mndobUser ==
                                          currentUserReference))
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: 276.84,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 16.0, 16.0, 0.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(4.0, 7.0,
                                                                4.0, 0.0),
                                                    child: Icon(
                                                      Icons.timer_sharp,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .tertiary,
                                                      size: 16.0,
                                                    ),
                                                  ),
                                                  Text(
                                                    'وقت الرحلة لـ${columnOrderRecord.totalTaim.toString()} ساعة ',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMediumFamily,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .titleMediumIsCustom,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              if (currentUserEmail == '1')
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        await showModalBottomSheet(
                                                          isScrollControlled:
                                                              true,
                                                          backgroundColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .secondaryBackground,
                                                          enableDrag: false,
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
                                                                  height: MediaQuery.sizeOf(
                                                                              context)
                                                                          .height *
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
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMediumFamily,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMediumIsCustom,
                                                                ),
                                                      ),
                                                    ),
                                                    FlutterFlowTimer(
                                                      initialTime: getCurrentTimestamp
                                                                  .millisecondsSinceEpoch <
                                                              FFAppState()
                                                                  .EndDate!
                                                                  .millisecondsSinceEpoch
                                                          ? functions
                                                              .calculateRemainingMs(
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
                                                          safeSetState(() {});
                                                      },
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .headlineSmall
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmallFamily,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmallIsCustom,
                                                          ),
                                                    ),
                                                    AlignedTooltip(
                                                      content: Padding(
                                                        padding:
                                                            EdgeInsets.all(4.0),
                                                        child: Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            '1jlut7ry' /* Update Time */,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .roboto(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                      offset: 4.0,
                                                      preferredDirection:
                                                          AxisDirection.down,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                      backgroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryBackground,
                                                      elevation: 4.0,
                                                      tailBaseWidth: 24.0,
                                                      tailLength: 12.0,
                                                      waitDuration: Duration(
                                                          milliseconds: 100),
                                                      showDuration: Duration(
                                                          milliseconds: 1500),
                                                      triggerMode:
                                                          TooltipTriggerMode
                                                              .tap,
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
                                                          _model
                                                              .timer1Controller
                                                              .onStartTimer();
                                                        },
                                                        child: Icon(
                                                          Icons.update_sharp,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .tertiary,
                                                          size: 22.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 8.0)),
                                                ),
                                              if (columnOrderRecord.halhText ==
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
                                                            MainAxisSize.max,
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
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          FlutterFlowTheme.of(context)
                                                                              .bodyMediumFamily,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          !FlutterFlowTheme.of(context)
                                                                              .bodyMediumIsCustom,
                                                                    ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .timer_outlined,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .success,
                                                                    size: 13.0,
                                                                  ),
                                                                  Text(
                                                                    dateTimeFormat(
                                                                      "d/M/y",
                                                                      tfaselOrserOrderRecord
                                                                          .start!,
                                                                      locale: FFLocalizations.of(
                                                                              context)
                                                                          .languageCode,
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyLarge
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).success,
                                                                          fontSize:
                                                                              12.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                        ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        8.0)),
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 4.0)),
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
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          FlutterFlowTheme.of(context)
                                                                              .bodyMediumFamily,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          !FlutterFlowTheme.of(context)
                                                                              .bodyMediumIsCustom,
                                                                    ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .timer_off_outlined,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    size: 13.0,
                                                                  ),
                                                                  Text(
                                                                    dateTimeFormat(
                                                                      "d/M/y",
                                                                      tfaselOrserOrderRecord
                                                                          .endTime!,
                                                                      locale: FFLocalizations.of(
                                                                              context)
                                                                          .languageCode,
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyLarge
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).error,
                                                                          fontSize:
                                                                              12.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                        ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        8.0)),
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 4.0)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      width: double.infinity,
                                                      height: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
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
                                                              MainAxisSize.max,
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
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'da1x0lkt' /* Start Time */,
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        useGoogleFonts:
                                                                            !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                      ),
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .timer_outlined,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .success,
                                                                      size:
                                                                          13.0,
                                                                    ),
                                                                    Text(
                                                                      dateTimeFormat(
                                                                        "jm",
                                                                        tfaselOrserOrderRecord
                                                                            .start!,
                                                                        locale:
                                                                            FFLocalizations.of(context).languageCode,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .override(
                                                                            fontFamily:
                                                                                FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).success,
                                                                            fontSize:
                                                                                12.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            useGoogleFonts:
                                                                                !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                          ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      width:
                                                                          8.0)),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  height: 4.0)),
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
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'uo3qzmy7' /* End Time */,
                                                                  ),
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        useGoogleFonts:
                                                                            !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                      ),
                                                                ),
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .timer_off_outlined,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .error,
                                                                      size:
                                                                          13.0,
                                                                    ),
                                                                    Text(
                                                                      dateTimeFormat(
                                                                        "jm",
                                                                        tfaselOrserOrderRecord
                                                                            .endTime!,
                                                                        locale:
                                                                            FFLocalizations.of(context).languageCode,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .override(
                                                                            fontFamily:
                                                                                FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).error,
                                                                            fontSize:
                                                                                12.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            useGoogleFonts:
                                                                                !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                          ),
                                                                    ),
                                                                  ].divide(SizedBox(
                                                                      width:
                                                                          8.0)),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  height: 4.0)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (columnOrderRecord.halhText !=
                                                  'مكتمل')
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    AlignedTooltip(
                                                      content: Padding(
                                                        padding:
                                                            EdgeInsets.all(4.0),
                                                        child: Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            'vlbi1eee' /* Update Time */,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .roboto(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                      offset: 4.0,
                                                      preferredDirection:
                                                          AxisDirection.down,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                      backgroundColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryBackground,
                                                      elevation: 4.0,
                                                      tailBaseWidth: 24.0,
                                                      tailLength: 12.0,
                                                      waitDuration: Duration(
                                                          milliseconds: 100),
                                                      showDuration: Duration(
                                                          milliseconds: 1500),
                                                      triggerMode:
                                                          TooltipTriggerMode
                                                              .tap,
                                                      child: Icon(
                                                        Icons.update_sharp,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 17.0,
                                                      ),
                                                    ),
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'xafw6vd4' /* Trip ends at: */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumIsCustom,
                                                          ),
                                                    ),
                                                    Text(
                                                      dateTimeFormat(
                                                        "jms",
                                                        FFAppState().EndDate,
                                                        locale:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .languageCode,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumIsCustom,
                                                          ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 8.0)),
                                                ),
                                              if (columnOrderRecord.halhText !=
                                                  'مكتمل')
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 8.0, 0.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      FFButtonWidget(
                                                        onPressed: () async {
                                                          _model.soundPlayer3 ??=
                                                              AudioPlayer();
                                                          if (_model
                                                              .soundPlayer3!
                                                              .playing) {
                                                            await _model
                                                                .soundPlayer3!
                                                                .stop();
                                                          }
                                                          _model.soundPlayer3!
                                                              .setVolume(1.0);
                                                          _model.soundPlayer3!
                                                              .setAsset(
                                                                  'assets/audios/835880__matustrm__completed.wav')
                                                              .then((_) => _model
                                                                  .soundPlayer3!
                                                                  .play());
                    
                                                          await showModalBottomSheet(
                                                            isScrollControlled:
                                                                true,
                                                            backgroundColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                            barrierColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
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
                                                                        0.45,
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
                                                        text:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                          'i7kt4eiw' /* وقت الرحلة */,
                                                        ),
                                                        icon: Icon(
                                                          Icons.timer_sharp,
                                                          size: 15.0,
                                                        ),
                                                        options:
                                                            FFButtonOptions(
                                                          width:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .width *
                                                                  0.386,
                                                          height: 42.94,
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      16.0,
                                                                      0.0,
                                                                      16.0,
                                                                      0.0),
                                                          iconPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                          iconColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .error,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          textStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .roboto(
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .titleSmall
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .titleSmall
                                                                          .fontStyle,
                                                                    ),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    fontSize:
                                                                        12.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmall
                                                                        .fontStyle,
                                                                  ),
                                                          elevation: 0.0,
                                                          borderSide:
                                                              BorderSide(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ].divide(SizedBox(height: 12.0)),
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
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 9.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'lv9mwjf6' /* Stops */,
                                              ),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleMedium
                                                  .override(
                                                    fontFamily: 'cairo',
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
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
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 9.0, 0.0, 0.0),
                                            child: Icon(
                                              Icons.map_outlined,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 11.0,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    5.0, 9.0, 5.0, 0.0),
                                            child: Text(
                                              '${columnOrderRecord.addCartNumer.toString()} من الأماكن  لمدة ${columnOrderRecord.totalTaim.toString()} ساعة/ساعات ',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleMedium
                                                  .override(
                                                    fontFamily: 'cairo',
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    fontSize: 12.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if ((columnOrderRecord.mndobUser ==
                                              currentUserReference) &&
                                          (columnOrderRecord.halhText !=
                                              'ملغي'))
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 8.0, 8.0, 8.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .accent4,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
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
                                                            'cjuivl12' /*  to Customer Location */,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                fontFamily:
                                                                    'cairo',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 12.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 4.0)),
                                                    ),
                                                  ),
                                                  FFButtonWidget(
                                                    onPressed: () {
                                                      DriverMapActions
                                                          .focusLocationHint(
                                                        context,
                                                        columnOrderRecord
                                                            .lokeshn,
                                                        title:
                                                            'موقع العميل على الخريطة',
                                                      );
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      'xajvgc9v' /*  Map */,
                                                    ),
                                                    icon: Icon(
                                                      Icons.maps_home_work,
                                                      size: 11.0,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: 88.78,
                                                      height: 44.7,
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelSmall
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmallFamily,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .error,
                                                                fontSize: 11.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmallIsCustom,
                                                              ),
                                                      elevation: 1.0,
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 8.0)),
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
                                            scrollDirection: Axis.vertical,
                                            itemCount: mkan.length,
                                            itemBuilder: (context, mkanIndex) {
                                              final mkanItem = mkan[mkanIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        8.0, 8.0, 8.0, 8.0),
                                                child: Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .accent4,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    border: Border.all(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate,
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
                                                                'الذهاب إلى ${mkanItem.naim}',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .override(
                                                                      fontFamily:
                                                                          'cairo',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      fontSize:
                                                                          12.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                    ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            7.0,
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        FFButtonWidget(
                                                                      onPressed:
                                                                          () async {
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text(
                                                                              'تمت تأكيد الزيارة',
                                                                              style: TextStyle(
                                                                                fontFamily: 'cairo',
                                                                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                              ),
                                                                            ),
                                                                            duration:
                                                                                Duration(milliseconds: 4000),
                                                                            backgroundColor:
                                                                                FlutterFlowTheme.of(context).secondary,
                                                                          ),
                                                                        );
                                                                      },
                                                                      text: FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'a7x02i9c' /* Site Visited */,
                                                                      ),
                                                                      icon:
                                                                          Icon(
                                                                        Icons
                                                                            .done,
                                                                        size:
                                                                            15.0,
                                                                      ),
                                                                      options:
                                                                          FFButtonOptions(
                                                                        width:
                                                                            90.2,
                                                                        height:
                                                                            44.64,
                                                                        padding:
                                                                            EdgeInsets.all(8.0),
                                                                        iconPadding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
                                                                        textStyle: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .override(
                                                                              fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                              letterSpacing: 0.0,
                                                                              useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                            ),
                                                                        elevation:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 4.0)),
                                                          ),
                                                        ),
                                                        FFButtonWidget(
                                                          onPressed: () {
                                                            DriverMapActions
                                                                .focusLocationHint(
                                                              context,
                                                              mkanItem.loceshn,
                                                              title:
                                                                  'الوجهة: ${mkanItem.naim}',
                                                            );
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            '8pdc6fff' /*  Map */,
                                                          ),
                                                          icon: Icon(
                                                            Icons.place_sharp,
                                                            size: 15.0,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            width: 99.88,
                                                            height: 47.4,
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          FlutterFlowTheme.of(context)
                                                                              .labelSmallFamily,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .error,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          !FlutterFlowTheme.of(context)
                                                                              .labelSmallIsCustom,
                                                                    ),
                                                            elevation: 1.0,
                                                          ),
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 8.0)),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      if ((columnOrderRecord.mndobUser ==
                                              currentUserReference) &&
                                          (columnOrderRecord.halhText !=
                                              'ملغي'))
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 8.0, 8.0, 8.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .accent4,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
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
                                                            '9ufh7ltr' /* Return to Customer Location */,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                fontFamily:
                                                                    'cairo',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 12.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 4.0)),
                                                    ),
                                                  ),
                                                  FFButtonWidget(
                                                    onPressed: () {
                                                      DriverMapActions
                                                          .focusLocationHint(
                                                        context,
                                                        columnOrderRecord
                                                            .lokeshn,
                                                        title:
                                                            'موقع العميل على الخريطة',
                                                      );
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      'zxky4qxq' /*  Map */,
                                                    ),
                                                    icon: Icon(
                                                      Icons.maps_home_work,
                                                      size: 12.0,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: 93.16,
                                                      height: 44.7,
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelSmall
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmallFamily,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .error,
                                                                fontSize: 11.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmallIsCustom,
                                                              ),
                                                      elevation: 1.0,
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 8.0)),
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
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
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
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 7.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          '8pbcsylb' /* Order Information */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'cairo',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 0.0, 5.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'zssd5l9x' /* Name: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'cairo',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          columnOrderRecord.naimUserText,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'cairo',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                letterSpacing: 0.0,
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 0.0, 5.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'yci4wt1i' /* Order Number: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'cairo',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          columnOrderRecord.iDorder,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'cairo',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  3.0, 0.0, 6.0, 4.0),
                                          child: InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              await Clipboard.setData(
                                                  ClipboardData(
                                                      text: columnOrderRecord
                                                          .iDorder));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'تم نسخ معرف الطلب/الرحلة',
                                                    style: TextStyle(
                                                      fontFamily: 'cairo',
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                    ),
                                                  ),
                                                  duration: Duration(
                                                      milliseconds: 900),
                                                  backgroundColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .tertiary,
                                                ),
                                              );
                                            },
                                            child: Icon(
                                              Icons.copy_all,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 0.0, 5.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'ewgx1exv' /* Vehicle Type: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          valueOrDefault<String>(
                                            columnOrderRecord.nameCar,
                                            'لم يتم تعيين مندوب',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 0.0, 5.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'may2r116' /* Order Status: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          columnOrderRecord.halhText,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
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
                                          FFLocalizations.of(context).getText(
                                            'flsiz002' /* Order Date: */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
                                              ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 0.0, 5.0, 0.0),
                                          child: Text(
                                            dateTimeFormat(
                                              "relative",
                                              columnOrderRecord.dataOrder!,
                                              locale:
                                                  FFLocalizations.of(context)
                                                      .languageCode,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
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
                                          FFLocalizations.of(context).getText(
                                            '4tq5mxgb' /* Total Hours: */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
                                              ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 0.0, 5.0, 0.0),
                                          child: Text(
                                            '${columnOrderRecord.totalTaim.toString()} ساعات ',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      thickness: 1.0,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  6.0, 0.0, 6.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'bimoowfd' /* Payment Method: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          DriverPaymentLabels.label(
                                            columnOrderRecord.paymentMethod,
                                            fallbackRaw: columnOrderRecord
                                                .paymentMethod?.name,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  6.0, 0.0, 6.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'n44ki8x4' /* Total Trip Amount: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          formatNumber(
                                            columnOrderRecord.total,
                                            formatType: FormatType.decimal,
                                            decimalType: DecimalType.automatic,
                                            currency: 'ر.س ',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.bold,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  6.0, 0.0, 6.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              '8xz5r4u1' /* Earnings: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          formatNumber(
                                            columnOrderRecord.totalMndob2,
                                            formatType: FormatType.decimal,
                                            decimalType: DecimalType.automatic,
                                            currency: 'ر.س ',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
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
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  6.0, 0.0, 6.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              '87c453o4' /* App Commission & Taxes: */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          formatNumber(
                                            columnOrderRecord.totalApp +
                                                columnOrderRecord.totalVat,
                                            formatType: FormatType.decimal,
                                            decimalType: DecimalType.automatic,
                                            currency: 'ر.س ',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMediumIsCustom,
                                              ),
                                        ),
                                      ],
                                    ),
                                    if (columnOrderRecord.halhOrderMndob ==
                                        HalhOrder.Accepted)
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 12.0, 16.0, 0.0),
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await launchURL(
                                                'https://wa.me/message/LHEPTGBXGS7UJ1');
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(8.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Icon(
                                                      Icons
                                                          .contact_support_outlined,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      size: 15.0,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(11.0, 0.0,
                                                                11.0, 0.0),
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'zci7ub2x' /* Have a problem? Contact us dir... */,
                                                      ),
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                            fontSize: 12.0,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumIsCustom,
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
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          child: Material(
                            color: Colors.transparent,
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                      ],
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
