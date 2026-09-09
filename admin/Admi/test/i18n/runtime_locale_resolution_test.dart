import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/flutter_flow/internationalization.dart';
import 'package:admin_arawatan/l10n/ui_catalog.dart';

Widget _app(Locale locale, Widget child) {
  return MaterialApp(
    locale: locale,
    supportedLocales: FFLocalizations.languages().map(Locale.new),
    localizationsDelegates: const [
      FFLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolveUiTr returns distinct locale values for catalog keys', () {
    const ar = 'السائق';
    final en = resolveUiTr(ar, languageCode: 'en');
    final ru = resolveUiTr(ar, languageCode: 'ru');
    final ky = resolveUiTr(ar, languageCode: 'ky');
    final fr = resolveUiTr(ar, languageCode: 'fr');
    final ur = resolveUiTr(ar, languageCode: 'ur');
    final pt = resolveUiTr(ar, languageCode: 'pt');
    final arOut = resolveUiTr(ar, languageCode: 'ar');

    expect(arOut, contains(RegExp(r'[\u0600-\u06FF]')));
    expect(en, isNot(contains(RegExp(r'[\u0600-\u06FF]'))));
    expect(en.toLowerCase(), contains('driver'));
    expect(ky, isNot(equals(ru)), reason: 'KY must not equal RU fallback');
    expect(fr, isNot(equals(en)), reason: 'FR must not equal EN fallback');
    expect(pt, isNot(equals(en)), reason: 'PT must not equal EN fallback');
    expect(ur, isNot(equals(arOut)), reason: 'UR must not copy Arabic');
    expect(fr.toLowerCase(), contains('chauffeur'));
    expect(ru, contains('одител')); // Водитель
  });

  testWidgets('FFLocalizations.getText login keys resolve ky/fr/pt',
      (tester) async {
    // Representative FlutterFlow login keys that previously lacked ky/fr/pt.
    const keys = <String>[
      'y9quj14n', // Select the app language
      'xzqrxbqw', // Login
      '8gngx8fm', // Email Address
    ];

    for (final locale in ['ky', 'fr', 'pt']) {
      late FFLocalizations ff;
      await tester.pumpWidget(
        _app(
          Locale(locale),
          Builder(builder: (context) {
            ff = FFLocalizations.of(context);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in keys) {
        final text = ff.getText(key);
        expect(text, isNotEmpty, reason: '$locale:$key empty');
        if (locale == 'ky') {
          // Should not silently equal English when translation exists.
          final en = FFLocalizations(const Locale('en')).getText(key);
          expect(text, isNot(equals(en)), reason: 'ky fell back to en for $key');
        }
        if (locale == 'fr' || locale == 'pt') {
          final en = FFLocalizations(const Locale('en')).getText(key);
          expect(text, isNot(equals(en)), reason: '$locale fell back to en for $key');
        }
      }
    }
  });

  testWidgets('uiTr works without FFLocalizations (test harness)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final text = uiTr(context, 'السائق');
            return Text(text);
          },
        ),
      ),
    );
    expect(find.textContaining('Driver'), findsOneWidget);
  });
}
