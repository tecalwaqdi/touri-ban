import 'package:firebase_auth/firebase_auth.dart';

import '/backend/admin_login_flow.dart';
import '/components/admin_ui.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    _model.emailAddressLoginTextController ??= TextEditingController();
    _model.emailAddressLoginFocusNode ??= FocusNode();

    _model.passwordLoginTextController ??= TextEditingController();
    _model.passwordLoginFocusNode ??= FocusNode();

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
        resizeToAvoidBottomInset: true,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: AdminUi.brandTeal,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            FFLocalizations.of(context).getText(
              'gdj3v3zk' /* Sign up / Sign in */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  useGoogleFonts:
                      !FlutterFlowTheme.of(context).headlineMediumIsCustom,
                ),
          ),
          actions: [],
          centerTitle: false,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              final logoHeight = compact ? 88.0 : 120.0;
              final logoWidth = compact ? 102.0 : 140.0;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  compact ? 8 : 12,
                  16,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/__2025-07-09_133622.png',
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    AdminLoginCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'ynbsay6v' /* Login */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'cairo',
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 4),
                            height: 3,
                            width: 72,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 20.0, 0.0, 0.0),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: TextFormField(
                                                    controller: _model
                                                        .emailAddressLoginTextController,
                                                    focusNode: _model
                                                        .emailAddressLoginFocusNode,
                                                    obscureText: false,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                        '8gngx8fm' /* Email Address */,
                                                      ),
                                                      labelStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmallFamily,
                                                                fontSize: 14.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmallIsCustom,
                                                              ),
                                                      hintText:
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                        'oz5u3njo' /* Enter your email... */,
                                                      ),
                                                      hintStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmallFamily,
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmallIsCustom,
                                                              ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      errorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      filled: true,
                                                      fillColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryBackground,
                                                      contentPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  20.0,
                                                                  24.0,
                                                                  20.0,
                                                                  24.0),
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMediumFamily,
                                                          fontSize: 14.0,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMediumIsCustom,
                                                        ),
                                                    validator: _model
                                                        .emailAddressLoginTextControllerValidator
                                                        .asValidator(context),
                                                  ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 12.0, 0.0, 0.0),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: TextFormField(
                                                    controller: _model
                                                        .passwordLoginTextController,
                                                    focusNode: _model
                                                        .passwordLoginFocusNode,
                                                    obscureText: !_model
                                                        .passwordLoginVisibility,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                        'h9szauvt' /* Password */,
                                                      ),
                                                      labelStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmallFamily,
                                                                fontSize: 14.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmallIsCustom,
                                                              ),
                                                      hintText:
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                        '6p3l2j5k' /* Enter your password... */,
                                                      ),
                                                      hintStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .override(
                                                                fontFamily: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmallFamily,
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmallIsCustom,
                                                              ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      errorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Color(0x00000000),
                                                          width: 1.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      filled: true,
                                                      fillColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryBackground,
                                                      contentPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  20.0,
                                                                  24.0,
                                                                  20.0,
                                                                  24.0),
                                                      suffixIcon: InkWell(
                                                        onTap: () =>
                                                            safeSetState(
                                                          () => _model
                                                                  .passwordLoginVisibility =
                                                              !_model
                                                                  .passwordLoginVisibility,
                                                        ),
                                                        focusNode: FocusNode(
                                                            skipTraversal:
                                                                true),
                                                        child: Icon(
                                                          _model.passwordLoginVisibility
                                                              ? Icons
                                                                  .visibility_outlined
                                                              : Icons
                                                                  .visibility_off_outlined,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          size: 20.0,
                                                        ),
                                                      ),
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
                                                    validator: _model
                                                        .passwordLoginTextControllerValidator
                                                        .asValidator(context),
                                                  ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 22.0, 0.0, 0.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'y9quj14n' /* Select the app language */,
                                                        ),
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
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      !FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMediumIsCustom,
                                                                ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    11.0,
                                                                    0.0,
                                                                    0.0),
                                                        child:
                                                            FlutterFlowLanguageSelector(
                                                          width: 200.0,
                                                          backgroundColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                          borderColor: Colors
                                                              .transparent,
                                                          dropdownIconColor:
                                                              Colors.white,
                                                          borderRadius: 8.0,
                                                          textStyle: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontSize: 13.0,
                                                          ),
                                                          hideFlags: true,
                                                          flagSize: 24.0,
                                                          flagTextGap: 8.0,
                                                          currentLanguage:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .languageCode,
                                                          languages:
                                                              FFLocalizations
                                                                  .languages(),
                                                          onChanged: (lang) =>
                                                              setAppLanguage(
                                                                  context,
                                                                  lang),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 24.0, 0.0, 0.0),
                                                  child: FFButtonWidget(
                                                    onPressed: () async {
                                                      GoRouter.of(context)
                                                          .prepareAuthEvent(
                                                              true);

                                                      final authUser =
                                                          await authManager
                                                              .signInWithEmail(
                                                        context,
                                                        _model
                                                            .emailAddressLoginTextController
                                                            .text,
                                                        _model
                                                            .passwordLoginTextController
                                                            .text,
                                                      );
                                                      if (authUser == null) {
                                                        return;
                                                      }

                                                      if (!context.mounted) {
                                                        return;
                                                      }

                                                      final result =
                                                          await completePanelSignIn(
                                                        authUser,
                                                      );

                                                      if (!context.mounted) {
                                                        return;
                                                      }

                                                      if (result ==
                                                          AdminLoginResult
                                                              .unauthorized) {
                                                        await showDialog(
                                                          context: context,
                                                          builder:
                                                              (alertDialogContext) {
                                                            return AlertDialog(
                                                              title: Text(uiTr(context, 'غير مصرّح')),
                                                              content: Text(
                                                                messageForLoginResult(
                                                                    result),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          alertDialogContext),
                                                                  child: const Text(
                                                                      'حسناً'),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                        GoRouter.of(context)
                                                            .prepareAuthEvent();
                                                        await authManager
                                                            .signOut();
                                                        GoRouter.of(context)
                                                            .clearRedirectLocation();
                                                        return;
                                                      }

                                                      if (result !=
                                                          AdminLoginResult
                                                              .success) {
                                                        final msg =
                                                            messageForLoginResult(
                                                                result);
                                                        if (msg.isNotEmpty) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                                content:
                                                                    Text(msg)),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      'xzqrxbqw' /* Login */,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: double.infinity,
                                                      height: 50.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
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
                                                                    .primaryBackground,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    !FlutterFlowTheme.of(
                                                                            context)
                                                                        .titleSmallIsCustom,
                                                              ),
                                                      elevation: 3.0,
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.transparent,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                  ),
                                                ),
                                               TextButton(
  onPressed: () async {
    if (_model.emailAddressLoginTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_login_enter_email_first'))),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _model.emailAddressLoginTextController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_login_reset_sent'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appTr(context, 'adm_load_failed')}: $e')),
      );
    }
  },
  child: 
  Text(
  FFLocalizations.of(context).getText(
    'h9t30wk4' /* Forgot Password ? */,
  ),
  style: TextStyle(color: Colors.blue),
),

),

                            ],
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
      ),
    );
  }
}
