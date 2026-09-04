/**
 * Structured submit validation for Driver Registration V2.
 */
'use strict';

const docStatus = require('./driver_registration_document_status.js');
const docReview = require('./driver_document_review.js');

const DOC_TYPE_BY_BLOCKER = {
  profile_photo_required: 'profilePhoto',
  national_id_required: 'nationalId',
  vehicle_registration_required: 'vehicleRegistration',
  driver_license_required: 'driverLicense',
};

const REASON_PRIORITY = [
  'EMAIL_NOT_VERIFIED',
  'APPLICATION_ALREADY_PENDING',
  'APPLICATION_ALREADY_APPROVED',
  'INVALID_APPLICATION_STATE',
  'COUNTRY_NOT_FOUND',
  'COUNTRY_CONFIG_MALFORMED',
  'COUNTRY_CONFIG_MISSING',
  'COUNTRY_MISSING',
  'VEHICLE_TYPE_MARKET_MISMATCH',
  'VEHICLE_TYPE_UNAVAILABLE',
  'REQUIRED_EXPIRY_MISSING',
  'REQUIRED_DOCUMENT_MISSING',
  'REQUIRED_DOCUMENT_METADATA_INVALID',
  'LOCATION_MISSING',
  'VEHICLE_INCOMPLETE',
  'PROFILE_INCOMPLETE',
];

function isHttps(url) {
  return typeof url === 'string' && /^https:\/\//i.test(url.trim());
}

function docStoragePath(driver, key) {
  const slot = driver[key];
  if (slot && typeof slot === 'object') {
    const p = String(slot.storagePath || '').trim();
    if (p.startsWith('users/') && !p.includes('..')) return p;
  }
  return '';
}

function docAssetPresent(driver, v2Key, legacyKey) {
  if (docStoragePath(driver, v2Key)) return true;
  const slot = driver[v2Key];
  if (slot && typeof slot === 'object' && isHttps(slot.url)) return true;
  if (legacyKey && isHttps(String(driver[legacyKey] || ''))) return true;
  return false;
}

function profilePhotoPresent(driver) {
  return docStatus.profilePhotoOk(driver);
}

function phonePresent(driver) {
  return docStatus.phonePresent(driver);
}

function locationPresent(driver) {
  const loc = driver.loceshnMndobNow;
  if (!loc || typeof loc !== 'object') return false;
  const lat = loc.latitude;
  const lng = loc.longitude;
  if (typeof lat !== 'number' || typeof lng !== 'number') return false;
  if (Number.isNaN(lat) || Number.isNaN(lng)) return false;
  if (lat === 0 && lng === 0) return false;
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

function countryRequirementsEnabled(reqs) {
  return (
    reqs &&
    typeof reqs === 'object' &&
    Object.values(reqs).some((v) => v && typeof v === 'object' && v.enabled === true)
  );
}

function legacySubmitBlockers(driver, authUser) {
  const blockers = [];
  if (!authUser.emailVerified) blockers.push('EMAIL_NOT_VERIFIED');
  if (!phonePresent(driver)) blockers.push('PHONE_REQUIRED');
  if (!locationPresent(driver)) blockers.push('LOCATION_MISSING');
  if (!driver.mndob_vill) blockers.push('village_required');
  if (!driver.mndob_type_car && !driver.carRev_mndob && !driver.car_rev_mndob) {
    blockers.push('vehicle_type_required');
  }
  if (!String(driver.NameCar || '').trim()) blockers.push('vehicle_name_required');
  if (!String(driver.ModelCar || '').trim()) blockers.push('vehicle_model_required');
  if (!String(driver.number_lohh_car || driver.normalized_plate || '').trim()) {
    blockers.push('plate_required');
  }
  if (!profilePhotoPresent(driver)) blockers.push('profile_photo_required');
  if (!docAssetPresent(driver, 'doc_national_id', 'img_id_rksh')) {
    blockers.push('national_id_required');
  }
  if (!docAssetPresent(driver, 'doc_vehicle_registration', 'img_id_car')) {
    blockers.push('vehicle_registration_required');
  }
  if (!docStatus.driverLicenseSubmitOk(driver, null)) {
    blockers.push('driver_license_required');
  }
  return blockers;
}

function parseExpiryDate(raw) {
  if (!raw) return null;
  if (raw.toDate) return raw.toDate();
  if (raw instanceof Date) return raw;
  if (typeof raw === 'string') {
    const t = Date.parse(raw);
    return Number.isNaN(t) ? null : new Date(t);
  }
  return null;
}

function expiryMissingTypes(driver, countryRequirements) {
  if (!countryRequirementsEnabled(countryRequirements)) return [];
  const missing = [];
  const types = ['driverLicense', 'vehicleRegistration', 'vehicleInsurance', 'nationalId'];
  for (const type of types) {
    const cfg = countryRequirements[type];
    if (!cfg || cfg.enabled !== true || cfg.required !== true || cfg.expiryRequired !== true) {
      continue;
    }
    const field = docReview.DOC_FIELD_BY_TYPE[type];
    if (!field) continue;
    const slot = driver[field];
    if (!slot || typeof slot !== 'object') continue;
    const hasAsset =
      docStoragePath(driver, field) ||
      isHttps(slot.url) ||
      (type === 'nationalId' && isHttps(String(driver.img_id_rksh || '')));
    if (!hasAsset) continue;
    const expiry = parseExpiryDate(slot.expiryDate || slot.expiry_date);
    if (!expiry) missing.push(type);
  }
  return missing;
}

function mapLegacyBlocker(code) {
  switch (code) {
    case 'EMAIL_NOT_VERIFIED':
      return 'EMAIL_NOT_VERIFIED';
    case 'PHONE_REQUIRED':
    case 'village_required':
      return 'PROFILE_INCOMPLETE';
    case 'LOCATION_MISSING':
      return 'LOCATION_MISSING';
    case 'vehicle_type_required':
    case 'vehicle_name_required':
    case 'vehicle_model_required':
    case 'plate_required':
      return 'VEHICLE_INCOMPLETE';
    case 'profile_photo_required':
    case 'national_id_required':
    case 'vehicle_registration_required':
    case 'driver_license_required':
      return 'REQUIRED_DOCUMENT_MISSING';
    case 'COUNTRY_CONFIG_MISSING':
    case 'COUNTRY_NOT_FOUND':
    case 'COUNTRY_CONFIG_MALFORMED':
    case 'COUNTRY_MISSING':
    case 'VEHICLE_TYPE_MARKET_MISMATCH':
    case 'VEHICLE_TYPE_UNAVAILABLE':
      return code;
    default:
      if (code.startsWith('SUBMIT_NOT_ALLOWED_FROM_')) return 'INVALID_APPLICATION_STATE';
      return 'PROFILE_INCOMPLETE';
  }
}

function safeMessageForReason(reasonCode) {
  switch (reasonCode) {
    case 'EMAIL_NOT_VERIFIED':
      return 'Email verification required before submit.';
    case 'PROFILE_INCOMPLETE':
      return 'Profile incomplete.';
    case 'LOCATION_MISSING':
      return 'Location missing.';
    case 'VEHICLE_INCOMPLETE':
      return 'Vehicle incomplete.';
    case 'REQUIRED_DOCUMENT_MISSING':
      return 'Required document missing.';
    case 'REQUIRED_EXPIRY_MISSING':
      return 'Required document expiry missing.';
    case 'COUNTRY_CONFIG_MISSING':
      return 'Country registration requirements unavailable.';
    case 'COUNTRY_NOT_FOUND':
      return 'Country not found.';
    case 'COUNTRY_CONFIG_MALFORMED':
      return 'Country registration requirements malformed.';
    case 'COUNTRY_MISSING':
      return 'Country missing.';
    case 'VEHICLE_TYPE_MARKET_MISMATCH':
      return 'Vehicle type does not belong to driver market.';
    case 'VEHICLE_TYPE_UNAVAILABLE':
      return 'Selected vehicle type is unavailable.';
    case 'APPLICATION_ALREADY_PENDING':
      return 'Application already pending review.';
    case 'APPLICATION_ALREADY_APPROVED':
      return 'Application already approved.';
    case 'INVALID_APPLICATION_STATE':
      return 'Invalid application state for submit.';
    default:
      return 'Submit precondition failed.';
  }
}

function buildRejectPayload(blockers, extra = {}) {
  const missingDocuments = blockers
    .map((b) => DOC_TYPE_BY_BLOCKER[b])
    .filter(Boolean);
  const missingFields = blockers.filter((b) => !DOC_TYPE_BY_BLOCKER[b]);
  const reasonCodes = new Set(
    blockers.map(mapLegacyBlocker).concat(extra.reasonCodes || []),
  );
  if (extra.missingExpiryTypes && extra.missingExpiryTypes.length) {
    reasonCodes.add('REQUIRED_EXPIRY_MISSING');
  }
  let reasonCode = 'PROFILE_INCOMPLETE';
  for (const candidate of REASON_PRIORITY) {
    if (reasonCodes.has(candidate)) {
      reasonCode = candidate;
      break;
    }
  }
  return {
    reasonCode,
    safeMessage: safeMessageForReason(reasonCode),
    details: {
      reasonCode,
      missingFields,
      missingDocuments,
      ...(extra.missingExpiryTypes ? {missingExpiryTypes: extra.missingExpiryTypes} : {}),
      ...(extra.countryId ? {countryId: extra.countryId} : {}),
      ...(extra.registrationStatus ? {registrationStatus: extra.registrationStatus} : {}),
    },
  };
}

function collectSubmitBlockers(
  driver,
  authUser,
  countryRequirements,
  countryRef,
  extra = {},
) {
  const blockers = legacySubmitBlockers(driver, authUser);
  if (!countryRef) {
    blockers.push('COUNTRY_MISSING');
  } else if (extra.countryExists === false) {
    blockers.push('COUNTRY_NOT_FOUND');
  } else if (extra.requirementsStatus === 'malformed') {
    blockers.push('COUNTRY_CONFIG_MALFORMED');
  } else if (!countryRequirementsEnabled(countryRequirements)) {
    blockers.push('COUNTRY_CONFIG_MISSING');
  }
  if (extra.vehicleReasonCode) {
    blockers.push(extra.vehicleReasonCode);
  }
  const missingExpiryTypes = expiryMissingTypes(driver, countryRequirements);
  return {blockers, missingExpiryTypes};
}

module.exports = {
  legacySubmitBlockers,
  collectSubmitBlockers,
  buildRejectPayload,
  locationPresent,
  phonePresent,
  profilePhotoPresent,
  docAssetPresent,
  countryRequirementsEnabled,
  safeMessageForReason,
  mapLegacyBlocker,
  DOC_TYPE_BY_BLOCKER,
};
