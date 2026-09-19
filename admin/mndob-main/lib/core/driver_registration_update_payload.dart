import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/driver_license_document_fields.dart';
import '/core/driver_registration_profile_loader.dart';
import '/core/tour_guide_status.dart';

/// Pure helpers for existing-driver profile update (no Auth / no CF submit).
abstract final class DriverRegistrationUpdatePayload {
  DriverRegistrationUpdatePayload._();

  /// Canonical Firestore key for document expiry (inside each `doc_*` map).
  static const expiryField = 'expiryDate';

  static const protectedKeys = <String>{
    'uid',
    'ismndob',
    'ismndom',
    'actev_mndob',
    'ngl',
    'registration_status',
    'submission_status',
    'registration_flow_version',
    'auto_activated',
    'approved_at',
    'approvedAt',
    'approvedBy',
    'rejectedAt',
    'rejectedBy',
    'rejectionReason',
    'rejection_reason',
    'requested_changes',
    'account_status',
    'operational_status',
    'created_time',
    'wallet',
    'walletId',
    'wallet_id',
    'fieldsToFix',
    'reviewVersion',
    'reviewAttemptCount',
    'vehicle_review_status',
    'document_review_status',
    TourGuideStatus.fieldStatus,
  };

  /// Build a merge-safe update map: never writes nulls (which delete fields).
  static Map<String, dynamic> build({
    required String uid,
    required String displayName,
    required String email,
    required String phoneE164,
    required String idNumber,
    required String vehicleName,
    required String modelYear,
    required String plate,
    required String color,
    required int seats,
    required String vehicleMake,
    required String vehicleTypeText,
    DateTime? birthDate,
    DateTime? licenseExpiry,
    DateTime? vehicleRegExpiry,
    String photoUrl = '',
    String photoStoragePath = '',
    String nationalIdUrl = '',
    String nationalIdStoragePath = '',
    String vehicleRegUrl = '',
    String vehicleRegStoragePath = '',
    String licenseFrontUrl = '',
    String licenseFrontStoragePath = '',
    String licenseBackUrl = '',
    String licenseBackStoragePath = '',
    @Deprecated('Use licenseFrontUrl') String licenseUrl = '',
    @Deprecated('Use licenseFrontStoragePath') String licenseStoragePath = '',
    Map<String, dynamic>? existingNationalId,
    Map<String, dynamic>? existingVehicleReg,
    Map<String, dynamic>? existingLicenseFront,
    Map<String, dynamic>? existingLicenseBack,
    @Deprecated('Use existingLicenseFront')
    Map<String, dynamic>? existingLicense,
    DocumentReference? regionRef,
    DocumentReference? villageRef,
    DocumentReference? countryRef,
    DocumentReference? vehicleTypeRef,
    String regionDisplay = '',
    String cityDisplay = '',
    String affiliationType = 'independent',
    String companyPath = '',
    String companyName = '',
    bool isTourGuide = false,
    String guidePermitUrl = '',
    LatLngLike? location,
  }) {
    final frontUrl =
        licenseFrontUrl.trim().isNotEmpty ? licenseFrontUrl : licenseUrl;
    final frontPath = licenseFrontStoragePath.trim().isNotEmpty
        ? licenseFrontStoragePath
        : licenseStoragePath;
    final frontExisting = existingLicenseFront ?? existingLicense;

    final frontSlot = mergeDocSlot(
      documentType: 'driver_license',
      side: 'front',
      existing: frontExisting,
      storagePath: frontPath,
      url: frontUrl,
      expiryDate: licenseExpiry,
    );
    final backSlot = mergeDocSlot(
      documentType: 'driver_license',
      side: 'back',
      existing: existingLicenseBack,
      storagePath: licenseBackStoragePath,
      url: licenseBackUrl,
    );

    final out = <String, dynamic>{
      'uid': uid,
      'display_name': displayName.trim(),
      'email': email.trim().toLowerCase(),
      'phone_number': phoneE164.trim(),
      'ID_hoyh_MNDOB': idNumber.trim(),
      'NameCar': vehicleName.trim(),
      'ModelCar': modelYear.trim(),
      'number_lohh_car': plate.trim(),
      'vehicle_color': color.trim(),
      'seat_count': seats,
      'vehicle_make': vehicleMake.trim().isEmpty
          ? vehicleName.trim()
          : vehicleMake.trim(),
      'text_type_car_mndob': vehicleTypeText.trim(),
      'mdenh_aml': vehicleTypeText.trim(),
      'normalized_plate': plate.trim(),
      'doc_national_id': mergeDocSlot(
        documentType: 'national_id',
        existing: existingNationalId,
        storagePath: nationalIdStoragePath,
        url: nationalIdUrl,
      ),
      'doc_vehicle_registration': mergeDocSlot(
        documentType: 'vehicle_registration',
        existing: existingVehicleReg,
        storagePath: vehicleRegStoragePath,
        url: vehicleRegUrl,
        expiryDate: vehicleRegExpiry,
      ),
      DriverLicenseDocumentFields.front: frontSlot,
      DriverLicenseDocumentFields.back: backSlot,
      // Legacy mirror of front for older Admin readers.
      DriverLicenseDocumentFields.legacy: mergeDocSlot(
        documentType: 'driver_license',
        side: 'front',
        existing: frontExisting,
        storagePath: frontPath,
        url: frontUrl,
        expiryDate: licenseExpiry,
      ),
      'profile_update_source': 'driver_app_edit_registration',
    };

    if (birthDate != null) {
      out['birth_date'] = Timestamp.fromDate(
        DateTime(birthDate.year, birthDate.month, birthDate.day),
      );
    }
    if (photoStoragePath.startsWith('users/')) {
      out['photo_storage_path'] = photoStoragePath;
    }
    final cleanPhoto = _cleanUrl(photoUrl);
    if (cleanPhoto.isNotEmpty) {
      out['photo_url'] = cleanPhoto;
    }
    final cleanId = _cleanUrl(nationalIdUrl);
    if (cleanId.isNotEmpty) {
      out['img_id_rksh'] = cleanId;
    }
    final cleanCar = _cleanUrl(vehicleRegUrl);
    if (cleanCar.isNotEmpty) {
      out['img_id_car'] = cleanCar;
    }
    if (regionRef != null) out['region_ref'] = regionRef;
    if (villageRef != null) out['mndob_vill'] = villageRef;
    if (countryRef != null) out['Rev_dolh'] = countryRef;
    if (vehicleTypeRef != null) {
      out['mndob_type_car'] = vehicleTypeRef;
      out['carRev_mndob'] = vehicleTypeRef;
    }
    if (regionDisplay.trim().isNotEmpty) {
      out['region_display'] = regionDisplay.trim();
    }
    if (cityDisplay.trim().isNotEmpty) {
      out['city_display'] = cityDisplay.trim();
      out['mndob_vill_text'] = cityDisplay.trim();
    }
    if (affiliationType == 'company' && companyPath.trim().isNotEmpty) {
      out['transport_company_text'] = companyName.trim();
    }
    out[TourGuideStatus.fieldIsTourGuide] = isTourGuide;
    if (isTourGuide && guidePermitUrl.trim().isNotEmpty) {
      out[TourGuideStatus.fieldPermitUrl] = guidePermitUrl.trim();
    }
    if (location != null) {
      out['loceshnMndobNow'] = GeoPoint(location.latitude, location.longitude);
    }

    // Strip protected + nulls (nulls delete fields under merge:true).
    out.removeWhere(
      (k, v) => v == null || protectedKeys.contains(k),
    );
    out['uid'] = uid;
    return out;
  }

  static Map<String, dynamic> mergeDocSlot({
    required String documentType,
    Map<String, dynamic>? existing,
    String storagePath = '',
    String url = '',
    DateTime? expiryDate,
    String? side,
  }) {
    final out = <String, dynamic>{
      if (existing != null) ...Map<String, dynamic>.from(existing),
      'documentType': documentType,
    };
    // Canonical expiry only — drop legacy duplicate key if present.
    out.remove('expiry_date');
    if (side != null && side.isNotEmpty) {
      out['side'] = side;
    }

    final path = storagePath.trim();
    final cleanedUrl = _cleanUrl(url);
    if (path.startsWith('users/')) {
      out['storagePath'] = path;
      out['status'] = out['status'] ?? 'uploaded';
    } else if (cleanedUrl.isNotEmpty) {
      out['url'] = cleanedUrl;
      out['status'] = out['status'] ?? 'uploaded';
    }

    if (expiryDate != null) {
      out[expiryField] = Timestamp.fromDate(
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day),
      );
    }
    out.removeWhere((k, v) => v == null);
    return out;
  }

  static String _cleanUrl(String url) {
    final t = url.trim();
    if (t.isEmpty) return '';
    if (t == DriverRegistrationProfileLoader.existingAssetMarker) return '';
    if (t.startsWith('pending://')) return '';
    if (t.startsWith('https://')) return t;
    return '';
  }
}

/// Simple lat/lng without depending on Flutter LatLng in pure unit tests.
class LatLngLike {
  const LatLngLike(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Expiry validation shared by UI step gate and tests.
abstract final class DriverRegistrationExpiryValidator {
  DriverRegistrationExpiryValidator._();

  static String? missingLicenseKey(DateTime? licenseExpiry) =>
      licenseExpiry == null
          ? 'Please enter the driver license expiry date'
          : null;

  static String? missingVehicleRegKey(DateTime? vehicleRegExpiry) =>
      vehicleRegExpiry == null
          ? 'Please enter the vehicle registration expiry date'
          : null;

  static List<String> blockingKeys({
    required DateTime? licenseExpiry,
    required DateTime? vehicleRegExpiry,
  }) {
    return [
      if (missingLicenseKey(licenseExpiry) != null)
        missingLicenseKey(licenseExpiry)!,
      if (missingVehicleRegKey(vehicleRegExpiry) != null)
        missingVehicleRegKey(vehicleRegExpiry)!,
    ];
  }
}

/// Resolve update mode from navigation query/extra (runtime path).
abstract final class DriverRegistrationNavMode {
  DriverRegistrationNavMode._();

  static bool isUpdateMode({
    String? queryMode,
    Object? extra,
  }) {
    final q = (queryMode ?? '').trim().toLowerCase();
    if (q == 'update') return true;
    if (extra is Map) {
      final m = extra['mode']?.toString().trim().toLowerCase() ?? '';
      if (m == 'update') return true;
    }
    if (extra is String && extra.trim().toLowerCase() == 'update') return true;
    return false;
  }
}
