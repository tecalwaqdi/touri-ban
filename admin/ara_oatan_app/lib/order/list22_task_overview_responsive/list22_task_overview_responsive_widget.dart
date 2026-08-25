import '/auth/firebase_auth/auth_util.dart';
import 'dart:ui' as ui;
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/core/app_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/core/app_design_system.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_navigation_service.dart';
import '/core/toury_order_meta.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_payment_flow.dart';
import '/core/toury_order_meta.dart';
import '/backend/schema/enums/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'list22_task_overview_responsive_model.dart';
export 'list22_task_overview_responsive_model.dart';

class List22TaskOverviewResponsiveWidget extends StatefulWidget {
  const List22TaskOverviewResponsiveWidget({super.key});

  static String routeName = 'List22TaskOverviewResponsive';
  static String routePath = '/list22TaskOverviewResponsive';

  @override
  State<List22TaskOverviewResponsiveWidget> createState() =>
      _List22TaskOverviewResponsiveWidgetState();
}

class _List22TaskOverviewResponsiveWidgetState
    extends State<List22TaskOverviewResponsiveWidget> {
  late List22TaskOverviewResponsiveModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => List22TaskOverviewResponsiveModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

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
      child: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: context.dsColors.scaffold,
        appBar: TouryMainAppBar(
          title: 'Reservations'.tr(),
          subtitle: 'ux_my_bookings_sub'.tr(),
          showLogo: false,
        ),
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (responsiveVisibility(
                context: context,
                phone: false,
                tablet: false,
              ))
                Container(
                  width: 270.0,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(0.0),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 24.0, 0.0, 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Icon(
                                Icons.add_task_rounded,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 32.0,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  FFLocalizations.of(context).getText(
                                    'm07n2e4l' /* check.io */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .headlineMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .headlineMediumIsCustom,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 12.0,
                          thickness: 2.0,
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 0.0, 0.0),
                                child: Text(
                                  FFLocalizations.of(context).getText(
                                    'tvbenol8' /* Platform Navigation */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelMediumIsCustom,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: double.infinity,
                                  height: 44.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 6.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.space_dashboard,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              '7z6qk66a' /* Dashboard */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: double.infinity,
                                  height: 44.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 6.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.forum_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'qxccyld3' /* Chats */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: double.infinity,
                                  height: 44.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).accent1,
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 6.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.checklist_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          size: 24.0,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '9wrj1aa5' /* All Tasks */,
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMediumFamily,
                                                        letterSpacing: 0.0,
                                                        useGoogleFonts:
                                                            !FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMediumIsCustom,
                                                      ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 32.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: Align(
                                            alignment:
                                                const AlignmentDirectional(
                                                    0.0, 0.0),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      8.0, 4.0, 8.0, 4.0),
                                              child: Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '83l0gq34' /* 12 */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      fontFamily:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMediumFamily,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .info,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts:
                                                          !FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMediumIsCustom,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: double.infinity,
                                  height: 44.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 6.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.work,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'j8uycbsl' /* Projects */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  FFLocalizations.of(context).getText(
                                    '1zd1cy7f' /* Settings */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .labelMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .labelMediumIsCustom,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: double.infinity,
                                  height: 44.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 6.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.attach_money_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'zhj23j26' /* Billing */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: double.infinity,
                                  height: 44.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 6.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.wifi_tethering_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                          child: Text(
                                            FFLocalizations.of(context).getText(
                                              'ylbdocbi' /* Explore */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ].divide(const SizedBox(height: 12.0)),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(0.0, -1.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 8.0, 0.0, 16.0),
                            child: Container(
                              width: 250.0,
                              height: 50.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          setDarkModeSetting(
                                              context, ThemeMode.light);
                                        },
                                        child: Container(
                                          width: 115.0,
                                          height: 100.0,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.light
                                                ? FlutterFlowTheme.of(context)
                                                    .secondaryBackground
                                                : FlutterFlowTheme.of(context)
                                                    .primaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            border: Border.all(
                                              color: valueOrDefault<Color>(
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .alternate
                                                    : FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                FlutterFlowTheme.of(context)
                                                    .alternate,
                                              ),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.wb_sunny_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.light
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText
                                                    : FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                size: 16.0,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        4.0, 0.0, 0.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    'nwm1u981' /* Light Mode */,
                                                  ),
                                                  style:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .light
                                                                ? FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText
                                                                : FlutterFlowTheme.of(
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
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          setDarkModeSetting(
                                              context, ThemeMode.dark);
                                        },
                                        child: Container(
                                          width: 115.0,
                                          height: 100.0,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? FlutterFlowTheme.of(context)
                                                    .secondaryBackground
                                                : FlutterFlowTheme.of(context)
                                                    .primaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            border: Border.all(
                                              color: valueOrDefault<Color>(
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .alternate
                                                    : FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                FlutterFlowTheme.of(context)
                                                    .primaryBackground,
                                              ),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.nightlight_round,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText
                                                    : FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                size: 16.0,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        4.0, 0.0, 0.0, 0.0),
                                                child: Text(
                                                  FFLocalizations.of(context)
                                                      .getText(
                                                    '1qy8wvsy' /* Dark Mode */,
                                                  ),
                                                  style:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText
                                                                : FlutterFlowTheme.of(
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
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Divider(
                          height: 12.0,
                          thickness: 2.0,
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 12.0, 16.0, 12.0),
                          child: AuthUserStreamWidget(
                            builder: (context) => Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  width: 50.0,
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).accent1,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: TouryAvatarImage(
                                        url: currentUserPhoto,
                                        size: 44.0,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            12.0, 0.0, 0.0, 0.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentUserDisplayName.isNotEmpty
                                              ? currentUserDisplayName
                                              : '—',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLargeFamily,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyLargeIsCustom,
                                              ),
                                        ),
                                        Text(
                                          currentUserEmail.isNotEmpty
                                              ? currentUserEmail
                                              : '—',
                                          style: FlutterFlowTheme.of(context)
                                              .labelMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMediumFamily,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .labelMediumIsCustom,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.menu_open_rounded,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                size: 24.0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Align(
                  alignment: const AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 970.0,
                    ),
                    decoration: const BoxDecoration(),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: TouryLayout.bottomNavSafe(context) + 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (responsiveVisibility(
                            context: context,
                            phone: false,
                            tablet: false,
                          ))
                            Container(
                              width: double.infinity,
                              height: 24.0,
                              decoration: const BoxDecoration(),
                            ),
                          if (responsiveVisibility(
                            context: context,
                            phone: false,
                          ))
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16.0, 16.0, 0.0, 4.0),
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'x24brybc' /* All Tasks */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .headlineMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .headlineMediumIsCustom,
                                    ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.md,
                              DsSpacing.md,
                              0,
                            ),
                            child: DsInformationCard(
                              title: 'Reservations'.tr(),
                              message: 'ux_my_bookings_sub'.tr(),
                              icon: Icons.calendar_month_rounded,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.sm,
                              DsSpacing.md,
                              0,
                            ),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'uxg886tt' /* A list of orders or reservatio... */,
                              ),
                              style: context.dsTypography.bodyMedium.copyWith(
                                color: context.dsColors.textSecondary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (responsiveVisibility(
                                  context: context,
                                  phone: false,
                                ))
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            16.0, 0.0, 0.0, 0.0),
                                    child: SizedBox(
                                      width: 300.0,
                                      child: TextFormField(
                                        controller: _model.textController,
                                        focusNode: _model.textFieldFocusNode,
                                        autofocus: false,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          labelText: FFLocalizations.of(context)
                                              .getText(
                                            'kqh2uhee' /* Search all tasks... */,
                                          ),
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMediumFamily,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .labelMediumIsCustom,
                                              ),
                                          hintStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMediumFamily,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .labelMediumIsCustom,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                              width: 2.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                  20.0, 0.0, 0.0, 0.0),
                                          suffixIcon: Icon(
                                            Icons.search_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                          ),
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMediumFamily,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .bodyMediumIsCustom,
                                            ),
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                        validator: _model
                                            .textControllerValidator
                                            .asValidator(context),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          StreamBuilder<List<OrderRecord>>(
                            stream: TouryFirestoreCache.userOrdersStream(
                              currentUserReference,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: DsSpacing.huge,
                                  ),
                                  child: DsErrorState(
                                    title: 'load_error_title'.tr(),
                                    message: 'load_error_message'.tr(),
                                    retryLabel: 'ux_retry'.tr(),
                                    onRetry: () {
                                      TouryFirestoreCache.invalidateUserOrders(
                                        currentUserReference,
                                      );
                                      safeSetState(() {});
                                    },
                                  ),
                                );
                              }
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: DsSpacing.huge,
                                  ),
                                  child: DsLoading(),
                                );
                              }
                              List<OrderRecord> listViewOrderRecordList =
                                  snapshot.data ?? const <OrderRecord>[];

                              if (listViewOrderRecordList.isEmpty) {
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 280,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: DsSpacing.huge,
                                      horizontal: DsSpacing.md,
                                    ),
                                    child: DsEmptyState(
                                      icon: DsIcons.bookings,
                                      title: 'ux_no_bookings_title'.tr(),
                                      message: 'ux_no_bookings_msg'.tr(),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  DsSpacing.xs,
                                  0,
                                  DsSpacing.huge,
                                ),
                                primary: false,
                                shrinkWrap: true,
                                cacheExtent: 560,
                                addRepaintBoundaries: true,
                                addAutomaticKeepAlives: false,
                                scrollDirection: Axis.vertical,
                                itemCount: listViewOrderRecordList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: DsSpacing.xs),
                                itemBuilder: (context, listViewIndex) {
                                  final listViewOrderRecord =
                                      listViewOrderRecordList[listViewIndex];
                                  return _TouryBookingCard(
                                    order: listViewOrderRecord,
                                    onOpen: () {
                                      context.pushNamed(
                                        TfaselOrderWidget.routeName,
                                        queryParameters: {
                                          'idorder': serializeParam(
                                            listViewOrderRecord,
                                            ParamType.Document,
                                          ),
                                        }.withoutNulls,
                                        extra: <String, dynamic>{
                                          'idorder': listViewOrderRecord,
                                        },
                                      );
                                    },
                                    onMap: () async {
                                      final pts = listViewOrderRecord
                                          .trackingRouteWaypoints();
                                      if (pts.isEmpty) {
                                        final pickup =
                                            listViewOrderRecord.customerPickup;
                                        if (pickup != null) {
                                          await TouryNavigationService
                                              .openGoogleMapsNavigation(
                                            destination: pickup,
                                            localeKey:
                                                TouryNavigationService
                                                    .localeForContext(context),
                                          );
                                        }
                                        return;
                                      }
                                      await TouryNavigationService
                                          .openGoogleMapsNavigation(
                                        origin: pts.first,
                                        destination: pts.last,
                                        waypoints: pts.length > 2
                                            ? pts.sublist(1, pts.length - 1)
                                            : const [],
                                        localeKey: TouryNavigationService
                                            .localeForContext(context),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
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

class _TouryBookingCard extends StatelessWidget {
  const _TouryBookingCard({
    required this.order,
    required this.onOpen,
    required this.onMap,
  });

  final OrderRecord order;
  final VoidCallback onOpen;
  final VoidCallback onMap;

  ({String key, Color color, IconData icon}) _status(
    BuildContext context,
  ) {
    final enumName = order.halhOrder?.name.toLowerCase() ?? '';
    final raw = '${order.halhText} ${order.halh}'.toLowerCase();
    final code = BookingStatusLocalizer.resolveCode(
      statusCode: order.statusCode,
      halhText: order.halhText,
    );

    if (code == TouryBookingStatusCodes.cancelled ||
        code == TouryBookingStatusCodes.cancelledByCustomer ||
        code == TouryBookingStatusCodes.cancelledByDriver ||
        code == TouryBookingStatusCodes.cancelledByAdmin ||
        enumName == 'canceled' ||
        raw.contains('ملغي') ||
        raw.contains('cancel')) {
      return (
        key: 'wallet_status_cancelled',
        color: FlutterFlowTheme.of(context).error,
        icon: Icons.cancel_outlined,
      );
    }

    // Never treat payment enum "Paid" as trip completed.
    if (BookingStatusLocalizer.isTripCompleted(
          statusCode: order.statusCode,
          halhText: order.halhText,
          driverOrderStatus: order.halhOrderMndob?.name,
        ) ||
        raw.contains('مكتمل')) {
      return (
        key: 'wallet_status_completed',
        color: FlutterFlowTheme.of(context).success,
        icon: Icons.check_circle_outline,
      );
    }

    if (order.isDriverEnRoute ||
        order.halhOrderMndob?.name.toLowerCase() == 'accepted' ||
        code == TouryBookingStatusCodes.driverAssigned ||
        code == TouryBookingStatusCodes.driverArrived ||
        code == TouryBookingStatusCodes.tripInProgress) {
      return (
        key: 'booking_status_active',
        color: FlutterFlowTheme.of(context).primary,
        icon: Icons.directions_car_filled_outlined,
      );
    }

    if (order.isAwaitingPayment ||
        code == TouryBookingStatusCodes.paymentPending) {
      return (
        key: 'status_awaiting_payment',
        color: FlutterFlowTheme.of(context).tertiary,
        icon: Icons.payments_outlined,
      );
    }

    return (
      key: 'wallet_status_pending',
      color: FlutterFlowTheme.of(context).warning,
      icon: Icons.schedule_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final status = _status(context);
    final hasRoute = order.trackingRouteWaypoints().isNotEmpty ||
        order.customerPickup != null;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.xxs,
      ),
      child: DsPressable(
        onTap: onOpen,
        child: DsCard(
          elevated: true,
          padding: DsSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: DsConstants.avatarMd,
                    height: DsConstants.avatarMd,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.14),
                      borderRadius: DsRadius.medium,
                    ),
                    child: Icon(status.icon, color: status.color, size: DsIcons.sm),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.iDorder}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.titleMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (order.villText.trim().isNotEmpty) ...[
                          const SizedBox(height: DsSpacing.xxs),
                          Text(
                            order.villText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: DsSpacing.chipPadding,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.13),
                      borderRadius: DsRadius.pill,
                    ),
                    child: Text(
                      status.key.tr(),
                      style: typography.labelSmall.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.sm),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: DsSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: DsIcons.xs,
                    color: colors.iconMuted,
                  ),
                  const SizedBox(width: DsSpacing.xs),
                  Expanded(
                    child: Text(
                      order.dataOrder == null
                          ? ''
                          : dateTimeFormat(
                              'yMMMd',
                              order.dataOrder!,
                              locale: context.locale.toString(),
                            ),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  if (order.isAwaitingPayment)
                    DsButton.text(
                      label: 'order_complete_payment'.tr(),
                      icon: Icons.payment_rounded,
                      size: DsButtonSize.sm,
                      onPressed: () async {
                        final result =
                            await touryRetryUnpaidOrderPayment(order: order);
                        if (!context.mounted) return;
                        if (!result.success) {
                          TouryDialogs.showSnackBar(
                            context,
                            result.errorMessage ??
                                'checkout_payment_temporarily_unavailable'
                                    .tr(),
                            type: TouryMessageType.error,
                          );
                          return;
                        }
                        await touryNavigateAfterCardPayment(
                          context,
                          result: result,
                          paymentFlowType: TypeHgz.Rhlh,
                        );
                      },
                    )
                  else if (hasRoute)
                    DsButton.text(
                      label: 'booking_view_route'.tr(),
                      icon: Icons.route_rounded,
                      size: DsButtonSize.sm,
                      onPressed: onMap,
                    ),
                  Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: colors.iconMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
