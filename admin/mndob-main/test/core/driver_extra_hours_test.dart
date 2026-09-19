import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/backend/schema/order_record.dart';
import 'package:mndob/core/driver_trip_service.dart';

// Test double only; no Firebase client or network is initialized.
// ignore: subtype_of_sealed_class
class _Ref extends Fake implements DocumentReference<Map<String, dynamic>> {}

void main() {
  final now = DateTime.now();
  OrderRecord order(
          {required DateTime start, required int hours, DateTime? end}) =>
      OrderRecord.getDocumentFromData({
        'START': start,
        'endTime': end,
        'total_taim': hours,
        'status_code': 'trip_in_progress',
      }, _Ref());

  test('extension resets countdown and blocks completion beyond original end',
      () {
    final start = now.subtract(const Duration(hours: 2, minutes: 10));
    final before = order(start: start, hours: 2);
    final extended = order(start: start, hours: 3);
    expect(
        DriverTripService.canCompleteTrip(
            order: before, allowRemoteOverride: true),
        isTrue);
    expect(
        DriverTripService.canCompleteTrip(
            order: extended, allowRemoteOverride: true),
        isFalse);
    expect(DriverTripService.remainingBeforeComplete(extended, now: now),
        const Duration(minutes: 50));
    expect(DriverTripService.remainingTripCountdownMs(extended, now: now),
        3000000);
  });
  test(
      'stale stored end cannot shorten canonical duration; later stored end is honored',
      () {
    final start = now.subtract(const Duration(hours: 2));
    expect(
        DriverTripService.tripEndsAt(order(start: start, hours: 3, end: now)),
        now.add(const Duration(hours: 1)));
    final later = now.add(const Duration(hours: 2));
    expect(
        DriverTripService.tripEndsAt(order(start: start, hours: 3, end: later)),
        later);
  });
  test('completion becomes available after extended end', () {
    final ended =
        order(start: now.subtract(const Duration(hours: 4)), hours: 3);
    expect(
        DriverTripService.canCompleteTrip(
            order: ended, allowRemoteOverride: true),
        isTrue);
    expect(DriverTripService.remainingBeforeComplete(ended, now: now),
        Duration.zero);
  });
}
