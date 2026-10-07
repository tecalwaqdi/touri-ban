import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/toury_support_policy.dart';

void main() {
  test('Saudi without an Agent phone uses the Saudi fallback', () {
    final result = TourySupportPolicy.resolve(
      iso2: 'SA',
      countryPath: 'countries/saudi_arabia',
      agentPhone: '',
    );
    expect(result.digits, '966533356126');
    expect(result.fallback, isTrue);
  });

  test('Kyrgyzstan and Russia without an Agent phone are not configured', () {
    for (final country in [
      ('KG', 'countries/kyrgyzstan'),
      ('RU', 'countries/russia'),
    ]) {
      final result = TourySupportPolicy.resolve(
        iso2: country.$1,
        countryPath: country.$2,
        agentPhone: '',
      );
      expect(result.ok, isFalse);
      expect(result.code, 'SUPPORT_NOT_CONFIGURED');
    }
  });

  test('a configured foreign Agent phone is used', () {
    final result = TourySupportPolicy.resolve(
      iso2: 'KG',
      countryPath: 'countries/kyrgyzstan',
      agentPhone: '+996555123456',
    );
    expect(result.digits, '996555123456');
    expect(result.fallback, isFalse);
  });
}
