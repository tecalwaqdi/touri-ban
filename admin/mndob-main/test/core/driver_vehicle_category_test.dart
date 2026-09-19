import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_vehicle_category.dart';

void main() {
  group('DriverVehicleCategoryMatch', () {
    test('exact type_car path matches', () {
      expect(
        DriverVehicleCategoryMatch.matches(
          driverTypePath: 'type_car/luxury_sa',
          orderTypePath: 'type_car/luxury_sa',
        ),
        isTrue,
      );
    });

    test('same luxury category across different docs matches', () {
      expect(
        DriverVehicleCategoryMatch.matches(
          driverTypePath: 'type_car/luxury_sa',
          orderTypePath: 'type_car/premium_riyadh',
          driverLabel: 'سيارة فارهة',
          orderLabel: 'Luxury car',
        ),
        isTrue,
      );
    });

    test('economy does not match luxury', () {
      expect(
        DriverVehicleCategoryMatch.matches(
          driverTypePath: 'type_car/economy',
          orderTypePath: 'type_car/luxury',
          driverLabel: 'سيارة اقتصادية',
          orderLabel: 'سيارة فارهة',
        ),
        isFalse,
      );
    });

    test('resolves luxury from arabic label', () {
      expect(
        DriverVehicleCategoryMatch.fromLabel('سيارة فارهة'),
        DriverVehicleCategory.luxury,
      );
    });
  });
}
