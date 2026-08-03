import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/design_system/colors/ds_color_scales.dart';
import '/design_system/colors/ds_colors.dart';
import '/design_system/radius/ds_radius.dart';
import '/design_system/typography/ds_typography.dart';

/// Toury Taxi visual identity tokens — aligned with Design System (`#1F6F5F`).
/// Prefer `/design_system/design_system.dart` in new UI; keep this for legacy callers.
abstract final class TouryBrand {
  // Core palette — mirrors DsPrimaryScale / DsNeutralScale
  static const Color teal = DsPrimaryScale.brand;
  static const Color tealDark = DsPrimaryScale.shade700;
  /// لون الشريك الأحمر من شعار توري تاكسي
  static const Color partnerRed = Color(0xFFEE3136);
  static const Color partnerTeal = DsPrimaryScale.shade400;
  static const Color tealDeeper = DsPrimaryScale.shade900;
  static const Color tealLight = DsPrimaryScale.shade50;
  static const Color tealMuted = DsPrimaryScale.shade200;

  static const Color surface = DsNeutralScale.shade50;
  static const Color surfaceCard = DsNeutralScale.shade0;
  static const Color border = DsNeutralScale.shade200;
  static const Color textPrimary = DsNeutralScale.shade900;
  static const Color textSecondary = DsNeutralScale.shade600;

  static const Color error = DsErrorScale.shade500;
  static const Color warning = DsWarningScale.shade500;
  static const Color success = DsSuccessScale.shade500;

  // Radii — mirrors DsRadius
  static const double radiusXs = DsRadius.xs;
  static const double radiusSm = DsRadius.sm;
  static const double radiusMd = DsRadius.md;
  static const double radiusLg = DsRadius.lg;
  static const double radiusXl = DsRadius.xl;

  static BorderRadius get borderRadiusMd =>
      BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg =>
      BorderRadius.circular(radiusLg);

  // Elevation / shadows
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceFor(BuildContext context) =>
      isDark(context) ? DsNeutralScale.shade900 : surface;

  static Color cardFor(BuildContext context) =>
      isDark(context) ? DsNeutralScale.shade800 : surfaceCard;

  static Color borderFor(BuildContext context) =>
      isDark(context) ? DsNeutralScale.shade700 : border;

  static Color textPrimaryFor(BuildContext context) =>
      isDark(context) ? DsNeutralScale.shade50 : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      isDark(context) ? DsNeutralScale.shade400 : textSecondary;

  static List<BoxShadow> cardShadow({
    bool elevated = false,
    bool dark = false,
  }) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: elevated ? 0.32 : 0.20)
              : tealDark.withValues(alpha: elevated ? 0.14 : 0.08),
          blurRadius: elevated ? 20 : 14,
          offset: Offset(0, elevated ? 8 : 4),
        ),
      ];

  static BoxDecoration cardDecoration({
    BuildContext? context,
    Color? color,
    bool elevated = false,
    Border? border,
  }) {
    final dark = context != null && isDark(context);
    return BoxDecoration(
        color: color ?? (dark ? DsNeutralScale.shade800 : surfaceCard),
        borderRadius: borderRadiusLg,
        border: border ??
            Border.all(
              color: dark
                  ? DsNeutralScale.shade700
                  : TouryBrand.border.withValues(alpha: 0.6),
            ),
        boxShadow: cardShadow(elevated: elevated, dark: dark),
      );
  }

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [teal, tealDark],
      );

  static LinearGradient get verticalGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [teal, tealDark],
      );

  static LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          teal.withValues(alpha: 0.18),
          tealDark.withValues(alpha: 0.10),
        ],
      );

  static BorderRadius get borderRadiusSm =>
      BorderRadius.circular(radiusSm);

  static LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          teal.withValues(alpha: 0.12),
          surface.withValues(alpha: 0),
        ],
      );
}

/// Builds Material 3–aware themes that propagate across all FlutterFlow screens.
abstract final class AppThemeBuilder {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: TouryBrand.teal,
      onPrimary: Colors.white,
      secondary: TouryBrand.tealDark,
      onSecondary: Colors.white,
      tertiary: TouryBrand.tealDeeper,
      surface: TouryBrand.surface,
      onSurface: TouryBrand.textPrimary,
      error: TouryBrand.error,
      outline: TouryBrand.border,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBg: TouryBrand.surface,
      cardBg: TouryBrand.surfaceCard,
      isDark: false,
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF4A9A87),
      onPrimary: Color(0xFF0D2B29),
      secondary: TouryBrand.teal,
      onSecondary: Color(0xFF0D2B29),
      tertiary: Color(0xFF1A786E),
      surface: Color(0xFF151B1F),
      onSurface: Color(0xFFF2FBFA),
      error: TouryBrand.error,
      outline: Color(0xFF4A575C),
    );

    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBg: const Color(0xFF151B1F),
      cardBg: const Color(0xFF1E262B),
      isDark: true,
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardBg,
    required bool isDark,
  }) {
    final inputFill = isDark
        ? const Color(0xFF2A3439)
        : Colors.white;
    final inputBorder = isDark
        ? const Color(0xFF4A575C)
        : TouryBrand.border.withValues(alpha: 0.9);
    final hintColor = isDark
        ? const Color(0xFF9AADAB)
        : TouryBrand.textSecondary.withValues(alpha: 0.7);
    final labelColor = isDark
        ? const Color(0xFFC5D4D2)
        : TouryBrand.textSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: 'cairo',
      // Cairo covers Arabic + Latin; Noto Sans covers Cyrillic + Kyrgyz ң/ө/ү.
      fontFamilyFallback: const [
        'Noto Sans',
        'Roboto',
        'Arial',
      ],
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E262B) : Colors.white,
        foregroundColor: isDark ? const Color(0xFFF2FBFA) : TouryBrand.tealDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE8FAF8) : TouryBrand.tealDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: TouryBrand.borderRadiusLg,
          side: BorderSide(
            color: isDark
                ? const Color(0xFF3A4549)
                : TouryBrand.border.withValues(alpha: 0.7),
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: TouryBrand.tealDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: TouryBrand.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontFamily: 'cairo',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: TouryBrand.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: TouryBrand.borderRadiusMd,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? const Color(0xFF4A9A87) : TouryBrand.tealDark,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF4A9A87).withValues(alpha: 0.55)
                : TouryBrand.teal.withValues(alpha: 0.6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: TouryBrand.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontFamily: 'cairo',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? const Color(0xFF4A9A87) : TouryBrand.tealDark,
          textStyle: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: TouryBrand.borderRadiusMd,
          borderSide: BorderSide(color: TouryBrand.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TouryBrand.borderRadiusMd,
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TouryBrand.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4A9A87) : TouryBrand.teal,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: TouryBrand.borderRadiusMd,
          borderSide: const BorderSide(color: TouryBrand.error),
        ),
        labelStyle: TextStyle(
          fontFamily: 'cairo',
          color: labelColor,
        ),
        hintStyle: TextStyle(
          fontFamily: 'cairo',
          color: hintColor,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: 'cairo',
          color: isDark ? const Color(0xFF4A9A87) : TouryBrand.tealDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E262B) : Colors.white,
        selectedItemColor:
            isDark ? const Color(0xFF4A9A87) : TouryBrand.tealDark,
        unselectedItemColor:
            isDark ? const Color(0xFF9AADAB) : TouryBrand.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'cairo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'cairo',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? const Color(0xFF3A4549)
            : TouryBrand.border.withValues(alpha: 0.8),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: TouryBrand.borderRadiusSm,
        ),
        backgroundColor: isDark ? const Color(0xFF2A3338) : TouryBrand.tealDark,
        contentTextStyle: const TextStyle(
          fontFamily: 'cairo',
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: TouryBrand.borderRadiusLg,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'cairo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFE8FAF8) : TouryBrand.tealDark,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TouryBrand.radiusXl),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? const Color(0xFF4A9A87) : TouryBrand.tealDark,
        unselectedLabelColor:
            isDark ? const Color(0xFF9AADAB) : TouryBrand.textSecondary,
        indicator: BoxDecoration(
          gradient: TouryBrand.primaryGradient,
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? const Color(0xFF2A3338) : TouryBrand.tealLight,
        selectedColor: TouryBrand.teal.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          fontFamily: 'cairo',
          color: isDark ? const Color(0xFFE8FAF8) : TouryBrand.tealDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: TouryBrand.borderRadiusSm,
        ),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: TouryBrand.tealMuted.withValues(alpha: 0.4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? const Color(0xFF95A1AC) : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TouryBrand.teal;
          }
          return isDark ? const Color(0xFF3A4549) : TouryBrand.border;
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: TouryBrand.borderRadiusSm,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'cairo',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE8FAF8) : TouryBrand.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'cairo',
          fontSize: 13,
          color: isDark ? const Color(0xFF95A1AC) : TouryBrand.textSecondary,
        ),
      ),
    );
  }

  /// Wraps page content with consistent horizontal padding when needed.
  static Widget pagePadding({required Widget child, double horizontal = 16}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: child,
    );
  }

  /// Branded section header used across lists and profile sections.
  static Widget sectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
    Widget? trailing,
  }) {
    final colors = Theme.of(context).extension<DsColors>();
    final typography = DsTypography.of(context);
    final titleColor = colors?.textPrimary ?? TouryBrand.textPrimary;
    final subtitleColor = colors?.textSecondary ?? TouryBrand.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: TouryBrand.primaryGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: typography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: typography.labelMedium.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
