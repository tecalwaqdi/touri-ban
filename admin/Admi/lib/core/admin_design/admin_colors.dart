import 'package:flutter/material.dart';

/// Admin UI V2 color tokens — Saudi enterprise / finance identity.
abstract final class AdminColors {
  AdminColors._();

  // Primary teal scale
  static const Color primary900 = Color(0xFF124E4B);
  static const Color primary800 = Color(0xFF17625E);
  static const Color primary700 = Color(0xFF1C736E);
  static const Color primary600 = Color(0xFF23847E);
  static const Color primary500 = Color(0xFF2A9690);
  static const Color primary100 = Color(0xFFDDF1EF);
  static const Color primary50 = Color(0xFFF0F9F8);

  /// Default brand accent (actions, active nav, focus).
  static const Color primary = primary700;

  // Light neutrals
  static const Color appBackground = Color(0xFFF5F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF9FAFB);
  static const Color border = Color(0xFFE5E9ED);
  static const Color borderStrong = Color(0xFFD5DAE0);
  static const Color textPrimary = Color(0xFF17202A);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF98A2B3);
  static const Color disabled = Color(0xFFC7CDD4);

  // Semantic
  static const Color success = Color(0xFF16845B);
  static const Color successBg = Color(0xFFEAF7F1);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningBg = Color(0xFFFFF7E8);
  static const Color danger = Color(0xFFC94A55);
  static const Color dangerBg = Color(0xFFFDEEEF);
  static const Color info = Color(0xFF3478C8);
  static const Color infoBg = Color(0xFFEDF5FD);

  // Dark mode
  static const Color darkBackground = Color(0xFF101617);
  static const Color darkSurface = Color(0xFF182021);
  static const Color darkSurfaceSecondary = Color(0xFF1E2829);
  static const Color darkBorder = Color(0xFF2B3738);
  static const Color darkTextPrimary = Color(0xFFF4F7F7);
  static const Color darkTextSecondary = Color(0xFFAAB8B8);
  static const Color darkPrimary = Color(0xFF2A9690);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : appBackground;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color surfaceSecondaryOf(BuildContext context) =>
      isDark(context) ? darkSurfaceSecondary : surfaceSecondary;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;
}
