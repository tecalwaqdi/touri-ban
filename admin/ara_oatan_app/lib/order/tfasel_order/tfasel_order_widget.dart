import '/core/toury_booking_status_localizer.dart';
import '/core/toury_customer_order_actions.dart';
import '/core/toury_navigation_service.dart';
import '/core/toury_order_meta.dart';
import 'package:easy_localization/easy_localization.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/components/add_extra_hours2_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:map_launcher/map_launcher.dart' as $ml;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'tfasel_order_model.dart';
export 'tfasel_order_model.dart';

class TfaselOrderWidget extends StatefulWidget {
  const TfaselOrderWidget({
    super.key,
    required this.idorder,
  });

  final OrderRecord? idorder;

  static String routeName = 'tfasel_order';
  static String routePath = '/tfaselOrder';

  @override
  State<TfaselOrderWidget> createState() => _TfaselOrderWidgetState();
}

class _TfaselOrderWidgetState extends State<TfaselOrderWidget>
    with TickerProviderStateMixin {
  late TfaselOrderModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TfaselOrderModel());

    animationsMap.addAll({
      'richTextOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'richTextOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeIn,
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
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 300.0.ms,
            begin: const Offset(-2.0, 1.0),
            end: const Offset(1.0, 1.0),
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
    return StreamBuilder<OrderRecord>(
      stream: OrderRecord.getDocument(widget.idorder!.reference),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitChasingDots(
                  color: FlutterFlowTheme.of(context).primary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }

        final tfaselOrderOrderRecord = snapshot.data!;

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          appBar: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).primary,
            automaticallyImplyLeading: false,
            leading: FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 30.0,
              buttonSize: 46.0,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 25.0,
              ),
              onPressed: () async {
                context.pop();
              },
            ),
            title: Text(
              'order_details_number'.tr(namedArgs: {
                'id': tfaselOrderOrderRecord.iDorder.toString(),
              }),
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: FlutterFlowTheme.of(context).titleSmallFamily,
                    color: Colors.white,
                    letterSpacing: 0.0,
                    useGoogleFonts:
                        !FlutterFlowTheme.of(context).titleSmallIsCustom,
                  ),
            ),
            actions: const [],
            centerTitle: false,
            elevation: 0.0,
          ),
          body: SafeArea(
            top: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (tfaselOrderOrderRecord.isDriverEnRoute &&
                      (tfaselOrderOrderRecord.etaLabel().isNotEmpty ||
                          tfaselOrderOrderRecord.driverLivePosition != null))
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0, 12.0, 16.0, 0.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00897B)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.directions_car_filled,
                                color: Color(0xFF00695C),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tfaselOrderOrderRecord
                                              .naimMndobText.isNotEmpty
                                          ? 'المندوب: ${tfaselOrderOrderRecord.naimMndobText}'
                                          : 'المندوب في الطريق',
                                      style: const TextStyle(
                                        fontFamily: 'cairo',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (tfaselOrderOrderRecord
                                        .etaLabel()
                                        .isNotEmpty)
                                      Text(
                                        tfaselOrderOrderRecord.etaLabel(),
                                        style: const TextStyle(
                                          fontFamily: 'cairo',
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (tfaselOrderOrderRecord.driverLivePosition !=
                                  null)
                                FlutterFlowIconButton(
                                  borderRadius: 8,
                                  buttonSize: 40,
                                  icon: const Icon(Icons.map_rounded),
                                  onPressed: () {
                                    context.pushNamed(
                                      MapTrdemoWidget.routeName,
                                      queryParameters: {
                                        'idd': serializeParam(
                                          tfaselOrderOrderRecord.reference,
                                          ParamType.DocumentReference,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 0.0, 0.0, 12.0),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 5.0,
                            color: Color(0x32171717),
                            offset: Offset(
                              0.0,
                              2.0,
                            ),
                          )
                        ],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16.0),
                          bottomRight: Radius.circular(16.0),
                          topLeft: Radius.circular(0.0),
                          topRight: Radius.circular(0.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 0.0, 12.0),
                        child: FutureBuilder<OrderRecord>(
                          future: OrderRecord.getDocumentOnce(
                              widget.idorder!.reference),
                          builder: (context, snapshot) {
                            // Customize what your widget looks like when it's loading.
                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  width: 50.0,
                                  height: 50.0,
                                  child: SpinKitChasingDots(
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 50.0,
                                  ),
                                ),
                              );
                            }

                            final columnOrderRecord = snapshot.data!;

                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      20.0, 0.0, 20.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      if (columnOrderRecord.user ==
                                          currentUserReference)
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0.0, 4.0, 0.0, 0.0),
                                            child: Text(
                                              BookingStatusLocalizer.label(
                                                context,
                                                statusCode:
                                                    columnOrderRecord
                                                        .statusCode,
                                                halhText:
                                                    columnOrderRecord.halhText,
                                              ),
                                              textAlign: TextAlign.center,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .displaySmall
                                                      .override(
                                                        fontFamily: 'cairo',
                                                        color: Colors.white,
                                                        fontSize: 22.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (columnOrderRecord.user ==
                                    currentUserReference)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            20.0, 0.0, 20.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(0.0, 12.0, 0.0, 0.0),
                                          child: Text(
                                            formatNumber(
                                              columnOrderRecord.total,
                                              formatType: FormatType.decimal,
                                              decimalType:
                                                  DecimalType.automatic,
                                              currency: 'ر.س',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .displaySmall
                                                .override(
                                                  fontFamily: 'cairo',
                                                  color: Colors.white,
                                                  fontSize: 36.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget.idorder?.driverGuide == false)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 11.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        RichText(
                                          textScaler:
                                              MediaQuery.of(context).textScaler,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: widget
                                                    .idorder!.addCartNumer
                                                    .toString(),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMediumFamily,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMediumIsCustom,
                                                        ),
                                              ),
                                              TextSpan(
                                                text:
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                  'm1a2p8d8' /*  - added places */,
                                                ),
                                                style: const TextStyle(),
                                              )
                                            ],
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumFamily,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMediumIsCustom,
                                                ),
                                          ),
                                        ).animateOnPageLoad(animationsMap[
                                            'richTextOnPageLoadAnimation1']!),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      20.0, 8.0, 20.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'order_time_label'.tr(namedArgs: {
                                          'time': dateTimeFormat(
                                            "relative",
                                            columnOrderRecord.dataOrder,
                                            locale: FFLocalizations.of(context)
                                                .languageCode,
                                          ),
                                        }),
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'cairo',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .info,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 11.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RichText(
                                        textScaler:
                                            MediaQuery.of(context).textScaler,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                'jar8h06x' /* Total number of hours:  */,
                                              ),
                                              style: const TextStyle(),
                                            ),
                                            TextSpan(
                                              text: valueOrDefault<String>(
                                                widget.idorder?.totalTaim
                                                    .toString(),
                                                '0',
                                              ),
                                              style: const TextStyle(),
                                            )
                                          ],
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'cairo',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ).animateOnPageLoad(animationsMap[
                                          'richTextOnPageLoadAnimation2']!),
                                    ],
                                  ),
                                ),
                                if (tfaselOrderOrderRecord.halhOrderMndob ==
                                    HalhOrder.Accepted)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 11.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(0.0, 11.0, 0.0, 0.0),
                                          child: FFButtonWidget(
                                            onPressed: () async {
                                              FFAppState().paymentFlowKind =
                                                  TypeHgz.Saat;
                                              FFAppState().revOrderSaatExtr =
                                                  columnOrderRecord.reference;
                                              FFAppState().RevMndonSaatExtra =
                                                  columnOrderRecord.mndobUser;
                                              FFAppState().idOrderSaatEXtra =
                                                  columnOrderRecord.iDorder;
                                              FFAppState().update(() {});
                                              await showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                enableDrag: false,
                                                context: context,
                                                builder: (context) {
                                                  return WebViewAware(
                                                    child: Padding(
                                                      padding: MediaQuery
                                                          .viewInsetsOf(
                                                              context),
                                                      child: SizedBox(
                                                        height:
                                                            MediaQuery.sizeOf(
                                                                        context)
                                                                    .height *
                                                                0.9,
                                                        child:
                                                            AddExtraHours2Widget(
                                                          idorder: widget
                                                              .idorder!
                                                              .reference,
                                                          srsaah:
                                                              columnOrderRecord
                                                                  .srSAAH,
                                                          idMndob:
                                                              columnOrderRecord
                                                                  .mndobUser!,
                                                          numperOrder:
                                                              columnOrderRecord
                                                                  .iDorder,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ).then((value) =>
                                                  safeSetState(() {}));
                                            },
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'w87ly4vb' /* Add Extra Hours */,
                                            ),
                                            icon: const Icon(
                                              Icons.add_alarm,
                                              size: 15.0,
                                            ),
                                            options: FFButtonOptions(
                                              height: 40.0,
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      24.0, 0.0, 24.0, 0.0),
                                              iconPadding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      0.0, 0.0, 0.0, 0.0),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .override(
                                                        fontFamily: 'cairo',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        fontSize: 13.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                              elevation: 3.0,
                                              borderSide: const BorderSide(
                                                color: Colors.transparent,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if ((tfaselOrderOrderRecord.halhOrderMndob ==
                          HalhOrder.Completed) &&
                      (tfaselOrderOrderRecord.revewSendClent != true))
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 0.0, 0.0, 11.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 11.0, 0.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                context.pushNamed(
                                  Details24QuizPageWidget.routeName,
                                  queryParameters: {
                                    'usermndob': serializeParam(
                                      tfaselOrderOrderRecord.mndobUser,
                                      ParamType.DocumentReference,
                                    ),
                                    'idordeer': serializeParam(
                                      widget.idorder?.reference,
                                      ParamType.DocumentReference,
                                    ),
                                    'naimMndob': serializeParam(
                                      tfaselOrderOrderRecord.naimMndobText,
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                );

                                await widget.idorder!.reference
                                    .update(createOrderRecordData());
                              },
                              text: FFLocalizations.of(context).getText(
                                'xwn3vxd5' /* rate the tour */,
                              ),
                              icon: const Icon(
                                Icons.star_rate_sharp,
                                size: 15.0,
                              ),
                              options: FFButtonOptions(
                                height: 40.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                iconPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .titleSmallFamily,
                                      color: FlutterFlowTheme.of(context).error,
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .titleSmallIsCustom,
                                    ),
                                elevation: 3.0,
                                borderSide: const BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tfaselOrderOrderRecord.halhOrderMndob ==
                          HalhOrder.Accepted)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 8.0,
                                color: Color(0x1A000000),
                                offset: Offset(
                                  0.0,
                                  4.0,
                                ),
                              )
                            ],
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 60.0,
                                          height: 60.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: touryNetworkImageProvider(
                                                tfaselOrderOrderRecord
                                                        .imgMndob ??
                                                    '',
                                                fallbackAsset:
                                                    kTouryAvatarFallback,
                                              ),
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ).animateOnPageLoad(animationsMap[
                                            'containerOnPageLoadAnimation']!),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Text(
                                                  tfaselOrderOrderRecord
                                                      .naimMndobText,
                                                  style:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleLarge
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLargeFamily,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLargeIsCustom,
                                                          ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 2.0, 0.0, 0.0),
                                                  child: Text(
                                                    '${tfaselOrderOrderRecord.carmndob}- ${valueOrDefault<String>(
                                                      tfaselOrderOrderRecord
                                                          .nameCar,
                                                      'لم يتم تحديث اسم السيارة',
                                                    )} ${valueOrDefault<String>(
                                                      tfaselOrderOrderRecord
                                                          .modelCar,
                                                      'لم يتم تحديث موديل  السيارة',
                                                    )}',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMediumFamily,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMediumIsCustom,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ].divide(const SizedBox(width: 12.0)),
                                    ),
                                    Container(
                                      width: 12.0,
                                      height: 12.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 24.0,
                                  color: Colors.transparent,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        await launchUrl(Uri(
                                          scheme: 'tel',
                                          path: tfaselOrderOrderRecord
                                              .phoneNuMndob
                                              .toString(),
                                        ));
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                size: 20.0,
                                              ),
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  await launchUrl(Uri(
                                                    scheme: 'tel',
                                                    path:
                                                        '0${tfaselOrderOrderRecord.phoneNuMndob.toString()}',
                                                  ));
                                                },
                                                child: Text(
                                                  '0${tfaselOrderOrderRecord.phoneNuMndob.toString()}',
                                                  style:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumFamily,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMediumIsCustom,
                                                          ),
                                                ),
                                              ),
                                            ].divide(
                                                const SizedBox(width: 12.0)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        FutureBuilder<int>(
                                          future: queryChatRecordCount(
                                            queryBuilder: (chatRecord) =>
                                                chatRecord
                                                    .where(
                                                      'idorder',
                                                      isEqualTo: widget
                                                          .idorder?.reference,
                                                    )
                                                    .where(
                                                      'user1',
                                                      isNotEqualTo:
                                                          currentUserReference,
                                                    ),
                                          ),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return Center(
                                                child: SizedBox(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  child: SpinKitChasingDots(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    size: 50.0,
                                                  ),
                                                ),
                                              );
                                            }
                                            int rowCount = snapshot.data!;

                                            return InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                context.pushNamed(
                                                  Chat2Widget.routeName,
                                                  queryParameters: {
                                                    'idorder': serializeParam(
                                                      widget.idorder?.reference,
                                                      ParamType
                                                          .DocumentReference,
                                                    ),
                                                    'naimMndob': serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .naimMndobText,
                                                      ParamType.String,
                                                    ),
                                                    'phoneMndob':
                                                        serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .phoneNuMndob,
                                                      ParamType.int,
                                                    ),
                                                    'imgMndob': serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .imgMndob,
                                                      ParamType.String,
                                                    ),
                                                    'idmndob': serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .mndobUser,
                                                      ParamType
                                                          .DocumentReference,
                                                    ),
                                                  }.withoutNulls,
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  SizedBox(
                                                    width: 20.0,
                                                    height: 20.0,
                                                    child: Stack(
                                                      children: [
                                                        Icon(
                                                          Icons.chat_bubble,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          size: 20.0,
                                                        ),
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  1.0, -1.0),
                                                          child: Container(
                                                            width: 8.0,
                                                            height: 8.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'rv58geej' /* Chat Messages */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMediumFamily,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMediumIsCustom,
                                                        ),
                                                  ),
                                                  if (rowCount >= 1)
                                                    Align(
                                                      alignment:
                                                          const AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: Text(
                                                        valueOrDefault<String>(
                                                          rowCount.toString(),
                                                          '0',
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
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMediumIsCustom,
                                                                ),
                                                      ).animateOnPageLoad(
                                                          animationsMap[
                                                              'textOnPageLoadAnimation']!),
                                                    ),
                                                ].divide(const SizedBox(
                                                    width: 12.0)),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    if (tfaselOrderOrderRecord.halhText ==
                                        'تم البدء في الرحلة')
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (tfaselOrderOrderRecord.endTime !=
                                              null)
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                context.pushNamed(
                                                  Chat2Widget.routeName,
                                                  queryParameters: {
                                                    'idorder': serializeParam(
                                                      widget.idorder?.reference,
                                                      ParamType
                                                          .DocumentReference,
                                                    ),
                                                    'naimMndob': serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .naimMndobText,
                                                      ParamType.String,
                                                    ),
                                                    'phoneMndob':
                                                        serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .phoneNuMndob,
                                                      ParamType.int,
                                                    ),
                                                    'imgMndob': serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .imgMndob,
                                                      ParamType.String,
                                                    ),
                                                    'idmndob': serializeParam(
                                                      tfaselOrderOrderRecord
                                                          .mndobUser,
                                                      ParamType
                                                          .DocumentReference,
                                                    ),
                                                  }.withoutNulls,
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Icon(
                                                    Icons.timer_sharp,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    size: 20.0,
                                                  ),
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'n5fehvoh' /* End of Trip */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
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
                                                  Text(
                                                    dateTimeFormat(
                                                      "jm",
                                                      tfaselOrderOrderRecord
                                                          .endTime!,
                                                      locale:
                                                          FFLocalizations.of(
                                                                  context)
                                                              .languageCode,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMediumFamily,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .error,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMediumIsCustom,
                                                        ),
                                                  ),
                                                ].divide(const SizedBox(
                                                    width: 12.0)),
                                              ),
                                            ),
                                        ],
                                      ),
                                  ].divide(const SizedBox(height: 16.0)),
                                ),
                                const Divider(
                                  height: 24.0,
                                  color: Colors.transparent,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: FFButtonWidget(
                                        onPressed: () async {
                                          context.pushNamed(
                                            MapTrdemoWidget.routeName,
                                            queryParameters: {
                                              'idd': serializeParam(
                                                tfaselOrderOrderRecord
                                                    .reference,
                                                ParamType.DocumentReference,
                                              ),
                                            }.withoutNulls,
                                          );
                                        },
                                        text:
                                            FFLocalizations.of(context).getText(
                                          '0ldnm3my' /* Track Location */,
                                        ),
                                        icon: const Icon(
                                          Icons.my_location,
                                          size: 12.0,
                                        ),
                                        options: FFButtonOptions(
                                          height: 44.0,
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                          iconColor:
                                              FlutterFlowTheme.of(context).info,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmallFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .info,
                                                fontSize: 12.0,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .titleSmallIsCustom,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: FFButtonWidget(
                                        onPressed: () async {
                                          await launchUrl(Uri(
                                            scheme: 'tel',
                                            path:
                                                '0${tfaselOrderOrderRecord.phoneNuMndob.toString()}',
                                          ));
                                        },
                                        text:
                                            FFLocalizations.of(context).getText(
                                          'pmkrdhph' /* Call Now */,
                                        ),
                                        icon: const Icon(
                                          Icons.phone,
                                          size: 12.0,
                                        ),
                                        options: FFButtonOptions(
                                          height: 44.0,
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                          iconColor:
                                              FlutterFlowTheme.of(context)
                                                  .success,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmallFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                fontSize: 12.0,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .titleSmallIsCustom,
                                              ),
                                          elevation: 0.0,
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                    ),
                                  ].divide(const SizedBox(width: 12.0)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Places / pickup — use live stream order (not stale nav param).
                      Builder(
                        builder: (context) {
                          final live = tfaselOrderOrderRecord;
                          final amakn = live.listAmakn.toList();
                          final pickup = live.lokeshn ?? live.customerPickup;
                          final isGuide = live.driverGuide ||
                              (widget.idorder?.driverGuide == true);

                          if (amakn.isEmpty && pickup == null) {
                            return const SizedBox.shrink();
                          }

                          Widget placeCard({
                            required String label,
                            LatLng? loc,
                          }) {
                            final title = label.trim().isEmpty
                                ? 'موقع غير محدد'
                                : label.trim();
                            return Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 8.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 0.92,
                                constraints: const BoxConstraints(minHeight: 70),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 3.0,
                                      color: Color(0x35000000),
                                      offset: Offset(0.0, 1.0),
                                    )
                                  ],
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      12, 8, 12, 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.map,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge
                                              .override(
                                                fontFamily: 'cairo',
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ),
                                      if (loc != null)
                                        IconButton(
                                          tooltip: 'عرض المسار',
                                          onPressed: () async {
                                            await TouryNavigationService
                                                .openGoogleMapsNavigation(
                                              destination: loc,
                                              localeKey: TouryNavigationService
                                                  .localeForContext(context),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.location_on_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 9.0, 0.0, 9.0),
                            child: Column(
                              children: [
                                if (amakn.isNotEmpty)
                                  ...amakn.map(
                                    (item) => placeCard(
                                      label: item.displayLabel,
                                      loc: item.loceshn,
                                    ),
                                  )
                                else if (pickup != null)
                                  placeCard(
                                    label: isGuide
                                        ? 'نقطة الالتقاط'
                                        : 'موقع الطلب',
                                    loc: pickup,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      StreamBuilder<List<ExtraHoursRecord>>(
                        stream: queryExtraHoursRecord(
                          queryBuilder: (extraHoursRecord) => extraHoursRecord
                              .where(
                                'RevOrder',
                                isEqualTo: widget.idorder?.reference,
                              )
                              .orderBy('dateAdd', descending: true),
                        ),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: SpinKitChasingDots(
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 50.0,
                                ),
                              ),
                            );
                          }
                          List<ExtraHoursRecord> listViewExtraHoursRecordList =
                              snapshot.data!;

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: listViewExtraHoursRecordList.length,
                            itemBuilder: (context, listViewIndex) {
                              final listViewExtraHoursRecord =
                                  listViewExtraHoursRecordList[listViewIndex];
                              return Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 16.0),
                                child: Container(
                                  width: MediaQuery.sizeOf(context).width * 1.0,
                                  height: 132.92,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 12.0,
                                        color: Color(0x34000000),
                                        offset: Offset(
                                          -2.0,
                                          5.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            8.0, 8.0, 12.0, 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          width: 4.0,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 12.0, 0.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 4.0, 0.0, 0.0),
                                                  child: Text(
                                                    '+ ${listViewExtraHoursRecord.addSaat.toString()} ${FFLocalizations.of(context).getVariableText(
                                                      enText: 'Hour/Hours',
                                                      arText: 'ساعة/ساعات',
                                                      zh_HansText: '',
                                                      trText: 'Hour/Hours',
                                                      urText: 'Hour/Hours',
                                                      ruText: 'Hour/Hours',
                                                      azText: 'Hour/Hours',
                                                      kaText: 'Hour/Hours',
                                                    )}',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .headlineSmall
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .headlineSmallFamily,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .error,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .headlineSmallIsCustom,
                                                        ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .fromSTEB(
                                                          0.0, 4.0, 0.0, 0.0),
                                                  child: Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      '12jh7osg' /* Extra hours have been added to... */,
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMediumFamily,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelMediumIsCustom,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'do2ea7bj' /* Order Summary */,
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmallFamily,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelSmallIsCustom,
                                                        ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        0.0, 4.0, 0.0, 4.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(4.0,
                                                              4.0, 0.0, 0.0),
                                                      child: Text(
                                                        formatNumber(
                                                          listViewExtraHoursRecord
                                                              .total,
                                                          formatType: FormatType
                                                              .decimal,
                                                          decimalType:
                                                              DecimalType
                                                                  .automatic,
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
                                                                  fontSize:
                                                                      22.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .headlineSmallIsCustom,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        0.0, 4.0, 0.0, 8.0),
                                                child: Text(
                                                  dateTimeFormat(
                                                    "relative",
                                                    listViewExtraHoursRecord
                                                        .dateAdd!,
                                                    locale: FFLocalizations.of(
                                                            context)
                                                        .languageCode,
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
                                                            color: const Color(
                                                                0xFF8C8C8C),
                                                            fontSize: 11.0,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
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
                          );
                        },
                      ),
                      if (tfaselOrderOrderRecord.canCancelByCustomer)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 8.0, 16.0, 11.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: FFButtonWidget(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return WebViewAware(
                                          child: AlertDialog(
                                            title: Text(
                                                'ui_text_b4bbf18b10'.tr()),
                                            content: Text(
                                                'ui_text_cff8cb30ef'.tr()),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    alertDialogContext, false),
                                                child: Text(
                                                    'ui_text_5c528d9fa3'.tr()),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    alertDialogContext, true),
                                                child: Text(
                                                    'ui_text_23ef9d7d03'.tr()),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ) ??
                                    false;
                                if (!confirm) return;
                                final err =
                                    await TouryCustomerOrderActions.cancelOrder(
                                  tfaselOrderOrderRecord,
                                );
                                if (!context.mounted) return;
                                if (err == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'ui_text_eae6165343'.tr(),
                                        style: TextStyle(
                                          fontFamily: 'cairo',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      duration:
                                          const Duration(milliseconds: 4000),
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).primary,
                                    ),
                                  );
                                  context.pushNamed(
                                    List22TaskOverviewResponsiveWidget
                                        .routeName,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        err,
                                        style: TextStyle(
                                          fontFamily: 'cairo',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                        ),
                                      ),
                                      duration:
                                          const Duration(milliseconds: 4000),
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).error,
                                      action: SnackBarAction(
                                        label: 'تواصل معنا',
                                        onPressed: () async {
                                          await launchURL(
                                              'https://wa.me/966533356126');
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              text: FFLocalizations.of(context).getText(
                                'hjqgpu0l' /* Cancel Order */,
                              ),
                              icon: const Icon(
                                Icons.cancel_rounded,
                                size: 15.0,
                              ),
                              options: FFButtonOptions(
                                height: 44.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                iconPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .titleSmallFamily,
                                      color:
                                          FlutterFlowTheme.of(context).error,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .titleSmallIsCustom,
                                    ),
                                elevation: 3.0,
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context).error,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16.0, 9.0, 16.0, 9.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                4.0, 12.0, 4.0, 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wechat_sharp,
                                  color: FlutterFlowTheme.of(context).error,
                                  size: 24.0,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        FFLocalizations.of(context).getText(
                                          'fp2zr3zu' /* Contact us directly */,
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMediumFamily,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .bodyMediumIsCustom,
                                            ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0.0, 4.0, 0.0, 0.0),
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            'n6stun37' /* Would you like to contact our ... */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmallFamily,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmallIsCustom,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      await launchURL(
                                          'https://wa.me/966533356126');
                                    },
                                    text: FFLocalizations.of(context).getText(
                                      'pn9qf61t' /* WhatsApp */,
                                    ),
                                    icon: const Icon(
                                      Icons.wechat_sharp,
                                      size: 15.0,
                                    ),
                                    options: FFButtonOptions(
                                      width: 111.0,
                                      height: 40.0,
                                      padding: const EdgeInsets.all(8.0),
                                      iconPadding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: FlutterFlowTheme.of(context).error,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmallFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .info,
                                            letterSpacing: 0.0,
                                            useGoogleFonts:
                                                !FlutterFlowTheme.of(context)
                                                    .bodySmallIsCustom,
                                          ),
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                ),
                              ].divide(const SizedBox(width: 12.0)),
                            ),
                          ),
                        ),
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
