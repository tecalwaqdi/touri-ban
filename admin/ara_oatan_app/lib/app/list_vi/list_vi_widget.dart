import 'package:easy_localization/easy_localization.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/toury_content_locale.dart';
import '/core/toury_mkan_i18n.dart';
import '/core/toury_landmark_filter.dart';
import '/core/toury_landmark_categories.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:text_search/text_search.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/core/toury_checkout_state.dart';
import '/core/toury_db_hero.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_mkan_pagination.dart';
import '/core/toury_perf.dart';
import '/core/app_ux_widgets.dart';
import '/core/app_design_system.dart';
import '/core/toury_landmark_skeleton.dart';
import '/core/toury_image.dart';
import '/core/toury_geo_aliases.dart';
import 'list_vi_model.dart';
export 'list_vi_model.dart';

/// خانة للبحث اول الصفحة
class ListViWidget extends StatefulWidget {
  const ListViWidget({
    super.key,
    required this.cite,
  });

  final DocumentReference? cite;

  static String routeName = 'List_vi';
  static String routePath = '/listVi';

  @override
  State<ListViWidget> createState() => _ListViWidgetState();
}

class _ListViWidgetState extends State<ListViWidget>
    with TickerProviderStateMixin {
  late ListViModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  late final TouryMkanPaginationController _mkanPage;
  Future<int>? _chatCountFuture;

  Future<int> _chatCount() => _chatCountFuture ??= TouryFirestoreCache.chatTodayCount(
        currentUserRef: currentUserReference,
      );

  Future<void> _runLandmarkSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _model.sser = false;
      safeSetState(() {});
      return;
    }

    _model.sser = true;
    safeSetState(() {});

    void applySearch() {
      _model.simpleSearchResults = TextSearch(
        _mkanPage.items
            .map(
              (record) => TextSearchItem.fromTerms(
                record,
                touryMkanSearchTerms(record),
              ),
            )
            .toList(),
      )
          .search(trimmed)
          .map((r) => r.object)
          .toList()
          .cast<MkanRecord>();
    }

    applySearch();
    if (_model.simpleSearchResults.isEmpty && _mkanPage.hasMore) {
      await _mkanPage.ensureLoadedForSearch(maxExtraPages: 2);
      if (!mounted) return;
      applySearch();
    }
    safeSetState(() {});
  }

  void _bindVillage(DocumentReference village) {
    final canonical = touryCanonicalVillageRef(village);
    if (FFAppState().villa?.path != canonical.path) {
      FFAppState().villa = canonical;
    }
    _mkanPage.bindVillage(canonical);
  }

  /// تحديث عدّاد السلة بعد الإطار الحالي — الضغط يستجيب فوراً.
  void _refreshCartBadgeDeferred() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) safeSetState(() {});
    });
  }

  void _onAppVillageChanged() {
    // مسار الشاشة (cite) له الأولوية على villa المخزّن.
    final village = widget.cite ?? FFAppState().villa;
    if (village != null &&
        _mkanPage.villagePath != touryCanonicalVillageRef(village).path) {
      _bindVillage(village);
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListViModel());
    _mkanPage = TouryMkanPaginationController();
    FFAppState().addListener(_onAppVillageChanged);

    final village = widget.cite ?? FFAppState().villa;
    if (village != null) {
      _bindVillage(village);
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      tourySyncBookingFlags();
      _model.sser = false;
    });

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    if (!TouryPerf.skipHeavyAnimations) {
      _initAnimations();
    }
  }

  void _initAnimations() {
    animationsMap.addAll({
      'textOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
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
            begin: const Offset(0.0, 60.0),
            end: const Offset(0.0, 0.0),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.95, 1.0),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 510.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 510.0.ms,
            begin: const Offset(30.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
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
            begin: const Offset(40.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'listViewOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeOut,
            delay: 0.0.ms,
            duration: 450.0.ms,
            begin: 0.0,
            end: 1.0,
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
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(60.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
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
            begin: const Offset(0.0, 40.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'choiceChipsOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 380.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'listViewOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
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
            begin: const Offset(0.0, 80.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'listViewOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
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
            begin: const Offset(0.0, 80.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'listViewOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
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
            begin: const Offset(0.0, 80.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });
  }

  @override
  void didUpdateWidget(ListViWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cite?.path != oldWidget.cite?.path && widget.cite != null) {
      _bindVillage(widget.cite!);
    }
  }

  @override
  void dispose() {
    FFAppState().removeListener(_onAppVillageChanged);
    _mkanPage.dispose();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedVilla = context.select<FFAppState, DocumentReference?>(
      (s) => s.villa,
    );
    final rawVillage = widget.cite ?? selectedVilla;
    if (rawVillage == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: const Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    final villageFilter = touryCanonicalVillageRef(rawVillage);

    if (_mkanPage.villagePath != villageFilter.path) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bindVillage(villageFilter);
      });
    }

    return ListenableBuilder(
      listenable: _mkanPage,
      builder: (context, _) {
        if (_mkanPage.lastError != null && _mkanPage.items.isEmpty) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: TouryEmptyState(
                title: 'load_error_title'.tr(),
                message: 'load_error_message'.tr(),
                icon: Icons.cloud_off_rounded,
                actionLabel: 'ux_retry'.tr(),
                onAction: () => _bindVillage(villageFilter),
              ),
            ),
          );
        }

        final listViMkanRecordList = touryFilterLandmarksForUi(
          _mkanPage.items,
          touryContentLocaleFromContext(context),
        );
        final showLandmarkSkeleton =
            listViMkanRecordList.isEmpty && _mkanPage.isLoading;

        return GestureDetector(
          onTap: () {
            TouryPerf.unfocusIfNeeded(context);
          },
          behavior: HitTestBehavior.deferToChild,
          child: TouryAdaptiveScope(
            child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            drawer: Drawer(
              elevation: 16.0,
              child: WebViewAware(
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: TouryLayout.drawerHeaderHeight(context),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20.0),
                          bottomRight: Radius.circular(22.0),
                        ),
                        shape: BoxShape.rectangle,
                      ),
                      child: Align(
                        alignment: const AlignmentDirectional(0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 12.0, 0.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'browsing_now'.tr(namedArgs: {
                                        'country': FFAppState().naimdolh,
                                      }),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmallFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w100,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelSmallIsCustom,
                                          ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 11.0, 0.0, 0.0),
                                          child: InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              context.pushNamed(
                                                  AldolWidget.routeName);
                                            },
                                            child: Text(
                                              'Change country'.tr(),
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
                                                    fontSize: 11.0,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts:
                                                        !FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMediumIsCustom,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]
                                      .divide(const SizedBox(height: 4.0))
                                      .around(const SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                          ]
                              .divide(const SizedBox(width: 16.0))
                              .around(const SizedBox(width: 16.0)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.vertical,
                        children: [
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(
                                    DemoDWidget.routeName,
                                    queryParameters: {
                                      'isSpeed': serializeParam(
                                        true,
                                        ParamType.bool,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.location_on,
                                      color: FlutterFlowTheme.of(context).error,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                     "Start".tr(),
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelLargeIsCustom,
                                          ),
                                    ),
                                    subtitle: Text(
                                    "Start from your current location".tr(),
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelMediumIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(ListWidget.routeName);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.location_on,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                      FFAppState().naimvillatext,
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelLargeIsCustom,
                                          ),
                                    ),
                                    subtitle: Text(
                                    "Change city".tr(),
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelMediumIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(
                                    Citie2Widget.routeName,
                                    queryParameters: {
                                      'coun': serializeParam(
                                        FFAppState().dolh,
                                        ParamType.DocumentReference,
                                      ),
                                      'naim': serializeParam(
                                        FFAppState().naimdolh,
                                        ParamType.String,
                                      ),
                                      'idcit': serializeParam(
                                        FFAppState().dolh,
                                        ParamType.DocumentReference,
                                      ),
                                      'imgDolh': serializeParam(
                                        FFAppState().imgDolh,
                                        ParamType.String,
                                      ),
                                    }.withoutNulls,
                                  );
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.map,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                      valueOrDefault<String>(
                                        FFAppState().naimmdenh,
                                        'change_region'.tr(),
                                      ),
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelLargeIsCustom,
                                          ),
                                    ),
                                    subtitle: Text(
                                      "Change region".tr(),
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelMediumIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios_outlined,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (FFAppState().ismapview == false)
                            Align(
                              alignment: const AlignmentDirectional(-1.0, -1.0),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 10.0, 0.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    context
                                        .pushNamed(ListViCopyWidget.routeName);

                                    FFAppState().ismapview = false;
                                    safeSetState(() {});
                                  },
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.map_outlined,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        size: 25.0,
                                      ),
                                      title: Text(
                                      "Browse the map".tr(),
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLargeFamily,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .labelLargeIsCustom,
                                            ),
                                      ),
                                      subtitle: Text(
                                        FFAppState().naimvillatext,
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMediumFamily,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontSize: 12.0,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .labelMediumIsCustom,
                                            ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 20.0,
                                      ),
                                      tileColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      dense: false,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (FFAppState().ismapview == true)
                            Align(
                              alignment: const AlignmentDirectional(-1.0, -1.0),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 10.0, 0.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    context.pushNamed(
                                      ListViWidget.routeName,
                                      queryParameters: {
                                        'cite': serializeParam(
                                          FFAppState().vil,
                                          ParamType.DocumentReference,
                                        ),
                                      }.withoutNulls,
                                    );

                                    FFAppState().ismapview = false;
                                    safeSetState(() {});
                                  },
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.list_alt,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        size: 25.0,
                                      ),
                                      title: Text(
                                      "View list".tr(),
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLargeFamily,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .labelLargeIsCustom,
                                            ),
                                      ),
                                      subtitle: Text(
                                        'places_in_city'.tr(namedArgs: {
                                          'city': FFAppState().naimvillatext,
                                        }),
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMediumFamily,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontSize: 12.0,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .labelMediumIsCustom,
                                            ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 20.0,
                                      ),
                                      tileColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      dense: false,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 11.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  touryOpenCheckout(context);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.playlist_add,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                      FFAppState().addcart.toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .titleLargeFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 20.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .titleLargeIsCustom,
                                          ),
                                    ),
                                    subtitle: Text(
                                     "Added destinations".tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelMediumIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios_sharp,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(1.0, 0.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 11.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(
                                      List22TaskOverviewResponsiveWidget
                                          .routeName);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.mail_sharp,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                     "Your Bookings".tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelLargeIsCustom,
                                          ),
                                    ),
                                    subtitle: 
                                    Text(
                                     "Booking list.".tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelMediumIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 11.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(NewPlaceWidget.routeName);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.add_to_photos,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                    "Suggest a Place".tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .titleLargeFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 20.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .titleLargeIsCustom,
                                          ),
                                    ),
                                    subtitle: Text(
                                      "Add a Special Place".tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelMediumIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios_sharp,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(AbutMdenhWidget.routeName);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.sunny_snowing,
                                      color: Color(0xFFF2B507),
                                      size: 25.0,
                                    ),
                                    title: Text(
                                      "general information".tr(),
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelLargeIsCustom,
                                          ),
                                    ),
                                    subtitle: Text(
                                      FFAppState().naimvillatext,
                                      textAlign: TextAlign.start,
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelMediumFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelMediumIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(1.0, 0.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 11.0, 0.0, 0.0),
                              child: FutureBuilder<int>(
                                future: _chatCount(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Icon(
                                      Icons.mail_outline,
                                      size: 20,
                                    );
                                  }
                                  if (!snapshot.hasData) {
                                    return const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  }
                                  int listTileCount = snapshot.data!;

                                  return InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                          List22TaskOverviewResponsiveWidget
                                              .routeName);
                                    },
                                    child: Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.mail_sharp,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 25.0,
                                        ),
                                        title: Text(
                                          valueOrDefault<String>(
                                            listTileCount.toString(),
                                            '0',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .titleLarge
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .titleLargeFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                fontSize: 20.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.normal,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .titleLargeIsCustom,
                                              ),
                                        ),
                                        subtitle: Text(
                                          "Message".tr(),
                                          style: FlutterFlowTheme.of(context)
                                              .labelMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMediumFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .labelMediumIsCustom,
                                              ),
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward_ios,
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
                                          size: 20.0,
                                        ),
                                        tileColor: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        dense: false,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 11.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(Profile05Widget.routeName);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.settings_outlined,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                     "Settings".tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelLargeIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 11.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.pushNamed(SupportWidget.routeName);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.help_outline,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 25.0,
                                    ),
                                    title: Text(
                                     "Help".tr(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .labelLargeFamily,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .labelLargeIsCustom,
                                          ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios_sharp,
                                      color: FlutterFlowTheme.of(context)
                                          .secondary,
                                      size: 20.0,
                                    ),
                                    tileColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    dense: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    Opacity(
                      opacity: 0.3,
                      child: Divider(
                        height: 1.0,
                        thickness: 0.75,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                    ),
                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Align(
                        alignment: const AlignmentDirectional(-1.0, -1.0),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            GoRouter.of(context).prepareAuthEvent();
                            await authManager.signOut();
                            GoRouter.of(context).clearRedirectLocation();

                            context.goNamedAuth(
                                HomePagWidget.routeName, context.mounted);
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: Icon(
                                Icons.logout_rounded,
                                color: FlutterFlowTheme.of(context).error,
                                size: 25.0,
                              ),
                              title: Text(
                                "Log Out".tr(),
                                style: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .labelLargeFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .labelLargeIsCustom,
                                    ),
                              ),
                              tileColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              dense: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            appBar: AppBar(
  backgroundColor: FlutterFlowTheme.of(context).primary,
  automaticallyImplyLeading: false,
  centerTitle: true,
  elevation: 2.0,

  // LEFT (MENU)
  leading:   Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 10, 0),
      child: FlutterFlowIconButton(
        borderRadius: 20.0,
        buttonSize: 40.0,
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),

  title: Text(
    [
      FFAppState().naimmdenh.trim(),
      FFAppState().naimvillatext.trim(),
    ].where((e) => e.isNotEmpty).join(' - '),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: FlutterFlowTheme.of(context).labelLarge.override(
      fontFamily: FlutterFlowTheme.of(context).labelLargeFamily,
      color: FlutterFlowTheme.of(context).secondaryBackground,
      fontSize: 13.0,
    ),
  ),

  // RIGHT (BACK)
  actions: [
  Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 11, 0),
    child: FlutterFlowIconButton(
      borderRadius: 20.0,
      buttonSize: 40.0,
      icon: Icon(
        Icons.menu,
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      onPressed: () {
        scaffoldKey.currentState!.openDrawer();
      },
    ),
  ),
  ],
),

            body: Stack(
              children: [
                Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final heroH = constraints.maxHeight.clamp(
                                200.0,
                                TouryLayout.heroHeight(context),
                              );
                              return Stack(
                            alignment: const AlignmentDirectional(0.0, -1.0),
                            children: [
                                Align(
                                  alignment:
                                      const AlignmentDirectional(0.05, -1.0),
                                  child: TouryVillageHeroBanner(
                                    height: heroH,
                                    villageRef: villageFilter,
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: heroH,
                                  decoration: const BoxDecoration(
                                    color: Color(0x8D090F13),
                                  ),
                                ),
                                Align(
                                  alignment:
                                      const AlignmentDirectional(0.0, 0.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            if (FFAppState().addcart >= 1)
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        0.0, 22.0, 0.0, 0.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(16.0,
                                                                0.0, 8.0, 0.0),
                                                        child: Text(
                                                          '${'destinations_added_label'.tr()} ${FFAppState().addcart}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .labelLarge
                                                              .override(
                                                                fontFamily:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLargeFamily,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLargeIsCustom,
                                                              ),
                                                        ).touryPageAnim(
                                                            animationsMap[
                                                                'textOnPageLoadAnimation1']),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: FFButtonWidget(
                                                      onPressed: () async {
                                                        if (FFAppState().addcart < 1) {
                                                          TouryDialogs.showSnackBar(
                                                            context,
                                                            'add_destination_first'.tr(),
                                                            type: TouryMessageType.warning,
                                                          );
                                                          return;
                                                        }
                                                        touryOpenCheckout(context);
                                                      },
                                                      text: "View My Trip".tr(),
                                                      icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .glasses,
                                                        size: 11.0,
                                                      ),
                                                      options: FFButtonOptions(
                                                        height: 31.76,
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(16.0,
                                                                0.0, 16.0, 0.0),
                                                        iconPadding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(0.0,
                                                                0.0, 0.0, 0.0),
                                                        iconColor: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        textStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .override(
                                                                  fontFamily: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmallFamily,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  fontSize: 9.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .titleSmallIsCustom,
                                                                ),
                                                        elevation: 0.0,
                                                        borderRadius:
                                                            const BorderRadius
                                                                .only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  11.0),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  11.0),
                                                          topLeft:
                                                              Radius.circular(
                                                                  11.0),
                                                          topRight:
                                                              Radius.circular(
                                                                  11.0),
                                                        ),
                                                      ),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(0.0, 32.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomLeft:
                                                    Radius.circular(0.0),
                                                bottomRight:
                                                    Radius.circular(0.0),
                                                topLeft: Radius.circular(16.0),
                                                topRight: Radius.circular(16.0),
                                              ),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      0.0, 8.0, 0.0, 24.0),
                                              child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Divider(
                                                      height: 4.0,
                                                      thickness: 2.0,
                                                      indent: 140.0,
                                                      endIndent: 140.0,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(16.0,
                                                              16.0, 16.0, 0.0),
                                                      child: Text(
                                                     "Experience top destinations".tr(),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  fontFamily: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMediumFamily,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                  fontSize:
                                                                      17.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMediumIsCustom,
                                                                ),
                                                      ).touryPageAnim(
                                                          animationsMap[
                                                              'textOnPageLoadAnimation2']),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(16.0,
                                                              4.0, 16.0, 0.0),
                                                      child: Text(
                                                        FFAppState()
                                                            .naimvillatext,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  fontFamily: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMediumFamily,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                  fontSize:
                                                                      16.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMediumIsCustom,
                                                                ),
                                                      ).touryPageAnim(
                                                          animationsMap[
                                                              'textOnPageLoadAnimation3']),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(0.0,
                                                              12.0, 0.0, 0.0),
                                                      child: Builder(
                                                          builder: (context) {
                                                            final featured =
                                                                touryFilterLandmarksForUi(
                                                              listViMkanRecordList
                                                                  .where((r) =>
                                                                      r.asAds),
                                                              touryContentLocaleFromContext(
                                                                  context),
                                                            );
                                                            // إن لم تُعلَّم معالم كإعلانات، اعرض أول عناصر القرية أعلى الشاشة.
                                                            final listViewMkanRecordList =
                                                                featured
                                                                        .isNotEmpty
                                                                    ? featured
                                                                    : touryFilterLandmarksForUi(
                                                                        listViMkanRecordList
                                                                            .take(8),
                                                                        touryContentLocaleFromContext(
                                                                            context),
                                                                      );
                                                            if (listViewMkanRecordList
                                                                .isEmpty) {
                                                              return const SizedBox
                                                                  .shrink();
                                                            }

                                                            return Container(
                                                              width: double
                                                                  .infinity,
                                                              height: TouryLayout
                                                                  .landmarkAdCarouselHeight(
                                                                      context),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme
                                                                        .of(context)
                                                                    .secondaryBackground,
                                                              ),
                                                              child: ListView
                                                                  .builder(
                                                                padding:
                                                                    const EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                        16.0,
                                                                        1.0,
                                                                        16.0,
                                                                        1.0),
                                                                primary: false,
                                                                scrollDirection:
                                                                    Axis
                                                                        .horizontal,
                                                                itemCount:
                                                                    listViewMkanRecordList
                                                                        .length,
                                                                itemBuilder: (context,
                                                                    listViewIndex) {
                                                                  final listViewMkanRecord =
                                                                      listViewMkanRecordList[
                                                                          listViewIndex];
                                                                  return Padding(
                                                                    padding:
                                                                        EdgeInsetsDirectional
                                                                            .fromSTEB(
                                                                      TouryLayout.pagePadding(context).left,
                                                                      6.0,
                                                                      0.0,
                                                                      6.0,
                                                                    ),
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          TouryLayout.landmarkAdCardWidth(context),
                                                                      height:
                                                                          TouryLayout.landmarkAdCardHeight(context),
                                                                      clipBehavior:
                                                                          Clip.antiAlias,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(
                                                                                context)
                                                                            .secondaryBackground,
                                                                        boxShadow: const [
                                                                          BoxShadow(
                                                                            blurRadius:
                                                                                8.0,
                                                                            color:
                                                                                Color(0x230F1113),
                                                                            offset:
                                                                                Offset(
                                                                              0.0,
                                                                              4.0,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                12.0),
                                                                        border:
                                                                            Border
                                                                                .all(
                                                                          color: FlutterFlowTheme.of(context)
                                                                              .primaryBackground,
                                                                          width:
                                                                              1.0,
                                                                        ),
                                                                      ),
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .stretch,
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
                                                                          onTap:
                                                                              () async {
                                                                            context.pushNamed(
                                                                              PlacedetailsWidget.routeName,
                                                                              queryParameters: {
                                                                                'mk': serializeParam(
                                                                                  listViewMkanRecord.reference,
                                                                                  ParamType.DocumentReference,
                                                                                ),
                                                                                'textnaim': serializeParam(
                                                                                  touryMkanName(context, listViewMkanRecord),
                                                                                  ParamType.String,
                                                                                ),
                                                                              }.withoutNulls,
                                                                            );
                                                                          },
                                                                          child:
                                                                              SizedBox(
                                                                            height: TouryLayout.landmarkAdImageHeight(context),
                                                                            width: double.infinity,
                                                                            child: ClipRRect(
                                                                            borderRadius:
                                                                                const BorderRadius.only(
                                                                              bottomLeft: Radius.circular(0.0),
                                                                              bottomRight: Radius.circular(0.0),
                                                                              topLeft: Radius.circular(12.0),
                                                                              topRight: Radius.circular(12.0),
                                                                            ),
                                                                            child:
                                                                                TouryNetworkImage.fromPlaceImages(
                                                                              img1: listViewMkanRecord.img1,
                                                                              img2: listViewMkanRecord.img2,
                                                                              img3: listViewMkanRecord.img3,
                                                                              documentId: listViewMkanRecord.reference.id,
                                                                              placeName: touryMkanName(context, listViewMkanRecord),
                                                                              latitude: listViewMkanRecord.location?.latitude,
                                                                              longitude: listViewMkanRecord.location?.longitude,
                                                                              width: double.infinity,
                                                                              height: TouryLayout.landmarkAdImageHeight(context),
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          child: Padding(
                                                                          padding: EdgeInsetsDirectional
                                                                              .fromSTEB(
                                                                              12.0,
                                                                              TouryLayout.isCompact(context) ? 6.0 : 8.0,
                                                                              12.0,
                                                                              TouryLayout.isCompact(context) ? 6.0 : 8.0),
                                                                          child:
                                                                              Row(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Expanded(
                                                                                child: Column(
                                                                                mainAxisSize:
                                                                                    MainAxisSize.min,
                                                                                crossAxisAlignment:
                                                                                    CrossAxisAlignment.start,
                                                                                children: [
                                                                                  InkWell(
                                                                                    splashColor: Colors.transparent,
                                                                                    focusColor: Colors.transparent,
                                                                                    hoverColor: Colors.transparent,
                                                                                    highlightColor: Colors.transparent,
                                                                                    onTap: () async {
                                                                                      context.pushNamed(
                                                                                        PlacedetailsWidget.routeName,
                                                                                        queryParameters: {
                                                                                          'mk': serializeParam(
                                                                                            listViewMkanRecord.reference,
                                                                                            ParamType.DocumentReference,
                                                                                          ),
                                                                                          'textnaim': serializeParam(
                                                                                            touryMkanName(context, listViewMkanRecord),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                        }.withoutNulls,
                                                                                      );
                                                                                    },
                                                                                    child: Text(
                                                                                      touryMkanName(context, listViewMkanRecord),
                                                                                      maxLines: 2,
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                                                            fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                                            color: FlutterFlowTheme.of(context).primary,
                                                                                            fontSize: TouryLayout.landmarkTitleFontSize(context),
                                                                                            letterSpacing: 0.0,
                                                                                            useGoogleFonts: !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                  Padding(
                                                                                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
                                                                                    child: Row(
                                                                                      mainAxisSize: MainAxisSize.max,
                                                                                      children: [
                                                                                        RatingBarIndicator(
                                                                                          itemBuilder: (context, index) => Icon(
                                                                                            Icons.radio_button_checked_rounded,
                                                                                            color: FlutterFlowTheme.of(context).primary,
                                                                                          ),
                                                                                          direction: Axis.horizontal,
                                                                                          rating: 5.0,
                                                                                          unratedColor: FlutterFlowTheme.of(context).error,
                                                                                          itemCount: 5,
                                                                                          itemSize: 12.0,
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              ),
                                                                              Row(
                                                                                mainAxisSize:
                                                                                    MainAxisSize.min,
                                                                                children: [
                                                                                  FlutterFlowIconButton(
                                                                                    borderRadius: 6.0,
                                                                                    buttonSize: 33.0,
                                                                                    icon: Icon(
                                                                                      Icons.add_circle,
                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                      size: 12.0,
                                                                                    ),
                                                                                    onPressed: () async {
                                                                                      if (touryLandmarkAlreadyInCart(listViewMkanRecord.reference)) {
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                          SnackBar(
                                                                                            content: Text(
                                                                                              'landmark_already_in_cart'.tr(),
                                                                                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                    fontFamily: 'cairo',
                                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    letterSpacing: 0.0,
                                                                                                  ),
                                                                                            ),
                                                                                            duration: const Duration(milliseconds: 4000),
                                                                                            backgroundColor: FlutterFlowTheme.of(context).error,
                                                                                          ),
                                                                                        );
                                                                                      } else {
                                                                                        FFAppState().addcart = FFAppState().addcart + 1;
                                                                                        FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                          naim: touryMkanName(context, listViewMkanRecord),
                                                                                          textivill: touryLandmarkCartSubtitle(listViewMkanRecord),
                                                                                          loceshn: listViewMkanRecord.location,
                                                                                          revmkan: listViewMkanRecord.reference,
                                                                                        ));
                                                                                        FFAppState().dataSchedule = getCurrentTimestamp;
                                                                                        FFAppState().fulltextSchedule = 'instant_booking'.tr();
                                                                                        FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                          return "$var1 $var2";
                                                                                        }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                        FFAppState().addToMkan(listViewMkanRecord.reference);
                                                                                        _refreshCartBadgeDeferred();
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                          SnackBar(
                                                                                            content: Text(
                                                                                              'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, listViewMkanRecord)}),
                                                                                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                    fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    letterSpacing: 0.0,
                                                                                                    useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                  ),
                                                                                            ),
                                                                                            duration: const Duration(milliseconds: 4000),
                                                                                            backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                            action: SnackBarAction(
                                                                                              label: 'view_my_trip'.tr(),
                                                                                              textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              onPressed: () async {
                                                                                                touryOpenCheckout(context);
                                                                                              },
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      }
                                                                                    },
                                                                                  ),
                                                                                  InkWell(
                                                                                    splashColor: Colors.transparent,
                                                                                    focusColor: Colors.transparent,
                                                                                    hoverColor: Colors.transparent,
                                                                                    highlightColor: Colors.transparent,
                                                                                    onTap: () async {
                                                                                      if (touryLandmarkAlreadyInCart(listViewMkanRecord.reference)) {
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                          SnackBar(
                                                                                            content: Text(
                                                                                              'landmark_already_in_cart'.tr(),
                                                                                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                    fontFamily: 'cairo',
                                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    letterSpacing: 0.0,
                                                                                                  ),
                                                                                            ),
                                                                                            duration: const Duration(milliseconds: 4000),
                                                                                            backgroundColor: FlutterFlowTheme.of(context).error,
                                                                                          ),
                                                                                        );
                                                                                      } else {
                                                                                        FFAppState().addcart = FFAppState().addcart + 1;
                                                                                        FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                          naim: touryMkanName(context, listViewMkanRecord),
                                                                                          textivill: touryLandmarkCartSubtitle(listViewMkanRecord),
                                                                                          loceshn: listViewMkanRecord.location,
                                                                                          revmkan: listViewMkanRecord.reference,
                                                                                        ));
                                                                                        FFAppState().dataSchedule = getCurrentTimestamp;
                                                                                        FFAppState().fulltextSchedule = 'instant_booking'.tr();
                                                                                        FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                          return "$var1 $var2";
                                                                                        }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                        FFAppState().addToMkan(listViewMkanRecord.reference);
                                                                                        _refreshCartBadgeDeferred();
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                          SnackBar(
                                                                                            content: Text(
                                                                                              'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, listViewMkanRecord)}),
                                                                                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                    fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    letterSpacing: 0.0,
                                                                                                    useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                  ),
                                                                                            ),
                                                                                            duration: const Duration(milliseconds: 4000),
                                                                                            backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                            action: SnackBarAction(
                                                                                              label: 'view_my_trip'.tr(),
                                                                                              textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              onPressed: () async {
                                                                                                touryOpenCheckout(context);
                                                                                              },
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                        FFAppState().akrLoceshn = listViewMkanRecord.location;
                                                                                        safeSetState(() {});
                                                                                      }
                                                                                    },
                                                                                    child: Text(
                                                                                    "Add".tr(),
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                                            color: FlutterFlowTheme.of(context).error,
                                                                                            fontSize: 12.0,
                                                                                            letterSpacing: 0.0,
                                                                                            useGoogleFonts: !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ).touryPageAnim(
                                                                          animationsMap[
                                                                              'containerOnPageLoadAnimation']),
                                                                );
                                                              },
                                                            ).touryPageAnim(
                                                                animationsMap[
                                                                    'listViewOnPageLoadAnimation1']),
                                                              );
                                                          },
                                                        ),
                                                      ),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                Expanded(
                                                                  child: Padding(
                                                                  padding:
                                                                      const EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                          16.0,
                                                                          16.0,
                                                                          16.0,
                                                                          0.0),
                                                                  child: Text(
                                                                   "Tourist landmarks".tr(),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).labelLargeFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primary,
                                                                          fontSize:
                                                                              17.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).labelLargeIsCustom,
                                                                        ),
                                                                  ).touryPageAnim(
                                                                      animationsMap[
                                                                          'textOnPageLoadAnimation4']),
                                                                ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                        0.0,
                                                                        11.0,
                                                                        16.0,
                                                                        11.0),
                                                                child:
                                                                    FlutterFlowChoiceChips(
                                                                  options: [
                                                                    ChipData('landmark_cat_all'.tr(), Icons.density_small),
                                                                    ChipData(
                                                                   'landmark_cat_religious'.tr(),
                                                                    Icons
                                                                        .tour_outlined),
                                                                             ChipData('landmark_cat_entertainment'.tr(), Icons.sentiment_satisfied_rounded),
                                                                    ChipData('landmark_cat_tourism'.tr(), Icons.restaurant),
                                                                    ChipData('landmark_cat_cafe'.tr(), Icons.coffee_outlined),
                                                                            ChipData(
                                                                       'landmark_cat_historical'.tr(),
                                                                        Icons
                                                                            .place_sharp),
                                                                    ChipData('landmark_cat_tourist_places'.tr(), Icons.place_sharp),
                                                                    ChipData('landmark_cat_markets'.tr(), Icons.shopping_cart_sharp),
                                                                    ChipData('landmark_cat_desert'.tr(), Icons.forest_outlined),
                                                                    ChipData('landmark_cat_sea'.tr(), Icons.support),
                                                                    ChipData('landmark_cat_hotels'.tr(), Icons.hotel_sharp),
                                                                    ChipData('landmark_cat_restaurants'.tr(), Icons.fastfood_rounded)
                                                                  ],
                                                                  onChanged:
                                                                      (val) async {
                                                                    safeSetState(() =>
                                                                        _model.choiceChipsValue =
                                                                            val?.firstOrNull);
                                                                    _model.sser =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  selectedChipStyle:
                                                                      ChipStyle(
                                                                    backgroundColor:
                                                                        FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                    textStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryBackground,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                        ),
                                                                    iconColor: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryBackground,
                                                                    iconSize:
                                                                        18.0,
                                                                    elevation:
                                                                        4.0,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16.0),
                                                                  ),
                                                                  unselectedChipStyle:
                                                                      ChipStyle(
                                                                    backgroundColor:
                                                                        FlutterFlowTheme.of(context)
                                                                            .alternate,
                                                                    textStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryText,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                        ),
                                                                    iconColor: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                    iconSize:
                                                                        18.0,
                                                                    elevation:
                                                                        0.0,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16.0),
                                                                  ),
                                                                  chipSpacing:
                                                                      12.0,
                                                                  rowSpacing:
                                                                      12.0,
                                                                  multiselect:
                                                                      false,
                                                                  initialized:
                                                                      _model.choiceChipsValue !=
                                                                          null,
                                                                  alignment:
                                                                      WrapAlignment
                                                                          .start,
                                                                  controller: _model
                                                                          .choiceChipsValueController ??=
                                                                      FormFieldController<
                                                                          List<
                                                                              String>>(
                                                                    [
                                                                      'landmark_cat_all'
                                                                          .tr(),
                                                                    ],
                                                                  ),
                                                                  wrapped:
                                                                      false,
                                                                ).touryPageAnim(
                                                                        animationsMap[
                                                                            'choiceChipsOnPageLoadAnimation']),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                  0.0,
                                                                  2.0,
                                                                  0.0,
                                                                  7.0),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Expanded(
                                                                child: Container(
                                                                height: 41.1,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .only(
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            11.0),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            11.0),
                                                                    topLeft: Radius
                                                                        .circular(
                                                                            11.0),
                                                                    topRight: Radius
                                                                        .circular(
                                                                            11.0),
                                                                  ),
                                                                  border: Border
                                                                      .all(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondary,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              TextFormField(
                                                                            controller:
                                                                                _model.textController,
                                                                            focusNode:
                                                                                _model.textFieldFocusNode,
                                                                            onChanged: (_) =>
                                                                                EasyDebounce.debounce(
                                                                              '_model.textController',
                                                                              const Duration(milliseconds: 800),
                                                                              () async {
                                                                                await _runLandmarkSearch(
                                                                                    _model.textController.text);
                                                                              },
                                                                            ),
                                                                            autofocus:
                                                                                false,
                                                                            enabled:
                                                                                true,
                                                                            obscureText:
                                                                                false,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              isDense: true,
                                                                              labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                    fontFamily: 'cairo',
                                                                                    fontSize: 11.0,
                                                                                    letterSpacing: 0.0,
                                                                                  ),
                                                                              hintText: 'landmark_search_hint'.tr(),
                                                                              hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                    fontFamily: 'cairo',
                                                                                    fontSize: 11.0,
                                                                                    letterSpacing: 0.0,
                                                                                  ),
                                                                              enabledBorder: OutlineInputBorder(
                                                                                borderSide: const BorderSide(
                                                                                  color: Color(0x00000000),
                                                                                  width: 1.0,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                              ),
                                                                              focusedBorder: OutlineInputBorder(
                                                                                borderSide: const BorderSide(
                                                                                  color: Color(0x00000000),
                                                                                  width: 1.0,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                              ),
                                                                              errorBorder: OutlineInputBorder(
                                                                                borderSide: BorderSide(
                                                                                  color: FlutterFlowTheme.of(context).error,
                                                                                  width: 1.0,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                              ),
                                                                              focusedErrorBorder: OutlineInputBorder(
                                                                                borderSide: BorderSide(
                                                                                  color: FlutterFlowTheme.of(context).error,
                                                                                  width: 1.0,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                              ),
                                                                              filled: true,
                                                                              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  fontFamily: 'cairo',
                                                                                  color: FlutterFlowTheme.of(context).secondary,
                                                                                  letterSpacing: 0.0,
                                                                                ),
                                                                            cursorColor:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            enableInteractiveSelection:
                                                                                true,
                                                                            validator:
                                                                                _model.textControllerValidator.asValidator(context),
                                                                          ),
                                                                        ),
                                                                        if (_model.sser ==
                                                                            true)
                                                                          Align(
                                                                            alignment:
                                                                                const AlignmentDirectional(1.0, 0.0),
                                                                            child:
                                                                                InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                _model.sser = false;
                                                                                safeSetState(() {});
                                                                                safeSetState(() {
                                                                                  _model.textController?.clear();
                                                                                });
                                                                              },
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: const EdgeInsetsDirectional.fromSTEB(2.0, 0.0, 2.0, 0.0),
                                                                                    child: Icon(
                                                                                      Icons.cancel_sharp,
                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                      size: 11.0,
                                                                                    ),
                                                                                  ),
                                                                                  Flexible(
                                                                                    child: Text(
                                                                                    FFLocalizations.of(context).getText(
                                                                                      'vmf8goz5' /* Cancel Search */,
                                                                                    ),
                                                                                    maxLines: 1,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                                          color: FlutterFlowTheme.of(context).error,
                                                                                          fontSize: 9.0,
                                                                                          letterSpacing: 0.0,
                                                                                          useGoogleFonts: !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                                        ),
                                                                                  ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (_model.sser == false)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(16.0,
                                                                8.0, 16.0, 0.0),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        14.0),
                                                            onTap: () async {
                                                              await context
                                                                  .pushNamed(
                                                                TouryCustomPlaceWidget
                                                                    .routeName,
                                                              );
                                                              safeSetState(
                                                                  () {});
                                                            },
                                                            child: Ink(
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    TouryBrand
                                                                        .primaryGradient,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            14.0),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 14,
                                                                vertical: 12,
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .add_location_alt_rounded,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 26,
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 12),
                                                                  Expanded(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          'landmarks_custom_list_title'.tr(),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .labelLarge
                                                                              .override(
                                                                                fontFamily: 'cairo',
                                                                                color: Colors.white,
                                                                                fontWeight: FontWeight.w700,
                                                                              ),
                                                                        ),
                                                                        Text(
                                                                          'custom_place_list_hint'.tr(),
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .override(
                                                                                fontFamily: 'cairo',
                                                                                color: Colors.white.withValues(alpha: 0.9),
                                                                                fontSize: 11,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const Icon(
                                                                    Icons
                                                                        .chevron_left,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    if ((TouryLandmarkCategories.isAll(_model.choiceChipsValue)) &&
                                                        (_model.sser == false))
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(0.0,
                                                                0.0, 0.0, 33.0),
                                                        child: Builder(
                                                          builder: (context) {
                                                            final listViewAllMkanRecordList =
                                                                touryFilterLandmarksForUi(
                                                              listViMkanRecordList,
                                                              touryContentLocaleFromContext(
                                                                  context),
                                                            );

                                                            if (showLandmarkSkeleton) {
                                                              return const TouryLandmarkSkeletonList(
                                                                itemCount: 8,
                                                              );
                                                            }

                                                            return ListView
                                                                .builder(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              primary: false,
                                                              shrinkWrap: true,
                                                              physics: TouryPerf.nestedListPhysics,
                                                              cacheExtent: 480,
                                                              addRepaintBoundaries: true,
                                                              addAutomaticKeepAlives: false,
                                                              scrollDirection:
                                                                  Axis.vertical,
                                                              itemCount:
                                                                  listViewAllMkanRecordList
                                                                      .length +
                                                                  (_mkanPage.hasMore
                                                                      ? 1
                                                                      : 0),
                                                              itemBuilder: (context,
                                                                  listViewAllIndex) {
                                                                if (listViewAllIndex >=
                                                                    listViewAllMkanRecordList
                                                                        .length) {
                                                                  return TouryLoadMoreTile(
                                                                    loading: _mkanPage
                                                                        .isLoadingMore,
                                                                    hasMore:
                                                                        _mkanPage
                                                                            .hasMore,
                                                                    loadedCount:
                                                                        _mkanPage
                                                                            .items
                                                                            .length,
                                                                    onLoadMore: () =>
                                                                        _mkanPage
                                                                            .loadMore(),
                                                                  );
                                                                }
                                                                final listViewAllMkanRecord =
                                                                    listViewAllMkanRecordList[
                                                                        listViewAllIndex];
                                                                return Padding(
                                                                  padding: TouryLayout
                                                                      .landmarkCardPadding(
                                                                          context),
                                                                  child:
                                                                      Container(
                                                                    width:
                                                                        TouryLayout.landmarkListCardWidth(context),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      boxShadow: const [
                                                                        BoxShadow(
                                                                          blurRadius:
                                                                              8.0,
                                                                          color:
                                                                              Color(0x230F1113),
                                                                          offset:
                                                                              Offset(
                                                                            0.0,
                                                                            4.0,
                                                                          ),
                                                                        )
                                                                      ],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        InkWell(
                                                                      splashColor:
                                                                          Colors
                                                                              .transparent,
                                                                      focusColor:
                                                                          Colors
                                                                              .transparent,
                                                                      hoverColor:
                                                                          Colors
                                                                              .transparent,
                                                                      highlightColor:
                                                                          Colors
                                                                              .transparent,
                                                                      onTap:
                                                                          () async {
                                                                        context
                                                                            .pushNamed(
                                                                          PlacedetailsWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'mk':
                                                                                serializeParam(
                                                                              listViewAllMkanRecord.reference,
                                                                              ParamType.DocumentReference,
                                                                            ),
                                                                            'textnaim':
                                                                                serializeParam(
                                                                              touryMkanName(context, listViewAllMkanRecord),
                                                                              ParamType.String,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      },
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Hero(
                                                                            tag:
                                                                                listViewAllMkanRecord.reference.id,
                                                                            transitionOnUserGestures:
                                                                                true,
                                                                            child:
                                                                                ClipRRect(
                                                                              borderRadius: const BorderRadius.only(
                                                                                bottomLeft: Radius.circular(0.0),
                                                                                bottomRight: Radius.circular(0.0),
                                                                                topLeft: Radius.circular(12.0),
                                                                                topRight: Radius.circular(12.0),
                                                                              ),
                                                                              child: TouryNetworkImage.fromPlaceImages(
                                                                                img1: listViewAllMkanRecord.img1,
                                                                                img2: listViewAllMkanRecord.img2,
                                                                                img3: listViewAllMkanRecord.img3,
                                                                                documentId: listViewAllMkanRecord.reference.id,
                                                                                placeName: touryMkanName(context, listViewAllMkanRecord),
                                                                                latitude: listViewAllMkanRecord.location?.latitude,
                                                                                longitude: listViewAllMkanRecord.location?.longitude,
                                                                                width: double.infinity,
                                                                                height: TouryLayout.cardImageHeight(context),
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: const EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                12.0,
                                                                                16.0,
                                                                                12.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        touryMkanName(context, listViewAllMkanRecord),
                                                                                        maxLines: 2,
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                                                              fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                                              color: FlutterFlowTheme.of(context).primary,
                                                                                              letterSpacing: 0.0,
                                                                                              useGoogleFonts: !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                                            ),
                                                                                      ),
                                                                                      Padding(
                                                                                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
                                                                                        child: Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          children: [
                                                                                            RatingBarIndicator(
                                                                                              itemBuilder: (context, index) => Icon(
                                                                                                Icons.radio_button_checked_rounded,
                                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                              ),
                                                                                              direction: Axis.horizontal,
                                                                                              rating: 4.0,
                                                                                              unratedColor: FlutterFlowTheme.of(context).error,
                                                                                              itemCount: 5,
                                                                                              itemSize: 13.0,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    if (touryLandmarkAlreadyInCart(listViewAllMkanRecord.reference)) {
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text(
                                                                                            'landmark_already_in_cart'.tr(),
                                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                  fontFamily: 'cairo',
                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                  letterSpacing: 0.0,
                                                                                                ),
                                                                                          ),
                                                                                          duration: const Duration(milliseconds: 4000),
                                                                                          backgroundColor: FlutterFlowTheme.of(context).error,
                                                                                        ),
                                                                                      );
                                                                                    } else {
                                                                                      FFAppState().addcart = FFAppState().addcart + 1;
                                                                                      FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                        naim: touryMkanName(context, listViewAllMkanRecord),
                                                                                        textivill: touryLandmarkCartSubtitle(listViewAllMkanRecord),
                                                                                        loceshn: listViewAllMkanRecord.location,
                                                                                        revmkan: listViewAllMkanRecord.reference,
                                                                                      ));
                                                                                      FFAppState().dataSchedule = getCurrentTimestamp;
                                                                                      FFAppState().fulltextSchedule = 'instant_booking'.tr();
                                                                                      FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                        return "$var1 $var2";
                                                                                      }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                      FFAppState().addToMkan(listViewAllMkanRecord.reference);
                                                                                      _refreshCartBadgeDeferred();
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text(
                                                                                            'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, listViewAllMkanRecord)}),
                                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                  fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                  letterSpacing: 0.0,
                                                                                                  useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                ),
                                                                                          ),
                                                                                          duration: const Duration(milliseconds: 4000),
                                                                                          backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                          action: SnackBarAction(
                                                                                            label: 'view_my_trip'.tr(),
                                                                                            textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                            onPressed: () async {
                                                                                              touryOpenCheckout(context);
                                                                                            },
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  },
                                                                                  child: Container(
                                                                                    height: 35.0,
                                                                                    constraints: const BoxConstraints(minWidth: 72, maxWidth: 110),
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                      borderRadius: BorderRadius.circular(12.0),
                                                                                    ),
                                                                                    alignment: const AlignmentDirectional(0.0, 0.0),
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
                                                                                      child: Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          FlutterFlowIconButton(
                                                                                            borderRadius: 8.0,
                                                                                            borderWidth: 1.0,
                                                                                            buttonSize: 31.7,
                                                                                            fillColor: FlutterFlowTheme.of(context).error,
                                                                                            icon: Icon(
                                                                                              Icons.add,
                                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              size: 12.0,
                                                                                            ),
                                                                                            onPressed: () async {
                                                                                              if (touryLandmarkAlreadyInCart(listViewAllMkanRecord.reference)) {
                                                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                                                  SnackBar(
                                                                                                    content: Text(
                                                                                                      'landmark_already_in_cart'.tr(),
                                                                                                      style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                            fontFamily: 'cairo',
                                                                                                            color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                            letterSpacing: 0.0,
                                                                                                          ),
                                                                                                    ),
                                                                                                    duration: const Duration(milliseconds: 4000),
                                                                                                    backgroundColor: FlutterFlowTheme.of(context).error,
                                                                                                  ),
                                                                                                );
                                                                                              } else {
                                                                                                FFAppState().addcart = FFAppState().addcart + 1;
                                                                                                FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                                  naim: touryMkanName(context, listViewAllMkanRecord),
                                                                                                  textivill: touryLandmarkCartSubtitle(listViewAllMkanRecord),
                                                                                                  loceshn: listViewAllMkanRecord.location,
                                                                                                  revmkan: listViewAllMkanRecord.reference,
                                                                                                ));
                                                                                                FFAppState().dataSchedule = getCurrentTimestamp;
                                                                                                FFAppState().fulltextSchedule = 'instant_booking'.tr();
                                                                                                FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                                  return "$var1 $var2";
                                                                                                }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                                FFAppState().addToMkan(listViewAllMkanRecord.reference);
                                                                                                _refreshCartBadgeDeferred();
                                                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                                                  SnackBar(
                                                                                                    content: Text(
                                                                                                      'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, listViewAllMkanRecord)}),
                                                                                                      style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                            fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                            color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                            letterSpacing: 0.0,
                                                                                                            useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                          ),
                                                                                                    ),
                                                                                                    duration: const Duration(milliseconds: 4000),
                                                                                                    backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                                    action: SnackBarAction(
                                                                                                      label: 'view_my_trip'.tr(),
                                                                                                      textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                      onPressed: () async {
                                                                                                        touryOpenCheckout(context);
                                                                                                      },
                                                                                                    ),
                                                                                                  ),
                                                                                                );
                                                                                              }
                                                                                            },
                                                                                          ),
                                                                                          Flexible(
                                                                                            child: Padding(
                                                                                            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 2.0, 0.0),
                                                                                            child: Text(
                                                                                              FFLocalizations.of(context).getText(
                                                                                                'y1rt0m4k' /* Add */,
                                                                                              ),
                                                                                              maxLines: 1,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                    fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                                                    color: FlutterFlowTheme.of(context).info,
                                                                                                    fontSize: 11.0,
                                                                                                    letterSpacing: 0.0,
                                                                                                    useGoogleFonts: !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                                                  ),
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
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ).touryPageAnim(
                                                                animationsMap[
                                                                    'listViewOnPageLoadAnimation2']);
                                                          },
                                                        ),
                                                      ),
                                                    if ((!TouryLandmarkCategories
                                                            .isAll(_model
                                                                .choiceChipsValue)) &&
                                                        (_model.sser == false))
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(0.0,
                                                                0.0, 0.0, 33.0),
                                                        child: Builder(
                                                          builder: (context) {
                                                            final category =
                                                                _model
                                                                    .choiceChipsValue;
                                                            final listViewMkanRecordList =
                                                                touryFilterLandmarksForUi(
                                                              listViMkanRecordList.where((r) =>
                                                                  TouryLandmarkCategories.matchesTsnef(
                                                                    r.tsnef,
                                                                    category,
                                                                  )),
                                                              touryContentLocaleFromContext(context),
                                                            );

                                                            return ListView
                                                                .builder(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              primary: false,
                                                              shrinkWrap: true,
                                                              physics: TouryPerf.nestedListPhysics,
                                                              cacheExtent: 480,
                                                              addRepaintBoundaries: true,
                                                              addAutomaticKeepAlives: false,
                                                              scrollDirection:
                                                                  Axis.vertical,
                                                              itemCount:
                                                                  listViewMkanRecordList
                                                                      .length +
                                                                  (_mkanPage.hasMore
                                                                      ? 1
                                                                      : 0),
                                                              itemBuilder: (context,
                                                                  listViewIndex) {
                                                                if (listViewIndex >=
                                                                    listViewMkanRecordList
                                                                        .length) {
                                                                  return TouryLoadMoreTile(
                                                                    loading: _mkanPage
                                                                        .isLoadingMore,
                                                                    hasMore:
                                                                        _mkanPage
                                                                            .hasMore,
                                                                    loadedCount:
                                                                        _mkanPage
                                                                            .items
                                                                            .length,
                                                                    onLoadMore: () =>
                                                                        _mkanPage
                                                                            .loadMore(),
                                                                  );
                                                                }
                                                                final listViewMkanRecord =
                                                                    listViewMkanRecordList[
                                                                        listViewIndex];
                                                                return Padding(
                                                                  padding: TouryLayout
                                                                      .landmarkCardPadding(
                                                                          context),
                                                                  child:
                                                                      Container(
                                                                    width:
                                                                        TouryLayout.landmarkListCardWidth(context),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      boxShadow: const [
                                                                        BoxShadow(
                                                                          blurRadius:
                                                                              8.0,
                                                                          color:
                                                                              Color(0x230F1113),
                                                                          offset:
                                                                              Offset(
                                                                            0.0,
                                                                            4.0,
                                                                          ),
                                                                        )
                                                                      ],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        InkWell(
                                                                      splashColor:
                                                                          Colors
                                                                              .transparent,
                                                                      focusColor:
                                                                          Colors
                                                                              .transparent,
                                                                      hoverColor:
                                                                          Colors
                                                                              .transparent,
                                                                      highlightColor:
                                                                          Colors
                                                                              .transparent,
                                                                      onTap:
                                                                          () async {
                                                                        context
                                                                            .pushNamed(
                                                                          PlacedetailsWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'mk':
                                                                                serializeParam(
                                                                              listViewMkanRecord.reference,
                                                                              ParamType.DocumentReference,
                                                                            ),
                                                                            'textnaim':
                                                                                serializeParam(
                                                                              touryMkanName(context, listViewMkanRecord),
                                                                              ParamType.String,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      },
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Hero(
                                                                            tag:
                                                                                listViewMkanRecord.reference.id,
                                                                            transitionOnUserGestures:
                                                                                true,
                                                                            child:
                                                                                ClipRRect(
                                                                              borderRadius: const BorderRadius.only(
                                                                                bottomLeft: Radius.circular(0.0),
                                                                                bottomRight: Radius.circular(0.0),
                                                                                topLeft: Radius.circular(12.0),
                                                                                topRight: Radius.circular(12.0),
                                                                              ),
                                                                              child: TouryNetworkImage.fromPlaceImages(
                                                                                img1: listViewMkanRecord.img1,
                                                                                img2: listViewMkanRecord.img2,
                                                                                img3: listViewMkanRecord.img3,
                                                                                documentId: listViewMkanRecord.reference.id,
                                                                                placeName: touryMkanName(context, listViewMkanRecord),
                                                                                latitude: listViewMkanRecord.location?.latitude,
                                                                                longitude: listViewMkanRecord.location?.longitude,
                                                                                width: double.infinity,
                                                                                height: TouryLayout.cardImageHeight(context),
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: const EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                12.0,
                                                                                16.0,
                                                                                12.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        touryMkanName(context, listViewMkanRecord),
                                                                                        maxLines: 2,
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                                                              fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                                              color: FlutterFlowTheme.of(context).primary,
                                                                                              letterSpacing: 0.0,
                                                                                              useGoogleFonts: !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                                            ),
                                                                                      ),
                                                                                      Padding(
                                                                                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
                                                                                        child: Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          children: [
                                                                                            RatingBarIndicator(
                                                                                              itemBuilder: (context, index) => Icon(
                                                                                                Icons.radio_button_checked_rounded,
                                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                              ),
                                                                                              direction: Axis.horizontal,
                                                                                              rating: 4.0,
                                                                                              unratedColor: FlutterFlowTheme.of(context).error,
                                                                                              itemCount: 5,
                                                                                              itemSize: 13.0,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    if (touryLandmarkAlreadyInCart(listViewMkanRecord.reference)) {
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text(
                                                                                            'landmark_already_in_cart'.tr(),
                                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                  fontFamily: 'cairo',
                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                  letterSpacing: 0.0,
                                                                                                ),
                                                                                          ),
                                                                                          duration: const Duration(milliseconds: 4000),
                                                                                          backgroundColor: FlutterFlowTheme.of(context).error,
                                                                                        ),
                                                                                      );
                                                                                    } else {
                                                                                      FFAppState().addcart = FFAppState().addcart + 1;
                                                                                      FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                        naim: touryMkanName(context, listViewMkanRecord),
                                                                                        textivill: touryLandmarkCartSubtitle(listViewMkanRecord),
                                                                                        loceshn: listViewMkanRecord.location,
                                                                                        revmkan: listViewMkanRecord.reference,
                                                                                      ));
                                                                                      FFAppState().dataSchedule = getCurrentTimestamp;
                                                                                      FFAppState().fulltextSchedule = 'instant_booking'.tr();
                                                                                      FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                        return "$var1 $var2";
                                                                                      }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                      FFAppState().addToMkan(listViewMkanRecord.reference);
                                                                                      _refreshCartBadgeDeferred();
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text(
                                                                                            'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, listViewMkanRecord)}),
                                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                  fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                  letterSpacing: 0.0,
                                                                                                  useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                ),
                                                                                          ),
                                                                                          duration: const Duration(milliseconds: 4000),
                                                                                          backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                          action: SnackBarAction(
                                                                                            label: 'view_my_trip'.tr(),
                                                                                            textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                            onPressed: () async {
                                                                                              touryOpenCheckout(context);
                                                                                            },
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  },
                                                                                  child: Container(
                                                                                    height: 35.0,
                                                                                    constraints: const BoxConstraints(minWidth: 72, maxWidth: 110),
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                      borderRadius: BorderRadius.circular(12.0),
                                                                                    ),
                                                                                    alignment: const AlignmentDirectional(0.0, 0.0),
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
                                                                                      child: Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          FlutterFlowIconButton(
                                                                                            borderRadius: 8.0,
                                                                                            borderWidth: 1.0,
                                                                                            buttonSize: 31.7,
                                                                                            fillColor: FlutterFlowTheme.of(context).error,
                                                                                            icon: Icon(
                                                                                              Icons.add,
                                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              size: 12.0,
                                                                                            ),
                                                                                            onPressed: () async {
                                                                                              FFAppState().addcart = FFAppState().addcart + 1;
                                                                                              FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                                naim: touryMkanName(context, listViewMkanRecord),
                                                                                                textivill: touryLandmarkCartSubtitle(listViewMkanRecord),
                                                                                                loceshn: listViewMkanRecord.location,
                                                                                              ));
                                                                                              FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                                return "$var1 $var2";
                                                                                              }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                              safeSetState(() {});
                                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text(
                                                                                                    'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, listViewMkanRecord)}),
                                                                                                    style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                          fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                          letterSpacing: 0.0,
                                                                                                          useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                        ),
                                                                                                  ),
                                                                                                  duration: const Duration(milliseconds: 4000),
                                                                                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                                  action: SnackBarAction(
                                                                                                    label: 'view_my_trip'.tr(),
                                                                                                    textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    onPressed: () async {
                                                                                                      touryOpenCheckout(context);
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              );
                                                                                            },
                                                                                          ),
                                                                                          Flexible(
                                                                                            child: Padding(
                                                                                            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 2.0, 0.0),
                                                                                            child: Text(
                                                                                              FFLocalizations.of(context).getText(
                                                                                                '3xvjxer6' /* Add */,
                                                                                              ),
                                                                                              maxLines: 1,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                    fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                                                    color: FlutterFlowTheme.of(context).info,
                                                                                                    fontSize: 11.0,
                                                                                                    letterSpacing: 0.0,
                                                                                                    useGoogleFonts: !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                                                  ),
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
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ).touryPageAnim(
                                                                animationsMap[
                                                                    'listViewOnPageLoadAnimation3']);
                                                          },
                                                        ),
                                                      ),
                                                    if (_model.sser == true)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsetsDirectional
                                                                .fromSTEB(0.0,
                                                                0.0, 0.0, 33.0),
                                                        child: Builder(
                                                          builder: (context) {
                                                            final ss = _model
                                                                .simpleSearchResults
                                                                .toList();

                                                            return ListView
                                                                .builder(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              primary: false,
                                                              shrinkWrap: true,
                                                              physics: TouryPerf.nestedListPhysics,
                                                              cacheExtent: 480,
                                                              addRepaintBoundaries: true,
                                                              addAutomaticKeepAlives: false,
                                                              scrollDirection:
                                                                  Axis.vertical,
                                                              itemCount:
                                                                  ss.length,
                                                              itemBuilder:
                                                                  (context,
                                                                      ssIndex) {
                                                                final ssItem =
                                                                    ss[ssIndex];
                                                                return Padding(
                                                                  padding: TouryLayout
                                                                      .landmarkCardPadding(
                                                                          context),
                                                                  child:
                                                                      Container(
                                                                    width:
                                                                        TouryLayout.landmarkListCardWidth(context),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      boxShadow: const [
                                                                        BoxShadow(
                                                                          blurRadius:
                                                                              8.0,
                                                                          color:
                                                                              Color(0x230F1113),
                                                                          offset:
                                                                              Offset(
                                                                            0.0,
                                                                            4.0,
                                                                          ),
                                                                        )
                                                                      ],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryBackground,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        InkWell(
                                                                      splashColor:
                                                                          Colors
                                                                              .transparent,
                                                                      focusColor:
                                                                          Colors
                                                                              .transparent,
                                                                      hoverColor:
                                                                          Colors
                                                                              .transparent,
                                                                      highlightColor:
                                                                          Colors
                                                                              .transparent,
                                                                      onTap:
                                                                          () async {
                                                                        context
                                                                            .pushNamed(
                                                                          PlacedetailsWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'mk':
                                                                                serializeParam(
                                                                              ssItem.reference,
                                                                              ParamType.DocumentReference,
                                                                            ),
                                                                            'textnaim':
                                                                                serializeParam(
                                                                              touryMkanName(context, ssItem),
                                                                              ParamType.String,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      },
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Hero(
                                                                            tag:
                                                                                ssItem.img1,
                                                                            transitionOnUserGestures:
                                                                                true,
                                                                            child:
                                                                                ClipRRect(
                                                                              borderRadius: const BorderRadius.only(
                                                                                bottomLeft: Radius.circular(0.0),
                                                                                bottomRight: Radius.circular(0.0),
                                                                                topLeft: Radius.circular(12.0),
                                                                                topRight: Radius.circular(12.0),
                                                                              ),
                                                                              child: TouryNetworkImage.fromPlaceImages(
                                                                                img1: ssItem.img1,
                                                                                img2: ssItem.img2,
                                                                                img3: ssItem.img3,
                                                                                documentId: ssItem.reference.id,
                                                                                placeName: touryMkanName(context, ssItem),
                                                                                latitude: ssItem.location?.latitude,
                                                                                longitude: ssItem.location?.longitude,
                                                                                width: double.infinity,
                                                                                height: TouryLayout.cardImageHeight(context),
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: const EdgeInsetsDirectional.fromSTEB(
                                                                                16.0,
                                                                                12.0,
                                                                                16.0,
                                                                                12.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        touryMkanName(context, ssItem),
                                                                                        maxLines: 2,
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                                                              fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                                              color: FlutterFlowTheme.of(context).primary,
                                                                                              letterSpacing: 0.0,
                                                                                              useGoogleFonts: !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                                            ),
                                                                                      ),
                                                                                      Padding(
                                                                                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
                                                                                        child: Row(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          children: [
                                                                                            RatingBarIndicator(
                                                                                              itemBuilder: (context, index) => Icon(
                                                                                                Icons.radio_button_checked_rounded,
                                                                                                color: FlutterFlowTheme.of(context).secondary,
                                                                                              ),
                                                                                              direction: Axis.horizontal,
                                                                                              rating: 4.0,
                                                                                              unratedColor: FlutterFlowTheme.of(context).error,
                                                                                              itemCount: 5,
                                                                                              itemSize: 13.0,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    if (touryLandmarkAlreadyInCart(ssItem.reference)) {
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text(
                                                                                            'landmark_already_in_cart'.tr(),
                                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                  fontFamily: 'cairo',
                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                  letterSpacing: 0.0,
                                                                                                ),
                                                                                          ),
                                                                                          duration: const Duration(milliseconds: 4000),
                                                                                          backgroundColor: FlutterFlowTheme.of(context).error,
                                                                                        ),
                                                                                      );
                                                                                    } else {
                                                                                      FFAppState().addcart = FFAppState().addcart + 1;
                                                                                      FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                        naim: touryMkanName(context, ssItem),
                                                                                        textivill: touryLandmarkCartSubtitle(ssItem),
                                                                                        loceshn: ssItem.location,
                                                                                        revmkan: ssItem.reference,
                                                                                      ));
                                                                                      FFAppState().dataSchedule = getCurrentTimestamp;
                                                                                      FFAppState().fulltextSchedule = 'instant_booking'.tr();
                                                                                      FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                        return "$var1 $var2";
                                                                                      }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                      FFAppState().addToMkan(ssItem.reference);
                                                                                      _refreshCartBadgeDeferred();
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text(
                                                                                            'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, ssItem)}),
                                                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                  fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                  letterSpacing: 0.0,
                                                                                                  useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                ),
                                                                                          ),
                                                                                          duration: const Duration(milliseconds: 4000),
                                                                                          backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                          action: SnackBarAction(
                                                                                            label: 'view_my_trip'.tr(),
                                                                                            textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                            onPressed: () async {
                                                                                              touryOpenCheckout(context);
                                                                                            },
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  },
                                                                                  child: Container(
                                                                                    height: 35.0,
                                                                                    constraints: const BoxConstraints(minWidth: 72, maxWidth: 110),
                                                                                    decoration: BoxDecoration(
                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                      borderRadius: BorderRadius.circular(12.0),
                                                                                    ),
                                                                                    alignment: const AlignmentDirectional(0.0, 0.0),
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
                                                                                      child: Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          FlutterFlowIconButton(
                                                                                            borderRadius: 8.0,
                                                                                            borderWidth: 1.0,
                                                                                            buttonSize: 31.7,
                                                                                            fillColor: FlutterFlowTheme.of(context).error,
                                                                                            icon: Icon(
                                                                                              Icons.add,
                                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                              size: 12.0,
                                                                                            ),
                                                                                            onPressed: () async {
                                                                                              FFAppState().addcart = FFAppState().addcart + 1;
                                                                                              FFAppState().addToCartmkss(AmaknCostmStruct(
                                                                                                naim: touryMkanName(context, ssItem),
                                                                                                textivill: touryLandmarkCartSubtitle(ssItem),
                                                                                                loceshn: ssItem.location,
                                                                                              ));
                                                                                              FFAppState().textallAlmdn = (String var1, String var2) {
                                                                                                return "$var1 $var2";
                                                                                              }(FFAppState().textallAlmdn, FFAppState().naimvillatext);
                                                                                              safeSetState(() {});
                                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text(
                                                                                                    'landmark_added_success'.tr(namedArgs: {'name': touryMkanName(context, ssItem)}),
                                                                                                    style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                                                          fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                                                                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                          letterSpacing: 0.0,
                                                                                                          useGoogleFonts: !FlutterFlowTheme.of(context).labelMediumIsCustom,
                                                                                                        ),
                                                                                                  ),
                                                                                                  duration: const Duration(milliseconds: 4000),
                                                                                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                                  action: SnackBarAction(
                                                                                                    label: 'view_my_trip'.tr(),
                                                                                                    textColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                    onPressed: () async {
                                                                                                      touryOpenCheckout(context);
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              );
                                                                                            },
                                                                                          ),
                                                                                          Flexible(
                                                                                            child: Padding(
                                                                                            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 2.0, 0.0),
                                                                                            child: Text(
                                                                                              FFLocalizations.of(context).getText(
                                                                                                'lpknsr86' /* Add */,
                                                                                              ),
                                                                                              maxLines: 1,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                    fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                                                                                                    color: FlutterFlowTheme.of(context).info,
                                                                                                    fontSize: 11.0,
                                                                                                    letterSpacing: 0.0,
                                                                                                    useGoogleFonts: !FlutterFlowTheme.of(context).bodyMediumIsCustom,
                                                                                                  ),
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
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ).touryPageAnim(
                                                                animationsMap[
                                                                    'listViewOnPageLoadAnimation4']);
                                                          },
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
                              ],
                            );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}
