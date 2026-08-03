import 'package:ara_oatan_app/core/toury_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('touryCalculatePriceQuote', () {
    test('keeps the booking accounting invariant in integer halalas', () {
      final quote = touryCalculatePriceQuote(
        hourlyRateSar: 220,
        bookingHours: 6,
        additionalHours: 0,
        vatEnabled: true,
        vatPercent: 15,
      );

      expect(quote.baseFareHalalas, 132000);
      expect(quote.appFeeHalalas, 19800);
      expect(quote.vatHalalas, 19800);
      expect(quote.driverNetHalalas, 92400);
      expect(quote.customerTotalHalalas, 132000);
      expect(quote.isConsistent, isTrue);
    });

    test('caps the additional-hours discount', () {
      final quote = touryCalculatePriceQuote(
        hourlyRateSar: 100,
        bookingHours: 4,
        additionalHours: 2,
        additionalHoursDiscountPercent: 10,
        additionalHoursDiscountCapSar: 15,
      );

      expect(quote.discountHalalas, 1500);
      expect(quote.customerTotalHalalas, 38500);
      expect(quote.isConsistent, isTrue);
    });

    test('sanitizes negative and excessive inputs', () {
      final quote = touryCalculatePriceQuote(
        hourlyRateSar: -10,
        bookingHours: 9999,
        additionalHours: 9999,
      );

      expect(quote.hourlyRateHalalas, 0);
      expect(quote.bookingHours, 720);
      expect(quote.customerTotalHalalas, 0);
      expect(quote.isConsistent, isTrue);
    });
  });
}
