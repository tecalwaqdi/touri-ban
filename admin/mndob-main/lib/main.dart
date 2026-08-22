import 'dart:async';
import 'dart:ui' as ui;

import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/push_notifications/push_notifications_util.dart';
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import '/core/driver_bootstrap.dart';
import '/core/driver_resolve_locale.dart';
import '/core/driver_locale_loader.dart';
import '/design_system/design_system.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';

const _supportedDriverLocales = driverSupportedLocales;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await const DriverCachedAssetLoader()
        .load('assets/langs', driverFallbackLocale);
  } catch (e) {
    debugPrint('DriverCachedAssetLoader: en preload failed: $e');
  }

  await EasyLocalization.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  // Never keep a registration guest session across app launches.
  await DriverBootstrap.clearAnonymousSession();

  await FlutterFlowTheme.initialize();
  await FFLocalizations.initialize();

  final startupLocale = driverResolveStartupLocale();
  try {
    if (startupLocale != driverFallbackLocale) {
      await const DriverCachedAssetLoader()
          .load('assets/langs', startupLocale);
    }
  } catch (e) {
    debugPrint('DriverCachedAssetLoader: startup locale preload failed: $e');
  }
  unawaited(
    DriverCachedAssetLoader.preloadAll('assets/langs', _supportedDriverLocales),
  );

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(EasyLocalization(
    supportedLocales: _supportedDriverLocales,
    path: 'assets/langs',
    assetLoader: const DriverCachedAssetLoader(),
    fallbackLocale: driverFallbackLocale,
    startLocale: startupLocale,
    saveLocale: false,
    child: ChangeNotifierProvider(
      create: (context) => appState,
      child: MyApp(),
    ),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;
  StreamSubscription? _userDocSub;
  StreamSubscription? _jwtSub;

  final authUserSub = authenticatedUserStream.listen((_) {});
  final fcmTokenSub = fcmTokenUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    _locale = driverResolveStartupLocale();
    userStream = mndobFirebaseUserStream();
    // Seed immediately so auth-dependent UI is not blocked if the stream lags.
    _appStateNotifier.update(
      MndobFirebaseUser(FirebaseAuth.instance.currentUser),
    );
    _userDocSub = userStream.listen((user) {
      _appStateNotifier.update(user);
    });
    _jwtSub = jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 800),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    authUserSub.cancel();
    fcmTokenSub.cancel();
    _userDocSub?.cancel();
    _jwtSub?.cancel();
    super.dispose();
  }

  void setLocale(String language) {
    final locale = createLocale(language);
    safeSetState(() => _locale = locale);
    FFLocalizations.storeLocale(language);
    unawaited(context.setLocale(locale));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    final locale = _locale ?? context.locale;
    final isRtl = locale.languageCode.toLowerCase() == 'ar' ||
        locale.languageCode.toLowerCase() == 'ur';
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MNDOB',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        ...context.localizationDelegates,
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      locale: locale,
      supportedLocales: context.supportedLocales,
      localeResolutionCallback: (deviceLocale, supported) =>
          driverLocaleOrDefault(deviceLocale),
      theme: DsTheme.light(),
      darkTheme: DsTheme.dark(),
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return Directionality(
          textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'home';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'home': HomeWidget(),
      'Now': NowWidget(),
      'Accepted': AcceptedWidget(),
      'Completed': CompletedWidget(),
      'cansel': CanselWidget(),
      'Profile07': Profile07Widget(),
    };
    final currentIndex = tabs.keys.toList().indexOf(_currentPageName);

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
            backgroundColor: colors.scaffold,
            body: _currentPage ?? tabs[_currentPageName],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: colors.navigation,
                boxShadow: DsShadows.bottomSheet(dark: isDark),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: DsSpacing.xxs),
                child: SizedBox(
                  height: DsConstants.bottomNavHeight,
                  child: BottomNavigationBar(
                  currentIndex: currentIndex < 0 ? 0 : currentIndex,
                  onTap: (i) => safeSetState(() {
                    _currentPage = null;
                    _currentPageName = tabs.keys.toList()[i];
                  }),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: colors.navigationSelected,
                  unselectedItemColor: colors.textSecondary,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: typography.labelSmall.copyWith(
                    color: colors.navigationSelected,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: typography.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: _DriverNavIcon(
                        icon: Icons.home_outlined,
                        selected: currentIndex == 0,
                      ),
                      activeIcon: const _DriverNavIcon(
                        icon: Icons.home_rounded,
                        selected: true,
                      ),
                      label: FFLocalizations.of(context).getText(
                        '1dctcly1' /* Home */,
                      ),
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _DriverNavIcon(
                        icon: Icons.fiber_new_outlined,
                        selected: currentIndex == 1,
                      ),
                      activeIcon: const _DriverNavIcon(
                        icon: Icons.fiber_new_rounded,
                        selected: true,
                      ),
                      label: FFLocalizations.of(context).getText(
                        'hvigto5g' /* Available */,
                      ),
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _DriverNavIcon(
                        icon: Icons.access_time_outlined,
                        selected: currentIndex == 2,
                      ),
                      activeIcon: const _DriverNavIcon(
                        icon: Icons.access_time_filled,
                        selected: true,
                      ),
                      label: FFLocalizations.of(context).getText(
                        '1kqxsp9k' /* Accepted */,
                      ),
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _DriverNavIcon(
                        icon: Icons.task_alt_outlined,
                        selected: currentIndex == 3,
                      ),
                      activeIcon: const _DriverNavIcon(
                        icon: Icons.task_alt_rounded,
                        selected: true,
                      ),
                      label: FFLocalizations.of(context).getText(
                        'cfe6acde' /* Completed */,
                      ),
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _DriverNavIcon(
                        icon: Icons.cancel_outlined,
                        selected: currentIndex == 4,
                      ),
                      activeIcon: const _DriverNavIcon(
                        icon: Icons.cancel_rounded,
                        selected: true,
                      ),
                      label: FFLocalizations.of(context).getText(
                        '3dyv5lob' /* Cancelled */,
                      ),
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _DriverNavIcon(
                        icon: Icons.account_circle_outlined,
                        selected: currentIndex == 5,
                      ),
                      activeIcon: const _DriverNavIcon(
                        icon: Icons.account_circle,
                        selected: true,
                      ),
                      label: FFLocalizations.of(context).getText(
                        '8w8yyua6' /* My account */,
                      ),
                      tooltip: '',
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

class _DriverNavIcon extends StatelessWidget {
  const _DriverNavIcon({
    required this.icon,
    required this.selected,
  });

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    return AnimatedContainer(
      duration: DsDurations.fast,
      curve: DsCurves.emphasized,
      padding: const EdgeInsets.all(DsSpacing.xxs),
      decoration: BoxDecoration(
        color: selected ? colors.primarySoft : Colors.transparent,
        borderRadius: DsRadius.small,
      ),
      child: Icon(
        icon,
        size: DsIcons.md,
        color: selected ? colors.primary : colors.textSecondary,
      ),
    );
  }
}
