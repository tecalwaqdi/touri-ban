/// Maps structured submitDriverApplicationV2 rejections to localized keys.
abstract final class DriverRegistrationSubmissionErrorMapper {
  DriverRegistrationSubmissionErrorMapper._();

  static const rawCodes = {
    'failed-precondition',
    'permission-denied',
    'internal',
    'unknown',
    'unauthenticated',
    'deadline-exceeded',
  };

  static String messageKey({
    String? reasonCode,
    String? fallbackMessage,
    String? cfCode,
    List<String> missingDocuments = const [],
    List<String> missingExpiryTypes = const [],
  }) {
    final reason = (reasonCode ?? '').trim();
    if (reason.isNotEmpty) {
      switch (reason) {
        case 'EMAIL_NOT_VERIFIED':
          return 'Please verify your email before submitting';
        case 'PROFILE_INCOMPLETE':
          return 'Please complete the required personal information.';
        case 'LOCATION_MISSING':
          return 'Please select your location before submitting.';
        case 'VEHICLE_INCOMPLETE':
          return 'Please complete the required vehicle information.';
        case 'REQUIRED_DOCUMENT_MISSING':
          return _documentMissingKey(missingDocuments);
        case 'REQUIRED_EXPIRY_MISSING':
          return _expiryMissingKey(missingExpiryTypes);
        case 'COUNTRY_CONFIG_MISSING':
        case 'COUNTRY_MISSING':
        case 'COUNTRY_NOT_FOUND':
        case 'COUNTRY_CONFIG_MALFORMED':
          return 'Country registration requirements could not be loaded. Please try again later or contact support.';
        case 'VEHICLE_TYPE_MARKET_MISMATCH':
        case 'VEHICLE_TYPE_UNAVAILABLE':
          return 'Please select a valid vehicle type for your country.';
        case 'APPLICATION_ALREADY_PENDING':
          return 'Your application is already pending review.';
        case 'APPLICATION_ALREADY_APPROVED':
          return 'Your account is already approved.';
        case 'INVALID_APPLICATION_STATE':
          return 'Could not complete registration. Please try again.';
      }
    }

    final msg = (fallbackMessage ?? '').trim();
    if (msg.isNotEmpty && !rawCodes.contains(msg.toLowerCase())) {
      if (msg.contains('EMAIL_NOT_VERIFIED')) {
        return 'Please verify your email before submitting';
      }
      if (msg.contains('COUNTRY_CONFIG_MISSING')) {
        return 'Country registration requirements could not be loaded. Please try again later or contact support.';
      }
      if (msg.contains('national_id_required') ||
          msg.contains('driver_license_required') ||
          msg.contains('vehicle_registration_required') ||
          msg.contains('profile_photo_required')) {
        return 'Please upload all required documents before continuing';
      }
      if (msg.contains('vehicle_') || msg.contains('plate_required')) {
        return 'Please complete the required vehicle information.';
      }
      if (msg.contains('village_required') || msg.contains('PHONE_REQUIRED')) {
        return 'Please complete the required personal information.';
      }
      if (msg.contains('LOCATION_MISSING')) {
        return 'Please select your location before submitting.';
      }
    }

    if (cfCode == 'deadline-exceeded' ||
        cfCode == 'unavailable' ||
        cfCode == 'unknown') {
      return 'Could not reach the service. Check your connection and try again.';
    }
    if (rawCodes.contains((cfCode ?? '').toLowerCase())) {
      return 'Could not complete registration. Please try again.';
    }
    return 'Could not complete registration. Please try again.';
  }

  static String _documentMissingKey(List<String> missingDocuments) {
    if (missingDocuments.length == 1) {
      switch (missingDocuments.first) {
        case 'driverLicense':
          return 'Please upload your driver license to continue.';
        case 'nationalId':
          return 'Please upload your national ID to continue.';
        case 'vehicleRegistration':
          return 'Please upload your vehicle registration to continue.';
        case 'profilePhoto':
          return 'Please upload your profile photo to continue.';
      }
    }
    return 'Please upload all required documents before continuing';
  }

  static String _expiryMissingKey(List<String> missingExpiryTypes) {
    if (missingExpiryTypes.isEmpty) {
      return 'Please enter the required document expiry date.';
    }
    if (missingExpiryTypes.length == 1) {
      switch (missingExpiryTypes.first) {
        case 'driverLicense':
          return 'Please enter the expiry date for your driver license.';
        case 'nationalId':
          return 'Please enter the expiry date for your national ID.';
        case 'vehicleRegistration':
          return 'Please enter the expiry date for your vehicle registration.';
        case 'vehicleInsurance':
          return 'Please enter the expiry date for your vehicle insurance.';
      }
    }
    final labels = missingExpiryTypes.map((t) {
      switch (t) {
        case 'driverLicense':
          return 'Please enter the expiry date for your driver license.';
        case 'vehicleRegistration':
          return 'Please enter the expiry date for your vehicle registration.';
        case 'nationalId':
          return 'Please enter the expiry date for your national ID.';
        case 'vehicleInsurance':
          return 'Please enter the expiry date for your vehicle insurance.';
        default:
          return t;
      }
    }).toList();
    return labels.join('\n');
  }

  static Map<String, dynamic> detailsFrom(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  static List<String> stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
