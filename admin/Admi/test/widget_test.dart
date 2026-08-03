import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin_arawatan/flutter_flow/internationalization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FFLocalizations.initialize();
  });

  test('FFLocalizations initializes and resolves device locale', () {
    expect(FFLocalizations.getStoredLocale(), isNull);
    expect(FFLocalizations.languages(), isNotEmpty);
    expect(FFLocalizations.resolveInitialLocale().languageCode, isNotEmpty);
    expect(
      FFLocalizations.resolveDeviceLocale(const Locale('fr')).languageCode,
      'en',
    );
    expect(
      FFLocalizations.resolveDeviceLocale(const Locale('ar')).languageCode,
      'ar',
    );
  });
}
