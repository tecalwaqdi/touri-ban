import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ara_oatan_app/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';
import 'backend/push_notifications/push_notifications_util.dart';
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/core/app_design_system.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_landmark_filter.dart';
import '/core/toury_locale_loader.dart';
import '/core/toury_location_service.dart';
import '/core/toury_resolve_locale.dart';
import '/design_system/design_system.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

late final List<Locale> _supportedAppLocales;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: DsNeutralScale.shade50,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DsSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: DsIcons.xl, color: DsErrorScale.shade500),
                const SizedBox(height: DsSpacing.md),
                Text(
                  'unexpected_error_title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: DsTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DsNeutralScale.shade900,
                  ),
                ),
                const SizedBox(height: DsSpacing.xs),
                Text(
                  'unexpected_error_msg'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: DsTypography.fontFamily,
                    color: DsNeutralScale.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  // الإنجليزية أولاً (الافتراضي) — باقي اللغات بالخلفية.
  try {
    await const TouryCachedAssetLoader()
        .load('assets/langs', touryFallbackLocale);
  } catch (e) {
    debugPrint('TouryCachedAssetLoader: en preload failed: $e');
  }

  await EasyLocalization.ensureInitialized();
  // Ensure Cyrillic + Kyrgyz glyphs (ң ө ү) via Noto Sans fallback family.
  GoogleFonts.config.allowRuntimeFetching = true;
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.notoSans(),
      GoogleFonts.notoSans(fontWeight: FontWeight.w600),
    ]);
  } catch (e) {
    debugPrint('Noto Sans preload skipped: $e');
  }
  _supportedAppLocales = await touryDiscoverSupportedLocales();
  FFLocalizations.configureLanguages(_supportedAppLocales);
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await Future.wait([
    initFirebase(),
    FlutterFlowTheme.initialize(),
    FFLocalizations.initialize(),
  ]);

  final startupLocale = touryResolveStartupLocale(_supportedAppLocales);
  try {
    if (startupLocale != touryFallbackLocale) {
      await const TouryCachedAssetLoader().load('assets/langs', startupLocale);
    }
  } catch (e) {
    debugPrint(
      'TouryCachedAssetLoader: startup locale preload failed: $e',
    );
  }
  unawaited(
    TouryCachedAssetLoader.preloadAll('assets/langs', _supportedAppLocales),
  );

  // Play Integrity لا يعمل في APK المُثبّت يدوياً خارج Play Store.
  const enableFirebaseAppCheck = bool.fromEnvironment(
      'ENABLE_FIREBASE_APP_CHECK',
      defaultValue: kReleaseMode);
  if (enableFirebaseAppCheck && !kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  final appState = FFAppState();
  await appState.initializePersistedState();
  // Rebuild landmark refs from persisted cart (avoids "already added" ghosts).
  tourySyncCartMkanRefs(appState);

  runApp(EasyLocalization(
      supportedLocales: _supportedAppLocales,
      path: 'assets/langs',
      assetLoader: const TouryCachedAssetLoader(),
      fallbackLocale: touryFallbackLocale,
      startLocale: startupLocale,
      saveLocale: false,
      child: ChangeNotifierProvider(
        create: (context) => appState,
        child: const MyApp(),
      )));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
  bool _assetsWarmed = false;

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
  StreamSubscription<BaseAuthUser>? _authUserUpdateSub;
  StreamSubscription<dynamic>? _jwtSub;

  final authUserSub = authenticatedUserStream.listen((_) {});
  final fcmTokenSub = fcmTokenUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();
    _locale = touryResolveStartupLocale(_supportedAppLocales);

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    // تجاوز انتظار auth stream — بدونه تبقى شاشة الشعار للأبد.
    _appStateNotifier.update(
      AraOatanAppFirebaseUser(FirebaseAuth.instance.currentUser),
    );
    _authUserUpdateSub =
        araOatanAppFirebaseUserStream().listen(_appStateNotifier.update);
    _jwtSub = jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (_appStateNotifier.user == null) {
        debugPrint('MyApp: auth stream timeout — continuing logged out');
        _appStateNotifier.update(AraOatanAppFirebaseUser(null));
        _appStateNotifier.stopShowingSplashImage();
      }
    });
  }

  @override
  void dispose() {
    authUserSub.cancel();
    fcmTokenSub.cancel();
    _authUserUpdateSub?.cancel();
    _jwtSub?.cancel();
    super.dispose();
  }

  void setLocale(String language) {
    final locale = createLocale(language);
    unawaited(context.setLocale(locale));
    safeSetState(() => _locale = locale);
    FFLocalizations.storeLocale(language);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    if (!_assetsWarmed) {
      _assetsWarmed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        precacheImage(
          const AssetImage('assets/images/torytaxi_transparent.png'),
          context,
        );
        precacheImage(
          const AssetImage('assets/images/brand/vision_2030.png'),
          context,
        );
        // كاش الموقع والبيانات الثابتة بعد ظهور الشاشة الأولى.
        Future<void>.delayed(const Duration(milliseconds: 900), () async {
          // Refresh persisted country/city labels to match UI locale (fixes
          // Arabic geo names stuck in SharedPreferences under ky/ru/en).
          await TouryLocationService.refreshStoredGeoLabels();
          unawaited(TouryLocationService.warmCache());
          unawaited(TouryLocationService.syncPersistedLocationFromGps());
          TouryFirestoreCache.warmup();
        });
      });
    }
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'app_title'.tr(),
        scrollBehavior: MyAppScrollBehavior(),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final width = mq.size.width;
          final height = mq.size.height;
          var textScale = mq.textScaler.scale(1.0);
          if (width < 360 || height < 640) {
            textScale = textScale.clamp(0.88, 1.05);
          } else if (width >= 900) {
            textScale = textScale.clamp(0.95, 1.12);
          } else {
            textScale = textScale.clamp(0.9, 1.1);
          }
          final appChild = Directionality(
            textDirection: _textDirectionForLocale(_locale ?? context.locale),
            child: child ?? const SizedBox.shrink(),
          );
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: appChild,
          );
        },
        locale: _locale ?? context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...context.localizationDelegates,
          const FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          const FallbackMaterialLocalizationDelegate(),
          const FallbackCupertinoLocalizationDelegate(),
        ],
        theme: DsTheme.light(),
        darkTheme: DsTheme.dark(),
        themeMode: _themeMode,
        routerConfig: _router,
      ),
    );
  }
}

ui.TextDirection _textDirectionForLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
    case 'ur':
      return ui.TextDirection.rtl;
    default:
      return ui.TextDirection.ltr;
  }
}

class NavBarPage extends StatefulWidget {
  const NavBarPage({
    super.key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  });

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'demoD';
  Widget? _currentPage;
  late final List<String> _tabKeys;
  late final Set<int> _visitedTabIndexes;
  final _builtTabs = <int, Widget>{};

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
    _tabKeys = const [
      'demoD',
      'List22TaskOverviewResponsive',
      'Profile05',
    ];
    final initialIndex = _tabKeys.indexOf(_currentPageName);
    _visitedTabIndexes = {initialIndex < 0 ? 0 : initialIndex};
  }

  Widget _tabPage(int index) {
    return _builtTabs.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const DemoDWidget();
        case 1:
          return const List22TaskOverviewResponsiveWidget();
        case 2:
          return const Profile05Widget();
        default:
          return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabKeys.indexOf(_currentPageName);

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Scaffold(
            resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
            backgroundColor: colors.scaffold,
            body: _currentPage ??
                IndexedStack(
                  index: currentIndex,
                  children: List.generate(_tabKeys.length, (index) {
                    if (!_visitedTabIndexes.contains(index)) {
                      return const SizedBox.shrink();
                    }
                    return _tabPage(index);
                  }),
                ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: colors.navigation,
                boxShadow: DsShadows.bottomSheet(
                  dark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: DsSpacing.xxs),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (i) => safeSetState(() {
                    _currentPage = null;
                    _currentPageName = _tabKeys[i];
                    _visitedTabIndexes.add(i);
                  }),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: colors.navigationSelected,
                  unselectedItemColor: colors.textSecondary,
                  selectedLabelStyle: typography.labelSmall.copyWith(
                    color: colors.navigationSelected,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: typography.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: _NavIcon(
                        icon: Icons.add_location_alt_rounded,
                        selected: currentIndex == 0,
                      ),
                      activeIcon: const _NavIcon(
                        icon: Icons.add_location_alt_rounded,
                        selected: true,
                      ),
                      label: 'Initiate'.tr(),
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _NavIcon(
                        icon: Icons.event_note_rounded,
                        selected: currentIndex == 1,
                      ),
                      activeIcon: const _NavIcon(
                        icon: Icons.event_note_rounded,
                        selected: true,
                      ),
                      label: 'Reservations'.tr(),
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: _NavIcon(
                        icon: Icons.person_rounded,
                        selected: currentIndex == 2,
                      ),
                      activeIcon: const _NavIcon(
                        icon: Icons.person_rounded,
                        selected: true,
                      ),
                      label: 'My account'.tr(),
                      tooltip: '',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
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
      curve: DsCurves.standard,
      padding: EdgeInsets.symmetric(
        horizontal: selected ? DsSpacing.sm : 0,
        vertical: selected ? DsSpacing.xxs : 2,
      ),
      decoration: selected
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primaryStrong],
              ),
              borderRadius: DsRadius.pill,
              boxShadow: DsShadows.primaryGlow(
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            )
          : null,
      child: Icon(
        icon,
        size: DsIcons.md,
        color: selected ? colors.onPrimary : colors.iconMuted,
      ),
    );
  }
}
