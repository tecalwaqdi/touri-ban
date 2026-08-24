import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_email_verification_gate.dart';

void main() {
  test('unverified customer blocked', () {
    expect(touryShouldBlockUnverifiedCustomer(emailVerified: false), isTrue);
  });

  test('verified customer continues', () {
    expect(touryShouldBlockUnverifiedCustomer(emailVerified: true), isFalse);
  });
}
