import '/core/driver_auth_validation_service.dart';
import '/core/driver_phone_number_service.dart';

/// Result of a field validation (errorKey = English i18n key).
class DriverFieldValidation {
  const DriverFieldValidation.valid()
      : isValid = true,
        errorKey = null,
        field = null;

  const DriverFieldValidation.invalid({
    required this.errorKey,
    this.field,
  }) : isValid = false;

  final bool isValid;
  final String? errorKey;
  final String? field;
}

/// Full names: Arabic / Latin / Cyrillic — not ASCII-only.
abstract final class DriverNameValidator {
  DriverNameValidator._();

  static final RegExp _hasDigit = RegExp(r'\p{N}', unicode: true);
  static final RegExp _badSymbols = RegExp(
    r"[^\p{L}\p{M}\s'\u2019\-]",
    unicode: true,
  );

  static String normalize(String? raw) =>
      (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  static DriverFieldValidation validate(String? raw) {
    final name = normalize(raw);
    if (name.isEmpty) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Full name is required',
        field: 'displayName',
      );
    }
    if (name.length < 2) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Name is too short',
        field: 'displayName',
      );
    }
    if (name.length > 80) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Name is too long',
        field: 'displayName',
      );
    }
    if (_hasDigit.hasMatch(name)) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Name cannot contain numbers',
        field: 'displayName',
      );
    }
    if (_badSymbols.hasMatch(name)) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Name contains unsupported characters',
        field: 'displayName',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverBirthDateValidator {
  DriverBirthDateValidator._();

  static const minAgeYears = 18;
  static const maxAgeYears = 80;

  static DriverFieldValidation validate(
    DateTime? birthDate, {
    DateTime? now,
    int minAge = minAgeYears,
    int maxAge = maxAgeYears,
  }) {
    if (birthDate == null) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Birth date is required',
        field: 'birthDate',
      );
    }
    final today = now ?? DateTime.now();
    final date = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    if (date.isAfter(todayDate)) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Birth date cannot be in the future',
        field: 'birthDate',
      );
    }
    final age = _ageYears(date, todayDate);
    if (age < minAge) {
      return const DriverFieldValidation.invalid(
        errorKey: 'You must be at least 18 years old',
        field: 'birthDate',
      );
    }
    if (age > maxAge) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid birth date',
        field: 'birthDate',
      );
    }
    return const DriverFieldValidation.valid();
  }

  static int _ageYears(DateTime birth, DateTime today) {
    var age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
  }
}

abstract final class DriverIdentityValidator {
  DriverIdentityValidator._();

  static DriverFieldValidation validate({
    required String? raw,
    String iso2 = '',
  }) {
    final cleaned = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid ID number',
        field: 'identityNumber',
      );
    }
    if (cleaned.length < 5 || cleaned.length > 20) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid ID number',
        field: 'identityNumber',
      );
    }
    if (iso2.toUpperCase() == 'SA') {
      final digits = cleaned.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10 &&
          !(digits.startsWith('1') || digits.startsWith('2'))) {
        return const DriverFieldValidation.invalid(
          errorKey: 'Please enter a valid ID number',
          field: 'identityNumber',
        );
      }
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverPlateNormalizer {
  DriverPlateNormalizer._();

  static const int minLength = 3;
  /// Allows regional plates and VIN-style identifiers used in some markets.
  static const int maxLength = 20;

  static String normalize(String? raw) {
    return (raw ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('-', '')
        .toUpperCase();
  }

  static String display(String? raw) =>
      (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  static DriverFieldValidation validate(String? raw) {
    final n = normalize(raw);
    if (n.isEmpty) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Plate Number is required',
        field: 'plateNumber',
      );
    }
    if (n.length < minLength || n.length > maxLength) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid plate number',
        field: 'plateNumber',
      );
    }
    // Letters and digits only after normalize (no symbols).
    if (!RegExp(r'^[A-Z0-9\u0600-\u06FF]+$').hasMatch(n)) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid plate number',
        field: 'plateNumber',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverVehicleYearValidator {
  DriverVehicleYearValidator._();

  static const minYear = 2010;

  static int get maxYear => DateTime.now().year;

  static int? parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString().trim());
  }

  static DriverFieldValidation validate(dynamic raw) {
    final year = parse(raw);
    if (year == null) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid manufacturing year',
        field: 'manufacturingYear',
      );
    }
    if (year < minYear || year > maxYear) {
      if (year > DateTime.now().year) {
        return const DriverFieldValidation.invalid(
          errorKey: 'Manufacturing year cannot be in the future',
          field: 'manufacturingYear',
        );
      }
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid manufacturing year',
        field: 'manufacturingYear',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverSeatCountValidator {
  DriverSeatCountValidator._();

  static int? parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString().trim());
  }

  static DriverFieldValidation validate(dynamic raw, {int max = 8}) {
    final seats = parse(raw);
    if (seats == null) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter seat count',
        field: 'seatCount',
      );
    }
    if (seats < 1 || seats > max) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter a valid seat count',
        field: 'seatCount',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverDocumentValidator {
  DriverDocumentValidator._();

  static const allowedMime = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf',
  };

  static const maxBytes = 8 * 1024 * 1024;

  static DriverFieldValidation validateMime(String? mime) {
    final m = (mime ?? '').toLowerCase();
    if (m.isEmpty || !allowedMime.contains(m)) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Unsupported file type',
        field: 'document',
      );
    }
    return const DriverFieldValidation.valid();
  }

  static DriverFieldValidation validateSize(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Could not read the selected file',
        field: 'document',
      );
    }
    if (bytes > maxBytes) {
      return const DriverFieldValidation.invalid(
        errorKey: 'File is too large',
        field: 'document',
      );
    }
    return const DriverFieldValidation.valid();
  }

  static DriverFieldValidation validateUploadedUrl(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty || !(u.startsWith('http://') || u.startsWith('https://'))) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Document upload is incomplete',
        field: 'document',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverPhoneValidator {
  DriverPhoneValidator._();

  static DriverFieldValidation validate({
    required String? raw,
    required String? iso2,
  }) {
    final e164 = DriverPhoneNumberService.toE164(
      raw: raw ?? '',
      iso2: iso2 ?? '',
    );
    if (e164 == null || e164.isEmpty) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Phone number is invalid for this country',
        field: 'phoneNumber',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverEmailValidator {
  DriverEmailValidator._();

  static String normalize(String? raw) =>
      DriverAuthValidationService.normalizeEmail(raw) ?? '';

  static DriverFieldValidation validate(String? raw) {
    final err = DriverAuthValidationService.validateEmail(raw);
    if (err != null) {
      return DriverFieldValidation.invalid(errorKey: err, field: 'email');
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverLocationValidator {
  DriverLocationValidator._();

  static DriverFieldValidation validate({
    required bool hasUsableGps,
    required bool hasCountry,
    required bool hasRegion,
    required bool hasCity,
    bool requireRegion = true,
    bool requireCity = true,
  }) {
    if (!hasUsableGps) {
      return const DriverFieldValidation.invalid(
        errorKey:
            'Enable GPS and allow location access so we can place you on the map',
        field: 'location',
      );
    }
    if (!hasCountry) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please select a country',
        field: 'country',
      );
    }
    if (requireRegion && !hasRegion) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please select a region',
        field: 'region',
      );
    }
    if (requireCity && !hasCity) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please select a city',
        field: 'city',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverVehicleValidator {
  DriverVehicleValidator._();

  static DriverFieldValidation validate({
    required String? name,
    required dynamic year,
    required String? plate,
    required dynamic seats,
    required String? color,
    required bool hasType,
  }) {
    if ((name ?? '').trim().isEmpty) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please enter vehicle name',
        field: 'vehicleName',
      );
    }
    final y = DriverVehicleYearValidator.validate(year);
    if (!y.isValid) return y;
    final p = DriverPlateNormalizer.validate(plate);
    if (!p.isValid) return p;
    final s = DriverSeatCountValidator.validate(seats);
    if (!s.isValid) return s;
    if ((color ?? '').trim().isEmpty) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Color is required',
        field: 'color',
      );
    }
    if (!hasType) {
      return const DriverFieldValidation.invalid(
        errorKey: 'Please select vehicle type',
        field: 'vehicleType',
      );
    }
    return const DriverFieldValidation.valid();
  }
}

abstract final class DriverRegistrationCompletenessValidator {
  DriverRegistrationCompletenessValidator._();

  static List<String> missingKeys({
    required String name,
    required String email,
    required String phone,
    required String idNumber,
    required String vehicleName,
    required String modelYear,
    required String plate,
    required bool hasVehicleType,
    required bool hasCountry,
    required bool hasLocation,
    required String photoUrl,
    required String idImageUrl,
    DateTime? birthDate,
    int? seats,
    String? color,
    String? phoneIso2,
    bool? hasRegion,
    bool? hasCity,
  }) {
    final missing = <String>[];
    if (!DriverNameValidator.validate(name).isValid) {
      missing.add('Full Name');
    }
    if (!DriverEmailValidator.validate(email).isValid) {
      missing.add('Email');
    }
    if (phoneIso2 != null) {
      if (!DriverPhoneValidator.validate(raw: phone, iso2: phoneIso2).isValid) {
        missing.add('Mobile Number');
      }
    } else if (phone.trim().isEmpty) {
      missing.add('Mobile Number');
    }
    if (!DriverIdentityValidator.validate(raw: idNumber).isValid) {
      missing.add('ID Number');
    }
    if (!DriverBirthDateValidator.validate(birthDate).isValid) {
      missing.add('Birth date');
    }
    if (!hasCountry) missing.add('Country');
    if (hasRegion == false) missing.add('Region');
    if (hasCity == false) missing.add('City');
    if (!hasLocation) missing.add('Location');
    if (!hasVehicleType) missing.add('Vehicle Type');
    if (vehicleName.trim().isEmpty) missing.add('Vehicle Name');
    if (!DriverVehicleYearValidator.validate(modelYear).isValid) {
      missing.add('Vehicle Model');
    }
    if (!DriverPlateNormalizer.validate(plate).isValid) {
      missing.add('Plate Number');
    }
    if (!DriverSeatCountValidator.validate(seats).isValid) {
      missing.add('Seats');
    }
    if ((color ?? '').trim().isEmpty) missing.add('Color');
    // Documents are collected optionally at submission time. They are
    // required by the admin approval gate, not by initial registration.
    return missing;
  }
}
