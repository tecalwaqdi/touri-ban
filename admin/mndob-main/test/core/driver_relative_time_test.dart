import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_relative_time.dart';
import 'package:mndob/core/toury_system_status_codes.dart';
import 'package:mndob/core/driver_payment_status_mapper.dart';

void main() {
  group('DriverRelativeTime', () {
    test('uses 1/2/other minute buckets', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      expect(
        DriverRelativeTime.format(null, now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        DriverRelativeTime.format(null, now.subtract(const Duration(minutes: 2)), now: now),
        '2 minutes ago',
      );
      final five = DriverRelativeTime.format(
        null,
        now.subtract(const Duration(minutes: 5)),
        now: now,
      );
      expect(five.contains('5') || five.contains('{count}'), isTrue);
      expect(five.toLowerCase().contains('minute'), isTrue);
    });

    test('uses 1/2/other hour buckets', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      expect(
        DriverRelativeTime.format(null, now.subtract(const Duration(hours: 1)), now: now),
        '1 hour ago',
      );
      expect(
        DriverRelativeTime.format(null, now.subtract(const Duration(hours: 2)), now: now),
        '2 hours ago',
      );
      final five = DriverRelativeTime.format(
        null,
        now.subtract(const Duration(hours: 5)),
        now: now,
      );
      expect(five.contains('5') || five.contains('{count}'), isTrue);
    });

    test('ETA approximate uses named template', () {
      final plain = DriverRelativeTime.etaMinutes(null, 8);
      expect(plain.contains('8'), isTrue);
      final approx = DriverRelativeTime.etaMinutes(null, 8, approximate: true);
      expect(approx.contains('8') || approx.contains('{value}'), isTrue);
    });
  });

  group('status / payment keys stay English', () {
    test('displayHalhKeyForCode never Arabic', () {
      final ar = RegExp(r'[\u0600-\u06FF]');
      for (final code in [
        TourySystemStatusCodes.pendingDriver,
        TourySystemStatusCodes.driverAssigned,
        TourySystemStatusCodes.driverArrived,
        TourySystemStatusCodes.tripInProgress,
        TourySystemStatusCodes.completed,
      ]) {
        final key = TourySystemStatusCodes.displayHalhKeyForCode(code);
        expect(ar.hasMatch(key), isFalse);
        expect(key, isNotEmpty);
      }
      final fromHalh = TourySystemStatusCodes.fromHalhText('بإنتظار قبول المندوب');
      expect(fromHalh, TourySystemStatusCodes.pendingDriver);
      expect(
        ar.hasMatch(TourySystemStatusCodes.displayHalhKeyForCode(fromHalh)),
        isFalse,
      );
    });

    test('payment displayKey never Arabic', () {
      final ar = RegExp(r'[\u0600-\u06FF]');
      for (final s in [
        TourySystemStatusCodes.paid,
        TourySystemStatusCodes.pendingCash,
        TourySystemStatusCodes.cashCollected,
        TourySystemStatusCodes.unpaid,
      ]) {
        final key = DriverPaymentStatusMapper.displayKey(s);
        expect(ar.hasMatch(key), isFalse);
        expect(key, isNotEmpty);
      }
    });
  });
}
