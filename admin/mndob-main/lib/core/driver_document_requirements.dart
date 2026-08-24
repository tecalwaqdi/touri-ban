/// Document requirements by country — Registration V2 + Legacy dual-write.
/// Maps to `user/{uid}` slots (legacy + V2 document maps).
abstract final class DriverDocumentRequirementsRepository {
  DriverDocumentRequirementsRepository._();

  static const supportedIso = {'SA', 'KG', 'RU', 'UZ'};

  static List<DriverDocumentRequirement> forCountry(String? iso2) {
    if ((iso2 ?? '').isNotEmpty && !isSupportedIso(iso2)) {
      // Unknown ISO: still return safe baseline.
    }
    return const [
      DriverDocumentRequirement(
        type: 'profilePhoto',
        firestoreField: 'photo_url',
        required: true,
        expiryRequired: false,
        localizedTitleKey: 'Profile photo',
      ),
      DriverDocumentRequirement(
        type: 'nationalId',
        firestoreField: 'doc_national_id',
        legacyField: 'img_id_rksh',
        required: true,
        expiryRequired: false,
        localizedTitleKey: 'National ID',
      ),
      DriverDocumentRequirement(
        type: 'vehicleRegistration',
        firestoreField: 'doc_vehicle_registration',
        legacyField: 'img_id_car',
        required: true,
        expiryRequired: false,
        localizedTitleKey: 'Vehicle registration',
      ),
      DriverDocumentRequirement(
        type: 'driverLicense',
        firestoreField: 'doc_driver_license',
        required: true,
        expiryRequired: false,
        localizedTitleKey: 'Driver license',
      ),
    ];
  }

  static bool isSupportedIso(String? iso2) =>
      supportedIso.contains((iso2 ?? '').toUpperCase());
}

class DriverDocumentRequirement {
  const DriverDocumentRequirement({
    required this.type,
    required this.firestoreField,
    required this.required,
    required this.expiryRequired,
    required this.localizedTitleKey,
    this.legacyField = '',
  });

  final String type;
  final String firestoreField;
  final String legacyField;
  final bool required;
  final bool expiryRequired;
  final String localizedTitleKey;
}
