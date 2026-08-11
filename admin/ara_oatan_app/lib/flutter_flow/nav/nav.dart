import 'dart:async';

import 'package:ara_oatan_app/wallet/screens/walletscreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';

import '/auth/base_auth_user_provider.dart';

import '/backend/push_notifications/push_notifications_handler.dart'
    show PushNotificationsHandler;
import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';
import '/core/toury_splash_screen.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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

  bool get loading => showSplashImage;
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

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? const NavBarPage() : const HomePagWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) =>
              appStateNotifier.loggedIn ? const NavBarPage() : const HomePagWidget(),
        ),
        FFRoute(
          name: HomePagWidget.routeName,
          path: HomePagWidget.routePath,
          builder: (context, params) => const HomePagWidget(),
        ),
         FFRoute(
          name: WalletScreenWidget.routeName,
          path: WalletScreenWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const WalletScreenWidget(),
        ),
        FFRoute(
          name: CitiesWidget.routeName,
          path: CitiesWidget.routePath,
          requireAuth: true,
          builder: (context, params) => CitiesWidget(
            dol: params.getParam(
              'dol',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['countries'],
            ),
            textstre: params.getParam(
              'textstre',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: Citie2Widget.routeName,
          path: Citie2Widget.routePath,
          requireAuth: true,
          builder: (context, params) => Citie2Widget(
            coun: params.getParam(
              'coun',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['countries'],
            ),
            naim: params.getParam(
              'naim',
              ParamType.String,
            ),
            osfdolh: params.getParam(
              'osfdolh',
              ParamType.String,
            ),
            idcit: params.getParam(
              'idcit',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['countries'],
            ),
            imgDolh: params.getParam(
              'imgDolh',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ListWidget.routeName,
          path: ListWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const ListWidget(),
        ),
        FFRoute(
          name: PlacedetailsWidget.routeName,
          path: PlacedetailsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => PlacedetailsWidget(
            mk: params.getParam(
              'mk',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['mkan'],
            ),
            textnaim: params.getParam(
              'textnaim',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: Profile05Widget.routeName,
          path: Profile05Widget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? const NavBarPage(initialPage: 'Profile05')
              : const Profile05Widget(),
        ),
        FFRoute(
          name: UpdateProfWidget.routeName,
          path: UpdateProfWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const UpdateProfWidget(),
        ),
        FFRoute(
          name: LISTCountriesWidget.routeName,
          path: LISTCountriesWidget.routePath,
          builder: (context, params) => const LISTCountriesWidget(),
        ),
        FFRoute(
          name: Checkout3Widget.routeName,
          path: Checkout3Widget.routePath,
          builder: (context, params) => const Checkout3Widget(),
        ),
        FFRoute(
          name: VidWidget.routeName,
          path: VidWidget.routePath,
          builder: (context, params) => const VidWidget(),
        ),
        FFRoute(
          name: ListViWidget.routeName,
          path: ListViWidget.routePath,
          requireAuth: true,
          builder: (context, params) => ListViWidget(
            cite: params.getParam(
              'cite',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['villages'],
            ),
          ),
        ),
        FFRoute(
          name: CarWidget.routeName,
          path: CarWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const CarWidget(),
        ),
        FFRoute(
          name: List22TaskOverviewResponsiveWidget.routeName,
          path: List22TaskOverviewResponsiveWidget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? const NavBarPage(initialPage: 'List22TaskOverviewResponsive')
              : const List22TaskOverviewResponsiveWidget(),
        ),
        FFRoute(
          name: TfaselOrderWidget.routeName,
          path: TfaselOrderWidget.routePath,
          requireAuth: true,
          asyncParams: {
            'idorder': getDoc(['order'], OrderRecord.fromSnapshot),
          },
          builder: (context, params) => TfaselOrderWidget(
            idorder: params.getParam(
              'idorder',
              ParamType.Document,
            ),
          ),
        ),
        FFRoute(
          name: Details24QuizPageWidget.routeName,
          path: Details24QuizPageWidget.routePath,
          builder: (context, params) => Details24QuizPageWidget(
            usermndob: params.getParam(
              'usermndob',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
            idordeer: params.getParam(
              'idordeer',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['order'],
            ),
            naimMndob: params.getParam(
              'naimMndob',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: Checkout66Widget.routeName,
          path: Checkout66Widget.routePath,
          requireAuth: true,
          builder: (context, params) => const Checkout66Widget(),
        ),
        FFRoute(
          // LEGACY copy — redirect to production checkout.
          name: Checkout66CopyWidget.routeName,
          path: Checkout66CopyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const Checkout66Widget(),
        ),
        FFRoute(
          name: AbutMdenhWidget.routeName,
          path: AbutMdenhWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AbutMdenhWidget(),
        ),
        FFRoute(
          name: AddpayWidget.routeName,
          path: AddpayWidget.routePath,
          builder: (context, params) => const AddpayWidget(),
        ),
        FFRoute(
          // LEGACY copy — redirect to production list.
          name: ListViCopyWidget.routeName,
          path: ListViCopyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => ListViWidget(
            cite: params.getParam(
              'cite',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['villages'],
            ),
          ),
        ),
        FFRoute(
          name: AldolWidget.routeName,
          path: AldolWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AldolWidget(),
        ),
        FFRoute(
          // LEGACY copy — redirect to production list.
          name: ListViCopyCopyWidget.routeName,
          path: ListViCopyCopyWidget.routePath,
          builder: (context, params) => ListViWidget(
            cite: params.getParam(
              'cite',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['villages'],
            ),
          ),
        ),
        FFRoute(
          // LEGACY copy — redirect to custom place / map flow.
          name: ViewMapCopyWidget.routeName,
          path: ViewMapCopyWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const TouryCustomPlaceWidget(),
        ),
        FFRoute(
          // LEGACY demo — redirect to custom place / map flow.
          name: MapdemoWidget.routeName,
          path: MapdemoWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const TouryCustomPlaceWidget(),
        ),
        FFRoute(
          name: TouryCustomPlaceWidget.routeName,
          path: TouryCustomPlaceWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const TouryCustomPlaceWidget(),
        ),
        FFRoute(
          name: ListvillnowWidget.routeName,
          path: ListvillnowWidget.routePath,
          builder: (context, params) => const ListvillnowWidget(),
        ),
        FFRoute(
          // LEGACY copy — redirect to production checkout.
          name: Checkout66Copy2Widget.routeName,
          path: Checkout66Copy2Widget.routePath,
          requireAuth: true,
          builder: (context, params) => const Checkout66Widget(),
        ),
        FFRoute(
          name: AddressaddWidget.routeName,
          path: AddressaddWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AddressaddWidget(),
        ),
        FFRoute(
          name: ScheduletheTripWidget.routeName,
          path: ScheduletheTripWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const ScheduletheTripWidget(),
        ),
        FFRoute(
          name: ListAdressWidget.routeName,
          path: ListAdressWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const ListAdressWidget(),
        ),
        FFRoute(
          name: PanelWidget.routeName,
          path: PanelWidget.routePath,
          builder: (context, params) => const PanelWidget(),
        ),
        FFRoute(
          name: ErrorpayWidget.routeName,
          path: ErrorpayWidget.routePath,
          builder: (context, params) => const ErrorpayWidget(),
        ),
        FFRoute(
          name: SelectadaddressWidget.routeName,
          path: SelectadaddressWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const SelectadaddressWidget(),
        ),
        FFRoute(
          name: MsgNoAdresdWidget.routeName,
          path: MsgNoAdresdWidget.routePath,
          builder: (context, params) => const MsgNoAdresdWidget(),
        ),
        FFRoute(
          name: EdetressaddWidget.routeName,
          path: EdetressaddWidget.routePath,
          requireAuth: true,
          asyncParams: {
            'ed': getDoc(['ADRESSUSER'], AdressuserRecord.fromSnapshot),
          },
          builder: (context, params) => EdetressaddWidget(
            ed: params.getParam(
              'ed',
              ParamType.Document,
            ),
          ),
        ),
        FFRoute(
          name: ListAdressSelectWidget.routeName,
          path: ListAdressSelectWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const ListAdressSelectWidget(),
        ),
        FFRoute(
          name: LogenWidget.routeName,
          path: LogenWidget.routePath,
          builder: (context, params) => const LogenWidget(),
        ),
        FFRoute(
          // LEGACY demo — redirect to booking home tab.
          name: DemoallWidget.routeName,
          path: DemoallWidget.routePath,
          builder: (context, params) =>
              const NavBarPage(initialPage: 'demoD'),
        ),
        FFRoute(
          name: OksendWidget.routeName,
          path: OksendWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const OksendWidget(),
        ),
        FFRoute(
          name: BookingsWidget.routeName,
          path: BookingsWidget.routePath,
          builder: (context, params) => const BookingsWidget(),
        ),
        FFRoute(
          name: SupportWidget.routeName,
          path: SupportWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const SupportWidget(),
        ),
        FFRoute(
          name: NewSupportTicketWidget.routeName,
          path: NewSupportTicketWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const NewSupportTicketWidget(),
        ),
        FFRoute(
          name: ForgotPasswordWidget.routeName,
          path: ForgotPasswordWidget.routePath,
          builder: (context, params) => const ForgotPasswordWidget(),
        ),
        FFRoute(
          name: ListCarWidget.routeName,
          path: ListCarWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const ListCarWidget(),
        ),
        FFRoute(
          name: REGdrevWidget.routeName,
          path: REGdrevWidget.routePath,
          builder: (context, params) => const REGdrevWidget(),
        ),
        FFRoute(
          name: DeletWidget.routeName,
          path: DeletWidget.routePath,
          builder: (context, params) => const DeletWidget(),
        ),
        FFRoute(
          name: EdetAdress2Widget.routeName,
          path: EdetAdress2Widget.routePath,
          requireAuth: true,
          builder: (context, params) => EdetAdress2Widget(
            idad: params.getParam(
              'idad',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['ADRESSUSER'],
            ),
          ),
        ),
        FFRoute(
          // LEGACY junk — redirect home.
          name: CLENTWidget.routeName,
          path: CLENTWidget.routePath,
          builder: (context, params) => const HomePagWidget(),
        ),
        FFRoute(
          // LEGACY junk screen — redirect home.
          name: DddWidget.routeName,
          path: DddWidget.routePath,
          builder: (context, params) => const HomePagWidget(),
        ),
        FFRoute(
          // LEGACY demo — redirect to booking home tab.
          name: DemoooWidget.routeName,
          path: DemoooWidget.routePath,
          builder: (context, params) =>
              const NavBarPage(initialPage: 'demoD'),
        ),
        FFRoute(
          // LEGACY demo — redirect to booking home tab.
          name: DemooooooWidget.routeName,
          path: DemooooooWidget.routePath,
          builder: (context, params) =>
              const NavBarPage(initialPage: 'demoD'),
        ),
        FFRoute(
          // LEGACY demo registration — redirect to account creation.
          name: RegdemoWidget.routeName,
          path: RegdemoWidget.routePath,
          builder: (context, params) => const CreateAccount1ShrekWidget(),
        ),
        FFRoute(
          name: SdsdWidget.routeName,
          path: SdsdWidget.routePath,
          builder: (context, params) => const HomePagWidget(),
        ),
        FFRoute(
          name: RegComWidget.routeName,
          path: RegComWidget.routePath,
          builder: (context, params) => const RegComWidget(),
        ),
        FFRoute(
          // LEGACY junk — redirect home.
          name: AaaaaWidget.routeName,
          path: AaaaaWidget.routePath,
          builder: (context, params) => const HomePagWidget(),
        ),
        FFRoute(
          name: CreateAccount1ShrekWidget.routeName,
          path: CreateAccount1ShrekWidget.routePath,
          builder: (context, params) => const CreateAccount1ShrekWidget(),
        ),
        FFRoute(
          name: DemoDWidget.routeName,
          path: DemoDWidget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? const NavBarPage(initialPage: 'demoD')
              : DemoDWidget(
                  isSpeed: params.getParam(
                    'isSpeed',
                    ParamType.bool,
                  ),
                ),
        ),
        FFRoute(
          // LEGACY junk — redirect to booking home.
          name: KhjWidget.routeName,
          path: KhjWidget.routePath,
          builder: (context, params) =>
              const NavBarPage(initialPage: 'demoD'),
        ),
        FFRoute(
          name: NewPlaceWidget.routeName,
          path: NewPlaceWidget.routePath,
          builder: (context, params) => const NewPlaceWidget(),
        ),
        FFRoute(
          // LEGACY junk — redirect home.
          name: MndobWidget.routeName,
          path: MndobWidget.routePath,
          builder: (context, params) => const HomePagWidget(),
        ),
        FFRoute(
          // LEGACY junk — redirect home.
          name: DddscccWidget.routeName,
          path: DddscccWidget.routePath,
          builder: (context, params) => const HomePagWidget(),
        ),
        FFRoute(
          name: Chat2Widget.routeName,
          path: Chat2Widget.routePath,
          requireAuth: true,
          builder: (context, params) => Chat2Widget(
            idorder: params.getParam(
              'idorder',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['order'],
            ),
            naimMndob: params.getParam(
              'naimMndob',
              ParamType.String,
            ),
            phoneMndob: params.getParam(
              'phoneMndob',
              ParamType.int,
            ),
            imgMndob: params.getParam(
              'imgMndob',
              ParamType.String,
            ),
            idmndob: params.getParam(
              'idmndob',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['user'],
            ),
          ),
        ),
        FFRoute(
          name: HomePlusWidget.routeName,
          path: HomePlusWidget.routePath,
          builder: (context, params) => const HomePlusWidget(),
        ),
        FFRoute(
          name: HomequickWidget.routeName,
          path: HomequickWidget.routePath,
          builder: (context, params) => const HomequickWidget(),
        ),
        FFRoute(
          name: List3Widget.routeName,
          path: List3Widget.routePath,
          builder: (context, params) => const List3Widget(),
        ),
        FFRoute(
          name: AddPaymentCardWidget.routeName,
          path: AddPaymentCardWidget.routePath,
          builder: (context, params) => const AddPaymentCardWidget(),
        ),
        FFRoute(
          name: WebviewWidget.routeName,
          path: WebviewWidget.routePath,
          requireAuth: true,
          builder: (context, params) => WebviewWidget(
            url: params.getParam(
              'url',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: PaymentConfirmWidget.routeName,
          path: PaymentConfirmWidget.routePath,
          requireAuth: true,
          builder: (context, params) => PaymentConfirmWidget(
            fromWebView: params.getParam(
              'fromWebView',
              ParamType.bool,
            ),
          ),
        ),
        FFRoute(
          name: 'payMoyserOK',
          path: '/payMoyserOK',
          requireAuth: true,
          builder: (context, params) => PaymentConfirmWidget(
            fromWebView: params.getParam(
              'fromWebView',
              ParamType.bool,
            ),
          ),
        ),
        FFRoute(
          name: PaymetHostreWidget.routeName,
          path: PaymetHostreWidget.routePath,
          builder: (context, params) => const PaymetHostreWidget(),
        ),
        FFRoute(
          name: DashbordWidget.routeName,
          path: DashbordWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const DashbordWidget(),
        ),
        FFRoute(
          // LEGACY copy — redirect to production list.
          name: ListViCopy2Widget.routeName,
          path: ListViCopy2Widget.routePath,
          requireAuth: true,
          builder: (context, params) => ListViWidget(
            cite: params.getParam(
              'cite',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['villages'],
            ),
          ),
        ),
        FFRoute(
          name: HsabWidget.routeName,
          path: HsabWidget.routePath,
          builder: (context, params) => const HsabWidget(),
        ),
        FFRoute(
          name: MapTrdemoWidget.routeName,
          path: MapTrdemoWidget.routePath,
          requireAuth: true,
          builder: (context, params) => MapTrdemoWidget(
            idd: params.getParam(
              'idd',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['order'],
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
    if (!mounted) return;
    // Prefer popping the real stack; if empty (deep link / goNamed), go home.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }

  /// Back for booking/checkout flows: pop when possible, else land on booking home.
  void safePopOrBookingHome({
    String? fallbackRouteName,
    Map<String, String>? fallbackQueryParameters,
  }) {
    if (!mounted) return;
    if (canPop()) {
      pop();
      return;
    }
    if (fallbackRouteName != null && fallbackRouteName.isNotEmpty) {
      goNamed(
        fallbackRouteName,
        queryParameters: fallbackQueryParameters ?? const <String, String>{},
      );
      return;
    }
    go('/');
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
  void setRedirectLocationIfUnset(String location) =>
      appState.setRedirectLocationIfUnset(location);
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
            return '/homePag';
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
          final wrappedPage = TouryResponsivePage(child: page);
          final child = appStateNotifier.loading
              ? const TourySplashScreen()
              : PushNotificationsHandler(child: wrappedPage);

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

  static TransitionInfo appDefault() =>
      const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
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
}
