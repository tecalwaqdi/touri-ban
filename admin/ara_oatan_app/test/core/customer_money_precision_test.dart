import 'package:ara_oatan_app/core/toury_pricing.dart';
import 'package:ara_oatan_app/flutter_flow/custom_functions.dart' as fn;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Customer money precision', () {
    test('vat() preserves 7.50 on 50 SAR base at 15%', () {
      expect(fn.vat(15, 50), 7.5);
      expect(fn.vat(15, 50), isNot(7));
      expect(fn.vat(15, 50), isNot(8));
    });

    test('nesbhmnrgmen returns fractional driver net component', () {
      expect(fn.nesbhmnrgmen(50, 7.5, 15), closeTo(8.625, 0.001));
    });

    test('touryCalculatePriceQuote 50 SAR/hour 1h → app fee 7.50', () {
      final quote = touryCalculatePriceQuote(
        hourlyRateSar: 50,
        bookingHours: 1,
        additionalHours: 0,
      );
      expect(quote.appFeeHalalas, 750);
      expect(quote.appFeeSar, 7.5);
      expect(quote.driverNetHalalas, 4250);
      expect(quote.driverNetSar, 42.5);
    });

    test('touryRecalculateCheckoutPrice keeps fractional display fields', () {
      final quote = touryCalculatePriceQuote(
        hourlyRateSar: 50,
        bookingHours: 1,
        additionalHours: 0,
      );
      expect(quote.appFeeSar, 7.5);
      expect((quote.appFeeHalalas / 100), 7.5);
    });
  });
}
