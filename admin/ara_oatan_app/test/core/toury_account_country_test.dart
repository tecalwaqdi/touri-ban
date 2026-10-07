import 'package:ara_oatan_app/core/toury_account_country.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves a country document chosen from location', () {
    expect(
      shouldPersistAccountCountry(
        outsideCoverage: false,
        countryPath: 'countries/turkey',
      ),
      isTrue,
    );
  });

  test('does not save a point outside every registered country', () {
    expect(
      shouldPersistAccountCountry(
        outsideCoverage: true,
        countryPath: 'countries/turkey',
      ),
      isFalse,
    );
  });

  test('does not save a country name that is not a document', () {
    expect(
      shouldPersistAccountCountry(
        outsideCoverage: false,
        countryPath: null,
      ),
      isFalse,
    );
    expect(
      shouldPersistAccountCountry(
        outsideCoverage: false,
        countryPath: 'تركيا',
      ),
      isFalse,
    );
  });
}
