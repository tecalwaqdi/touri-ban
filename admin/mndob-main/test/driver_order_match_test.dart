import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_order_match.dart';

void main() {
  group('DriverOrderMatch.scoreForMatch', () {
    test('same village near pickup is kept', () {
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

    test('same city but far from pickup is dropped', () {
      final sameCityFar = DriverOrderMatch.scoreForMatch(
        orderCityPath: 'cities/jeddah',
        driverCityPath: 'cities/jeddah',
        distanceKm: 55,
      );
      expect(sameCityFar, isNull);
    });

    test('different city is dropped even when nearby', () {
      final cityOnlyWrong = DriverOrderMatch.scoreForMatch(
        orderVillPath: 'villages/b',
        orderCityPath: 'cities/x',
        driverVillPath: 'villages/a',
        driverCityPath: 'villages/a', // must NOT match cities/x
        distanceKm: 3,
      );
      expect(cityOnlyWrong, isNull);
    });

    test('drops far out-of-area orders when GPS known', () {
      final far = DriverOrderMatch.scoreForMatch(
        orderVillPath: 'villages/b',
        orderCityPath: 'cities/y',
        driverVillPath: 'villages/a',
        driverCityPath: 'cities/x',
        distanceKm: 200,
      );
      expect(far, isNull);
    });

    test('GPS-only mode keeps near pickups and drops far ones', () {
      final far = DriverOrderMatch.scoreForMatch(
        distanceKm: 200,
      );
      expect(far, isNull);
      final near = DriverOrderMatch.scoreForMatch(
        distanceKm: 10,
      );
      expect(near?.boost, 1);
      expect(near?.km, 10);
    });
  });
}
