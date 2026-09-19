import '/core/driver_document_expiry_resolver.dart';
import '/core/driver_license_document_fields.dart';
import '/core/tour_guide_status.dart';

/// Snapshot of editable registration fields loaded from an existing driver doc.
class DriverRegistrationProfileSnapshot {
  const DriverRegistrationProfileSnapshot({
    required this.displayName,
    required this.idNumber,
    required this.email,
    required this.phone,
    required this.vehicleName,
    required this.modelYear,
    required this.plate,
    required this.color,
    required this.seats,
    required this.make,
    required this.cityDisplay,
    required this.regionDisplay,
    required this.regionPath,
    required this.villagePath,
    required this.countryPath,
    required this.vehicleTypePath,
    required this.vehicleTypeText,
    required this.photoUrl,
    required this.photoStoragePath,
    required this.nationalIdUrl,
    required this.nationalIdStoragePath,
    required this.vehicleRegUrl,
    required this.vehicleRegStoragePath,
    required this.licenseFrontUrl,
    required this.licenseFrontStoragePath,
    required this.licenseBackUrl,
    required this.licenseBackStoragePath,
    required this.affiliationType,
    required this.companyPath,
    required this.companyName,
    required this.isTourGuide,
    required this.guidePermitUrl,
    this.birthDate,
    this.licenseExpiry,
    this.vehicleRegExpiry,
    this.lat,
    this.lng,
  });

  final String displayName;
  final String idNumber;
  final String email;
  final String phone;
  final String vehicleName;
  final String modelYear;
  final String plate;
  final String color;
  final String seats;
  final String make;
  final String cityDisplay;
  final String regionDisplay;
  final String regionPath;
  final String villagePath;
  final String countryPath;
  final String vehicleTypePath;
  final String vehicleTypeText;
  final String photoUrl;
  final String photoStoragePath;
  final String nationalIdUrl;
  final String nationalIdStoragePath;
  final String vehicleRegUrl;
  final String vehicleRegStoragePath;
  final String licenseFrontUrl;
  final String licenseFrontStoragePath;
  final String licenseBackUrl;
  final String licenseBackStoragePath;
  final String affiliationType;
  final String companyPath;
  final String companyName;
  final bool isTourGuide;
  final String guidePermitUrl;
  final DateTime? birthDate;
  final DateTime? licenseExpiry;
  final DateTime? vehicleRegExpiry;
  final double? lat;
  final double? lng;

  /// Legacy alias — front side (or migrated single license).
  String get licenseUrl => licenseFrontUrl;
  String get licenseStoragePath => licenseFrontStoragePath;
}

/// Pure loader — maps Firestore user map → registration form snapshot.
abstract final class DriverRegistrationProfileLoader {
  DriverRegistrationProfileLoader._();

  static const existingAssetMarker = 'existing://present';

  static DriverRegistrationProfileSnapshot fromUserData(
    Map<String, dynamic> data,
  ) {
    final national = _slot(data, 'doc_national_id');
    final vehicleReg = _slot(data, 'doc_vehicle_registration');
    final licenseLegacy = _slot(data, DriverLicenseDocumentFields.legacy);
    final licenseFront =
        _slot(data, DriverLicenseDocumentFields.front) ?? licenseLegacy;
    final licenseBack = _slot(data, DriverLicenseDocumentFields.back);

    final photoPath = (data['photo_storage_path'] as String?)?.trim() ?? '';
    final photoUrl = (data['photo_url'] as String?)?.trim() ?? '';
    final idLegacy = (data['img_id_rksh'] as String?)?.trim() ?? '';
    final carLegacy = (data['img_id_car'] as String?)?.trim() ?? '';

    final company = data['transport_company'];
    final companyPath = company is Map && company['path'] is String
        ? (company['path'] as String)
        : (company?.toString().contains('/') == true
            ? company
                .toString()
                .replaceFirst('DocumentReference(', '')
                .split(')')[0]
            : '');
    String resolvedCompanyPath = '';
    try {
      final dynamic ref = data['transport_company'];
      if (ref != null && ref.path is String) {
        resolvedCompanyPath = (ref.path as String).trim();
      }
    } catch (_) {}
    if (resolvedCompanyPath.isEmpty) {
      resolvedCompanyPath = companyPath;
    }

    final loc = data['loceshn_mndob_now'] ?? data['loceshnMndobNow'];
    double? lat;
    double? lng;
    try {
      if (loc != null) {
        lat = (loc.latitude as num?)?.toDouble();
        lng = (loc.longitude as num?)?.toDouble();
      }
    } catch (_) {}

    String refPath(dynamic v) {
      try {
        if (v != null && v.path is String) return (v.path as String).trim();
      } catch (_) {}
      return '';
    }

    return DriverRegistrationProfileSnapshot(
      displayName: (data['display_name'] as String?)?.trim() ?? '',
      idNumber: (data['ID_hoyh_MNDOB'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone_number'] as String?)?.trim() ?? '',
      vehicleName: (data['NameCar'] as String?)?.trim() ??
          (data['vehicle_make'] as String?)?.trim() ??
          '',
      modelYear: (data['ModelCar'] as String?)?.trim() ?? '',
      plate: (data['number_lohh_car'] as String?)?.trim() ??
          (data['normalized_plate'] as String?)?.trim() ??
          '',
      color: (data['vehicle_color'] as String?)?.trim() ?? '',
      seats: '${data['seat_count'] ?? ''}'.trim(),
      make: (data['vehicle_make'] as String?)?.trim() ?? '',
      cityDisplay: (data['city_display'] as String?)?.trim() ??
          (data['mndob_vill_text'] as String?)?.trim() ??
          '',
      regionDisplay: (data['region_display'] as String?)?.trim() ??
          (data['naimmdenh'] as String?)?.trim() ??
          '',
      regionPath: refPath(data['region_ref'] ?? data['mdenh']),
      villagePath: refPath(data['mndob_vill']),
      countryPath: refPath(data['rev_dolh'] ?? data['Rev_dolh'] ?? data['dolh']),
      vehicleTypePath: refPath(data['mndob_type_car'] ?? data['carRev_mndob']),
      vehicleTypeText: (data['text_type_car_mndob'] as String?)?.trim() ??
          (data['mdenh_aml'] as String?)?.trim() ??
          '',
      photoUrl: _assetUrl(photoUrl, photoPath),
      photoStoragePath: photoPath,
      nationalIdUrl: _assetUrl(
        _slotUrl(national) ?? idLegacy,
        _slotPath(national),
      ),
      nationalIdStoragePath: _slotPath(national),
      vehicleRegUrl: _assetUrl(
        _slotUrl(vehicleReg) ?? carLegacy,
        _slotPath(vehicleReg),
      ),
      vehicleRegStoragePath: _slotPath(vehicleReg),
      licenseFrontUrl: _assetUrl(_slotUrl(licenseFront), _slotPath(licenseFront)),
      licenseFrontStoragePath: _slotPath(licenseFront),
      licenseBackUrl: _assetUrl(_slotUrl(licenseBack), _slotPath(licenseBack)),
      licenseBackStoragePath: _slotPath(licenseBack),
      affiliationType:
          resolvedCompanyPath.isNotEmpty ? 'company' : 'independent',
      companyPath: resolvedCompanyPath,
      companyName: (data['transport_company_text'] as String?)?.trim() ?? '',
      isTourGuide: data[TourGuideStatus.fieldIsTourGuide] == true,
      guidePermitUrl:
          (data[TourGuideStatus.fieldPermitUrl] as String?)?.trim() ?? '',
      birthDate: DriverDocumentExpiryResolver.parseExpiry(data['birth_date']),
      licenseExpiry: DriverDocumentExpiryResolver.parseExpiry(
        licenseFront?['expiryDate'] ??
            licenseFront?['expiry_date'] ??
            licenseLegacy?['expiryDate'] ??
            licenseLegacy?['expiry_date'],
      ),
      vehicleRegExpiry: DriverDocumentExpiryResolver.parseExpiry(
        vehicleReg?['expiryDate'] ?? vehicleReg?['expiry_date'],
      ),
      lat: lat,
      lng: lng,
    );
  }

  static Map<String, dynamic>? _slot(Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static String? _slotUrl(Map<String, dynamic>? slot) {
    final u = (slot?['url'] as String?)?.trim();
    if (u != null && u.isNotEmpty) return u;
    return null;
  }

  static String _slotPath(Map<String, dynamic>? slot) {
    final p = (slot?['storagePath'] as String?)?.trim() ?? '';
    return p.startsWith('users/') ? p : '';
  }

  static String _assetUrl(String? url, String storagePath) {
    final u = (url ?? '').trim();
    if (u.startsWith('https://')) return u;
    if (storagePath.startsWith('users/')) return existingAssetMarker;
    return '';
  }
}
