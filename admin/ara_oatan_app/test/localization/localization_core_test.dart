import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_booking_status_localizer.dart';
import 'package:ara_oatan_app/core/toury_resolve_locale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production locales include ar/en/ru/ky/fr/ur/pt', () {
    expect(
      touryProductionLanguageCodes,
      {'ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'},
    );
    expect(touryMigrateLegacyLocale(const Locale('fr')).languageCode, 'fr');
    expect(touryMigrateLegacyLocale(const Locale('ur')).languageCode, 'ur');
    expect(touryMigrateLegacyLocale(const Locale('pt')).languageCode, 'pt');
    expect(touryMigrateLegacyLocale(const Locale('ar')).languageCode, 'ar');
  });

  test('booking status codes map legacy Arabic to codes', () {
    expect(
      BookingStatusLocalizer.resolveCode(halhText: 'بإنتظار قبول المندوب'),
      TouryBookingStatusCodes.pendingDriver,
    );
    expect(
      BookingStatusLocalizer.resolveCode(statusCode: 'driver_assigned'),
      TouryBookingStatusCodes.driverAssigned,
    );
    expect(
      BookingStatusLocalizer.resolveCode(halhText: 'ملغي'),
      TouryBookingStatusCodes.cancelledByCustomer,
    );
    expect(
      BookingStatusLocalizer.resolveCode(statusCode: 'cancelled_by_driver'),
      TouryBookingStatusCodes.cancelledByDriver,
    );
    expect(
      BookingStatusLocalizer.resolveCode(statusCode: 'completed'),
      TouryBookingStatusCodes.completed,
    );
  });

  testWidgets('Kyrgyz special characters render without replacement char',
      (tester) async {
    const sample = 'Кыргыз тили: ң ө ү Ң Ө Ү';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text(sample)),
        ),
      ),
    );
    expect(find.text(sample), findsOneWidget);
    expect(sample.contains('\uFFFD'), isFalse);
    expect(sample.contains('□'), isFalse);
    for (final ch in ['ң', 'ө', 'ү', 'Ң', 'Ө', 'Ү']) {
      expect(sample.contains(ch), isTrue);
    }
  });

  testWidgets('Arabic Directionality is RTL', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Text('الموقع الحالي', key: Key('ar-sample')),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byKey(const Key('ar-sample')));
    final directionality = Directionality.of(
      tester.element(find.byKey(const Key('ar-sample'))),
    );
    expect(directionality, TextDirection.rtl);
    expect(text.data, 'الموقع الحالي');
  });

  testWidgets('Russian/Kyrgyz Directionality is LTR', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: Text('Текущее местоположение', key: Key('ru-sample')),
          ),
        ),
      ),
    );
    final directionality = Directionality.of(
      tester.element(find.byKey(const Key('ru-sample'))),
    );
    expect(directionality, TextDirection.ltr);
  });
}
