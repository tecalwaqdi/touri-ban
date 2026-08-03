// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';

SharedPreferences? _prefs;

enum DeviceSize {
  mobile,
  tablet,
  desktop,
}

abstract class FlutterFlowTheme {
  static DeviceSize deviceSize = DeviceSize.mobile;

  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme? _lightCache;
  static FlutterFlowTheme? _darkCache;
  static DeviceSize? _cachedDeviceSize;
  static Typography? _cachedTypography;
  static FlutterFlowTheme? _cachedTypographyTheme;

  static FlutterFlowTheme of(BuildContext context) {
    deviceSize = getDeviceSize(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _darkCache ??= DarkModeTheme();
    }
    return _lightCache ??= LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary;
  late Color secondary;
  late Color tertiary;
  late Color alternate;
  late Color primaryText;
  late Color secondaryText;
  late Color primaryBackground;
  late Color secondaryBackground;
  late Color accent1;
  late Color accent2;
  late Color accent3;
  late Color accent4;
  late Color success;
  late Color warning;
  late Color error;
  late Color info;

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;
  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;
  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;
  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;
  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;
  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;
  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;
  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;
  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;
  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;
  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;
  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;
  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;
  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;
  bool get displayLargeIsCustom => typography.displayLargeIsCustom;
  TextStyle get displayLarge => typography.displayLarge;
  String get displayMediumFamily => typography.displayMediumFamily;
  bool get displayMediumIsCustom => typography.displayMediumIsCustom;
  TextStyle get displayMedium => typography.displayMedium;
  String get displaySmallFamily => typography.displaySmallFamily;
  bool get displaySmallIsCustom => typography.displaySmallIsCustom;
  TextStyle get displaySmall => typography.displaySmall;
  String get headlineLargeFamily => typography.headlineLargeFamily;
  bool get headlineLargeIsCustom => typography.headlineLargeIsCustom;
  TextStyle get headlineLarge => typography.headlineLarge;
  String get headlineMediumFamily => typography.headlineMediumFamily;
  bool get headlineMediumIsCustom => typography.headlineMediumIsCustom;
  TextStyle get headlineMedium => typography.headlineMedium;
  String get headlineSmallFamily => typography.headlineSmallFamily;
  bool get headlineSmallIsCustom => typography.headlineSmallIsCustom;
  TextStyle get headlineSmall => typography.headlineSmall;
  String get titleLargeFamily => typography.titleLargeFamily;
  bool get titleLargeIsCustom => typography.titleLargeIsCustom;
  TextStyle get titleLarge => typography.titleLarge;
  String get titleMediumFamily => typography.titleMediumFamily;
  bool get titleMediumIsCustom => typography.titleMediumIsCustom;
  TextStyle get titleMedium => typography.titleMedium;
  String get titleSmallFamily => typography.titleSmallFamily;
  bool get titleSmallIsCustom => typography.titleSmallIsCustom;
  TextStyle get titleSmall => typography.titleSmall;
  String get labelLargeFamily => typography.labelLargeFamily;
  bool get labelLargeIsCustom => typography.labelLargeIsCustom;
  TextStyle get labelLarge => typography.labelLarge;
  String get labelMediumFamily => typography.labelMediumFamily;
  bool get labelMediumIsCustom => typography.labelMediumIsCustom;
  TextStyle get labelMedium => typography.labelMedium;
  String get labelSmallFamily => typography.labelSmallFamily;
  bool get labelSmallIsCustom => typography.labelSmallIsCustom;
  TextStyle get labelSmall => typography.labelSmall;
  String get bodyLargeFamily => typography.bodyLargeFamily;
  bool get bodyLargeIsCustom => typography.bodyLargeIsCustom;
  TextStyle get bodyLarge => typography.bodyLarge;
  String get bodyMediumFamily => typography.bodyMediumFamily;
  bool get bodyMediumIsCustom => typography.bodyMediumIsCustom;
  TextStyle get bodyMedium => typography.bodyMedium;
  String get bodySmallFamily => typography.bodySmallFamily;
  bool get bodySmallIsCustom => typography.bodySmallIsCustom;
  TextStyle get bodySmall => typography.bodySmall;

  Typography get typography {
    if (_cachedTypography != null &&
        _cachedDeviceSize == deviceSize &&
        identical(_cachedTypographyTheme, this)) {
      return _cachedTypography!;
    }
    _cachedDeviceSize = deviceSize;
    _cachedTypographyTheme = this;
    _cachedTypography = switch (deviceSize) {
      DeviceSize.mobile => MobileTypography(this),
      DeviceSize.tablet => TabletTypography(this),
      DeviceSize.desktop => DesktopTypography(this),
    };
    return _cachedTypography!;
  }
}

DeviceSize getDeviceSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 479) {
    return DeviceSize.mobile;
  } else if (width < 991) {
    return DeviceSize.tablet;
  } else {
    return DeviceSize.desktop;
  }
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFF1F6F5F);
  late Color secondary = const Color(0xFF154D42);
  late Color tertiary = const Color(0xFF0A2B24);
  late Color alternate = const Color(0xFFE2E8E6);
  late Color primaryText = const Color(0xFF121A18);
  late Color secondaryText = const Color(0xFF4A5854);
  late Color primaryBackground = const Color(0xFFF7F9F8);
  late Color secondaryBackground = const Color(0xFFFFFFFF);
  late Color accent1 = const Color(0x4C1F6F5F);
  late Color accent2 = const Color(0x4D4A9A87);
  late Color accent3 = const Color(0x4DD4A017);
  late Color accent4 = const Color(0xCCFFFFFF);
  late Color success = const Color(0xFF1F8A64);
  late Color warning = const Color(0xFFD4A017);
  late Color error = const Color(0xFFD64550);
  late Color info = const Color(0xFFFFFFFF);
}

abstract class Typography {
  String get displayLargeFamily;
  bool get displayLargeIsCustom;
  TextStyle get displayLarge;
  String get displayMediumFamily;
  bool get displayMediumIsCustom;
  TextStyle get displayMedium;
  String get displaySmallFamily;
  bool get displaySmallIsCustom;
  TextStyle get displaySmall;
  String get headlineLargeFamily;
  bool get headlineLargeIsCustom;
  TextStyle get headlineLarge;
  String get headlineMediumFamily;
  bool get headlineMediumIsCustom;
  TextStyle get headlineMedium;
  String get headlineSmallFamily;
  bool get headlineSmallIsCustom;
  TextStyle get headlineSmall;
  String get titleLargeFamily;
  bool get titleLargeIsCustom;
  TextStyle get titleLarge;
  String get titleMediumFamily;
  bool get titleMediumIsCustom;
  TextStyle get titleMedium;
  String get titleSmallFamily;
  bool get titleSmallIsCustom;
  TextStyle get titleSmall;
  String get labelLargeFamily;
  bool get labelLargeIsCustom;
  TextStyle get labelLarge;
  String get labelMediumFamily;
  bool get labelMediumIsCustom;
  TextStyle get labelMedium;
  String get labelSmallFamily;
  bool get labelSmallIsCustom;
  TextStyle get labelSmall;
  String get bodyLargeFamily;
  bool get bodyLargeIsCustom;
  TextStyle get bodyLarge;
  String get bodyMediumFamily;
  bool get bodyMediumIsCustom;
  TextStyle get bodyMedium;
  String get bodySmallFamily;
  bool get bodySmallIsCustom;
  TextStyle get bodySmall;
}

class MobileTypography extends Typography {
  MobileTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'cairo';
  bool get displayLargeIsCustom => true;
  TextStyle get displayLarge => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.normal,
        fontSize: 64.0,
      );
  String get displayMediumFamily => 'cairo';
  bool get displayMediumIsCustom => true;
  TextStyle get displayMedium => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.normal,
        fontSize: 44.0,
      );
  String get displaySmallFamily => 'cairo';
  bool get displaySmallIsCustom => true;
  TextStyle get displaySmall => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.w600,
        fontSize: 36.0,
      );
  String get headlineLargeFamily => 'cairo';
  bool get headlineLargeIsCustom => true;
  TextStyle get headlineLarge => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.w600,
        fontSize: 32.0,
      );
  String get headlineMediumFamily => 'cairo';
  bool get headlineMediumIsCustom => true;
  TextStyle get headlineMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 24.0,
      );
  String get headlineSmallFamily => 'cairo';
  bool get headlineSmallIsCustom => true;
  TextStyle get headlineSmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 24.0,
      );
  String get titleLargeFamily => 'cairo';
  bool get titleLargeIsCustom => true;
  TextStyle get titleLarge => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 22.0,
      );
  String get titleMediumFamily => 'cairo';
  bool get titleMediumIsCustom => true;
  TextStyle get titleMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
      );
  String get titleSmallFamily => 'cairo';
  bool get titleSmallIsCustom => true;
  TextStyle get titleSmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );
  String get labelLargeFamily => 'cairo';
  bool get labelLargeIsCustom => true;
  TextStyle get labelLarge => TextStyle(
        fontFamily: 'cairo',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );
  String get labelMediumFamily => 'cairo';
  bool get labelMediumIsCustom => true;
  TextStyle get labelMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );
  String get labelSmallFamily => 'cairo';
  bool get labelSmallIsCustom => true;
  TextStyle get labelSmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
  String get bodyLargeFamily => 'cairo';
  bool get bodyLargeIsCustom => true;
  TextStyle get bodyLarge => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );
  String get bodyMediumFamily => 'cairo';
  bool get bodyMediumIsCustom => true;
  TextStyle get bodyMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );
  String get bodySmallFamily => 'cairo';
  bool get bodySmallIsCustom => true;
  TextStyle get bodySmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
}

class TabletTypography extends Typography {
  TabletTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'cairo';
  bool get displayLargeIsCustom => true;
  TextStyle get displayLarge => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.normal,
        fontSize: 64.0,
      );
  String get displayMediumFamily => 'cairo';
  bool get displayMediumIsCustom => true;
  TextStyle get displayMedium => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.normal,
        fontSize: 44.0,
      );
  String get displaySmallFamily => 'cairo';
  bool get displaySmallIsCustom => true;
  TextStyle get displaySmall => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.w600,
        fontSize: 36.0,
      );
  String get headlineLargeFamily => 'cairo';
  bool get headlineLargeIsCustom => true;
  TextStyle get headlineLarge => const TextStyle(
        fontFamily: 'cairo',
        color: Color(0xFF154D42),
        fontWeight: FontWeight.w600,
        fontSize: 32.0,
      );
  String get headlineMediumFamily => 'cairo';
  bool get headlineMediumIsCustom => true;
  TextStyle get headlineMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 24.0,
      );
  String get headlineSmallFamily => 'cairo';
  bool get headlineSmallIsCustom => true;
  TextStyle get headlineSmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 22.0,
      );
  String get titleLargeFamily => 'cairo';
  bool get titleLargeIsCustom => true;
  TextStyle get titleLarge => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 22.0,
      );
  String get titleMediumFamily => 'cairo';
  bool get titleMediumIsCustom => true;
  TextStyle get titleMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
      );
  String get titleSmallFamily => 'cairo';
  bool get titleSmallIsCustom => true;
  TextStyle get titleSmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );
  String get labelLargeFamily => 'cairo';
  bool get labelLargeIsCustom => true;
  TextStyle get labelLarge => TextStyle(
        fontFamily: 'cairo',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );
  String get labelMediumFamily => 'cairo';
  bool get labelMediumIsCustom => true;
  TextStyle get labelMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );
  String get labelSmallFamily => 'cairo';
  bool get labelSmallIsCustom => true;
  TextStyle get labelSmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
  String get bodyLargeFamily => 'cairo';
  bool get bodyLargeIsCustom => true;
  TextStyle get bodyLarge => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
        height: 1.5,
      );
  String get bodyMediumFamily => 'cairo';
  bool get bodyMediumIsCustom => true;
  TextStyle get bodyMedium => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
        height: 1.45,
      );
  String get bodySmallFamily => 'cairo';
  bool get bodySmallIsCustom => true;
  TextStyle get bodySmall => TextStyle(
        fontFamily: 'cairo',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
        height: 1.4,
      );
}

class DesktopTypography extends Typography {
  TabletTypography get _t => TabletTypography(theme);

  DesktopTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => _t.displayLargeFamily;
  bool get displayLargeIsCustom => _t.displayLargeIsCustom;
  TextStyle get displayLarge => _t.displayLarge;
  String get displayMediumFamily => _t.displayMediumFamily;
  bool get displayMediumIsCustom => _t.displayMediumIsCustom;
  TextStyle get displayMedium => _t.displayMedium;
  String get displaySmallFamily => _t.displaySmallFamily;
  bool get displaySmallIsCustom => _t.displaySmallIsCustom;
  TextStyle get displaySmall => _t.displaySmall;
  String get headlineLargeFamily => _t.headlineLargeFamily;
  bool get headlineLargeIsCustom => _t.headlineLargeIsCustom;
  TextStyle get headlineLarge => _t.headlineLarge;
  String get headlineMediumFamily => _t.headlineMediumFamily;
  bool get headlineMediumIsCustom => _t.headlineMediumIsCustom;
  TextStyle get headlineMedium => _t.headlineMedium;
  String get headlineSmallFamily => _t.headlineSmallFamily;
  bool get headlineSmallIsCustom => _t.headlineSmallIsCustom;
  TextStyle get headlineSmall => _t.headlineSmall;
  String get titleLargeFamily => _t.titleLargeFamily;
  bool get titleLargeIsCustom => _t.titleLargeIsCustom;
  TextStyle get titleLarge => _t.titleLarge;
  String get titleMediumFamily => _t.titleMediumFamily;
  bool get titleMediumIsCustom => _t.titleMediumIsCustom;
  TextStyle get titleMedium => _t.titleMedium;
  String get titleSmallFamily => _t.titleSmallFamily;
  bool get titleSmallIsCustom => _t.titleSmallIsCustom;
  TextStyle get titleSmall => _t.titleSmall;
  String get labelLargeFamily => _t.labelLargeFamily;
  bool get labelLargeIsCustom => _t.labelLargeIsCustom;
  TextStyle get labelLarge => _t.labelLarge;
  String get labelMediumFamily => _t.labelMediumFamily;
  bool get labelMediumIsCustom => _t.labelMediumIsCustom;
  TextStyle get labelMedium => _t.labelMedium;
  String get labelSmallFamily => _t.labelSmallFamily;
  bool get labelSmallIsCustom => _t.labelSmallIsCustom;
  TextStyle get labelSmall => _t.labelSmall;
  String get bodyLargeFamily => _t.bodyLargeFamily;
  bool get bodyLargeIsCustom => _t.bodyLargeIsCustom;
  TextStyle get bodyLarge => _t.bodyLarge;
  String get bodyMediumFamily => _t.bodyMediumFamily;
  bool get bodyMediumIsCustom => _t.bodyMediumIsCustom;
  TextStyle get bodyMedium => _t.bodyMedium;
  String get bodySmallFamily => _t.bodySmallFamily;
  bool get bodySmallIsCustom => _t.bodySmallIsCustom;
  TextStyle get bodySmall => _t.bodySmall;
}

class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFF4A9A87);
  late Color secondary = const Color(0xFF1F6F5F);
  late Color tertiary = const Color(0xFF8CC3B4);
  late Color alternate = const Color(0xFF33403D);
  late Color primaryText = const Color(0xFFF7F9F8);
  late Color secondaryText = const Color(0xFF9AA8A4);
  late Color primaryBackground = const Color(0xFF121A18);
  late Color secondaryBackground = const Color(0xFF1F2A27);
  late Color accent1 = const Color(0x4C1F6F5F);
  late Color accent2 = const Color(0x4D4A9A87);
  late Color accent3 = const Color(0x4DD4A017);
  late Color accent4 = const Color(0xB21F2A27);
  late Color success = const Color(0xFF1F8A64);
  late Color warning = const Color(0xFFD4A017);
  late Color error = const Color(0xFFD64550);
  late Color info = const Color(0xFFFFFFFF);
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    TextStyle? font,
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = false,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
    String? package,
  }) {
    if (useGoogleFonts && fontFamily != null) {
      font = GoogleFonts.getFont(fontFamily,
          fontWeight: fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? this.fontStyle);
    }

    return font != null
        ? font.copyWith(
            color: color ?? this.color,
            fontSize: fontSize ?? this.fontSize,
            letterSpacing: letterSpacing ?? this.letterSpacing,
            fontWeight: fontWeight ?? this.fontWeight,
            fontStyle: fontStyle ?? this.fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          )
        : copyWith(
            fontFamily: fontFamily,
            package: package,
            color: color,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          );
  }
}
