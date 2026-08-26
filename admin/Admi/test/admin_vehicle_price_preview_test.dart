import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/core/admin_vehicle_price_preview.dart';

void main() {
  group('adminVehiclePricePreview', () {
    test('matches customer hourly base fare', () {
      final preview = adminVehiclePricePreview(
        hourlyRateSar: 220,
        bookingHours: 6,
        additionalHours: 0,
      );
      expect(preview.baseFareSar, 1320);
      expect(preview.customerTotalSar, 1320);
      expect(preview.discountSar, 0);
    });

    test('caps extra-hours discount', () {
      final preview = adminVehiclePricePreview(
        hourlyRateSar: 100,
        bookingHours: 4,
        additionalHours: 2,
        additionalHoursDiscountPercent: 10,
        additionalHoursDiscountCapSar: 15,
      );
      expect(preview.discountSar, 15);
      expect(preview.customerTotalSar, 385);
    });
  });
}
