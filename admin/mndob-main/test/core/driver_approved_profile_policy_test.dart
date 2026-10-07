import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_approved_profile_policy.dart';

void main() {
  group('DriverApprovedProfilePolicy', () {
    test('filterApprovedUpdate keeps only contact fields', () {
      final filtered = DriverApprovedProfilePolicy.filterApprovedUpdate(
        {
          'phone_number': '+966500000000',
          'email': 'a@b.com',
          'display_name': 'Should drop',
          'NameCar': 'Should drop',
          'number_lohh_car': 'ABC',
          'uid': 'u1',
        },
        approved: true,
      );
      expect(filtered.keys.toSet(), {
        'phone_number',
        'email',
        'uid',
      });
      expect(filtered.containsKey('display_name'), isFalse);
      expect(filtered.containsKey('NameCar'), isFalse);
    });

    test('filterApprovedUpdate passes through when not approved', () {
      final filtered = DriverApprovedProfilePolicy.filterApprovedUpdate(
        {
          'display_name': 'Keep',
          'NameCar': 'Keep',
        },
        approved: false,
      );
      expect(filtered['display_name'], 'Keep');
      expect(filtered['NameCar'], 'Keep');
    });

    test('protected fields include identity vehicle docs', () {
      expect(
        DriverApprovedProfilePolicy.protectedFieldKeys.contains('display_name'),
        isTrue,
      );
      expect(
        DriverApprovedProfilePolicy.protectedFieldKeys
            .contains('number_lohh_car'),
        isTrue,
      );
      expect(
        DriverApprovedProfilePolicy.protectedFieldKeys
            .contains('doc_national_id'),
        isTrue,
      );
      expect(
        DriverApprovedProfilePolicy.normalEditableFirestoreKeys
            .contains('phone_number'),
        isTrue,
      );
    });
  });
}
