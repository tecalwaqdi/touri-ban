import 'package:flutter/material.dart';

import 'ds_color_scales.dart';

/// Semantic color tokens for Tory Taxi Design System.
///
/// Prefer these over raw hex values. Access via [DsColors.of] or
/// [BuildContext] extensions once the theme is applied.
@immutable
class DsColors extends ThemeExtension<DsColors> {
  const DsColors({
    required this.primary,
    required this.primarySoft,
    required this.primaryMuted,
    required this.primaryStrong,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.scaffold,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.hint,
    required this.icon,
    required this.iconMuted,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.disabled,
    required this.onDisabled,
    required this.overlay,
    required this.scrim,
    required this.navigation,
    required this.navigationSelected,
    required this.focus,
    required this.hover,
    required this.pressed,
    required this.selected,
  });

  final Color primary;
  final Color primarySoft;
  final Color primaryMuted;
  final Color primaryStrong;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color scaffold;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color border;
  final Color divider;
  final Color shadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color hint;
  final Color icon;
  final Color iconMuted;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color disabled;
  final Color onDisabled;
  final Color overlay;
  final Color scrim;
  final Color navigation;
  final Color navigationSelected;
  final Color focus;
  final Color hover;
  final Color pressed;
  final Color selected;

  static DsColors of(BuildContext context) {
    final ext = Theme.of(context).extension<DsColors>();
    assert(ext != null, 'DsColors missing from ThemeData.extensions');
    return ext ?? DsColors.light;
  }

  static const DsColors light = DsColors(
    primary: DsPrimaryScale.shade500,
    primarySoft: DsPrimaryScale.shade50,
    primaryMuted: DsPrimaryScale.shade100,
    primaryStrong: DsPrimaryScale.shade700,
    onPrimary: DsNeutralScale.shade0,
    secondary: DsPrimaryScale.shade700,
    onSecondary: DsNeutralScale.shade0,
    background: DsNeutralScale.shade50,
    scaffold: DsNeutralScale.shade50,
    surface: DsNeutralScale.shade0,
    surfaceElevated: DsNeutralScale.shade0,
    card: DsNeutralScale.shade0,
    border: DsNeutralScale.shade200,
    divider: DsNeutralScale.shade200,
    shadow: Color(0x1A154D42),
    textPrimary: DsNeutralScale.shade900,
    textSecondary: DsNeutralScale.shade600,
    hint: DsNeutralScale.shade400,
    icon: DsNeutralScale.shade700,
    iconMuted: DsNeutralScale.shade400,
    success: DsSuccessScale.shade500,
    onSuccess: DsNeutralScale.shade0,
    successContainer: DsSuccessScale.shade50,
    warning: DsWarningScale.shade500,
    onWarning: DsNeutralScale.shade900,
    warningContainer: DsWarningScale.shade50,
    error: DsErrorScale.shade500,
    onError: DsNeutralScale.shade0,
    errorContainer: DsErrorScale.shade50,
    info: DsInfoScale.shade500,
    onInfo: DsNeutralScale.shade0,
    infoContainer: DsInfoScale.shade50,
    disabled: DsNeutralScale.shade200,
    onDisabled: DsNeutralScale.shade400,
    overlay: Color(0x0F1F6F5F),
    scrim: Color(0x66121A18),
    navigation: DsNeutralScale.shade0,
    navigationSelected: DsPrimaryScale.shade500,
    focus: DsPrimaryScale.shade400,
    hover: Color(0x141F6F5F),
    pressed: Color(0x241F6F5F),
    selected: DsPrimaryScale.shade50,
  );

  static const DsColors dark = DsColors(
    primary: Color(0xFF4A9A87),
    primarySoft: Color(0xFF103C33),
    primaryMuted: Color(0xFF154D42),
    primaryStrong: Color(0xFF8CC3B4),
    onPrimary: DsNeutralScale.shade950,
    secondary: Color(0xFF8CC3B4),
    onSecondary: DsNeutralScale.shade950,
    background: DsNeutralScale.shade950,
    scaffold: DsNeutralScale.shade950,
    surface: DsNeutralScale.shade900,
    surfaceElevated: DsNeutralScale.shade800,
    card: DsNeutralScale.shade900,
    border: DsNeutralScale.shade700,
    divider: DsNeutralScale.shade700,
    shadow: Color(0x66000000),
    textPrimary: DsNeutralScale.shade50,
    textSecondary: DsNeutralScale.shade400,
    hint: DsNeutralScale.shade500,
    icon: DsNeutralScale.shade200,
    iconMuted: DsNeutralScale.shade500,
    success: Color(0xFF3DB889),
    onSuccess: DsNeutralScale.shade950,
    successContainer: Color(0xFF0F2E22),
    warning: Color(0xFFE0B84A),
    onWarning: DsNeutralScale.shade950,
    warningContainer: Color(0xFF2E2508),
    error: Color(0xFFE86A72),
    onError: DsNeutralScale.shade950,
    errorContainer: Color(0xFF3A1216),
    info: Color(0xFF5B9AD0),
    onInfo: DsNeutralScale.shade950,
    infoContainer: Color(0xFF122433),
    disabled: DsNeutralScale.shade800,
    onDisabled: DsNeutralScale.shade600,
    overlay: Color(0x1AFFFFFF),
    scrim: Color(0x99000000),
    navigation: DsNeutralScale.shade900,
    navigationSelected: Color(0xFF4A9A87),
    focus: Color(0xFF4A9A87),
    hover: Color(0x14FFFFFF),
    pressed: Color(0x24FFFFFF),
    selected: Color(0xFF154D42),
  );

  @override
  DsColors copyWith({
    Color? primary,
    Color? primarySoft,
    Color? primaryMuted,
    Color? primaryStrong,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? scaffold,
    Color? surface,
    Color? surfaceElevated,
    Color? card,
    Color? border,
    Color? divider,
    Color? shadow,
    Color? textPrimary,
    Color? textSecondary,
    Color? hint,
    Color? icon,
    Color? iconMuted,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? disabled,
    Color? onDisabled,
    Color? overlay,
    Color? scrim,
    Color? navigation,
    Color? navigationSelected,
    Color? focus,
    Color? hover,
    Color? pressed,
    Color? selected,
  }) {
    return DsColors(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      card: card ?? this.card,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      hint: hint ?? this.hint,
      icon: icon ?? this.icon,
      iconMuted: iconMuted ?? this.iconMuted,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      disabled: disabled ?? this.disabled,
      onDisabled: onDisabled ?? this.onDisabled,
      overlay: overlay ?? this.overlay,
      scrim: scrim ?? this.scrim,
      navigation: navigation ?? this.navigation,
      navigationSelected: navigationSelected ?? this.navigationSelected,
      focus: focus ?? this.focus,
      hover: hover ?? this.hover,
      pressed: pressed ?? this.pressed,
      selected: selected ?? this.selected,
    );
  }

  @override
  DsColors lerp(ThemeExtension<DsColors>? other, double t) {
    if (other is! DsColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DsColors(
      primary: l(primary, other.primary),
      primarySoft: l(primarySoft, other.primarySoft),
      primaryMuted: l(primaryMuted, other.primaryMuted),
      primaryStrong: l(primaryStrong, other.primaryStrong),
      onPrimary: l(onPrimary, other.onPrimary),
      secondary: l(secondary, other.secondary),
      onSecondary: l(onSecondary, other.onSecondary),
      background: l(background, other.background),
      scaffold: l(scaffold, other.scaffold),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      card: l(card, other.card),
      border: l(border, other.border),
      divider: l(divider, other.divider),
      shadow: l(shadow, other.shadow),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      hint: l(hint, other.hint),
      icon: l(icon, other.icon),
      iconMuted: l(iconMuted, other.iconMuted),
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      error: l(error, other.error),
      onError: l(onError, other.onError),
      errorContainer: l(errorContainer, other.errorContainer),
      info: l(info, other.info),
      onInfo: l(onInfo, other.onInfo),
      infoContainer: l(infoContainer, other.infoContainer),
      disabled: l(disabled, other.disabled),
      onDisabled: l(onDisabled, other.onDisabled),
      overlay: l(overlay, other.overlay),
      scrim: l(scrim, other.scrim),
      navigation: l(navigation, other.navigation),
      navigationSelected: l(navigationSelected, other.navigationSelected),
      focus: l(focus, other.focus),
      hover: l(hover, other.hover),
      pressed: l(pressed, other.pressed),
      selected: l(selected, other.selected),
    );
  }
}
