import '/flutter_flow/lat_lng.dart';
import '/core/driver_registration_validators.dart';
import '/core/toury_maps_config.dart';

/// Canonical registration location readiness — map pin, draft, and Next must agree.
class DriverRegistrationLocationInput {
  const DriverRegistrationLocationInput({
    this.selectedPosition,
    required this.hasCountry,
    required this.hasRegion,
    required this.hasCity,
  });

  final LatLng? selectedPosition;
  final bool hasCountry;
  final bool hasRegion;
  final bool hasCity;

  bool get hasSelectedPosition =>
      TouryMapsConfig.isUsableCoordinate(selectedPosition);

  /// Product rule: manual map pin OR GPS-acquired pin + country/region/city.
  bool get isReady =>
      hasSelectedPosition && hasCountry && hasRegion && hasCity;

  DriverFieldValidation validate() => DriverLocationValidator.validate(
        hasSelectedLocation: hasSelectedPosition,
        hasCountry: hasCountry,
        hasRegion: hasRegion,
        hasCity: hasCity,
      );
}
