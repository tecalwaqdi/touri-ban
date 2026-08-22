import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mndob/core/driver_auth_errors.dart';
import 'package:mndob/core/driver_payment_labels.dart';
import 'package:mndob/core/driver_resolve_locale.dart';
import 'package:mndob/core/toury_system_status_codes.dart';
import 'package:mndob/backend/schema/enums/enums.dart';

void main() {
  group('lang JSON parity', () {
    late Map<String, Map<String, dynamic>> langs;

    setUpAll(() {
      langs = {};
      for (final code in ['en', 'ar', 'ru', 'ky', 'fr', 'ur', 'pt']) {
        final file = File('assets/langs/$code.json');
        expect(file.existsSync(), isTrue, reason: '$code.json missing');
        langs[code] =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      }
    });

    test('all production locales share the same key set', () {
      final enKeys = langs['en']!.keys.toSet();
      for (final code in ['ar', 'ru', 'ky', 'fr', 'ur', 'pt']) {
        expect(langs[code]!.keys.toSet(), enKeys, reason: code);
      }
      expect(enKeys.length, greaterThan(200));
    });

    test('no empty translations', () {
      for (final entry in langs.entries) {
        final empty = entry.value.entries
            .where((e) => (e.value?.toString() ?? '').trim().isEmpty)
            .map((e) => e.key)
            .toList();
        expect(empty, isEmpty, reason: '${entry.key} empty: $empty');
      }
    });

    test('placeholders match across locales', () {
      final ph = RegExp(r'\{[^}]+\}');
      for (final key in langs['en']!.keys) {
        final enPh =
            ph.allMatches(langs['en']![key].toString()).map((m) => m.group(0)!).toSet();
        for (final code in ['ar', 'ru', 'ky', 'fr', 'ur', 'pt']) {
          final other = ph
              .allMatches(langs[code]![key].toString())
              .map((m) => m.group(0)!)
              .toSet();
          expect(other, enPh, reason: '$code::$key');
        }
      }
    });
  });

  group('locale resolve / RTL', () {
    test('supported locales include fr/ur/pt', () {
      expect(
        driverSupportedLocales.map((e) => e.languageCode).toSet(),
        {'ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'},
      );
      expect(driverFallbackLocale.languageCode, 'en');
    });

    test('RTL for Arabic and Urdu', () {
      ui.TextDirection dirFor(String code) =>
          (code == 'ar' || code == 'ur')
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr;
      expect(dirFor('ar'), ui.TextDirection.rtl);
      expect(dirFor('ur'), ui.TextDirection.rtl);
      expect(dirFor('en'), ui.TextDirection.ltr);
      expect(dirFor('fr'), ui.TextDirection.ltr);
      expect(dirFor('pt'), ui.TextDirection.ltr);
      expect(dirFor('ru'), ui.TextDirection.ltr);
      expect(dirFor('ky'), ui.TextDirection.ltr);
    });
  });

  group('status / payment localization keys', () {
    test('displayHalhKeyForCode never returns Arabic', () {
      final ar = RegExp(r'[\u0600-\u06FF]');
      for (final code in [
        TourySystemStatusCodes.pendingDriver,
        TourySystemStatusCodes.driverAssigned,
        TourySystemStatusCodes.driverArrived,
        TourySystemStatusCodes.tripInProgress,
        TourySystemStatusCodes.completed,
        TourySystemStatusCodes.cancelledByCustomer,
      ]) {
        final key = TourySystemStatusCodes.displayHalhKeyForCode(code);
        expect(key, isNotEmpty);
        expect(ar.hasMatch(key), isFalse, reason: key);
      }
    });

    test('payment labels are English keys', () {
      expect(
        DriverPaymentLabels.labelKey(PaymentMethod.Cash),
        'Cash',
      );
      expect(
        DriverPaymentLabels.labelKey(PaymentMethod.OnlinePayment),
        'Online payment',
      );
      expect(DriverPaymentLabels.isCash(PaymentMethod.Cash), isTrue);
      expect(DriverPaymentLabels.isCash(PaymentMethod.OnlinePayment), isFalse);
    });

    test('auth errors map to English keys not raw Firebase messages', () {
      final key = DriverAuthErrors.messageKeyForCode('permission-denied');
      // unmapped codes fall back to generic English key, never raw code
      expect(key.contains('permission-denied'), isFalse);
      expect(
        DriverAuthErrors.messageKeyForCode('wrong-password'),
        isNot(contains('Firebase')),
      );
      expect(
        DriverAuthErrors.messageKeyForCode('network-request-failed'),
        'No internet connection.',
      );
    });
  });
}
