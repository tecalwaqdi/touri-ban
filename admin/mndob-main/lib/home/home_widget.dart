import '/components/driver_daily_stats_card.dart';
import '/components/driver_home_map_panel.dart';
import '/components/driver_order_stat_card.dart';
import '/core/driver_document_expiry_banners.dart';
import '/core/driver_daily_stats_service.dart';
import '/core/driver_design_system.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_legacy_field_compat.dart';
import '/core/driver_order_match.dart';
import '/core/driver_eligibility_service.dart';
import '/core/driver_online_state.dart';
import '/core/driver_trip_constants.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
                child: DriverContentWidth(
                  child: DriverPagePadding(
                    top: DsSpacing.sm,
                    bottom: DsSpacing.lg,
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
                    DsCard(
                      elevated: true,
                      margin: const EdgeInsets.only(bottom: DsSpacing.sm),
                      child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const DriverDocumentExpiryBanners(),
                              if (DriverOnlineState.isApproved)
                                AuthUserStreamWidget(
                                  builder: (context) => Text(
                                    '${driverTr(context, 'Account status')}: ${driverTr(context, DriverLegacyFieldCompat.statusMessageKey(DriverOnlineState.lifecycle))}',
                                    style: context.dsTypography.bodyMedium
                                        .copyWith(
                                      color: context.dsColors.textPrimary,
                                    ),
                                  ),
                                ),
                              if (DriverOnlineState.isApproved)
                                AuthUserStreamWidget(
                                  builder: (context) => Text(
                                    '${driverTr(context, 'Work location')}: ${driverTr(context, 'Your current location')} - ${valueOrDefault(currentUserDocument?.textTypeCarMndob, '')} - ${valueOrDefault(currentUserDocument?.numberLohhCar, '')}',
                                    style: context.dsTypography.bodyMedium
                                        .copyWith(
                                      color: context.dsColors.success,
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
                                        return const Center(
                                          child: SizedBox(
                                            width: 50.0,
                                            height: 50.0,
                                            child: DsLoading(),
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
                                              padding: const EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 5.0, 0.0, 0.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        const AlignmentDirectional(
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
                                                      style: context
                                                          .dsTypography.bodyMedium
                                                          .copyWith(
                                                        color: context
                                                            .dsColors.error,
                                                        fontSize: 15.0,
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        const AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
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
                                                          DsButton.primary(
                                                            label: !DriverOnlineState
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
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 8.0,
                                                                0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Flexible(
                                                          child: Padding(
                                                          padding:
                                                              const EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      7.0,
                                                                      0.0,
                                                                      7.0,
                                                                      0.0),
                                                          child: DsButton.danger(
                                                            label: FFLocalizations
                                                                    .of(context)
                                                                .getText(
                                                              '9lc03d0o' /* Check your registration */,
                                                            ),
                                                            icon: Icons
                                                                .check_box_sharp,
                                                            expanded: true,
                                                            onPressed:
                                                                () async {
                                                              context.pushNamed(
                                                                  DriverPendingApprovalWidget
                                                                      .routeName);
                                                            },
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
                            ].divide(const SizedBox(height: 8.0)),
                          ),
                    ),
                    DsCard(
                      elevated: true,
                      margin: const EdgeInsets.only(bottom: DsSpacing.sm),
                      child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  'xhprzvoj' /* Orders */,
                                ),
                                style: context.dsTypography.titleLarge.copyWith(
                                  color: context.dsColors.textPrimary,
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
                                            return const Center(
                                              child: SizedBox(
                                                width: 50.0,
                                                height: 50.0,
                                                child: DsLoading(),
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
                                          return const Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: DsLoading(),
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
                                          return const Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: DsLoading(),
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
                                ].divide(const SizedBox(width: 8.0)),
                              ),
                            ].divide(const SizedBox(height: 12.0)),
                          ),
                    ),
                    DsCard(
                      elevated: true,
                      margin: const EdgeInsets.only(bottom: DsSpacing.sm),
                      child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'oadi4ucn' /* Finance / Wallet */,
                                  ),
                                  style: context.dsTypography.titleLarge
                                      .copyWith(
                                    color: context.dsColors.textPrimary,
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AuthUserStreamWidget(
                                  builder: (context) => _FinanceMetricTile(
                                    label: FFLocalizations.of(context).getText(
                                      '5w1bmqit' /* Total Earnings */,
                                    ),
                                    value: valueOrDefault(
                                            currentUserDocument?.totalMndob, 0)
                                        .toString(),
                                    valueColor: context.dsColors.success,
                                    background: context.dsColors.success
                                        .withValues(alpha: 0.08),
                                    icon: Icons.trending_up_rounded,
                                  ),
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
                                              padding: const EdgeInsetsDirectional
                                                  .fromSTEB(7.0, 0.0, 7.0, 0.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '3wrjokzf' /* Electronic payment obligations */,
                                                ),
                                                style: context
                                                    .dsTypography.bodyLarge,
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
                                              style: context
                                                  .dsTypography.titleMedium
                                                  .copyWith(
                                                color:
                                                    context.dsColors.success,
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
                                                padding: const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 4.0, 0.0, 4.0),
                                                child: DsButton.primary(
                                                  label: FFLocalizations.of(
                                                          context)
                                                      .getText(
                                                    'hfjkl3wt' /* Request payment now */,
                                                  ),
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
                                                              driverTr(context, 'Request electronic payout'),
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
                                                                      driverTr(context, 'Confirm')),
                                                                  content: Text(
                                                                      driverTr(context, 'Are you sure you want to submit a payout transfer request?')),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(
                                                                          alertDialogContext,
                                                                          false),
                                                                      child: Text(
                                                                          driverTr(context, 'No')),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(
                                                                          alertDialogContext,
                                                                          true),
                                                                      child: Text(
                                                                          driverTr(context, 'Yes')),
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
                                                            title: Text(driverTr(context, 'Done')),
                                                            content: Text(
                                                                driverTr(context, 'Your payout request was submitted successfully.')),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        alertDialogContext),
                                                                child: Text(
                                                                  driverTr(
                                                                      context,
                                                                      'Ok'),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    }
                                                  },
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
                                                  Expanded(
                                                    child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'xvmvyd3d' /* Please add a bank account to r... */,
                                                        ),
                                                        maxLines: 3,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: context
                                                            .dsTypography
                                                            .bodyMedium
                                                            .copyWith(
                                                          color: context
                                                              .dsColors.error,
                                                        ),
                                                      ),
                                                      DsButton.primary(
                                                        label:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                          '7hlqu0xi' /* Bank account update */,
                                                        ),
                                                        icon: Icons
                                                            .account_balance,
                                                        onPressed: () async {
                                                          context.pushNamed(
                                                              UpdetBankWidget
                                                                  .routeName);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                AuthUserStreamWidget(
                                  builder: (context) {
                                    final colors = context.dsColors;
                                    final typography = context.dsTypography;
                                    final unpaid = valueOrDefault(
                                        currentUserDocument?.totalApp, 0);
                                    final hasUnpaid = unpaid > 0;

                                    if (!hasUnpaid) {
                                      return _FinanceMetricTile(
                                        label: FFLocalizations.of(context)
                                            .getText(
                                          'p9lt26gd' /* Unpaid app commissions */,
                                        ),
                                        value: '0',
                                        valueColor: colors.textSecondary,
                                        background: colors.primarySoft
                                            .withValues(alpha: 0.55),
                                        icon: Icons
                                            .check_circle_outline_rounded,
                                      );
                                    }

                                    return Container(
                                      width: double.infinity,
                                      padding:
                                          const EdgeInsets.all(DsSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: colors.error
                                            .withValues(alpha: 0.08),
                                        borderRadius: DsRadius.medium,
                                        border: Border.all(
                                          color: colors.error
                                              .withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: colors.error,
                                                size: 22,
                                              ),
                                              const SizedBox(
                                                  width: DsSpacing.xs),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'p9lt26gd' /* Unpaid app commissions */,
                                                      ),
                                                      softWrap: true,
                                                      style: typography
                                                          .titleSmall
                                                          .copyWith(
                                                        color: colors.error,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      unpaid.toString(),
                                                      style: typography
                                                          .headlineSmall
                                                          .copyWith(
                                                        color: colors.error,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: DsSpacing.xs),
                                          Text(
                                            FFLocalizations.of(context)
                                                .getText(
                                              '7rctg8a4' /* Due payment notice */,
                                            ),
                                            softWrap: true,
                                            style:
                                                typography.bodySmall.copyWith(
                                              color: colors.error
                                                  .withValues(alpha: 0.92),
                                              height: 1.45,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: DsSpacing.sm),
                                          DsButton.danger(
                                            label: FFLocalizations.of(context)
                                                .getText(
                                              '3hqugl0j' /* Pay commissions now */,
                                            ),
                                            icon: Icons.payments_rounded,
                                            expanded: true,
                                            onPressed: () async {
                                              context.pushNamed(
                                                  SuportWidget.routeName);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                DriverGradientButton(
                                  label: driverTr(
                                      context, 'Wallet and transactions'),
                                  icon: Icons.account_balance_wallet_rounded,
                                  onPressed: () async {
                                    context.pushNamed(
                                        DriverWalletWidget.routeName);
                                  },
                                ),
                              ].divide(const SizedBox(height: 12.0)),
                            ),
                    ),
                  ],
                ),
                  ),
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

class _FinanceMetricTile extends StatelessWidget {
  const _FinanceMetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.background,
    required this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: DsRadius.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: valueColor, size: 22),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: typography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: DsSpacing.xs),
          Text(
            value,
            style: typography.titleLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
