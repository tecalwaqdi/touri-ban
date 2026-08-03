import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/toury_system_status_codes.dart';

void main() {
  group('TourySystemStatusCodes.isAssignable', () {
    test('pending_driver is assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable('pending_driver', '', 'Pending'),
        isTrue,
      );
    });

    test('already assigned is not assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable('driver_assigned', 'مقبول', ''),
        isFalse,
      );
    });

    test('completed is not assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable('completed', 'مكتمل', 'Paid'),
        isFalse,
      );
    });

    test('legacy Arabic waiting is assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable(
          '',
          'بإنتظار قبول المندوب',
          '',
        ),
        isTrue,
      );
    });
  });
}
