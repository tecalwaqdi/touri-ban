import 'package:flutter/material.dart';

import '/design_system/colors/ds_color_scales.dart';
import '/design_system/radius/ds_radius.dart';

/// هوية توري تاكسي للمندوب — متوافقة 100٪ مع Design System لتطبيق العميل (`#1F6F5F`).
/// يُفضّل في الواجهات الجديدة: `import '/design_system/design_system.dart';`
abstract final class DriverBrand {
  DriverBrand._();

  static const Color teal = DsPrimaryScale.brand;
  static const Color tealDark = DsPrimaryScale.shade700;
  static const Color tealDeeper = DsPrimaryScale.shade900;
  static const Color partnerRed = Color(0xFFEE3136);
  static const Color partnerTeal = DsPrimaryScale.shade400;
  static const Color tealLight = DsPrimaryScale.shade50;
  static const Color tealMuted = DsPrimaryScale.shade200;
  static const Color surface = DsNeutralScale.shade50;
  static const Color card = DsNeutralScale.shade0;
  static const Color border = DsNeutralScale.shade200;
  static const Color textPrimary = DsNeutralScale.shade900;
  static const Color textSecondary = DsNeutralScale.shade600;
  static const Color success = DsSuccessScale.shade500;
  static const Color warning = DsWarningScale.shade500;
  static const Color error = DsErrorScale.shade500;

  static const Color darkSurface = DsNeutralScale.shade950;
  static const Color darkCard = DsNeutralScale.shade800;
  static const Color darkBorder = DsNeutralScale.shade700;
  static const Color darkTextPrimary = DsNeutralScale.shade50;
  static const Color darkTextSecondary = DsNeutralScale.shade400;

  static const double radiusXs = DsRadius.xs;
  static const double radiusSm = DsRadius.sm;
  static const double radiusMd = DsRadius.md;
  static const double radiusLg = DsRadius.lg;
  static const double radiusXl = DsRadius.xl;

  static BorderRadius get borderRadiusSm => DsRadius.small;
  static BorderRadius get borderRadiusMd => DsRadius.medium;
  static BorderRadius get borderRadiusLg => DsRadius.large;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? darkCard : card;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color textPrimaryColor(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static List<BoxShadow> cardShadow({
    bool elevated = false,
    bool dark = false,
  }) =>
      [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: elevated ? 0.32 : 0.20)
              : tealDark.withValues(alpha: elevated ? 0.14 : 0.08),
          blurRadius: elevated ? 20 : 14,
          offset: Offset(0, elevated ? 8 : 4),
        ),
      ];

  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? color,
    bool elevated = false,
  }) {
    final dark = isDark(context);
    return BoxDecoration(
      color: color ?? cardColor(context),
      borderRadius: borderRadiusLg,
      border: Border.all(
        color: dark ? darkBorder : border.withValues(alpha: 0.7),
      ),
      boxShadow: cardShadow(elevated: elevated, dark: dark),
    );
  }

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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

  static LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          teal.withValues(alpha: 0.12),
          surface.withValues(alpha: 0),
        ],
      );
}
