/// Shared readable text styles for accountant Finance surfaces (F2.1).
///
/// LightModeTheme.primaryText is brand teal — fine for accents, but headings
/// and money values must use dark [secondaryText] on light cards to avoid
/// low-contrast / invisible text.
library;

import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/admin_design/admin_design.dart';
import '/flutter_flow/flutter_flow_theme.dart';

abstract final class AccountantFinanceText {
  AccountantFinanceText._();

  /// Dark readable ink on finance cards (UI V2 textPrimary).
  static Color ink(FlutterFlowTheme theme) {
    final c = theme.primaryText;
    if (c.computeLuminance() <= 0.55) return c;
    return AdminColors.textPrimary;
  }

  static Color muted(FlutterFlowTheme theme) => theme.secondaryText;

  static Color accent(FlutterFlowTheme theme) => AdminUi.brandTeal;

  static TextStyle pageTitle(FlutterFlowTheme theme) =>
      theme.headlineSmall.override(
        fontFamily: theme.headlineSmallFamily,
        color: ink(theme),
        fontSize: 28,
        fontWeight: FontWeight.w700,
        useGoogleFonts: !theme.headlineSmallIsCustom,
      );

  static TextStyle sectionTitle(FlutterFlowTheme theme) =>
      theme.titleSmall.override(
        fontFamily: theme.titleSmallFamily,
        color: ink(theme),
        fontWeight: FontWeight.w600,
        useGoogleFonts: !theme.titleSmallIsCustom,
      );

  static TextStyle body(FlutterFlowTheme theme) => theme.bodyMedium.override(
        fontFamily: theme.bodyMediumFamily,
        color: ink(theme),
        fontWeight: FontWeight.w400,
        useGoogleFonts: !theme.bodyMediumIsCustom,
      );

  static TextStyle label(FlutterFlowTheme theme) => theme.labelMedium.override(
        fontFamily: theme.labelMediumFamily,
        color: muted(theme),
        fontWeight: FontWeight.w500,
        useGoogleFonts: !theme.labelMediumIsCustom,
      );

  static TextStyle money(FlutterFlowTheme theme) => theme.titleMedium.override(
        fontFamily: theme.titleMediumFamily,
        color: ink(theme),
        fontWeight: FontWeight.w700,
        useGoogleFonts: !theme.titleMediumIsCustom,
      );

  static TextStyle tableHeader(FlutterFlowTheme theme) =>
      theme.labelLarge.override(
        fontFamily: theme.labelLargeFamily,
        color: ink(theme),
        fontWeight: FontWeight.w600,
        useGoogleFonts: !theme.labelLargeIsCustom,
      );

  static InputDecoration fieldDecoration(
    BuildContext context, {
    required String labelText,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecoration(
      labelText: labelText,
      isDense: true,
      labelStyle: label(theme),
      floatingLabelStyle: TextStyle(
        color: ink(theme),
        fontWeight: FontWeight.w600,
      ),
      border: const OutlineInputBorder(),
    );
  }
}
