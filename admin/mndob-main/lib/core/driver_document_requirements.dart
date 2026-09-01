/// Document requirements by country — Registration V2 + Legacy dual-write.
///
/// Baseline is hardcoded for safety. Optional override from
/// `countries/{countryId}.driver_requirements` (map of type → config).
/// Super Admin can set that field without requiring a second collection.
abstract final class DriverDocumentRequirementsRepository {
  DriverDocumentRequirementsRepository._();

  static const supportedIso = {'SA', 'KG', 'RU', 'UZ'};

  static const baseline = <DriverDocumentRequirement>[
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
      expiryRequired: true,
      operationalBlockingOnExpiry: true,
      expiryWarningDays: 30,
      localizedTitleKey: 'Vehicle registration',
    ),
    DriverDocumentRequirement(
      type: 'driverLicense',
      firestoreField: 'doc_driver_license',
      required: true,
      expiryRequired: true,
      operationalBlockingOnExpiry: true,
      expiryWarningDays: 30,
      localizedTitleKey: 'Driver license',
    ),
  ];

  static List<DriverDocumentRequirement> forCountry(String? iso2) {
    if ((iso2 ?? '').isNotEmpty && !isSupportedIso(iso2)) {
      // Unknown ISO: still return safe baseline.
    }
    return baseline;
  }

  /// Merge optional Firestore map onto baseline.
  ///
  /// Expected shape:
  /// ```json
  /// {
  ///   "vehicle_insurance": {"required": true, "expiryRequired": true, "enabled": true},
  ///   "nationalId": {"required": false}
  /// }
  /// ```
  static List<DriverDocumentRequirement> mergeCountryConfig(
    List<DriverDocumentRequirement> base,
    Map<String, dynamic>? config,
  ) {
    if (config == null || config.isEmpty) return base;
    final byType = {for (final r in base) r.type: r};
    for (final entry in config.entries) {
      final type = entry.key.trim();
      if (type.isEmpty) continue;
      final raw = entry.value;
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['enabled'] == false) {
        byType.remove(type);
        // Also remove by alias keys used in CF.
        byType.remove(_aliasToType(type));
        continue;
      }
      final existing = byType[type] ?? byType[_aliasToType(type)];
      final resolvedType = existing?.type ?? _aliasToType(type) ?? type;
      byType[resolvedType] = DriverDocumentRequirement(
        type: resolvedType,
        firestoreField: (map['firestoreField'] as String?) ??
            existing?.firestoreField ??
            _defaultField(resolvedType),
        legacyField:
            (map['legacyField'] as String?) ?? existing?.legacyField ?? '',
        required: map['required'] is bool
            ? map['required'] as bool
            : (existing?.required ?? true),
        expiryRequired: map['expiryRequired'] is bool
            ? map['expiryRequired'] as bool
            : (existing?.expiryRequired ?? false),
        operationalBlockingOnExpiry: map['operationalBlockingOnExpiry'] is bool
            ? map['operationalBlockingOnExpiry'] as bool
            : (existing?.operationalBlockingOnExpiry ?? false),
        expiryWarningDays: map['expiryWarningDays'] is num
            ? (map['expiryWarningDays'] as num).toInt()
            : (existing?.expiryWarningDays ?? 30),
        effectiveFrom: map.containsKey('effectiveFrom')
            ? map['effectiveFrom']
            : existing?.effectiveFrom,
        gracePeriodDays: map['gracePeriodDays'] is num
            ? (map['gracePeriodDays'] as num).toInt()
            : existing?.gracePeriodDays,
        localizedTitleKey: (map['labelKey'] as String?) ??
            existing?.localizedTitleKey ??
            resolvedType,
      );
    }
    return byType.values.toList();
  }

  static String? _aliasToType(String key) {
    switch (key) {
      case 'national_id':
        return 'nationalId';
      case 'vehicle_registration':
        return 'vehicleRegistration';
      case 'driver_license':
        return 'driverLicense';
      case 'profile_photo':
        return 'profilePhoto';
      case 'vehicle_insurance':
        return 'vehicleInsurance';
      default:
        return key;
    }
  }

  static String _defaultField(String type) {
    switch (type) {
      case 'profilePhoto':
        return 'photo_url';
      case 'nationalId':
        return 'doc_national_id';
      case 'vehicleRegistration':
        return 'doc_vehicle_registration';
      case 'driverLicense':
        return 'doc_driver_license';
      case 'vehicleInsurance':
        return 'doc_vehicle_insurance';
      default:
        return 'doc_$type';
    }
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
    this.operationalBlockingOnExpiry = false,
    this.expiryWarningDays = 30,
    this.effectiveFrom,
    this.gracePeriodDays,
  });

  final String type;
  final String firestoreField;
  final String legacyField;
  final bool required;
  final bool expiryRequired;
  final String localizedTitleKey;
  final bool operationalBlockingOnExpiry;
  final int expiryWarningDays;

  /// Rollout start for already-approved drivers (ISO string or Timestamp).
  final dynamic effectiveFrom;

  /// Inclusive grace days after [effectiveFrom] before operational blocking.
  final int? gracePeriodDays;
}
