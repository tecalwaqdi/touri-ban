import '/backend/schema/user_record.dart';
import '/core/driver_account_state_resolver.dart';
import '/core/driver_license_document_fields.dart';
import '/core/tour_guide_status.dart';

/// Policy for APPROVED / ACTIVE drivers: contact Auth fields vs locked identity.
abstract final class DriverApprovedProfilePolicy {
  DriverApprovedProfilePolicy._();

  /// Fields an approved driver may update on Firestore (contact mirrors only).
  /// Password is Auth-only and never written here.
  static const normalEditableFirestoreKeys = <String>{
    'phone_number',
    'phone_n',
    'email',
    'profile_updated_at',
    'profile_update_source',
    'uid',
  };

  /// Identity / vehicle / geo / document keys that must stay read-only for
  /// approved drivers (direct overwrite blocked; change-request only).
  static const protectedFieldKeys = <String>{
    'display_name',
    'ID_hoyh_MNDOB',
    'birth_date',
    'photo_url',
    'photo_storage_path',
    'Rev_dolh',
    'region_ref',
    'mndob_vill',
    'region_display',
    'city_display',
    'mndob_vill_text',
    'mndob_type_car',
    'carRev_mndob',
    'text_type_car_mndob',
    'mdenh_aml',
    'NameCar',
    'vehicle_make',
    'ModelCar',
    'vehicle_color',
    'seat_count',
    'number_lohh_car',
    'normalized_plate',
    'doc_national_id',
    'doc_vehicle_registration',
    DriverLicenseDocumentFields.front,
    DriverLicenseDocumentFields.back,
    DriverLicenseDocumentFields.legacy,
    'img_id_rksh',
    'img_id_car',
    'transport_company',
    'transport_company_text',
    TourGuideStatus.fieldIsTourGuide,
    TourGuideStatus.fieldPermitUrl,
    'loceshnMndobNow',
  };

  /// Sections a driver may request to change (Admin/Agent reviews).
  static const changeRequestSections = <String>[
    'personal_info',
    'vehicle',
    'national_id',
    'vehicle_registration',
    'driver_license',
    'plate',
    'location',
    'documents',
    'other',
  ];

  static bool isApprovedOrActive(UserRecord? doc) {
    if (doc == null) return false;
    if (doc.actevMndob == true) return true;
    final status = doc.registrationStatus.trim().toLowerCase();
    if (status == 'approved') return true;
    final life = DriverAccountStateResolver.resolveFromDocument(doc);
    return life == DriverLifecycle.activeOffline ||
        life == DriverLifecycle.activeOnline ||
        life == DriverLifecycle.onTrip;
  }

  /// True when driver is in Admin correction pipeline — reuse existing flow.
  static bool hasOpenCorrectionRequest(UserRecord? doc) {
    if (doc == null) return false;
    final status = doc.registrationStatus.trim().toLowerCase();
    return status == 'needs_changes' || status == 'changes_requested';
  }

  /// Strip any protected keys from a client update map for approved drivers.
  static Map<String, dynamic> filterApprovedUpdate(
    Map<String, dynamic> fields, {
    required bool approved,
  }) {
    if (!approved) return Map<String, dynamic>.from(fields);
    final out = <String, dynamic>{};
    for (final e in fields.entries) {
      if (normalEditableFirestoreKeys.contains(e.key)) {
        out[e.key] = e.value;
      }
    }
    return out;
  }
}
