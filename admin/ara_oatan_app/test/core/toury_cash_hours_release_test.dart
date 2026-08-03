import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_checkout_state.dart';
import 'package:ara_oatan_app/core/toury_duration_model.dart';
import 'package:ara_oatan_app/core/toury_payment_flags.dart';
import 'package:ara_oatan_app/core/toury_payment_labels.dart';

void main() {
  group('TouryDurationModel', () {
    test('total = base + extra', () {
      expect(
        TouryDurationModel.totalBookingHours(saatcar: 3, addhors: 0),
        3,
      );
      expect(
        TouryDurationModel.totalBookingHours(saatcar: 3, addhors: 1),
        4,
      );
    });

    test('extra cannot go below zero via clamp', () {
      expect(
        TouryDurationModel.extraBookingHours(-2),
        0,
      );
    });

    test('drive shorter than booking is normal for tours', () {
      expect(
        TouryDurationModel.isDriveShorterThanBookingNormal(
          bookingHours: 3,
          driveMinutes: 20,
        ),
        isTrue,
      );
    });

    test('format minutes', () {
      expect(TouryDurationModel.formatMinutes(20, localeTag: 'en'), '20 min');
      expect(TouryDurationModel.formatMinutes(180, localeTag: 'en'), '3 h');
      expect(
        TouryDurationModel.formatMinutes(90, localeTag: 'en'),
        '1 h 30 min',
      );
    });
  });

  group('hours vs route gate', () {
    test('3h booking with 20min drive is NOT missing hours', () {
      final missing = touryMissingBookingHours(
        bookingHours: 3,
        osrmTimeMinutes: 20,
        landmarkCount: 2,
      );
      expect(missing, isNull);
    });

    test('booking below landmark minimum is missing hours', () {
      final missing = touryMissingBookingHours(
        bookingHours: 1,
        landmarkCount: 6,
        driverGuide: false,
      );
      expect(missing, isNotNull);
      expect(missing! >= 1, isTrue);
    });

    test('touryBookingHoursSufficient ignores short drive estimate', () {
      expect(
        touryBookingHoursSufficient(
          bookingHours: 3,
          suggestedHours: 0.33,
        ),
        isTrue,
      );
    });
  });

  group('cash-only flags', () {
    test('online payment disabled by default', () {
      expect(TouryPaymentFlags.enableOnlinePayment, isFalse);
      expect(TouryPaymentFlags.cashOnlyMode, isTrue);
    });

    test('cash visible even when remote OKcash false', () {
      expect(
        TouryPaymentFlags.cashOptionVisible(remoteOkCash: false),
        isTrue,
      );
    });

    test('online option hidden', () {
      expect(TouryPaymentFlags.onlineOptionVisible(), isFalse);
    });

    test('cash book-now accepts unset when cash-only', () {
      expect(touryIsCashBookNowPayment(TouryPaymentKeys.unset), isTrue);
      expect(touryRequiresPaymentMethodSelection(TouryPaymentKeys.unset), isFalse);
    });

    test('client cash fallback enabled by default', () {
      expect(TouryPaymentFlags.allowClientCashFallback, isTrue);
    });

    test('online payment value detection', () {
      expect(touryIsOnlinePaymentValue(TouryPaymentKeys.online), isTrue);
      expect(touryIsOnlinePaymentValue(TouryPaymentKeys.cash), isFalse);
    });
  });
}
