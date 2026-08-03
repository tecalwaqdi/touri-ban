import '/components/driver_daily_stats_card.dart';
import '/components/driver_home_map_panel.dart';
import '/components/driver_order_stat_card.dart';
import '/core/driver_daily_stats_service.dart';
import '/core/driver_design_system.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';
import '/core/driver_legacy_field_compat.dart';
import '/core/driver_order_match.dart';
import '/core/driver_eligibility_service.dart';
import '/core/driver_online_state.dart';
import '/core/driver_trip_constants.dart';
import '/driver_pending_approval/driver_pending_approval_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_model.dart';
export 'home_model.dart';

/// Create a driver dashboard page for a mobile app.
///
/// At the top of the page, display a personalized greeting such as: "Welcome,
/// Ahmed".
/// Below the greeting, show the account status, for example: "Account Status:
/// Active".
///
/// Next, include an Orders section that contains three categories:
///
/// Available Orders
///
/// Active Orders
///
/// Completed Orders
///
/// Below that, include a Financials section showing:
///
/// Total Earnings
///
/// Unpaid App Commissions
///
/// Also, add a button labeled: Pay App Commissions.
///
/// The design should be clean, mobile-friendly, and easy to navigate.
class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late HomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await DriverOrderMatch.ensureDriverCountry();
      if (currentUserDocument?.ngl == null) {
        await currentUserReference!.update(createUserRecordData(
          ngl: false,
        ));
      }
      if (mounted) safeSetState(() {});
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
    return DsScreenShell(
      child: Builder(
        builder: (context) {
    return StreamBuilder<List<SettingsRecord>>(
      stream: querySettingsRecord(
        queryBuilder: (settingsRecord) => settingsRecord.where(
          'id',
          isEqualTo: 1,
        ),
        singleRecord: true,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: DsColors.of(context).scaffold,
            body: const Center(
              child: DsLoading(),
            ),
          );
        }
        List<SettingsRecord> homeSettingsRecordList = snapshot.data!;
        // Return an empty Container when the item does not exist.
        if (snapshot.data!.isEmpty) {
          return Container();
        }
        final homeSettingsRecord = homeSettingsRecordList.isNotEmpty
            ? homeSettingsRecordList.first
            : null;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: context.dsColors.scaffold,
            body: Column(
              children: [
                DriverHomeMapPanel(
                  googleMapsController: _model.googleMapsController,
                  onCenterChanged: (latLng) =>
                      _model.googleMapsCenter = latLng,
                  initialCenter: _model.googleMapsCenter,
                  settingsRecord: homeSettingsRecord,
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AuthUserStreamWidget(
                      builder: (context) => FutureBuilder<DriverDailyStats>(
                        future: DriverDailyStatsService.fetch(
                          driverRef: currentUserReference,
                          villRef: currentUserDocument?.mndobVill,
                          carTypeRef: currentUserDocument?.mndobTypeCar,
                        ),
                        builder: (context, snapshot) => DriverDailyStatsCard(
                          stats: snapshot.data ?? DriverDailyStats.empty,
                          isLoading:
                              snapshot.connectionState ==
                                  ConnectionState.waiting,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              context.dsColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 16.0, 16.0, 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (DriverOnlineState.isApproved)
                                AuthUserStreamWidget(
                                  builder: (context) => Text(
                                    '${driverTr(context, 'Account status')}: ${driverTr(context, DriverLegacyFieldCompat.statusMessageKey(DriverOnlineState.lifecycle))}',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
                                          color: context.dsColors.textPrimary,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .bodyMediumIsCustom,
                                        ),
                                  ),
                                ),
                              if (DriverOnlineState.isApproved)
                                AuthUserStreamWidget(
                                  builder: (context) => Text(
                                    '${driverTr(context, 'Work location')}: ${driverTr(context, 'Your current location')} - ${valueOrDefault(currentUserDocument?.textTypeCarMndob, '')} - ${valueOrDefault(currentUserDocument?.numberLohhCar, '')}',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
                                          color: context.dsColors.success,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .bodyMediumIsCustom,
                                        ),
                                  ),
                                ),
                              if (!DriverOnlineState.isApproved ||
                                  !DriverOnlineState.isMarkedOnline)
                                AuthUserStreamWidget(
                                  builder: (context) =>
                                      StreamBuilder<List<SettingsRecord>>(
                                    stream: querySettingsRecord(
                                      queryBuilder: (settingsRecord) =>
                                          settingsRecord.where(
                                        'id',
                                        isEqualTo: 1,
                                      ),
                                      singleRecord: true,
                                    ),
                                    builder: (context, snapshot) {
                                      // Customize what your widget looks like when it's loading.
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: SizedBox(
                                            width: 50.0,
                                            height: 50.0,
                                            child: const DsLoading(),
                                          ),
                                        );
                                      }
                                      List<SettingsRecord>
                                          containerSettingsRecordList =
                                          snapshot.data!;
                                      // Return an empty Container when the item does not exist.
                                      if (snapshot.data!.isEmpty) {
                                        return Container();
                                      }
                                      final containerSettingsRecord =
                                          containerSettingsRecordList.isNotEmpty
                                              ? containerSettingsRecordList
                                                  .first
                                              : null;

                                      return Container(
                                        width: double.infinity,
                                        height: 149.41,
                                        decoration: BoxDecoration(
                                          color: context.dsColors.scaffold,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 5.0, 0.0, 0.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Text(
                                                      () {
                                                        final account =
                                                            DriverEligibilityService
                                                                .evaluateAccount();
                                                        if (!account
                                                            .isEligible) {
                                                          return driverTr(
                                                            context,
                                                            account.messageKey
                                                                    .isNotEmpty
                                                                ? account
                                                                    .messageKey
                                                                : 'Your account is waiting for admin approval before going online.',
                                                          );
                                                        }
                                                        return driverTr(
                                                          context,
                                                          'Go online to receive requests.',
                                                        );
                                                      }(),
                                                      textAlign:
                                                          TextAlign.center,
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
                                                                    .error,
                                                                fontSize: 15.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMediumIsCustom,
                                                              ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  12.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          FFButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              if (!DriverOnlineState
                                                                  .isApproved) {
                                                                context.pushNamed(
                                                                    DriverPendingApprovalWidget
                                                                        .routeName);
                                                                return;
                                                              }
                                                              final result =
                                                                  await DriverOnlineState
                                                                      .goOnline();
                                                              if (!result.ok &&
                                                                  context
                                                                      .mounted) {
                                                                await DriverDialogs
                                                                    .showAlert(
                                                                  context,
                                                                  title: driverTr(
                                                                      context,
                                                                      'Error'),
                                                                  message: driverTr(
                                                                    context,
                                                                    result.message ??
                                                                        'Something went wrong. Please try again.',
                                                                  ),
                                                                  type:
                                                                      DriverMessageType
                                                                          .error,
                                                                );
                                                              }
                                                              safeSetState(
                                                                  () {});
                                                            },
                                                            text: !DriverOnlineState
                                                                    .isApproved
                                                                ? FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                    'md9y2x4q' /* Account Activation */,
                                                                  )
                                                                : driverTr(
                                                                    context,
                                                                    'Go Online',
                                                                  ),
                                                            options:
                                                                FFButtonOptions(
                                                              height: 40.0,
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
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            FlutterFlowTheme.of(context).titleSmallFamily,
                                                                        color: Colors
                                                                            .white,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        useGoogleFonts:
                                                                            !FlutterFlowTheme.of(context).titleSmallIsCustom,
                                                                      ),
                                                              elevation: 0.0,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 8.0,
                                                                0.0, 0.0),
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
                                                                      7.0,
                                                                      0.0,
                                                                      7.0,
                                                                      0.0),
                                                          child: FFButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              context.pushNamed(
                                                                  DriverPendingApprovalWidget
                                                                      .routeName);
                                                            },
                                                            text: FFLocalizations
                                                                    .of(context)
                                                                .getText(
                                                              '9lc03d0o' /* Check your registration */,
                                                            ),
                                                            icon: Icon(
                                                              Icons
                                                                  .check_box_sharp,
                                                              size: 15.0,
                                                            ),
                                                            options:
                                                                FFButtonOptions(
                                                              height: 40.0,
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
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            FlutterFlowTheme.of(context).titleSmallFamily,
                                                                        color: context.dsColors.info,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        useGoogleFonts:
                                                                            !FlutterFlowTheme.of(context).titleSmallIsCustom,
                                                                      ),
                                                              elevation: 0.0,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ].divide(SizedBox(height: 8.0)),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              context.dsColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 16.0, 16.0, 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  'xhprzvoj' /* Orders */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .titleLargeFamily,
                                      color: context.dsColors.textPrimary,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .titleLargeIsCustom,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: AuthUserStreamWidget(
                                      builder: (context) => FutureBuilder<int>(
                                        future: queryOrderRecordCount(
                                          queryBuilder:
                                              DriverOrderMatch.queryBuilder(),
                                        ),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Center(
                                              child: SizedBox(
                                                width: 50.0,
                                                height: 50.0,
                                                child: const DsLoading(),
                                              ),
                                            );
                                          }
                                          int containerCount = snapshot.data!;

                                          return DriverOrderStatCard(
                                            count: DriverOnlineState.isApproved
                                                ? containerCount.toString()
                                                : '0',
                                            label: FFLocalizations.of(context)
                                                .getText(
                                              'tf28iy1f' /* Available */,
                                            ),
                                            accentColor: DriverBrand.teal,
                                            onTap: () => context.pushNamed(
                                                NowWidget.routeName),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: FutureBuilder<int>(
                                      future: queryOrderRecordCount(
                                        queryBuilder: (orderRecord) =>
                                            orderRecord
                                                .where(
                                                  'mndob_user',
                                                  isEqualTo:
                                                      currentUserReference,
                                                )
                                                .where(
                                                  'ALLNOW',
                                                  isEqualTo: true,
                                                )
                                                .where(
                                                  'ActiveOrder',
                                                  isEqualTo: true,
                                                ),
                                      ),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: const DsLoading(),
                                            ),
                                          );
                                        }
                                        int containerCount = snapshot.data!;

                                        return DriverOrderStatCard(
                                          count: containerCount.toString(),
                                          label: FFLocalizations.of(context)
                                              .getText(
                                            'sblrapru' /* Active */,
                                          ),
                                          accentColor: DriverBrand.warning,
                                          onTap: () => context.pushNamed(
                                              AcceptedWidget.routeName),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: FutureBuilder<int>(
                                      future: queryOrderRecordCount(
                                        queryBuilder: (orderRecord) =>
                                            orderRecord
                                                .where(
                                                  'mndob_user',
                                                  isEqualTo:
                                                      currentUserReference,
                                                )
                                                .where(
                                                  'halh_text',
                                                  isEqualTo: DriverTripHalh.completed,
                                                ),
                                      ),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: const DsLoading(),
                                            ),
                                          );
                                        }
                                        int containerCount = snapshot.data!;

                                        return DriverOrderStatCard(
                                          count: containerCount.toString(),
                                          label: FFLocalizations.of(context)
                                              .getText(
                                            '22fe4dkq' /* Completed */,
                                          ),
                                          accentColor: DriverBrand.success,
                                          onTap: () => context.pushNamed(
                                              CompletedWidget.routeName),
                                        );
                                      },
                                    ),
                                  ),
                                ].divide(SizedBox(width: 8.0)),
                              ),
                            ].divide(SizedBox(height: 12.0)),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              context.dsColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 16.0, 16.0, 16.0),
                          child: SingleChildScrollView(
                            primary: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'oadi4ucn' /* Financials */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .titleLargeFamily,
                                        color: context.dsColors.textPrimary,
                                        fontSize: 17.0,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .titleLargeIsCustom,
                                      ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 4.0, 0.0, 8.0),
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      context.pushNamed(
                                          DriverWalletWidget.routeName);
                                    },
                                    text: driverTr(context, 'Wallet and transactions'),
                                    icon: Icon(Icons.account_balance_wallet,
                                        size: 18),
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 42,
                                      color:
                                          context.dsColors.primary,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmallFamily,
                                            color: Colors.white,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .titleSmallIsCustom,
                                          ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          7.0, 0.0, 7.0, 0.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          '5w1bmqit' /* Total Earnings */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLargeFamily,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .bodyLargeIsCustom,
                                            ),
                                      ),
                                    ),
                                    AuthUserStreamWidget(
                                      builder: (context) => Text(
                                        valueOrDefault(
                                                currentUserDocument?.totalMndob,
                                                0)
                                            .toString(),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMediumFamily,
                                              color:
                                                  context.dsColors.success,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .titleMediumIsCustom,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (valueOrDefault(
                                        currentUserDocument
                                            ?.outstandingonlinepayment,
                                        0.0) >=
                                    1.0)
                                  AuthUserStreamWidget(
                                    builder: (context) => Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(7.0, 0.0, 7.0, 0.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '3wrjokzf' /* Electronic payment obligations */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLargeFamily,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyLargeIsCustom,
                                                        ),
                                              ),
                                            ),
                                            Text(
                                              formatNumber(
                                                valueOrDefault(
                                                    currentUserDocument
                                                        ?.outstandingonlinepayment,
                                                    0.0),
                                                formatType: FormatType.decimal,
                                                decimalType:
                                                    DecimalType.automatic,
                                              ),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleMedium
                                                  .override(
                                                    fontFamily:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleMediumFamily,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .success,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts:
                                                        !FlutterFlowTheme.of(
                                                                context)
                                                            .titleMediumIsCustom,
                                                  ),
                                            ),
                                            if ((valueOrDefault(
                                                            currentUserDocument
                                                                ?.bankIdAcc,
                                                            '') !=
                                                        null &&
                                                    valueOrDefault(
                                                            currentUserDocument
                                                                ?.bankIdAcc,
                                                            '') !=
                                                        '') &&
                                                (valueOrDefault(
                                                            currentUserDocument
                                                                ?.ipanBank,
                                                            '') !=
                                                        null &&
                                                    valueOrDefault(
                                                            currentUserDocument
                                                                ?.ipanBank,
                                                            '') !=
                                                        ''))
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 4.0, 0.0, 4.0),
                                                child: FFButtonWidget(
                                                  onPressed: () async {
                                                    await EPaymentduerequestsRecord
                                                        .collection
                                                        .doc()
                                                        .set(
                                                            createEPaymentduerequestsRecordData(
                                                          userRev:
                                                              currentUserReference,
                                                          total: valueOrDefault(
                                                              currentUserDocument
                                                                  ?.outstandingonlinepayment,
                                                              0.0),
                                                          osf:
                                                              'طلب مستحقات للمدفوعات الإلكترونية',
                                                          dateAdd:
                                                              getCurrentTimestamp,
                                                          okPay: false,
                                                        ));
                                                    var confirmDialogResponse =
                                                        await showDialog<bool>(
                                                              context: context,
                                                              builder:
                                                                  (alertDialogContext) {
                                                                return AlertDialog(
                                                                  title: Text(
                                                                      'تأكيد'),
                                                                  content: Text(
                                                                      'هل انت متأكد من إرسال طلبك تحويل المستحقات المالية '),
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
                                                                          'نعم'),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ) ??
                                                            false;
                                                    if (confirmDialogResponse) {
                                                      await showDialog(
                                                        context: context,
                                                        builder:
                                                            (alertDialogContext) {
                                                          return AlertDialog(
                                                            title: Text('تم'),
                                                            content: Text(
                                                                'تم إرسال طلبك بنجاح وسيتم تحويل المبلغ في أقرب وقت'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        alertDialogContext),
                                                                child:
                                                                    Text('Ok'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    }
                                                  },
                                                  text: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'hfjkl3wt' /* Request payment now */,
                                                  ),
                                                  options: FFButtonOptions(
                                                    height: 40.0,
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(16.0, 0.0,
                                                                16.0, 0.0),
                                                    iconPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 0.0),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmallFamily,
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .titleSmallIsCustom,
                                                        ),
                                                    elevation: 0.0,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                ),
                                              ),
                                            if ((valueOrDefault(
                                                            currentUserDocument
                                                                ?.bankIdAcc,
                                                            '') ==
                                                        null ||
                                                    valueOrDefault(
                                                            currentUserDocument
                                                                ?.bankIdAcc,
                                                            '') ==
                                                        '') ||
                                                (valueOrDefault(
                                                            currentUserDocument
                                                                ?.ipanBank,
                                                            '') ==
                                                        null ||
                                                    valueOrDefault(
                                                            currentUserDocument
                                                                ?.ipanBank,
                                                            '') ==
                                                        ''))
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'xvmvyd3d' /* Please add a bank account to r... */,
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
                                                                      .error,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMediumIsCustom,
                                                                ),
                                                      ),
                                                      FFButtonWidget(
                                                        onPressed: () async {
                                                          context.pushNamed(
                                                              UpdetBankWidget
                                                                  .routeName);
                                                        },
                                                        text:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                          '7hlqu0xi' /* Bank account update */,
                                                        ),
                                                        icon: Icon(
                                                          Icons.account_balance,
                                                          size: 15.0,
                                                        ),
                                                        options:
                                                            FFButtonOptions(
                                                          height: 40.0,
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
                                                                      3.0,
                                                                      0.0,
                                                                      0.0),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          textStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .override(
                                                                    fontFamily:
                                                                        FlutterFlowTheme.of(context)
                                                                            .titleSmallFamily,
                                                                    color: Colors
                                                                        .white,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        !FlutterFlowTheme.of(context)
                                                                            .titleSmallIsCustom,
                                                                  ),
                                                          elevation: 0.0,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                Divider(
                                  thickness: 2.0,
                                  color: context.dsColors.border,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          7.0, 0.0, 7.0, 0.0),
                                      child: Text(
                                        FFLocalizations.of(context).getText(
                                          'p9lt26gd' /* Unpaid App Commissions */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLargeFamily,
                                              color:
                                                  context.dsColors.error,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .bodyLargeIsCustom,
                                            ),
                                      ),
                                    ),
                                    AuthUserStreamWidget(
                                      builder: (context) => Text(
                                        valueOrDefault(
                                                currentUserDocument?.totalApp,
                                                0)
                                            .toString(),
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMediumFamily,
                                              color:
                                                  context.dsColors.error,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .titleMediumIsCustom,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                SingleChildScrollView(
                                  child: 
                                    AuthUserStreamWidget(
                                      builder: (context) => Text(
                                        FFLocalizations.of(context).getText(
                                          '7rctg8a4' /* This balance is due for paymen... */,
                                        ),
                                        textAlign: TextAlign.center,
                                          maxLines: 3,                 // ✅ Limit to 3 lines
                                          softWrap: true,              // ✅ Allow wrapping
                                          overflow: TextOverflow.ellipsis, // ✅ If still longer, show ...
                                        style: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(
                                                          context)
                                                      .bodyLargeFamily,
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .error,
                                              fontSize: 11.0,
                                              letterSpacing: 0.0,
                                              decoration:
                                                  TextDecoration.underline,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(
                                                          context)
                                                      .bodyLargeIsCustom,
                                            ),
                                      ),
                                      
                                    ),
                                ),
                                if (valueOrDefault(
                                        currentUserDocument?.totalApp, 0) >
                                    0)
                                  AuthUserStreamWidget(
                                    builder: (context) => FFButtonWidget(
                                      onPressed: () async {
                                        context
                                            .pushNamed(SuportWidget.routeName);
                                      },
                                      text: FFLocalizations.of(context).getText(
                                        '3hqugl0j' /* Pay App Commissions */,
                                      ),
                                      icon: Icon(
                                        Icons.payments_sharp,
                                        size: 15.0,
                                      ),
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: 50.0,
                                        padding: EdgeInsets.all(8.0),
                                        iconPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                        color: context.dsColors.surface,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmallFamily,
                                              color:
                                                  context.dsColors.error,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .titleSmallIsCustom,
                                            ),
                                        elevation: 2.0,
                                        borderSide: BorderSide(
                                          color: context.dsColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                              ].divide(SizedBox(height: 12.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              context.dsColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
        );
      },
    );
        },
      ),
    );
  }
}
