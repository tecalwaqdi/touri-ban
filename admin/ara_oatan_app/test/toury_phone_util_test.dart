import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_phone_util.dart';

void main() {
  group('TouryPhoneUtil', () {
    test('digitsOnly strips plus spaces and dashes', () {
      expect(TouryPhoneUtil.digitsOnly('+966 50-123-4567'), '966501234567');
    });

    test('digitsOnly maps Arabic-Indic digits', () {
      expect(TouryPhoneUtil.digitsOnly('٠٥٠١٢٣٤٥٦٧'), '0501234567');
    });

    test('normalizeForSave keeps display text and parses phoneN', () {
      final n = TouryPhoneUtil.normalizeForSave('+966501234567');
      expect(n.phoneNumber, '+966501234567');
      expect(n.phoneN, 966501234567);
    });

    test('hasUsablePhone accepts phoneN when text empty', () {
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '', phoneN: 501234567),
        isTrue,
      );
      expect(
        TouryPhoneUtil.hasUsablePhone(phoneNumber: '', phoneN: 0),
        isFalse,
      );
    });
  });
}
