import 'package:ara_oatan_app/core/app_design_system.dart';
import 'package:ara_oatan_app/core/toury_notification_localizer.dart';
import 'package:ara_oatan_app/core/toury_resolve_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const supported = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
    Locale('ru'),
    Locale('ky'),
    Locale('ur'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  group('locale resolution', () {
    test('selects supported device language and falls back to English', () {
      expect(
        touryResolveDeviceLocale(
          supported,
          deviceLocales: const [Locale('ky', 'KG')],
        ),
        const Locale('ky'),
      );
      expect(
        touryResolveDeviceLocale(
          supported,
          deviceLocales: const [Locale('de', 'DE')],
        ),
        touryFallbackLocale,
      );
    });

    test('preserves script locale and storage key', () {
      const locale = Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
      );
      expect(
        touryResolveDeviceLocale(supported, deviceLocales: const [locale]),
        locale,
      );
      expect(touryLocaleStorageKey(locale), 'zh_Hans');
    });

    test('uses RTL only for RTL languages', () {
      expect(Bidi.isRtlLanguage('ar'), isTrue);
      expect(Bidi.isRtlLanguage('ur'), isTrue);
      expect(Bidi.isRtlLanguage('en'), isFalse);
      expect(Bidi.isRtlLanguage('fr'), isFalse);
      expect(Bidi.isRtlLanguage('ru'), isFalse);
      expect(Bidi.isRtlLanguage('ky'), isFalse);
    });

    test('localizes notification templates and replaces arguments', () async {
      final text = await TouryNotificationLocalizer.text(
        'ru',
        'notification_payment_success_body',
        args: const {'bookingId': '42'},
      );
      expect(text, contains('42'));
      expect(text, isNot(contains('{bookingId}')));
      expect(
          text,
          isNot(equals(
            'Payment for booking #42 was confirmed. We are finding a driver for you.',
          )));
    });
  });

  group('application themes', () {
    test('publish readable Material light and dark themes', () {
      final light = AppThemeBuilder.light();
      final dark = AppThemeBuilder.dark();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(
        _contrastRatio(
          light.colorScheme.onSurface,
          light.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(
          dark.colorScheme.onSurface,
          dark.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(dark.inputDecorationTheme.filled, isTrue);
      expect(dark.bottomNavigationBarTheme.backgroundColor, isNotNull);
    });
  });
}
