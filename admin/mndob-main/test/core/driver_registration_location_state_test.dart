import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_registration_location_state.dart';
import 'package:mndob/core/driver_registration_validators.dart';
import 'package:mndob/flutter_flow/lat_lng.dart';

void main() {
  group('DriverRegistrationLocationInput', () {
    test('ready when pin region and city are set', () {
      const input = DriverRegistrationLocationInput(
        selectedPosition: LatLng(21.4225, 39.8262),
        hasCountry: true,
        hasRegion: true,
        hasCity: true,
      );
      expect(input.isReady, isTrue);
      expect(input.validate().isValid, isTrue);
    });

    test('not ready when map center visible but pin not committed', () {
      const input = DriverRegistrationLocationInput(
        selectedPosition: null,
        hasCountry: true,
        hasRegion: true,
        hasCity: true,
      );
      expect(input.isReady, isFalse);
      final result = input.validate();
      expect(result.isValid, isFalse);
      expect(result.field, 'location');
      expect(
        result.errorKey,
        'Please select your location to continue',
      );
    });

    test('manual pin valid without GPS service semantics', () {
      const input = DriverRegistrationLocationInput(
        selectedPosition: LatLng(24.7136, 46.6753),
        hasCountry: true,
        hasRegion: true,
        hasCity: true,
      );
      expect(input.hasSelectedPosition, isTrue);
      expect(input.isReady, isTrue);
    });

    test('rejects null island coordinates', () {
      const input = DriverRegistrationLocationInput(
        selectedPosition: LatLng(0, 0),
        hasCountry: true,
        hasRegion: true,
        hasCity: true,
      );
      expect(input.isReady, isFalse);
    });

    test('region missing shows region error not gps', () {
      const input = DriverRegistrationLocationInput(
        selectedPosition: LatLng(21.4, 39.8),
        hasCountry: true,
        hasRegion: false,
        hasCity: true,
      );
      final result = input.validate();
      expect(result.isValid, isFalse);
      expect(result.field, 'region');
      expect(result.errorKey, 'Please select a region');
    });

    test('city missing shows city error not gps', () {
      const input = DriverRegistrationLocationInput(
        selectedPosition: LatLng(21.4, 39.8),
        hasCountry: true,
        hasRegion: true,
        hasCity: false,
      );
      final result = input.validate();
      expect(result.isValid, isFalse);
      expect(result.field, 'city');
    });
  });

  group('DriverLocationValidator', () {
    test('requires country region city and selected location', () {
      expect(
        DriverLocationValidator.validate(
          hasSelectedLocation: true,
          hasCountry: true,
          hasRegion: true,
          hasCity: true,
        ).isValid,
        isTrue,
      );
      expect(
        DriverLocationValidator.validate(
          hasSelectedLocation: true,
          hasCountry: true,
          hasRegion: false,
          hasCity: false,
        ).isValid,
        isFalse,
      );
      expect(
        DriverLocationValidator.validate(
          hasSelectedLocation: false,
          hasCountry: true,
          hasRegion: true,
          hasCity: true,
        ).field,
        'location',
      );
    });
  });
}
