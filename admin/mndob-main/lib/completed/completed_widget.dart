import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_design_system.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_online_state.dart';
import '/core/driver_order_match.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import '/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'completed_model.dart';
export 'completed_model.dart';

/// Completed مكتملة
class CompletedWidget extends StatefulWidget {
  const CompletedWidget({super.key});

  static String routeName = 'Completed';
  static String routePath = '/Completed';

  @override
  State<CompletedWidget> createState() => _CompletedWidgetState();
}

class _CompletedWidgetState extends State<CompletedWidget> {
  late CompletedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CompletedModel());

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
          return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: context.dsColors.scaffold,
        appBar: DsAppBar(
          title: FFLocalizations.of(context).getText(
            '49igunvq' /* Completed requests */,
          ),
          centerTitle: false,
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
                          color: context.dsColors.error,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: context.dsColors.divider,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              't4jivayf' /* This account is inactive. For ... */,
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
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '${FFLocalizations.of(context).getText('error')}\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
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
                      List<OrderRecord> listViewOrderRecordList =
                          snapshot.data!
                              .where(
                                (o) =>
                                    DriverTripActionGates.isCompletedListItem(
                                  (o.snapshotData['status_code'] ?? '')
                                      .toString(),
                                  o.halhText,
                                ),
                              )
                              .toList();

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
                                      listViewOrderRecord.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                );
                              },
                              child: Material(
                                color: Colors.transparent,
                                elevation: 2.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: context.dsColors.surface,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 16.0, 16.0, 16.0),
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
                                                    context.dsColors.primarySoft,
                                                shape: BoxShape.circle,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(30.0),
                                                child:
                                                            Image(
                                        fit: BoxFit.cover,
                                        image: (listViewOrderRecord.imgProfileClent.isNotEmpty)
                                            ? NetworkImage(listViewOrderRecord.imgProfileClent)
                                            : const AssetImage('assets/images/logo.png') as ImageProvider,
                                      )
                                                
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    listViewOrderRecord
                                                        .naimUserText,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLargeFamily,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyLargeIsCustom,
                                                        ),
                                                  ),
                                                  SingleChildScrollView(
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Icon(
                                                              Icons.schedule,
                                                              color: context.dsColors.textSecondary,
                                                              size: 12.0,
                                                            ),
                                                            Text(
                                                              'الساعات: ${listViewOrderRecord.totalTaim.toString()}',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmall
                                                                  .override(
                                                                    fontFamily: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmallFamily,
                                                                    color: context.dsColors.textSecondary,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        !FlutterFlowTheme.of(
                                                                                context)
                                                                            .bodySmallIsCustom,
                                                                  ),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 4.0)),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .grid_3x3_sharp,
                                                              color: context.dsColors.textSecondary,
                                                              size: 12.0,
                                                            ),
                                                            Text(
                                                              listViewOrderRecord
                                                                  .iDorder,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmall
                                                                  .override(
                                                                    fontFamily: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmallFamily,
                                                                    color: context.dsColors.textSecondary,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        !FlutterFlowTheme.of(
                                                                                context)
                                                                            .bodySmallIsCustom,
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
                                                                await Clipboard.setData(
                                                                    ClipboardData(
                                                                        text: listViewOrderRecord
                                                                            .iDorder));
                                                                ScaffoldMessenger
                                                                        .of(context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'تم ا',
                                                                      style:
                                                                          TextStyle(
                                                                        color: context.dsColors.textPrimary,
                                                                      ),
                                                                    ),
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            4000),
                                                                    backgroundColor:
                                                                        context.dsColors.secondary,
                                                                  ),
                                                                );
                                                              },
                                                              child: Icon(
                                                                Icons
                                                                    .content_copy,
                                                                color: context.dsColors.textPrimary,
                                                                size: 12.0,
                                                              ),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 4.0)),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Icon(
                                                              Icons.place,
                                                              color: context.dsColors.textSecondary,
                                                              size: 12.0,
                                                            ),
                                                            Text(
                                                              'المعالم: ${listViewOrderRecord.addCartNumer.toString()}',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmall
                                                                  .override(
                                                                    fontFamily: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmallFamily,
                                                                    color: context.dsColors.textSecondary,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        !FlutterFlowTheme.of(
                                                                                context)
                                                                            .bodySmallIsCustom,
                                                                  ),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 4.0)),
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 16.0)),
                                                    ),
                                                  ),
                                                ].divide(SizedBox(height: 4.0)),
                                              ),
                                            ),
                                          ].divide(SizedBox(width: 12.0)),
                                        ),
                                        Divider(
                                          thickness: 1.0,
                                          color: context.dsColors.border,
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'z3snkf0u' /* Total Earnings */,
                                                  ),
                                                  style:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            letterSpacing: 0.0,
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
                                                    formatType:
                                                        FormatType.decimal,
                                                    decimalType:
                                                        DecimalType.automatic,
                                                    currency: ' ر.س ',
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .headlineSmall
                                                      .override(
                                                        fontFamily:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .headlineSmallFamily,
                                                        color:
                                                            context.dsColors.primary,
                                                        letterSpacing: 0.0,
                                                        useGoogleFonts:
                                                            !FlutterFlowTheme
                                                                    .of(context)
                                                                .headlineSmallIsCustom,
                                                      ),
                                                ),
                                              ].divide(SizedBox(height: 4.0)),
                                            ),
                                            FFButtonWidget(
                                              onPressed: () async {
                                                context.pushNamed(
                                                  TfaselOrserWidget.routeName,
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
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                'd1vcn2dg' /* Details */,
                                              ),
                                              options: FFButtonOptions(
                                                width: 100.0,
                                                height: 40.0,
                                                padding: EdgeInsets.all(8.0),
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    context.dsColors.secondary,
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMediumFamily,
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMediumIsCustom,
                                                        ),
                                                elevation: 1.0,
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          dateTimeFormat(
                                            "relative",
                                            listViewOrderRecord.dataOrder!,
                                            locale: FFLocalizations.of(context)
                                                .languageCode,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmallFamily,
                                                color:
                                                    context.dsColors.textSecondary,
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
        },
      ),
    );
  }
}
