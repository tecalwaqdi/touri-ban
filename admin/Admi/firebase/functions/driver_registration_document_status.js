/**
 * Registration V2 document completeness — shared with Admin/Driver Dart helper.
 * Required slots: national_id, vehicle_registration, driver_license (front+back).
 * Profile photo is checked separately for submit/approve blockers.
 */
'use strict';

const REQUIRED_TYPES = [
  'national_id',
  'vehicle_registration',
  'driver_license',
];

const TYPE_KEYS = {
  national_id: ['doc_national_id', 'img_id_rksh'],
  vehicle_registration: ['doc_vehicle_registration', 'img_id_car'],
  driver_license: ['doc_driver_license_front', 'doc_driver_license_back', 'doc_driver_license'],
};

function isStoragePath(raw) {
  const p = String(raw || '').trim();
  return p.startsWith('users/') && !p.includes('..');
}

function isHttps(url) {
  return typeof url === 'string' && /^https:\/\//i.test(url.trim());
}

function storagePathFrom(data, v2Key) {
  const slot = data[v2Key];
  if (slot && typeof slot === 'object') {
    const p = String(slot.storagePath || '').trim();
    if (isStoragePath(p)) return p;
  }
  return '';
}

function urlFrom(data, v2Key, legacyKey) {
  const slot = data[v2Key];
  if (slot && typeof slot === 'object' && typeof slot.url === 'string') {
    const u = slot.url.trim();
    if (u) return u;
  }
  if (legacyKey) {
    const leg = data[legacyKey];
    if (typeof leg === 'string' && leg.trim()) return leg.trim();
  }
  return '';
}

function slotStatusRaw(data, v2Key) {
  const slot = data[v2Key];
  if (slot && typeof slot === 'object' && typeof slot.status === 'string') {
    return String(slot.status).trim().toLowerCase();
  }
  return '';
}

function sidePresent(data, v2Key, legacyKey) {
  if (storagePathFrom(data, v2Key)) return true;
  const url = urlFrom(data, v2Key, legacyKey);
  return url && (isStoragePath(url) || isHttps(url));
}

function isApprovedLegacyLicenseOnly(data) {
  const status = String(data.registration_status || '').trim();
  const approved = status === 'approved' && data.actev_mndob === true;
  const legacy = sidePresent(data, 'doc_driver_license', '');
  const front = sidePresent(data, 'doc_driver_license_front', '');
  const back = sidePresent(data, 'doc_driver_license_back', '');
  return approved && legacy && !front && !back;
}

function driverLicenseSubmitOk(data, countryRequirements) {
  const backRequired = isLicenseBackRequired(countryRequirements);
  const front = sidePresent(data, 'doc_driver_license_front', '');
  const back = sidePresent(data, 'doc_driver_license_back', '');
  if (front && (!backRequired || back)) return true;
  return false;
}

function isLicenseBackRequired(countryRequirements) {
  if (!countryRequirements || typeof countryRequirements !== 'object') return true;
  const cfg = countryRequirements.driverLicenseBack || countryRequirements.driver_license_back;
  if (cfg && typeof cfg === 'object' && cfg.required === false) return false;
  return true;
}

function statusForType(data, type) {
  const keys = TYPE_KEYS[type];
  if (!keys) return 'missing';
  if (type === 'driver_license') {
    for (const key of keys) {
      const raw = slotStatusRaw(data, key);
      if (raw === 'rejected') return 'rejected';
      if (raw === 'needs_reupload') return 'needs_reupload';
    }
    const front = sidePresent(data, 'doc_driver_license_front', '');
    const back = sidePresent(data, 'doc_driver_license_back', '');
    if (front && back) return 'complete';
    if (isApprovedLegacyLicenseOnly(data)) return 'complete';
    const legacy = sidePresent(data, 'doc_driver_license', '');
    if (legacy && !front && !back) return 'missing';
    return 'missing';
  }
  const [v2, legacy] = keys;
  const raw = slotStatusRaw(data, v2);
  if (raw === 'rejected') return 'rejected';
  if (raw === 'needs_reupload') return 'needs_reupload';
  if (storagePathFrom(data, v2)) return 'complete';
  const url = urlFrom(data, v2, legacy);
  if (url && (isStoragePath(url) || isHttps(url))) return 'complete';
  return 'missing';
}

function profilePhotoOk(data) {
  if (isStoragePath(data.photo_storage_path)) return true;
  return isHttps(data.photo_url || '');
}

function overallRequiredDocs(data) {
  const slots = REQUIRED_TYPES.map((t) => statusForType(data, t));
  if (slots.some((s) => s === 'rejected' || s === 'needs_reupload')) {
    return 'needs_reupload';
  }
  if (slots.some((s) => s === 'missing')) return 'missing';
  return 'complete';
}

function registrationDocumentsStatus(data) {
  const flow = Number(data.registration_flow_version || 0);
  if (flow !== 2) return 'unknown_legacy';
  return overallRequiredDocs(data);
}

function isCompleteForSubmit(data) {
  return overallRequiredDocs(data) === 'complete' && profilePhotoOk(data);
}

function phonePresent(data) {
  const pn = String(data.phone_number || data.phoneNumber || '').trim();
  if (pn.replace(/\D/g, '').length >= 8) return true;
  const phoneN = data.phone_n ?? data.phoneN;
  if (typeof phoneN === 'number' && String(Math.trunc(phoneN)).length >= 8) {
    return true;
  }
  if (typeof phoneN === 'string' && phoneN.replace(/\D/g, '').length >= 8) {
    return true;
  }
  return false;
}

module.exports = {
  REQUIRED_TYPES,
  statusForType,
  profilePhotoOk,
  overallRequiredDocs,
  registrationDocumentsStatus,
  isCompleteForSubmit,
  phonePresent,
  driverLicenseSubmitOk,
  isLicenseBackRequired,
  sidePresent,
  isApprovedLegacyLicenseOnly,
};
