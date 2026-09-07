'use strict';

/**
 * Temporary compatibility layer for OLD Customer builds that remapped
 * Africa-three (NG/TD/NE) region IDs into non-existent region_sa_* paths.
 *
 * Source of truth: original cities/villages/mkan documents.
 * Shadows are marked legacy_geo_compat: true for safe later cleanup.
 *
 * DO NOT create visible region clones (would duplicate country region lists).
 * Old clients only need alias DocumentReference values for village queries.
 */

const LEGACY_GEO_VERSION = 1;
const LEGACY_GEO_COMPAT = true;
const SHADOW_LANDMARK_PREFIX = 'legacycompat_';

/** ISO country codes in scope (lowercase). */
const COMPAT_COUNTRY_CODES = Object.freeze(['ng', 'td', 'ne']);

const VILLAGE_MIRROR_FIELDS = Object.freeze([
  'naim',
  'names_i18n',
  'osf',
  'osf_i18n',
  'img',
  'lat_ling',
  'acctev',
  'country_iso',
  'naimciteText',
  'dolh',
  'noDeletePlace',
]);

const LANDMARK_MIRROR_FIELDS = Object.freeze([
  'naim',
  'osf',
  'names_i18n',
  'osf_i18n',
  'content_locale',
  'address',
  'address_i18n',
  'Location',
  'img1',
  'img2',
  'img3',
  'img',
  'img_license',
  'img_attribution',
  'images_license_verified',
  'img_source',
  'sr',
  'acctev',
  'as_ads',
  'ismzod',
  'isShrek',
  'ismsgd',
  'isfood',
  'ishmam',
  'tsnef',
  'rate',
  'add_saat',
  'ser',
  'idclassification',
  'Rev_dolh',
  'country_iso',
  'wikidata_id',
  'source_provider',
  'verification_status',
  'verification_confidence',
]);

function str(v) {
  return v == null ? '' : String(v).trim();
}

function isCompatCountryCode(code) {
  return COMPAT_COUNTRY_CODES.includes(String(code || '').toLowerCase());
}

function isLegacyCompatDoc(data) {
  return !!(data && data.legacy_geo_compat === true);
}

/**
 * city_ng_abuja → city_sa_ng_abuja
 * Returns null if not in NG/TD/NE scope.
 */
function mapOriginalVillageIdToShadow(villageId) {
  const id = str(villageId);
  const m = /^city_(ng|td|ne)_(.+)$/i.exec(id);
  if (!m) return null;
  return `city_sa_${m[1].toLowerCase()}_${m[2]}`;
}

/**
 * region_ng_abuja → region_sa_ng_abuja
 * Alias reference only — do not auto-create visible region docs.
 */
function mapOriginalRegionIdToAlias(regionId) {
  const id = str(regionId);
  const m = /^region_(ng|td|ne)_(.+)$/i.exec(id);
  if (!m) return null;
  return `region_sa_${m[1].toLowerCase()}_${m[2]}`;
}

/**
 * lm_ng_abuja_aso-rock → legacycompat_lm_ng_abuja_aso-rock
 */
function mapOriginalLandmarkIdToShadow(landmarkId) {
  const id = str(landmarkId);
  if (!id || id.startsWith(SHADOW_LANDMARK_PREFIX)) return null;
  if (!/^lm_(ng|td|ne)_/i.test(id)) return null;
  return `${SHADOW_LANDMARK_PREFIX}${id}`;
}

function pathId(pathOrRef) {
  if (!pathOrRef) return '';
  if (typeof pathOrRef === 'string') {
    const parts = pathOrRef.split('/');
    return parts[parts.length - 1] || '';
  }
  if (pathOrRef.id) return str(pathOrRef.id);
  if (pathOrRef.path) {
    const parts = String(pathOrRef.path).split('/');
    return parts[parts.length - 1] || '';
  }
  return '';
}

function pathFull(pathOrRef) {
  if (!pathOrRef) return '';
  if (typeof pathOrRef === 'string') return pathOrRef;
  if (pathOrRef.path) return String(pathOrRef.path);
  return '';
}

/**
 * True when village id belongs to Africa-three compatibility scope.
 */
function isCompatOriginalVillageId(villageId) {
  return !!mapOriginalVillageIdToShadow(villageId);
}

/**
 * True when landmark is an original Africa-three source (not a shadow).
 */
function isCompatOriginalLandmarkId(landmarkId) {
  return !!mapOriginalLandmarkIdToShadow(landmarkId);
}

/**
 * Resolve whether a village write is in scope from id and/or data.
 */
function villageInCompatScope(villageId, data) {
  if (isLegacyCompatDoc(data)) return false;
  if (isCompatOriginalVillageId(villageId)) return true;
  const iso = str(data && data.country_iso).toUpperCase();
  if (iso === 'NG' || iso === 'TD' || iso === 'NE') {
    // Only if id still matches city_<cc>_* pattern after lowercasing check
    return /^city_(ng|td|ne)_/i.test(str(villageId));
  }
  return false;
}

/**
 * Landmark in scope if id matches lm_ng|td|ne_* OR id_vill points at city_ng|td|ne_*.
 */
function landmarkInCompatScope(landmarkId, data) {
  if (isLegacyCompatDoc(data)) return false;
  if (isCompatOriginalLandmarkId(landmarkId)) return true;
  const villId = pathId(data && data.id_vill);
  if (isCompatOriginalVillageId(villId)) return true;
  const iso = str(data && data.country_iso).toUpperCase();
  if ((iso === 'NG' || iso === 'TD' || iso === 'NE') &&
      /^lm_(ng|td|ne)_/i.test(str(landmarkId))) {
    return true;
  }
  return false;
}

function pickFields(data, fields) {
  const out = {};
  if (!data) return out;
  for (const key of fields) {
    if (Object.prototype.hasOwnProperty.call(data, key) && data[key] !== undefined) {
      out[key] = data[key];
    }
  }
  return out;
}

function resolveAliasRegionFromVillageData(db, villageId, data) {
  const citiesPath = pathFull(data && data.cities);
  const regionId = pathId(citiesPath) || '';
  const aliasRegionId = mapOriginalRegionIdToAlias(regionId);
  if (aliasRegionId) {
    return db.doc(`cities/${aliasRegionId}`);
  }
  // Fallback: derive from village id city_ng_x → region_sa_ng_x is wrong;
  // only remap known region id. If cities already alias, keep it.
  if (/^region_sa_(ng|td|ne)_/i.test(regionId)) {
    return db.doc(`cities/${regionId}`);
  }
  // Last resort from village suffix: city_ng_abuja → region_sa_ng_abuja
  const vm = /^city_(ng|td|ne)_(.+)$/i.exec(str(villageId));
  if (vm) {
    return db.doc(`cities/region_sa_${vm[1].toLowerCase()}_${vm[2]}`);
  }
  return null;
}

function buildShadowVillagePayload(db, villageId, data) {
  const shadowId = mapOriginalVillageIdToShadow(villageId);
  if (!shadowId) return null;
  const aliasRegionRef = resolveAliasRegionFromVillageData(db, villageId, data);
  if (!aliasRegionRef) return null;

  const payload = {
    ...pickFields(data, VILLAGE_MIRROR_FIELDS),
    cities: aliasRegionRef,
    legacy_geo_compat: LEGACY_GEO_COMPAT,
    legacy_geo_source_path: `villages/${villageId}`,
    legacy_geo_version: LEGACY_GEO_VERSION,
    legacy_geo_updated_at: new Date().toISOString(),
  };
  return {shadowId, payload};
}

function resolveShadowVillageRefForLandmark(db, landmarkId, data) {
  const villId = pathId(data && data.id_vill);
  const shadowVillageId = mapOriginalVillageIdToShadow(villId);
  if (shadowVillageId) {
    return {
      shadowVillageRef: db.doc(`villages/${shadowVillageId}`),
      aliasRegionRef: (() => {
        const citId = pathId(data && data.id_cit);
        const alias = mapOriginalRegionIdToAlias(citId);
        if (alias) return db.doc(`cities/${alias}`);
        const vm = /^city_(ng|td|ne)_(.+)$/i.exec(villId);
        if (vm) {
          return db.doc(`cities/region_sa_${vm[1].toLowerCase()}_${vm[2]}`);
        }
        return null;
      })(),
    };
  }
  // Derive from landmark id lm_ng_abuja_* → city_sa_ng_abuja
  const lm = /^lm_(ng|td|ne)_([^_]+)_/i.exec(str(landmarkId));
  if (lm) {
    const cc = lm[1].toLowerCase();
    const citySlug = lm[2];
    return {
      shadowVillageRef: db.doc(`villages/city_sa_${cc}_${citySlug}`),
      aliasRegionRef: db.doc(`cities/region_sa_${cc}_${citySlug}`),
    };
  }
  return null;
}

function buildShadowLandmarkPayload(db, landmarkId, data) {
  const shadowId = mapOriginalLandmarkIdToShadow(landmarkId);
  if (!shadowId) return null;
  const resolved = resolveShadowVillageRefForLandmark(db, landmarkId, data);
  if (!resolved || !resolved.shadowVillageRef) return null;

  const payload = {
    ...pickFields(data, LANDMARK_MIRROR_FIELDS),
    id_vill: resolved.shadowVillageRef,
    // Point id_cit at alias region so NEW app region counts (id_cit ==
    // original region) do not double-count shadows.
    id_cit: resolved.aliasRegionRef || null,
    legacy_geo_compat: LEGACY_GEO_COMPAT,
    legacy_geo_source_path: `mkan/${landmarkId}`,
    legacy_geo_version: LEGACY_GEO_VERSION,
    legacy_geo_updated_at: new Date().toISOString(),
  };
  return {shadowId, payload};
}

/**
 * Sync one village write into its shadow. Idempotent.
 * Returns {action, shadowPath} or {action:'skip', reason}.
 */
async function syncVillageShadow(db, villageId, beforeData, afterData) {
  if (afterData && isLegacyCompatDoc(afterData)) {
    return {action: 'skip', reason: 'shadow_doc'};
  }
  if (beforeData && !afterData) {
    // Delete
    if (isLegacyCompatDoc(beforeData)) {
      return {action: 'skip', reason: 'shadow_delete'};
    }
    if (!villageInCompatScope(villageId, beforeData)) {
      return {action: 'skip', reason: 'out_of_scope'};
    }
    const shadowId = mapOriginalVillageIdToShadow(villageId);
    if (!shadowId) return {action: 'skip', reason: 'no_shadow_id'};
    const shadowRef = db.collection('villages').doc(shadowId);
    const snap = await shadowRef.get();
    if (snap.exists) {
      await shadowRef.delete();
      return {action: 'deleted', shadowPath: shadowRef.path};
    }
    return {action: 'noop', shadowPath: shadowRef.path};
  }

  if (!villageInCompatScope(villageId, afterData)) {
    return {action: 'skip', reason: 'out_of_scope'};
  }
  const built = buildShadowVillagePayload(db, villageId, afterData);
  if (!built) return {action: 'skip', reason: 'cannot_build'};
  const shadowRef = db.collection('villages').doc(built.shadowId);
  await shadowRef.set(built.payload, {merge: true});
  return {action: 'upserted', shadowPath: shadowRef.path};
}

/**
 * Sync one landmark write into its shadow. Idempotent.
 */
async function syncLandmarkShadow(db, landmarkId, beforeData, afterData) {
  if (afterData && isLegacyCompatDoc(afterData)) {
    return {action: 'skip', reason: 'shadow_doc'};
  }
  if (beforeData && !afterData) {
    if (isLegacyCompatDoc(beforeData)) {
      return {action: 'skip', reason: 'shadow_delete'};
    }
    if (!landmarkInCompatScope(landmarkId, beforeData)) {
      return {action: 'skip', reason: 'out_of_scope'};
    }
    const shadowId = mapOriginalLandmarkIdToShadow(landmarkId);
    if (!shadowId) return {action: 'skip', reason: 'no_shadow_id'};
    const shadowRef = db.collection('mkan').doc(shadowId);
    const snap = await shadowRef.get();
    if (snap.exists) {
      await shadowRef.delete();
      return {action: 'deleted', shadowPath: shadowRef.path};
    }
    return {action: 'noop', shadowPath: shadowRef.path};
  }

  if (!landmarkInCompatScope(landmarkId, afterData)) {
    return {action: 'skip', reason: 'out_of_scope'};
  }
  const built = buildShadowLandmarkPayload(db, landmarkId, afterData);
  if (!built) return {action: 'skip', reason: 'cannot_build'};
  const shadowRef = db.collection('mkan').doc(built.shadowId);
  await shadowRef.set(built.payload, {merge: true});
  return {action: 'upserted', shadowPath: shadowRef.path};
}

/**
 * Simulate old Customer remaps for verification helpers.
 */
function simulateOldClientRegionId(regionId) {
  const id = str(regionId);
  if (id.startsWith('region_sa_') ||
      id.startsWith('region_kg_') ||
      id.startsWith('region_uz_') ||
      id.startsWith('region_ru_') ||
      /^region_(es|ma|pt|tn|id|my|in)_/i.test(id)) {
    return id;
  }
  const legacy = /^region_(.+)$/i.exec(id);
  if (!legacy) return id;
  const slug = legacy[1].toLowerCase();
  if (/^(kg|uz|ru|sa|es|ma|pt|tn|id|my|in)_/.test(slug)) return id;
  // OLD BUG: ng_/td_/ne_ fall through to Saudi remap
  return `region_sa_${slug}`;
}

module.exports = {
  LEGACY_GEO_VERSION,
  LEGACY_GEO_COMPAT,
  SHADOW_LANDMARK_PREFIX,
  COMPAT_COUNTRY_CODES,
  VILLAGE_MIRROR_FIELDS,
  LANDMARK_MIRROR_FIELDS,
  isLegacyCompatDoc,
  isCompatCountryCode,
  mapOriginalVillageIdToShadow,
  mapOriginalRegionIdToAlias,
  mapOriginalLandmarkIdToShadow,
  isCompatOriginalVillageId,
  isCompatOriginalLandmarkId,
  villageInCompatScope,
  landmarkInCompatScope,
  buildShadowVillagePayload,
  buildShadowLandmarkPayload,
  syncVillageShadow,
  syncLandmarkShadow,
  simulateOldClientRegionId,
  pathId,
  pathFull,
};
