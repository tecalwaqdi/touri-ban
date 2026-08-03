/// Document requirements by country — compatibility layer (no new Firestore
/// collection / no Deploy). Maps to existing upload slots on `user/{uid}`.
abstract final class DriverDocumentRequirementsRepository {
  DriverDocumentRequirementsRepository._();

  static const supportedIso = {'SA', 'KG', 'RU', 'UZ'};

  static List<DriverDocumentRequirement> forCountry(String? iso2) {
    // Same baseline for SA/KG/RU/UZ until Admin per-country config exists.
    // Keep iso2 in the API so callers pass country without a parallel path.
    if ((iso2 ?? '').isNotEmpty && !isSupportedIso(iso2)) {
      // Unknown ISO: still return safe baseline (do not hard-fail registration).
    }
    return const [
      DriverDocumentRequirement(
        type: 'profilePhoto',
        firestoreField: 'photo_url',
        required: false,
        expiryRequired: false,
        localizedTitleKey: 'Profile photo',
      ),
      DriverDocumentRequirement(
        type: 'nationalId',
        firestoreField: 'img_id_rksh',
        required: false,
        expiryRequired: false,
        localizedTitleKey: 'ID document',
      ),
      DriverDocumentRequirement(
        type: 'vehiclePhoto',
        firestoreField: 'img_id_car',
        required: false,
        expiryRequired: false,
        localizedTitleKey: 'Vehicle photo',
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
  });

  final String type;
  final String firestoreField;
  final bool required;
  final bool expiryRequired;
  final String localizedTitleKey;
}
