import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_trip_constants.dart';

void main() {
  test('driver package smoke — trip constants load', () {
    expect(DriverTripHalh.accepted, isNotEmpty);
    expect(DriverWalletRules.minCashWalletBalance, greaterThan(0));
  });
}
