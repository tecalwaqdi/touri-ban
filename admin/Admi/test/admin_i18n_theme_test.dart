import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin_arawatan/flutter_flow/flutter_flow_theme.dart';
import 'package:admin_arawatan/flutter_flow/internationalization.dart';
import 'package:admin_arawatan/l10n/admin_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FFLocalizations.initialize();
    await FlutterFlowTheme.initialize();
  });

  test('theme mode persists light and dark preference', () {
    expect(FlutterFlowTheme.themeMode, ThemeMode.light);

    FlutterFlowTheme.saveThemeMode(ThemeMode.dark);
    expect(FlutterFlowTheme.themeMode, ThemeMode.dark);

    FlutterFlowTheme.saveThemeMode(ThemeMode.light);
    expect(FlutterFlowTheme.themeMode, ThemeMode.light);

    // System is coerced to light storage (admin uses explicit light/dark only).
    FlutterFlowTheme.saveThemeMode(ThemeMode.system);
    expect(FlutterFlowTheme.themeMode, ThemeMode.light);
  });

  test('theme translation keys exist for ar/en', () {
    for (final key in [
      'adm_theme_title',
      'adm_theme_subtitle',
      'adm_theme_light',
      'adm_theme_dark',
    ]) {
      final map = kAdminTranslations[key];
      expect(map, isNotNull, reason: key);
      expect(map!['ar'], isNotEmpty);
      expect(map['en'], isNotEmpty);
    }
  });

  test('login and error keys exist for ar/en/ru/ky', () {
    const keys = [
      'adm_login_profile_failed',
      'adm_login_unauthorized',
      'adm_login_nav_failed',
      'adm_err_generic',
      'adm_err_network',
      'adm_err_permission',
      'adm_ok',
    ];
    for (final key in keys) {
      final map = kAdminTranslations[key];
      expect(map, isNotNull, reason: key);
      for (final lang in ['en', 'ar', 'ru', 'ky']) {
        expect(
          map![lang],
          isNotEmpty,
          reason: '$key missing $lang',
        );
      }
    }
  });

  test('FFLocalizations returns ky or ru fallback', () {
    final ky = FFLocalizations(const Locale('ky'));
    expect(ky.getText('adm_ok'), isNotEmpty);
    expect(ky.getText('adm_err_generic'), isNotEmpty);
  });
}
