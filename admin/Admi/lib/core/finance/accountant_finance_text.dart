/// Shared readable text styles for accountant Finance surfaces (F2.1).
///
/// LightModeTheme.primaryText is brand teal — fine for accents, but headings
/// and money values must use dark [secondaryText] on light cards to avoid
/// low-contrast / invisible text.
library;

import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';

abstract final class AccountantFinanceText {
  AccountantFinanceText._();

  /// Dark readable ink on light finance cards. Never use near-white tokens
  /// (DarkModeTheme.primaryText / info) for accountant headings/values.
  static Color ink(FlutterFlowTheme theme) {
    final c = theme.secondaryText;
    if (c.computeLuminance() <= 0.45) return c;
    // Same as LightModeTheme.secondaryText — Safari white-on-white guard.
    return const Color(0xFF1F1F1F);
  }

  static Color muted(FlutterFlowTheme theme) =>
      theme.secondaryText.withValues(alpha: 0.72);

  static Color accent(FlutterFlowTheme theme) => AdminUi.brandTeal;

  static TextStyle pageTitle(FlutterFlowTheme theme) =>
      theme.headlineSmall.override(
        fontFamily: theme.headlineSmallFamily,
        color: ink(theme),
        fontWeight: FontWeight.w700,
        useGoogleFonts: !theme.headlineSmallIsCustom,
      );

  static TextStyle sectionTitle(FlutterFlowTheme theme) =>
      theme.titleSmall.override(
        fontFamily: theme.titleSmallFamily,
        color: ink(theme),
        fontWeight: FontWeight.w700,
        useGoogleFonts: !theme.titleSmallIsCustom,
      );

  static TextStyle body(FlutterFlowTheme theme) => theme.bodyMedium.override(
        fontFamily: theme.bodyMediumFamily,
        color: ink(theme),
        useGoogleFonts: !theme.bodyMediumIsCustom,
      );

  static TextStyle label(FlutterFlowTheme theme) => theme.labelMedium.override(
        fontFamily: theme.labelMediumFamily,
        color: muted(theme),
        useGoogleFonts: !theme.labelMediumIsCustom,
      );

  static TextStyle money(FlutterFlowTheme theme) => theme.titleMedium.override(
        fontFamily: theme.titleMediumFamily,
        color: ink(theme),
        fontWeight: FontWeight.w800,
        useGoogleFonts: !theme.titleMediumIsCustom,
      );

  static TextStyle tableHeader(FlutterFlowTheme theme) =>
      theme.labelLarge.override(
        fontFamily: theme.labelLargeFamily,
        color: ink(theme),
        fontWeight: FontWeight.w700,
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
