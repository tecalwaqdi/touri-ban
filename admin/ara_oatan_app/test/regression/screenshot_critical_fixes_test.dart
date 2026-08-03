import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_pricing.dart';
import 'package:ara_oatan_app/core/toury_error_localizer.dart';
import 'package:ara_oatan_app/core/toury_landmark_filter.dart';
import 'package:ara_oatan_app/core/toury_i18n_text.dart';
import 'package:ara_oatan_app/core/toury_booking_service.dart';

void main() {
  group('extra hours pricing', () {
    test('increasing extra hours increases customer total', () {
      final base = touryCalculatePriceQuote(
        hourlyRateSar: 200,
        bookingHours: 4,
        additionalHours: 0,
      );
      final plusOne = touryCalculatePriceQuote(
        hourlyRateSar: 200,
        bookingHours: 5,
        additionalHours: 1,
      );
      final plusTwo = touryCalculatePriceQuote(
        hourlyRateSar: 200,
        bookingHours: 6,
        additionalHours: 2,
      );
      expect(plusOne.customerTotalHalalas, greaterThan(base.customerTotalHalalas));
      expect(plusTwo.customerTotalHalalas, greaterThan(plusOne.customerTotalHalalas));
      expect(base.isConsistent, isTrue);
      expect(plusOne.isConsistent, isTrue);
    });

    test('decreasing extra hours restores previous total', () {
      final withTwo = touryCalculatePriceQuote(
        hourlyRateSar: 200,
        bookingHours: 6,
        additionalHours: 2,
      );
      final withOne = touryCalculatePriceQuote(
        hourlyRateSar: 200,
        bookingHours: 5,
        additionalHours: 1,
      );
      expect(withOne.customerTotalHalalas, lessThan(withTwo.customerTotalHalalas));
    });

    test('extra hours cannot drive negative total', () {
      final q = touryCalculatePriceQuote(
        hourlyRateSar: 100,
        bookingHours: 1,
        additionalHours: 0,
        additionalHoursDiscountPercent: 100,
        additionalHoursDiscountCapSar: 9999,
      );
      expect(q.customerTotalHalalas, greaterThanOrEqualTo(0));
    });
  });

  group('payment error mapping', () {
    test('NOT_FOUND is not shown raw', () {
      final msg = ErrorLocalizer.fromCode('not-found');
      expect(msg.toLowerCase().contains('not-found'), isFalse);
      expect(msg.toLowerCase().contains('not_found'), isFalse);
      // Without EasyLocalization runtime, .tr() returns the key itself.
      expect(msg.contains('error_payment_function_unavailable'), isTrue);
    });
  });

  group('landmark i18n fallback', () {
    test('ky prefers en over arabic', () {
      final text = touryLocalizedText(
        {'ar': 'مكة المكرمة', 'en': 'Makkah'},
        'مكة المكرمة',
        localeKey: 'ky',
      );
      expect(text, 'Makkah');
      expect(RegExp(r'[\u0600-\u06FF]').hasMatch(text), isFalse);
    });
  });

  group('cash booking ids', () {
    test('idempotency key maps to stable sha256 doc id', () {
      // Mirrors Cloud Function sessionIdFor(uid, `cash:${key}`).
      final a = touryCashOrderDocId('uid1', 'cash_abc');
      final b = touryCashOrderDocId('uid1', 'cash_abc');
      final c = touryCashOrderDocId('uid1', 'cash_xyz');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.length, 64);
    });
  });
}
