import 'package:ara_oatan_app/core/toury_signup_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PHONE_REQUIRED when empty', () {
    expect(touryValidateSignupPhone('  '), 'PHONE_REQUIRED');
  });

  test('PHONE_REQUIRED when too short', () {
    expect(touryValidateSignupPhone('+966 12'), 'PHONE_REQUIRED');
  });

  test('accepts phone with country code and trim', () {
    expect(touryValidateSignupPhone('  +966 50 123 4567  '), isNull);
  });
}
