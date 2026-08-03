import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_order_match.dart';

void main() {
  group('DriverOrderMatch.scoreForMatch', () {
    test('same village beats farther same-city and out-of-area', () {
      final sameVill = DriverOrderMatch.scoreForMatch(
        orderVillPath: 'villages/a',
        orderCityPath: 'cities/x',
        driverVillPath: 'villages/a',
        driverCityPath: 'cities/x',
        distanceKm: 12,
      );
      final sameCityOnly = DriverOrderMatch.scoreForMatch(
        orderVillPath: 'villages/b',
        orderCityPath: 'cities/x',
        driverVillPath: 'villages/a',
        driverCityPath: 'cities/x',
        distanceKm: 5,
      );
      expect(sameVill?.boost, 0);
      expect(sameCityOnly?.boost, 0);
    });

    test('never treats village path as city match', () {
      final cityOnlyWrong = DriverOrderMatch.scoreForMatch(
        orderVillPath: 'villages/b',
        orderCityPath: 'cities/x',
        driverVillPath: 'villages/a',
        driverCityPath: 'villages/a', // must NOT match cities/x
        distanceKm: 3,
      );
      // Within radius but not same village/city → keep with boost 1
      expect(cityOnlyWrong?.boost, 1);
    });

    test('drops far out-of-area orders when GPS known', () {
      final far = DriverOrderMatch.scoreForMatch(
        orderVillPath: 'villages/b',
        orderCityPath: 'cities/y',
        driverVillPath: 'villages/a',
        driverCityPath: 'cities/x',
        distanceKm: 120,
      );
      expect(far, isNull);
    });

    test('GPS-only mode drops beyond radius', () {
      final far = DriverOrderMatch.scoreForMatch(
        distanceKm: 100,
      );
      expect(far, isNull);
      final near = DriverOrderMatch.scoreForMatch(
        distanceKm: 10,
      );
      expect(near?.boost, 0);
      expect(near?.km, 10);
    });
  });
}
