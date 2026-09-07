import 'package:flutter/material.dart';

import 'admin_colors.dart';

/// Admin UI V2 typography — Cairo (bundled assets).
abstract final class AdminTypography {
  AdminTypography._();

  static const String fontFamily = 'cairo';

  static TextStyle pageTitle(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AdminColors.textPrimaryOf(context),
      );

  static TextStyle sectionTitle(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AdminColors.textPrimaryOf(context),
      );

  static TextStyle cardTitle(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AdminColors.textPrimaryOf(context),
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AdminColors.textPrimaryOf(context),
      );

  static TextStyle label(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AdminColors.textSecondaryOf(context),
      );

  static TextStyle caption(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AdminColors.textMuted,
      );

  static TextStyle table(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AdminColors.textPrimaryOf(context),
      );

  static TextStyle tableHeader(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AdminColors.textSecondaryOf(context),
      );

  static TextStyle button(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AdminColors.textPrimaryOf(context),
      );

  static TextStyle money(BuildContext context) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AdminColors.textPrimaryOf(context),
      );
}
