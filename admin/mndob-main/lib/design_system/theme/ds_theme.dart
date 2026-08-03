import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors/ds_color_scales.dart';
import '../colors/ds_colors.dart';
import '../constants/ds_constants.dart';
import '../extensions/ds_theme_extension.dart';
import '../radius/ds_radius.dart';
import '../spacing/ds_spacing.dart';
import '../typography/ds_typography.dart';

/// Builds Material 3 ThemeData for Tory Taxi Design System.
///
/// Not wired into [main.dart] yet — ready for Phase 2 screen migration.
abstract final class DsTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        colors: DsColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        colors: DsColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required DsColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final typography = DsTypography.standard;
    final textTheme = typography.toTextTheme(color: colors.textPrimary);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      error: colors.error,
      onError: colors.onError,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.border,
      outlineVariant: colors.divider,
      surfaceContainerHighest: colors.surfaceElevated,
      primaryContainer: colors.primaryMuted,
      onPrimaryContainer: colors.primaryStrong,
      secondaryContainer: colors.selected,
      onSecondaryContainer: colors.primaryStrong,
      tertiary: DsPrimaryScale.shade400,
      onTertiary: colors.onPrimary,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.error,
      scrim: colors.scrim,
      shadow: colors.shadow,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: DsRadius.medium,
      borderSide: BorderSide(color: colors.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.scaffold,
      canvasColor: colors.background,
      fontFamily: DsTypography.fontFamily,
      fontFamilyFallback: DsTypography.fontFamilyFallback,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        typography,
        DsThemeExtension(colors: colors, typography: typography),
      ],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: typography.titleLarge.copyWith(
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: colors.icon,
          size: DsConstants.iconMd,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md,
          vertical: DsSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: DsRadius.large,
          side: BorderSide(color: colors.border.withValues(alpha: 0.9)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          background: colors.primary,
          foreground: colors.onPrimary,
          typography: typography,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          background: colors.primary,
          foreground: colors.onPrimary,
          typography: typography,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(64, DsConstants.buttonHeightMd),
          padding: DsSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.55)),
          textStyle: typography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(48, DsConstants.buttonHeightSm),
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: DsRadius.small),
          textStyle: typography.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.large),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.icon,
          minimumSize: const Size(
            DsConstants.minTapTarget,
            DsConstants.minTapTarget,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colors.surfaceElevated : colors.surface,
        contentPadding: DsSpacing.inputContentPadding,
        hintStyle: typography.bodyMedium.copyWith(color: colors.hint),
        labelStyle: typography.bodyMedium.copyWith(color: colors.textSecondary),
        errorStyle: typography.bodySmall.copyWith(color: colors.error),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: colors.focus, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: DsRadius.medium,
          borderSide: BorderSide(color: colors.disabled),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.extraLarge),
        titleTextStyle: typography.headlineSmall.copyWith(
          color: colors.textPrimary,
        ),
        contentTextStyle: typography.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: DsRadius.xlRadius),
        ),
        showDragHandle: true,
        dragHandleColor: colors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textPrimary,
        contentTextStyle: typography.bodyMedium.copyWith(
          color: isDark ? colors.background : colors.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.primarySoft,
        selectedColor: colors.primaryMuted,
        disabledColor: colors.disabled,
        labelStyle: typography.labelMedium.copyWith(color: colors.textPrimary),
        secondaryLabelStyle:
            typography.labelMedium.copyWith(color: colors.onPrimary),
        padding: DsSpacing.chipPadding,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.pill),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.navigation,
        indicatorColor: colors.selected,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: DsConstants.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return typography.labelSmall.copyWith(
            color: selected ? colors.navigationSelected : colors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: DsConstants.iconMd,
            color: selected ? colors.navigationSelected : colors.iconMuted,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: DsSpacing.md,
      ),
      iconTheme: IconThemeData(
        color: colors.icon,
        size: DsConstants.iconMd,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        circularTrackColor: colors.primaryMuted,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: DsRadius.small,
        ),
        textStyle: typography.bodySmall.copyWith(
          color: isDark ? colors.background : colors.surface,
        ),
      ),
    );
  }

  static ButtonStyle _buttonStyle({
    required Color background,
    required Color foreground,
    required DsTypography typography,
  }) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: DsColors.light.disabled,
      disabledForegroundColor: DsColors.light.onDisabled,
      minimumSize: const Size(64, DsConstants.buttonHeightMd),
      padding: DsSpacing.buttonPadding,
      shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
      textStyle: typography.labelLarge,
    );
  }
}
