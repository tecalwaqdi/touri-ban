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
import '/core/toury_async_action_guard.dart';
import '/core/toury_booking_filter.dart';
import '/core/toury_booking_status_localizer.dart';
import '/core/toury_currency.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_payment_flow.dart';
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
                          const _TouryBookingsSection(),
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

/// Bookings list with status segmentation, skeleton loading and per-tab
/// empty states.
class _TouryBookingsSection extends StatefulWidget {
  const _TouryBookingsSection();

  @override
  State<_TouryBookingsSection> createState() => _TouryBookingsSectionState();
}

class _TouryBookingsSectionState extends State<_TouryBookingsSection> {
  static const _tabs = <TouryBookingBucket>[
    TouryBookingBucket.active,
    TouryBookingBucket.awaitingPayment,
    TouryBookingBucket.completed,
    TouryBookingBucket.cancelled,
  ];

  TouryBookingBucket _selected = TouryBookingBucket.active;

  static String _tabLabelKey(TouryBookingBucket bucket) {
    switch (bucket) {
      case TouryBookingBucket.active:
        return 'bookings_tab_current';
      case TouryBookingBucket.awaitingPayment:
        return 'bookings_tab_awaiting_payment';
      case TouryBookingBucket.completed:
        return 'bookings_tab_completed';
      case TouryBookingBucket.cancelled:
        return 'bookings_tab_cancelled';
    }
  }

  static ({String titleKey, String messageKey, IconData icon}) _emptyFor(
    TouryBookingBucket bucket,
  ) {
    switch (bucket) {
      case TouryBookingBucket.active:
        return (
          titleKey: 'bookings_empty_active_title',
          messageKey: 'bookings_empty_active_msg',
          icon: Icons.directions_car_filled_outlined,
        );
      case TouryBookingBucket.awaitingPayment:
        return (
          titleKey: 'bookings_empty_payment_title',
          messageKey: 'bookings_empty_payment_msg',
          icon: Icons.payments_outlined,
        );
      case TouryBookingBucket.completed:
        return (
          titleKey: 'bookings_empty_completed_title',
          messageKey: 'bookings_empty_completed_msg',
          icon: Icons.check_circle_outline,
        );
      case TouryBookingBucket.cancelled:
        return (
          titleKey: 'bookings_empty_cancelled_title',
          messageKey: 'bookings_empty_cancelled_msg',
          icon: Icons.cancel_outlined,
        );
    }
  }

  /// Blocks the second tap of a double-tap from pushing a duplicate route.
  bool _claimNavigation() {
    final now = DateTime.now();
    final last = _lastNavigationAt;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return false;
    }
    _lastNavigationAt = now;
    return true;
  }

  DateTime? _lastNavigationAt;

  void _openDetails(OrderRecord order) {
    if (!_claimNavigation()) return;
    context.pushNamed(
      TfaselOrderWidget.routeName,
      queryParameters: {
        'idorder': serializeParam(order, ParamType.Document),
      }.withoutNulls,
      extra: <String, dynamic>{'idorder': order},
    );
  }

  void _openTracking(OrderRecord order) {
    if (!_claimNavigation()) return;
    context.pushNamed(
      MapTrdemoWidget.routeName,
      queryParameters: {
        'idd': serializeParam(order.reference, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  Future<void> _openExternalRoute(OrderRecord order) async {
    final localeKey = TouryNavigationService.localeForContext(context);
    final pts = order.trackingRouteWaypoints();
    if (pts.isEmpty) {
      final pickup = order.customerPickup;
      if (pickup == null) return;
      await TouryNavigationService.openGoogleMapsNavigation(
        destination: pickup,
        localeKey: localeKey,
      );
      return;
    }
    await TouryNavigationService.openGoogleMapsNavigation(
      origin: pts.first,
      destination: pts.last,
      waypoints: pts.length > 2 ? pts.sublist(1, pts.length - 1) : const [],
      localeKey: localeKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderRecord>>(
      stream: TouryFirestoreCache.userOrdersStream(currentUserReference),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: DsSpacing.huge),
            child: DsErrorState(
              title: 'load_error_title'.tr(),
              message: 'load_error_message'.tr(),
              retryLabel: 'ux_retry'.tr(),
              onRetry: () {
                TouryFirestoreCache.invalidateUserOrders(currentUserReference);
                safeSetState(() {});
              },
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _BookingsSkeleton();
        }

        final all = snapshot.data ?? const <OrderRecord>[];

        if (all.isEmpty) {
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 280),
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

        final counts = touryCountBuckets(all);
        final visible = touryFilterBookings(all, _selected);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: DsSpacing.xs),
                itemBuilder: (context, index) {
                  final bucket = _tabs[index];
                  return _BookingTab(
                    label: _tabLabelKey(bucket).tr(),
                    count: counts[bucket] ?? 0,
                    selected: bucket == _selected,
                    onTap: () => safeSetState(() => _selected = bucket),
                  );
                },
              ),
            ),
            const SizedBox(height: DsSpacing.xs),
            if (visible.isEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 240),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DsSpacing.xl,
                    horizontal: DsSpacing.md,
                  ),
                  child: Builder(
                    builder: (context) {
                      final empty = _emptyFor(_selected);
                      return DsEmptyState(
                        icon: empty.icon,
                        title: empty.titleKey.tr(),
                        message: empty.messageKey.tr(),
                      );
                    },
                  ),
                ),
              )
            else
              ListView.separated(
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
                itemCount: visible.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DsSpacing.xs),
                itemBuilder: (context, index) {
                  final order = visible[index];
                  return _TouryBookingCard(
                    key: ValueKey(order.reference.id),
                    order: order,
                    onOpen: () => _openDetails(order),
                    onTrack: () => _openTracking(order),
                    onMap: () => _openExternalRoute(order),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _BookingTab extends StatelessWidget {
  const _BookingTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: DsRadius.pill,
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: typography.labelMedium.copyWith(
                color: selected ? colors.onPrimary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: DsSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.onPrimary.withValues(alpha: 0.22)
                      : colors.primarySoft,
                  borderRadius: DsRadius.pill,
                ),
                child: Text(
                  '$count',
                  style: typography.labelSmall.copyWith(
                    color: selected ? colors.onPrimary : colors.primaryStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingsSkeleton extends StatelessWidget {
  const _BookingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.md,
        DsSpacing.sm,
        DsSpacing.md,
        DsSpacing.huge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsShimmer(width: 92, height: 34, borderRadius: DsRadius.pill),
              const SizedBox(width: DsSpacing.xs),
              DsShimmer(width: 92, height: 34, borderRadius: DsRadius.pill),
              const SizedBox(width: DsSpacing.xs),
              DsShimmer(width: 92, height: 34, borderRadius: DsRadius.pill),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpacing.sm),
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        DsShimmer(
                          width: 40,
                          height: 40,
                          borderRadius: DsRadius.medium,
                        ),
                        const SizedBox(width: DsSpacing.sm),
                        const Expanded(child: DsShimmer(height: 14)),
                        const SizedBox(width: DsSpacing.sm),
                        DsShimmer(
                          width: 64,
                          height: 22,
                          borderRadius: DsRadius.pill,
                        ),
                      ],
                    ),
                    const SizedBox(height: DsSpacing.md),
                    const DsShimmer(height: 12),
                    const SizedBox(height: DsSpacing.xs),
                    const DsShimmer(height: 12),
                    const SizedBox(height: DsSpacing.md),
                    const DsShimmer(height: 32),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TouryBookingCard extends StatelessWidget {
  const _TouryBookingCard({
    super.key,
    required this.order,
    required this.onOpen,
    required this.onTrack,
    required this.onMap,
  });

  final OrderRecord order;
  final VoidCallback onOpen;
  final VoidCallback onTrack;
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

  String _pickupLabel() {
    final raw = order.loceshStreng.trim();
    if (raw.isNotEmpty) return raw;
    if (order.villText.trim().isNotEmpty) return order.villText.trim();
    return 'booking_pickup_unknown'.tr();
  }

  String? _destinationLabel() {
    if (order.listAmakn.isEmpty) return null;
    final label = order.listAmakn.last.displayLabel.trim();
    return label.isEmpty ? null : label;
  }

  String _vehicleLabel() {
    final parts = <String>[
      if (order.nameCar.trim().isNotEmpty) order.nameCar.trim(),
      if (order.modelCar.trim().isNotEmpty) order.modelCar.trim(),
    ];
    return parts.join(' · ');
  }

  String _money(BuildContext context) {
    final total = order.total;
    if (total <= 0) return '';
    final formatted = formatNumber(
      total,
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
    );
    final currency = TouryCurrency.displaySymbolForOrder(order).trim();
    return currency.isEmpty ? formatted : '$formatted $currency';
  }

  Future<void> _completePayment(BuildContext context) async {
    // Rapid taps must never create a second payment attempt for this order.
    final guardKey = 'payment:retry:${order.reference.id}';
    if (!TouryAsyncActionGuard.tryStart(guardKey)) return;
    try {
      final result = await touryRetryUnpaidOrderPayment(order: order);
      if (!context.mounted) return;
      if (!result.success) {
        TouryDialogs.showSnackBar(
          context,
          result.errorMessage ??
              'checkout_payment_temporarily_unavailable'.tr(),
          type: TouryMessageType.error,
        );
        return;
      }
      await touryNavigateAfterCardPayment(
        context,
        result: result,
        paymentFlowType: TypeHgz.Rhlh,
      );
    } finally {
      TouryAsyncActionGuard.finish(guardKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final status = _status(context);
    final hasRoute = order.trackingRouteWaypoints().isNotEmpty ||
        order.customerPickup != null;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    final destination = _destinationLabel();
    final vehicle = _vehicleLabel();
    final driver = order.naimMndobText.trim();
    final money = _money(context);
    final canTrack = order.driverLivePosition != null && order.isDriverEnRoute;

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
                    child:
                        Icon(status.icon, color: status.color, size: DsIcons.sm),
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
                        if (order.dataOrder != null) ...[
                          const SizedBox(height: DsSpacing.xxs),
                          Text(
                            dateTimeFormat(
                              'yMMMd · jm',
                              order.dataOrder!,
                              locale: context.locale.toString(),
                            ),
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
              _RouteLine(
                pickup: _pickupLabel(),
                destination: destination,
              ),
              if (vehicle.isNotEmpty || driver.isNotEmpty) ...[
                const SizedBox(height: DsSpacing.sm),
                Wrap(
                  spacing: DsSpacing.xs,
                  runSpacing: DsSpacing.xxs,
                  children: [
                    if (vehicle.isNotEmpty)
                      _MetaChip(icon: DsIcons.car, label: vehicle),
                    if (driver.isNotEmpty)
                      _MetaChip(
                        icon: Icons.person_outline_rounded,
                        label: driver,
                      ),
                    if (order.totalTaim > 0)
                      _MetaChip(
                        icon: Icons.schedule_outlined,
                        label: 'order_hours_label'.tr(
                          namedArgs: {'hours': order.totalTaim.toString()},
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: DsSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (money.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            money,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.titleMedium.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            order.paymentMethod == PaymentMethod.Cash
                                ? 'order_pay_method_cash'.tr()
                                : PaymentStatusLocalizer.label(
                                    (order.snapshotData['payment_status'] ?? '')
                                        .toString(),
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.labelSmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  if (order.isAwaitingPayment)
                    DsButton.primary(
                      label: 'order_complete_payment'.tr(),
                      icon: Icons.payment_rounded,
                      size: DsButtonSize.sm,
                      onPressed: () => _completePayment(context),
                    )
                  else if (canTrack)
                    DsButton.primary(
                      label: 'order_track_driver'.tr(),
                      icon: Icons.my_location_rounded,
                      size: DsButtonSize.sm,
                      onPressed: onTrack,
                    )
                  else if (hasRoute)
                    DsButton.outlined(
                      label: 'booking_view_route'.tr(),
                      icon: Icons.route_rounded,
                      size: DsButtonSize.sm,
                      onPressed: onMap,
                    )
                  else
                    DsButton.outlined(
                      label: 'booking_view_details'.tr(),
                      icon: isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: DsButtonSize.sm,
                      onPressed: onOpen,
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

/// Pickup → destination with a connector rail.
class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.pickup, this.destination});

  final String pickup;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final dest = destination;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: colors.success,
                  shape: BoxShape.circle,
                ),
              ),
              if (dest != null) ...[
                Container(
                  width: 2,
                  height: 18,
                  color: colors.border,
                ),
                Icon(Icons.place, size: 12, color: colors.error),
              ],
            ],
          ),
        ),
        const SizedBox(width: DsSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (dest != null) ...[
                const SizedBox(height: DsSpacing.sm),
                Text(
                  dest,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: DsRadius.pill,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.iconMuted),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.labelSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
