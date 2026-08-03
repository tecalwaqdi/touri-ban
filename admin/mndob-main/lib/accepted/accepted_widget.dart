import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_design_system.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_online_state.dart';
import '/core/driver_order_match.dart';
import '/core/driver_ux_widgets.dart';
import '/core/driver_i18n.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'accepted_model.dart';
export 'accepted_model.dart';

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
class AcceptedWidget extends StatefulWidget {
  const AcceptedWidget({super.key});

  static String routeName = 'Accepted';
  static String routePath = '/Accepted';

  @override
  State<AcceptedWidget> createState() => _AcceptedWidgetState();
}

class _AcceptedWidgetState extends State<AcceptedWidget>
    with TickerProviderStateMixin {
  late AcceptedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AcceptedModel());

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: DriverBrand.tealDark,
          automaticallyImplyLeading: true,
          title: Text(
            FFLocalizations.of(context).getText(
              'xolnmkh5' /* Accepted requests */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                  color: Colors.white,
                  fontSize: 18.0,
                  letterSpacing: 0.0,
                  useGoogleFonts:
                      !FlutterFlowTheme.of(context).headlineMediumIsCustom,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Container(
                    width: double.infinity,
                  ),
                ),
                if (!DriverOnlineState.isApproved)
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                    child: AuthUserStreamWidget(
                      builder: (context) => Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).error,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'jjqc2d63' /* This account is inactive. For ... */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .bodyMediumIsCustom,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: StreamBuilder<List<OrderRecord>>(
                    stream: queryOrderRecord(
                      queryBuilder: DriverOrderMatch.assignedToMeQuery(),
                      limit: 40,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return DriverEmptyState(
                          title: driverTr(context, 'Error'),
                          message:
                              '${driverTr(context, 'Something went wrong. Please try again.')}\n(${snapshot.error})',
                          icon: Icons.cloud_off_rounded,
                          actionLabel: driverTr(context, 'Retry'),
                          onAction: () => safeSetState(() {}),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: SpinKitPulse(
                              color: FlutterFlowTheme.of(context).secondary,
                              size: 50.0,
                            ),
                          ),
                        );
                      }
                      List<OrderRecord> listViewOrderRecordList =
                          snapshot.data!
                              .where(
                                (o) => DriverTripActionGates.isActiveListItem(
                                  (o.snapshotData['status_code'] ?? '')
                                      .toString(),
                                  o.halhText,
                                ),
                              )
                              .toList();

                      if (listViewOrderRecordList.isEmpty) {
                        return DriverEmptyState(
                          title: driverNoOrdersTitle(context),
                          message: driverNoOrdersMessage(context),
                          icon: Icons.assignment_turned_in_outlined,
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
                              listViewOrderRecordList[listViewIndex];
                          return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 8.0),
                              child: FutureBuilder<int>(
                                future: queryChatRecordCount(
                                  queryBuilder: (chatRecord) =>
                                      chatRecord.where(
                                    'idorder',
                                    isEqualTo: listViewOrderRecord.reference,
                                  ),
                                ),
                                builder: (context, snapshot) {
                                  // Customize what your widget looks like when it's loading.
                                  if (!snapshot.hasData) {
                                    return SpinKitPulse(
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 10,
                                    );
                                  }
                                  int containerCount = snapshot.data!;

                                  return InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: DriverBrand.cardDecoration(
                                          context,
                                          elevated: true,
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  8.0, 8.0, 8.0, 8.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Container(
                                                    width: 60.0,
                                                    height: 60.0,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .accent1,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30.0),
                                                      child: Image(
                                                        fit: BoxFit.cover,
                                                        image: (listViewOrderRecord
                                                                        .imgProfileClent !=
                                                                    null &&
                                                                listViewOrderRecord
                                                                    .imgProfileClent!
                                                                    .isNotEmpty)
                                                            ? NetworkImage(
                                                                listViewOrderRecord
                                                                    .imgProfileClent!)
                                                            : const AssetImage(
                                                                    'assets/images/logo.png')
                                                                as ImageProvider,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          listViewOrderRecord
                                                              .naimUserText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLargeFamily,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyLargeIsCustom,
                                                              ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.grid_3x3,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              size: 10.0,
                                                            ),
                                                            const SizedBox(
                                                                width: 4.0),
                                                            Flexible(
                                                              child: Text(
                                                                '${listViewOrderRecord.iDorder}',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .override(
                                                                      fontFamily:
                                                                          FlutterFlowTheme.of(context)
                                                                              .bodySmallFamily,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          !FlutterFlowTheme.of(context)
                                                                              .bodySmallIsCustom,
                                                                    ),
                                                              ),
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
                                                              onTap: () async {
                                                                await Clipboard
                                                                    .setData(
                                                                  ClipboardData(
                                                                    text: listViewOrderRecord
                                                                        .iDorder,
                                                                  ),
                                                                );
                                                                ScaffoldMessenger
                                                                        .of(context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content:
                                                                        Text(
                                                                      'تم النسخ',
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            'cairo',
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
                                                                      ),
                                                                    ),
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            4000),
                                                                    backgroundColor:
                                                                        FlutterFlowTheme.of(context)
                                                                            .secondary,
                                                                  ),
                                                                );
                                                              },
                                                              child: Icon(
                                                                Icons
                                                                    .content_copy,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                size: 10.0,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Wrap(
                                                          spacing: 16.0,
                                                          runSpacing: 4.0,
                                                          children: [
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .schedule,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  size: 10.0,
                                                                ),
                                                                const SizedBox(
                                                                    width: 4.0),
                                                                Text(
                                                                  'الساعات: ${listViewOrderRecord.totalTaim.toString()}',
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .override(
                                                                        fontFamily:
                                                                            FlutterFlowTheme.of(context).bodySmallFamily,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        useGoogleFonts:
                                                                            !FlutterFlowTheme.of(context).bodySmallIsCustom,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons.place,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  size: 16.0,
                                                                ),
                                                                const SizedBox(
                                                                    width: 4.0),
                                                                Text(
                                                                  'المعالم: ${listViewOrderRecord.addCartNumer.toString()}',
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .override(
                                                                        fontFamily:
                                                                            FlutterFlowTheme.of(context).bodySmallFamily,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        useGoogleFonts:
                                                                            !FlutterFlowTheme.of(context).bodySmallIsCustom,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ].divide(SizedBox(
                                                          height: 4.0)),
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 12.0)),
                                              ),
                                              Divider(
                                                thickness: 1.0,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
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
                                                          'osbf1yq2' /* Total Earnings */,
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  fontFamily: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMediumFamily,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMediumIsCustom,
                                                                ),
                                                      ),
                                                      Text(
                                                        formatNumber(
                                                          listViewOrderRecord
                                                              .totalMndob2,
                                                          formatType: FormatType
                                                              .decimal,
                                                          decimalType:
                                                              DecimalType
                                                                  .automatic,
                                                          currency: ' ر.س ',
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .headlineSmall
                                                                .override(
                                                                  fontFamily: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmallFamily,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .headlineSmallIsCustom,
                                                                ),
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          if (containerCount >=
                                                              1)
                                                            FutureBuilder<int>(
                                                              future:
                                                                  queryChatRecordCount(
                                                                queryBuilder:
                                                                    (chatRecord) =>
                                                                        chatRecord
                                                                            .where(
                                                                              'idorder',
                                                                              isEqualTo: listViewOrderRecord.reference,
                                                                            )
                                                                            .where(
                                                                              'user1',
                                                                              isNotEqualTo: currentUserReference,
                                                                            ),
                                                              ),
                                                              builder: (context,
                                                                  snapshot) {
                                                                // Customize what your widget looks like when it's loading.
                                                                if (!snapshot
                                                                    .hasData) {
                                                                  return Center(
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          50.0,
                                                                      height:
                                                                          50.0,
                                                                      child:
                                                                          SpinKitPulse(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondary,
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
                                                                  splashColor:
                                                                      Colors
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
                                                                          listViewOrderRecord
                                                                              .reference,
                                                                          ParamType
                                                                              .DocumentReference,
                                                                        ),
                                                                        'phoneClent':
                                                                            serializeParam(
                                                                          listViewOrderRecord
                                                                              .phoneNumper,
                                                                          ParamType
                                                                              .int,
                                                                        ),
                                                                        'iduserclent':
                                                                            serializeParam(
                                                                          listViewOrderRecord
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
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        size:
                                                                            16.0,
                                                                      ),
                                                                      Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'vp3hdudk' /* Chat */,
                                                                        ),
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                              letterSpacing: 0.0,
                                                                              useGoogleFonts: !FlutterFlowTheme.of(context).bodyMediumIsCustom,
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
                                                                              containerCount.toString(),
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                                    color: FlutterFlowTheme.of(context).error,
                                                                                    letterSpacing: 0.0,
                                                                                    useGoogleFonts: !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                                  ),
                                                                            ).animateOnPageLoad(animationsMap['textOnPageLoadAnimation']!),
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
                                                    ].divide(
                                                        SizedBox(height: 4.0)),
                                                  ),
                                                  FFButtonWidget(
                                                    onPressed: () async {
                                                      context.pushNamed(
                                                        TfaselOrserWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'id': serializeParam(
                                                            listViewOrderRecord
                                                                .reference,
                                                            ParamType
                                                                .DocumentReference,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      'tiln3xf1' /* Details */,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: 100.0,
                                                      height: 40.0,
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .tertiary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMediumIsCustom,
                                                              ),
                                                      elevation: 1.0,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                dateTimeFormat(
                                                  "relative",
                                                  listViewOrderRecord
                                                      .dataOrder!,
                                                  locale: FFLocalizations.of(
                                                          context)
                                                      .languageCode,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .labelSmall
                                                    .override(
                                                      fontFamily:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelSmallFamily,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts:
                                                          !FlutterFlowTheme.of(
                                                                  context)
                                                              .labelSmallIsCustom,
                                                    ),
                                              ),
                                            ].divide(SizedBox(height: 12.0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
