import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_phone_util.dart';

void main() {
  group('TouryPhoneUtil.hasUsablePhone', () {
    test('accepts phone_number string SoT', () {
      expect(
        TouryPhoneUtil.hasUsablePhone(
          phoneNumber: '+966501234567',
          phoneN: 0,
        ),
        isTrue,
      );
    });

    test('accepts phone_n when string empty', () {
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '', phoneN: 501234567),
        isTrue,
      );
    });

    test('rejects zero phone_n and empty string (stale gate bug)', () {
      // Pre-fix Book Now used `0.toString() != ''` which always passed.
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '', phoneN: 0),
        isFalse,
      );
    });

    test('rejects small phone_n without enough digits', () {
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '', phoneN: 12345),
        isFalse,
      );
    });

    test('accepts Arabic-Indic digits in display string', () {
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '٠٥٠١٢٣٤٥٦٧'),
        isTrue,
      );
    });
  });

  group('TouryPhoneUtil.displayPhone', () {
    test('prefers phone_number over phone_n', () {
      expect(
        TouryPhoneUtil.displayPhone(
          phoneNumber: '+966501234567',
          phoneN: 999,
        ),
        '+966501234567',
      );
    });

    test('falls back to phone_n when string empty', () {
      expect(
        TouryPhoneUtil.displayPhone(phoneNumber: '', phoneN: 501234567),
        '501234567',
      );
    });

    test('does not seed form with literal 0', () {
      expect(
        TouryPhoneUtil.displayPhone(phoneNumber: '', phoneN: 0),
        '',
      );
    });
  });

  group('TouryPhoneUtil.normalizeForSave', () {
    test('dual-writes digits for phone_n', () {
      final n = TouryPhoneUtil.normalizeForSave('+966 50 123 4567');
      expect(n.phoneNumber, '+966 50 123 4567');
      expect(n.phoneN, 966501234567);
    });
  });
}
