'use strict';

/**
 * Landmark write helpers.
 *
 * IMPORTANT: Never rewrite `Location`. Clamping into city bboxes made Admin
 * look correct while Firestore (and the customer app map) showed the wrong pin.
 * List visibility is handled by `id_vill` in current apps.
 *
 * Still fills missing `tsnef` so category chips / queries keep working.
 */

const CITY_BOXES = {
  taif: {
    lat: 21.2703,
    lng: 40.4158,
    minLat: 21.15,
    maxLat: 21.45,
    minLng: 40.25,
    maxLng: 40.62,
  },
  makkah: {
    lat: 21.4225,
    lng: 39.8262,
    minLat: 21.3,
    maxLat: 21.55,
    minLng: 39.72,
    maxLng: 40.02,
  },
  mecca: {
    lat: 21.4225,
    lng: 39.8262,
    minLat: 21.3,
    maxLat: 21.55,
    minLng: 39.72,
    maxLng: 40.02,
  },
  jeddah: {
    lat: 21.5433,
    lng: 39.1728,
    minLat: 21.45,
    maxLat: 21.78,
    minLng: 39.02,
    maxLng: 39.38,
  },
  madinah: {
    lat: 24.4686,
    lng: 39.6142,
    minLat: 24.38,
    maxLat: 24.58,
    minLng: 39.48,
    maxLng: 39.72,
  },
  medina: {
    lat: 24.4686,
    lng: 39.6142,
    minLat: 24.38,
    maxLat: 24.58,
    minLng: 39.48,
    maxLng: 39.72,
  },
  riyadh: {
    lat: 24.7136,
    lng: 46.6753,
    minLat: 24.45,
    maxLat: 25.05,
    minLng: 46.35,
    maxLng: 47.05,
  },
};

const DEFAULT_TSNEF = 'معالم سياحية';
const SOFT_EDGE_KM = 12;

function villageIdFromRef(ref) {
  if (!ref) return null;
  if (typeof ref === 'string') {
    const parts = ref.split('/');
    return parts[parts.length - 1] || null;
  }
  if (typeof ref.id === 'string') return ref.id;
  if (typeof ref.path === 'string') {
    const parts = ref.path.split('/');
    return parts[parts.length - 1] || null;
  }
  return null;
}

function slugFromVillageId(villageId) {
  if (!villageId) return null;
  let id = String(villageId).trim().toLowerCase();
  if (id.startsWith('city_sa_')) id = id.slice('city_sa_'.length);
  else if (id.startsWith('city_')) id = id.slice('city_'.length);
  return id || null;
}

function boxForVillageId(villageId) {
  const slug = slugFromVillageId(villageId);
  if (!slug) return null;
  return CITY_BOXES[slug] || null;
}

function distKm(a, b) {
  const p = 0.017453292519943295;
  const lat1 = a.lat * p;
  const lat2 = b.lat * p;
  const dLat = (b.lat - a.lat) * p;
  const dLng = (b.lng - a.lng) * p;
  const h =
    (1 - Math.cos(dLat)) / 4 +
    Math.cos(lat1) * Math.cos(lat2) * (1 - Math.cos(dLng)) / 4;
  return 12742 * Math.asin(Math.sqrt(Math.min(1, Math.max(0, h))));
}

function isValidLatLng(lat, lng) {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
  if (Math.abs(lat) < 0.0001 && Math.abs(lng) < 0.0001) return false;
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

function passesStoreFilter(box, lat, lng) {
  if (!box) return true;
  if (
    lat >= box.minLat &&
    lat <= box.maxLat &&
    lng >= box.minLng &&
    lng <= box.maxLng
  ) {
    return true;
  }
  return distKm({lat, lng}, {lat: box.lat, lng: box.lng}) <= SOFT_EDGE_KM;
}

function clampIntoBox(box, lat, lng) {
  return {
    lat: Math.min(box.maxLat, Math.max(box.minLat, lat)),
    lng: Math.min(box.maxLng, Math.max(box.minLng, lng)),
  };
}

function readGeo(data) {
  const loc = data && data.Location;
  if (!loc) return null;
  if (typeof loc.latitude === 'number' && typeof loc.longitude === 'number') {
    return {lat: loc.latitude, lng: loc.longitude};
  }
  if (typeof loc._latitude === 'number' && typeof loc._longitude === 'number') {
    return {lat: loc._latitude, lng: loc._longitude};
  }
  return null;
}

/**
 * Only fill missing category — never mutate Location.
 * @param {FirebaseFirestore.DocumentData} data
 * @param {import('firebase-admin').firestore.GeoPoint} GeoPoint unused
 * @returns {{patch: object, changed: boolean}|null}
 */
function computeVisibilityPatch(data, GeoPoint) {
  if (!data) return null;
  const patch = {};
  let changed = false;

  const tsnef = typeof data.tsnef === 'string' ? data.tsnef.trim() : '';
  if (!tsnef) {
    patch.tsnef = DEFAULT_TSNEF;
    changed = true;
  }

  // Intentionally ignore GeoPoint / city boxes — keep admin's real pin.
  void GeoPoint;
  void readGeo;
  void boxForVillageId;
  void passesStoreFilter;
  void clampIntoBox;

  return changed ? {patch, changed} : null;
}

module.exports = {
  CITY_BOXES,
  DEFAULT_TSNEF,
  computeVisibilityPatch,
  passesStoreFilter,
  boxForVillageId,
  clampIntoBox,
  isValidLatLng,
  readGeo,
};
