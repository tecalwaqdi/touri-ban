import '/backend/backend.dart';

/// Validates Country → Region(cities) → City(villages) → Landmark relationships
/// using real Firestore DocumentReferences only.
abstract final class AdminGeoCascade {
  AdminGeoCascade._();

  static bool regionBelongsToCountry(
    CitiesRecord region,
    DocumentReference countryRef,
  ) {
    final dolh = region.dolh;
    return dolh != null && dolh.path == countryRef.path;
  }

  static bool cityBelongsToRegion(
    VillagesRecord city,
    DocumentReference regionRef,
  ) {
    final parent = city.cities;
    return parent != null && parent.path == regionRef.path;
  }

  static bool cityBelongsToCountry(
    VillagesRecord city,
    DocumentReference countryRef,
  ) {
    final dolh = city.dolh;
    return dolh != null && dolh.path == countryRef.path;
  }

  /// Returns Arabic error message, or null when valid for create/update.
  static String? validateLandmarkParents({
    required String name,
    required DocumentReference? countryRef,
    required DocumentReference? regionRef,
    required DocumentReference? cityRef,
    CitiesRecord? region,
    VillagesRecord? city,
    LatLng? location,
    bool requireLocation = true,
  }) {
    if (name.trim().isEmpty) {
      return 'اسم المعلم مطلوب';
    }
    if (countryRef == null) {
      return 'يرجى اختيار الدولة';
    }
    if (regionRef == null) {
      return 'يرجى اختيار المنطقة';
    }
    if (cityRef == null) {
      return 'يرجى اختيار المدينة';
    }
    if (region != null && !regionBelongsToCountry(region, countryRef)) {
      return 'المنطقة لا تنتمي للدولة المختارة';
    }
    if (city != null && !cityBelongsToRegion(city, regionRef)) {
      return 'المدينة لا تنتمي للمنطقة المختارة';
    }
    if (city != null && !cityBelongsToCountry(city, countryRef)) {
      return 'المدينة لا تنتمي للدولة المختارة';
    }
    if (requireLocation) {
      final err = validateLatLng(location);
      if (err != null) return err;
    }
    return null;
  }

  static String? validateLatLng(LatLng? location) {
    if (location == null) {
      return 'يرجى تحديد موقع المعلم على الخريطة';
    }
    final lat = location.latitude;
    final lng = location.longitude;
    if (lat.isNaN || lng.isNaN) {
      return 'إحداثيات غير صالحة';
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return 'خط العرض يجب أن يكون بين -90 و 90 وخط الطول بين -180 و 180';
    }
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) {
      return 'الموقع غير محدد';
    }
    return null;
  }

  static String? validateRegionParents({
    required String name,
    required DocumentReference? countryRef,
  }) {
    if (name.trim().isEmpty) return 'اسم المنطقة مطلوب';
    if (countryRef == null) return 'يرجى اختيار الدولة';
    return null;
  }

  static String? validateCityParents({
    required String name,
    required DocumentReference? countryRef,
    required DocumentReference? regionRef,
    CitiesRecord? region,
  }) {
    if (name.trim().isEmpty) return 'اسم المدينة مطلوب';
    if (countryRef == null) return 'يرجى اختيار الدولة';
    if (regionRef == null) return 'يرجى اختيار المنطقة';
    if (region != null && !regionBelongsToCountry(region, countryRef)) {
      return 'المنطقة لا تنتمي للدولة المختارة';
    }
    return null;
  }
}
