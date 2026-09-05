import 'dart:async';

import 'package:admin_arawatan/add_place_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_panel_session.dart';
import '/backend/admin_agent_session_ready.dart';
import '/backend/admin_route_guard.dart';
import '/backend/admin_role_service.dart';

import '/core/admin_splash_screen.dart';
import '/core/admin_qa_fixtures.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';
import '/admin/admin_driver_review_fixture/admin_qa_fixture_unavailable_widget.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Widget _panelHomeForCurrentUser() {
  if (AdminRoleService.isPartner) {
    return const PartnerBookingsWidget();
  }
  if (AdminRoleService.isTransportCompany) {
    return const CompanyDriversWidget();
  }
  return Home22DashboardWidget();
}

/// Login screen, loading while profile loads, or panel home when authenticated.
Widget _loginOrPanelHome() {
  if (!loggedIn) {
    return HomePageWidget();
  }
  if (currentUserDocument == null) {
    return const _AuthLoadingScreen();
  }
  if (!AdminRoleService.hasPanelAccess) {
    return HomePageWidget();
  }
  WidgetsBinding.instance.addPostFrameCallback((_) => syncPanelHomeUrl());
  return _PanelSessionGate(child: _panelHomeForCurrentUser());
}

/// Blocks panel home until role scope + dashboard cache are prepared.
class _PanelSessionGate extends StatefulWidget {
  const _PanelSessionGate({required this.child});

  final Widget child;

  @override
  State<_PanelSessionGate> createState() => _PanelSessionGateState();
}

class _PanelSessionGateState extends State<_PanelSessionGate> {
  bool _ready = AdminPanelSession.isScopeReady;
  StreamSubscription<void>? _readySub;

  @override
  void initState() {
    super.initState();
    _readySub = AdminAgentSessionReady.onReady.listen((_) {
      if (mounted && AdminPanelSession.isScopeReady) {
        setState(() => _ready = true);
      }
    });
    _prepare();
  }

  Future<void> _prepare() async {
    await AdminPanelSession.ensureScopeReady();
    if (!mounted) return;
    setState(() => _ready = AdminPanelSession.isScopeReady);
    // Let the home UI paint before background stats queries start.
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) unawaited(AdminPanelSession.warmDashboard());
    });
  }

  @override
  void dispose() {
    _readySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const _AuthLoadingScreen();
    }
    return Semantics(
      identifier: 'qa-panel-ready',
      label: 'qa-panel-ready',
      child: widget.child,
    );
  }
}

/// Updates the browser/app route to the panel home when still on a login path.
void syncPanelHomeUrl() {
  final navContext = appNavigatorKey.currentContext;
  if (navContext == null) return;
  final router = GoRouter.of(navContext);
  final loc = router.routeInformationProvider.value.uri.path;
  if (loc != HomePageWidget.routePath && loc != '/') return;
  router.go(homePathForCurrentUser());
}

String? globalAuthRedirect(AppStateNotifier notifier, GoRouterState state) {
  if (!notifier.loggedIn) return null;

  final loc = state.uri.path;
  final onLoginScreen = loc == '/' || loc == HomePageWidget.routePath;
  if (!onLoginScreen) return null;

  if (currentUserDocument == null) return null;
  if (!AdminRoleService.hasPanelAccess) return null;

  return homePathForCurrentUser();
}

/// Auth/session gate loading — same branded chrome as app boot splash.
/// Avoids white-spinner ↔ teal-splash shell flicker during claims/profile wait.
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) => const AdminSplashScreen();
}

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  /// Updates auth user without triggering a router rebuild (during sign-in flow).
  void updateSilently(BaseAuthUser newUser) {
    initialUser ??= newUser;
    user = newUser;
  }

  void update(BaseAuthUser newUser, {bool forceNotify = false}) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if ((notifyOnAuthChange && shouldUpdate) || forceNotify) {
      notifyListeners();
    }
    // Re-enable auth notifications only when they were already on — do not undo
    // prepareAuthEvent() while a sign-in/sign-out flow is in progress.
    if (notifyOnAuthChange) {
      updateNotifyOnAuthChange(true);
    }
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }

  /// Call when Firestore profile finished loading (triggers router redirect).
  void notifyProfileReady() => notifyListeners();
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      redirect: (context, state) => globalAuthRedirect(appStateNotifier, state),
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? AuthUserStreamWidget(
              builder: (context) {
                if (!AdminRoleService.hasPanelAccess) {
                  return HomePageWidget();
                }
                return _panelHomeForCurrentUser();
              },
            )
          : HomePageWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? AuthUserStreamWidget(
                  builder: (context) {
                    if (!AdminRoleService.hasPanelAccess) {
                      return HomePageWidget();
                    }
                    return _panelHomeForCurrentUser();
                  },
                )
              : HomePageWidget(),
        ),
        //add_page
        FFRoute(
          name: AddPlacePage.routeName,
          path: AddPlacePage.routePath,
          requireAuth: true,
          builder: (context, params) => AddPlacePage(),
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          builder: (context, params) => AuthUserStreamWidget(
            builder: (context) => _loginOrPanelHome(),
          ),
        ),
        FFRoute(
          name: AdminHomeWidget.routeName,
          path: AdminHomeWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminHomeWidget(),
        ),
        FFRoute(
          name: AdminM3almWidget.routeName,
          path: AdminM3almWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminM3almWidget(
            partnersOnly: params.getParam(
                  'partnersOnly',
                  ParamType.bool,
                ) ??
                false,
          ),
        ),
        FFRoute(
          name: AdminPartnersWidget.routeName,
          path: AdminPartnersWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminPartnersWidget(),
        ),
        FFRoute(
          name: AdminAddPartnerWidget.routeName,
          path: AdminAddPartnerWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminAddPartnerWidget(),
        ),
        FFRoute(
          name: AdminaddMkanWidget.routeName,
          path: AdminaddMkanWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminaddMkanWidget(),
        ),
        FFRoute(
          name: AdminDolWidget.routeName,
          path: AdminDolWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminDolWidget(),
        ),
        FFRoute(
          name: AdminregionWidget.routeName,
          path: AdminregionWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminregionWidget(),
        ),
        FFRoute(
          name: AdminciteWidget.routeName,
          path: AdminciteWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminciteWidget(),
        ),
        FFRoute(
          name: AdminuserWidget.routeName,
          path: AdminuserWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminuserWidget(),
        ),
        FFRoute(
          name: AdminDriversWidget.routeName,
          path: AdminDriversWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminDriversWidget(),
        ),
        FFRoute(
          name: AdminBookingDetailsWidget.routeName,
          path: AdminBookingDetailsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminBookingDetailsWidget(
            idbokeng: params.getParam(
              'idbokeng',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['order'],
            ),
          ),
        ),
        FFRoute(
          name: AdminALLhgZWidget.routeName,
          path: AdminALLhgZWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminALLhgZWidget(),
        ),
        FFRoute(
          name: AdminAgentWidget.routeName,
          path: AdminAgentWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminAgentWidget(),
        ),
        FFRoute(
          name: AdminAgentReportWidget.routeName,
          path: AdminAgentReportWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminAgentReportWidget(
            iduser: params.getParam(
              'iduser',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
          ),
        ),
        FFRoute(
          name: AdminAddAgentWidget.routeName,
          path: AdminAddAgentWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminAddAgentWidget(),
        ),
        FFRoute(
          name: EdetAgentWidget.routeName,
          path: EdetAgentWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EdetAgentWidget(
            agentRef: params.getParam(
              'agentRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
          ),
        ),
        FFRoute(
          name: AdminSuperAdminsWidget.routeName,
          path: AdminSuperAdminsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminSuperAdminsWidget(),
        ),
        FFRoute(
          name: AdminAddSuperAdminWidget.routeName,
          path: AdminAddSuperAdminWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminAddSuperAdminWidget(),
        ),
        FFRoute(
          name: EdetSuperAdminWidget.routeName,
          path: EdetSuperAdminWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EdetSuperAdminWidget(
            superAdminRef: params.getParam(
              'superAdminRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
          ),
        ),
        FFRoute(
          name: AdminSuportWidget.routeName,
          path: AdminSuportWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminSuportWidget(),
        ),
        FFRoute(
          name: AdminNotificationsWidget.routeName,
          path: AdminNotificationsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminNotificationsWidget(),
        ),
        FFRoute(
          name: AdminUserManagementSystemWidget.routeName,
          path: AdminUserManagementSystemWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminUserManagementSystemWidget(),
        ),
        FFRoute(
          name: AdminRegesrWidget.routeName,
          path: AdminRegesrWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminRegesrWidget(),
        ),
        FFRoute(
          name: AdmintypecarWidget.routeName,
          path: AdmintypecarWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdmintypecarWidget(),
        ),
        FFRoute(
          name: AddDolhWidget.routeName,
          path: AddDolhWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AddDolhWidget(),
        ),
        FFRoute(
          name: AdminaddMkanCopyWidget.routeName,
          path: AdminaddMkanCopyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminaddMkanCopyWidget(
            idmkan: params.getParam(
              'idmkan',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['mkan'],
            ),
          ),
        ),
        FFRoute(
          name: AddRegWidget.routeName,
          path: AddRegWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AddRegWidget(),
        ),
        FFRoute(
          name: EdetRegWidget.routeName,
          path: EdetRegWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EdetRegWidget(
            idreg: params.getParam(
              'idreg',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['cities'],
            ),
          ),
        ),
        FFRoute(
          name: EdetDolhWidget.routeName,
          path: EdetDolhWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EdetDolhWidget(
            iddolhe: params.getParam(
              'iddolhe',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['countries'],
            ),
          ),
        ),
        FFRoute(
          name: AddVillWidget.routeName,
          path: AddVillWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AddVillWidget(),
        ),
        FFRoute(
          name: EdetVillWidget.routeName,
          path: EdetVillWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EdetVillWidget(
            idvill: params.getParam(
              'idvill',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['villages'],
            ),
          ),
        ),
        FFRoute(
          name: AdminDriversCopyWidget.routeName,
          path: AdminDriversCopyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminDriversCopyWidget(),
        ),
        FFRoute(
          name: DriverActivationWidget.routeName,
          path: DriverActivationWidget.routePath,
          requireAuth: true,
          builder: (context, params) => DriverActivationWidget(
            dre: params.getParam(
              'dre',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
          ),
        ),
        FFRoute(
          name: AdminDriverExpiryQueueWidget.routeName,
          path: AdminDriverExpiryQueueWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminDriverExpiryQueueWidget(
            initialBucket: params.getParam(
                  'bucket',
                  ParamType.String,
                ) ??
                'expiring_soon',
          ),
        ),
        FFRoute(
          name: AdminDriverReviewFixtureWidget.routeName,
          path: AdminDriverReviewFixtureWidget.routePath,
          requireAuth: true,
          builder: (context, params) {
            if (!AdminQaFixtures.enabled) {
              return const AdminQaFixtureUnavailableWidget();
            }
            return AdminDriverReviewFixtureWidget(
              reviewState: params.getParam(
                    'state',
                    ParamType.String,
                  ) ??
                  'pending_review',
            );
          },
        ),
        FFRoute(
          name: CarTypeAdditionWidget.routeName,
          path: CarTypeAdditionWidget.routePath,
          requireAuth: true,
          builder: (context, params) => CarTypeAdditionWidget(),
        ),
        FFRoute(
          name: AdminvillWidget.routeName,
          path: AdminvillWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminvillWidget(),
        ),
        FFRoute(
          name: AddDrevWidget.routeName,
          path: AddDrevWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AddDrevWidget(
            editUserRef: params.getParam(
              'editUser',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
            companyRef: params.getParam(
              'companyRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['transport_company'],
            ),
          ),
        ),
        FFRoute(
          name: AdminTransportCompaniesWidget.routeName,
          path: AdminTransportCompaniesWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminTransportCompaniesWidget(),
        ),
        FFRoute(
          name: AddTransportCompanyWidget.routeName,
          path: AddTransportCompanyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AddTransportCompanyWidget(),
        ),
        FFRoute(
          name: EdetTransportCompanyWidget.routeName,
          path: EdetTransportCompanyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EdetTransportCompanyWidget(
            companyRef: params.getParam(
              'companyRef',
              ParamType.DocumentReference,
              isList: false,
            ),
          ),
        ),
        FFRoute(
          name: AdmindreverWidget.routeName,
          path: AdmindreverWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdmindreverWidget(),
        ),
        FFRoute(
          name: AdminTourGuidesWidget.routeName,
          path: AdminTourGuidesWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminTourGuidesWidget(),
        ),
        FFRoute(
          name: AdminFinanceHubWidget.routeName,
          path: AdminFinanceHubWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminFinanceHubWidget(),
        ),
        FFRoute(
          name: AdminFinanceChannelsWidget.routeName,
          path: AdminFinanceChannelsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminFinanceChannelsWidget(),
        ),
        FFRoute(
          name: AdminFinanceReceivablesWidget.routeName,
          path: AdminFinanceReceivablesWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminFinanceReceivablesWidget(),
        ),
        FFRoute(
          name: AdminAgentFinanceWidget.routeName,
          path: AdminAgentFinanceWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminAgentFinanceWidget(),
        ),
        FFRoute(
          name: AdminReconciliationWidget.routeName,
          path: AdminReconciliationWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminReconciliationWidget(),
        ),
        FFRoute(
          name: AdminFinancialPeriodsWidget.routeName,
          path: AdminFinancialPeriodsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminFinancialPeriodsWidget(),
        ),
        FFRoute(
          name: AdminFinanceReportsWidget.routeName,
          path: AdminFinanceReportsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminFinanceReportsWidget(),
        ),
        FFRoute(
          name: AdminFinanceAuditWidget.routeName,
          path: AdminFinanceAuditWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminFinanceAuditWidget(),
        ),
        FFRoute(
          name: AdminDiagnosticsWidget.routeName,
          path: AdminDiagnosticsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminDiagnosticsWidget(),
        ),
        FFRoute(
          name: AdminDriverWalletsWidget.routeName,
          path: AdminDriverWalletsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminDriverWalletsWidget(),
        ),
        FFRoute(
          name: AddUserWidget.routeName,
          path: AddUserWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AddUserWidget(),
        ),
        FFRoute(
          name: HomeWidget.routeName,
          path: HomeWidget.routePath,
          requireAuth: true,
          builder: (context, params) => HomeWidget(),
        ),
        FFRoute(
          name: Home3Widget.routeName,
          path: Home3Widget.routePath,
          requireAuth: true,
          builder: (context, params) => Home3Widget(),
        ),
        FFRoute(
          name: Home22DashboardWidget.routeName,
          path: Home22DashboardWidget.routePath,
          requireAuth: true,
          builder: (context, params) => Home22DashboardWidget(),
        ),
        FFRoute(
          name: AdminProfitsWidget.routeName,
          path: AdminProfitsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminProfitsWidget(),
        ),
        FFRoute(
          name: AdminSettlementsWidget.routeName,
          path: AdminSettlementsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminSettlementsWidget(),
        ),
        FFRoute(
          name: AdminSettlementDetailsWidget.routeName,
          path: AdminSettlementDetailsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminSettlementDetailsWidget(
            settlementId: params.getParam(
              'settlementId',
              ParamType.String,
            ),
            diagnostic: params.getParam('diagnostic', ParamType.String) == '1',
          ),
        ),
        FFRoute(
          name: AdminSettlementReceiptWidget.routeName,
          path: AdminSettlementReceiptWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminSettlementReceiptWidget(
            paymentId: params.getParam(
              'paymentId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AdminAuditLogWidget.routeName,
          path: AdminAuditLogWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminAuditLogWidget(),
        ),
        FFRoute(
          name: AdminReportsHubWidget.routeName,
          path: AdminReportsHubWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AdminReportsHubWidget(),
        ),
        FFRoute(
          name: PartnerBookingsWidget.routeName,
          path: PartnerBookingsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const PartnerBookingsWidget(),
        ),
        FFRoute(
          name: CompanyDriversWidget.routeName,
          path: CompanyDriversWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const CompanyDriversWidget(),
        ),
        FFRoute(
          name: SettingsWidget.routeName,
          path: SettingsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => SettingsWidget(),
        ),
        FFRoute(
          name: AdminAgentCopyWidget.routeName,
          path: AdminAgentCopyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AdminAgentCopyWidget(),
        ),
        FFRoute(
          name: DriverProfileWidget.routeName,
          path: DriverProfileWidget.routePath,
          requireAuth: true,
          builder: (context, params) => DriverProfileWidget(
            iduser: params.getParam(
              'iduser',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
          ),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) {
    appState.updateNotifyOnAuthChange(false);
    appState.setRedirectLocationIfUnset(location);
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/homePage';
          }

          final roleRedirect = adminRouteRedirect(state.name);
          if (roleRedirect != null) {
            return roleRedirect;
          }

          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child =
              appStateNotifier.loading ? const AdminSplashScreen() : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    // Avoid GoRouterState.of — release null-check in go_router 12.1.3 registry.
    final location = adminCurrentLocation(context);
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  /// Safe current [GoRoute.name] without [GoRouterState.of].
  ///
  /// go_router 12.1.3 [GoRouterState.of] → `_createPageRouteAssociation` uses
  /// `registry[page]!`. In release builds the preceding `assert(containsKey)`
  /// is stripped, so shell widgets (e.g. menu highlight) throw
  /// "Null check operator used on a null value" during navigation transitions
  /// when the Page is briefly absent from the registry.
  String? getCurrentRouteName() {
    final config = routerDelegate.currentConfiguration;
    if (config.isEmpty) return null;
    final RouteMatch lastMatch = config.last;
    final RouteMatchList matchList =
        lastMatch is ImperativeRouteMatch ? lastMatch.matches : config;
    for (final match in matchList.matches.reversed) {
      final route = match.route;
      if (route is GoRoute) {
        final name = route.name;
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return null;
  }
}

/// Admin-safe route name for shell widgets. Never calls [GoRouterState.of].
String? adminCurrentRouteName(BuildContext context) {
  try {
    return GoRouter.of(context).getCurrentRouteName();
  } catch (_) {
    return null;
  }
}

/// Admin-safe location string. Never calls [GoRouterState.of].
String adminCurrentLocation(BuildContext context) {
  try {
    return GoRouter.of(context).getCurrentLocation();
  } catch (_) {
    return '/';
  }
}
