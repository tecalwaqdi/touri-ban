import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_phone_util.dart';
import 'package:ara_oatan_app/core/toury_profile_completeness.dart';

void main() {
  group('TouryPhoneUtil edge cases', () {
    test('rejects short phone_n legacy values', () {
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '', phoneN: 50123),
        isFalse,
      );
    });

    test('rejects all-zero digits', () {
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '0000000'),
        isFalse,
      );
    });

    test('normalizeForSave omits phone_n when digits too short', () {
      final n = TouryPhoneUtil.normalizeForSave('12345');
      expect(n.phoneN, isNull);
    });
  });

  group('TouryProfileCompleteness', () {
    test('missingRequiredFields includes phone when absent', () {
      expect(
        TouryProfileCompleteness.missingRequiredFields(
          user: null,
          authUser: null,
        ),
        contains('phone'),
      );
    });
  });
}
