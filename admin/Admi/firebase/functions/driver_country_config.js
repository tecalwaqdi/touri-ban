'use strict';

/**
 * Canonical Driver country configuration — baseline init, readiness, audits.
 * Shared by submit, triggers, callables, and migration scripts.
 */

const countryResolver = require('./driver_country_resolver.js');

const DRIVER_REQUIREMENTS_VERSION = 1;

const KNOWN_DOC_TYPES = [
  'profilePhoto',
  'nationalId',
  'vehicleRegistration',
  'driverLicense',
  'vehicleInsurance',
];

/** Touri onboarding baseline — not a legal claim. operationalBlockingOnExpiry=false on auto-seed. */
function operationalBaseline() {
  return {
    profilePhoto: {
      enabled: true,
      required: true,
      expiryRequired: false,
      operationalBlockingOnExpiry: false,
      expiryWarningDays: 30,
      effectiveFrom: null,
      gracePeriodDays: null,
      displayOrder: 0,
    },
    nationalId: {
      enabled: true,
      required: true,
      expiryRequired: false,
      operationalBlockingOnExpiry: false,
      expiryWarningDays: 30,
      effectiveFrom: null,
      gracePeriodDays: null,
      displayOrder: 1,
    },
    vehicleRegistration: {
      enabled: true,
      required: true,
      expiryRequired: true,
      operationalBlockingOnExpiry: false,
      expiryWarningDays: 30,
      effectiveFrom: null,
      gracePeriodDays: null,
      displayOrder: 2,
    },
    driverLicense: {
      enabled: true,
      required: true,
      expiryRequired: true,
      operationalBlockingOnExpiry: false,
      expiryWarningDays: 30,
      effectiveFrom: null,
      gracePeriodDays: null,
      displayOrder: 3,
    },
    vehicleInsurance: {
      enabled: true,
      required: false,
      expiryRequired: false,
      operationalBlockingOnExpiry: false,
      expiryWarningDays: 30,
      effectiveFrom: null,
      gracePeriodDays: null,
      displayOrder: 4,
    },
  };
}

function countEnabledRequirements(reqs) {
  if (!reqs || typeof reqs !== 'object') return 0;
  return Object.values(reqs).filter(
    (v) => v && typeof v === 'object' && v.enabled === true,
  ).length;
}

function classifyRequirements(reqs) {
  if (reqs == null) return 'missing';
  if (typeof reqs !== 'object' || Array.isArray(reqs)) return 'malformed';
  if (Object.keys(reqs).length === 0) return 'empty';
  const enabled = countEnabledRequirements(reqs);
  if (enabled > 0) return 'configured';
  return 'empty';
}

function sanitizeRequirementsForLog(reqs) {
  if (!reqs || typeof reqs !== 'object') return {};
  const out = {};
  for (const [k, v] of Object.entries(reqs)) {
    if (!v || typeof v !== 'object') continue;
    out[k] = {
      enabled: v.enabled === true,
      required: v.required === true,
      expiryRequired: v.expiryRequired === true,
      operationalBlockingOnExpiry: v.operationalBlockingOnExpiry === true,
    };
  }
  return out;
}

/**
 * Returns patch map or null when custom config must be preserved.
 */
function buildInitializationPatch(existing) {
  const status = classifyRequirements(existing);
  if (status === 'configured') return null;
  if (status === 'malformed') return null;
  return operationalBaseline();
}

function isActiveTypeCar(data) {
  if (!data || typeof data !== 'object') return false;
  if (Object.prototype.hasOwnProperty.call(data, 'actev')) {
    return data.actev === true;
  }
  if (Object.prototype.hasOwnProperty.call(data, 'acctev')) {
    return data.acctev === true;
  }
  return true;
}

function matchesCountryTypeCar(data, countryPath, iso2) {
  const iso = (iso2 || '').trim().toUpperCase();
  const myIso = String(data.country_iso2 || '')
    .trim()
    .toUpperCase();
  if (myIso && iso && myIso === iso) return true;
  const dolhPath =
    data.dolh && data.dolh.path ? data.dolh.path : data.dolh || null;
  if (dolhPath && countryPath && dolhPath === countryPath) return true;
  if (dolhPath && iso) {
    const dolhId = String(dolhPath).split('/').pop();
    const dolhIso = countryResolver.normalizeIso(dolhId);
    if (dolhIso && dolhIso === iso) return true;
  }
  if (!dolhPath && !myIso) return false;
  return false;
}

async function countActiveVehiclesForCountry(db, countryPath, iso2) {
  const snap = await db.collection('type_car').get();
  let count = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (!isActiveTypeCar(data)) continue;
    if (matchesCountryTypeCar(data, countryPath, iso2)) count++;
  }
  return count;
}

function resolveCountryIso(countryId, countryData) {
  const fromDoc = String(countryData?.iso_code || countryData?.country_iso2 || '')
    .trim()
    .toUpperCase();
  if (fromDoc) return fromDoc;
  return countryResolver.normalizeIso(countryId) || '';
}

function evaluateMarketReadiness({enabledRequirements, activeVehicles, acctev}) {
  const active = acctev !== false;
  if (!active) {
    return {
      registrationReady: false,
      reasonCode: 'COUNTRY_INACTIVE',
      status: 'INCOMPLETE',
    };
  }
  if (enabledRequirements <= 0) {
    return {
      registrationReady: false,
      reasonCode: 'MISSING_DRIVER_REQUIREMENTS',
      status: 'MISSING_DRIVER_REQUIREMENTS',
    };
  }
  if (activeVehicles <= 0) {
    return {
      registrationReady: false,
      reasonCode: 'MISSING_VEHICLE_CATALOG',
      status: 'MISSING_VEHICLE_CATALOG',
    };
  }
  return {
    registrationReady: true,
    reasonCode: 'READY',
    status: 'READY',
  };
}

async function auditCountryMarket(db, countryId, countryData) {
  const countryPath = `countries/${countryId}`;
  const iso2 = resolveCountryIso(countryId, countryData);
  const reqStatus = classifyRequirements(countryData?.driver_requirements);
  const enabledRequirements = countEnabledRequirements(
    countryData?.driver_requirements,
  );
  const activeVehicles = await countActiveVehiclesForCountry(
    db,
    countryPath,
    iso2,
  );
  const readiness = evaluateMarketReadiness({
    enabledRequirements,
    activeVehicles,
    acctev: countryData?.acctev,
  });
  return {
    countryId,
    countryPath,
    iso2,
    requirementsStatus: reqStatus,
    enabledRequirements,
    activeVehicles,
    ...readiness,
  };
}

/**
 * Idempotent initialization for one country document.
 */
async function ensureDriverCountryConfiguration(db, countryRef, options = {}) {
  const dryRun = options.dryRun === true;
  const actor = options.actor || 'system';
  const ref = typeof countryRef === 'string' ? db.doc(countryRef) : countryRef;
  if (!ref || !ref.path) {
    return {ok: false, action: 'invalid_ref', countryPath: null};
  }

  const snap = await ref.get();
  if (!snap.exists) {
    return {ok: false, action: 'not_found', countryPath: ref.path};
  }

  const before = snap.data() || {};
  const beforeEnabled = countEnabledRequirements(before.driver_requirements);
  const patch = buildInitializationPatch(before.driver_requirements);
  const reqStatus = classifyRequirements(before.driver_requirements);

  if (patch == null) {
    return {
      ok: true,
      action: reqStatus === 'malformed' ? 'malformed_preserved' : 'preserved',
      countryPath: ref.path,
      beforeEnabled,
      afterEnabled: beforeEnabled,
      customConfigPreserved: true,
    };
  }

  if (dryRun) {
    return {
      ok: true,
      action: 'would_initialize',
      countryPath: ref.path,
      beforeEnabled,
      afterEnabled: countEnabledRequirements(patch),
      customConfigPreserved: false,
    };
  }

  const now = new Date().toISOString();
  await ref.set(
    {
      driver_requirements: patch,
      driver_requirements_version: DRIVER_REQUIREMENTS_VERSION,
      driver_requirements_initialized_at: now,
      driver_requirements_initialized_by: actor,
    },
    {merge: true},
  );

  console.log(
    JSON.stringify({
      event: 'DRIVER_COUNTRY_CONFIG_AUTO_INITIALIZED',
      countryPath: ref.path,
      configVersion: DRIVER_REQUIREMENTS_VERSION,
      actor,
    }),
  );

  return {
    ok: true,
    action: 'initialized',
    countryPath: ref.path,
    beforeEnabled,
    afterEnabled: countEnabledRequirements(patch),
    customConfigPreserved: false,
  };
}

async function ensureAllDriverCountryConfigurations(db, options = {}) {
  const dryRun = options.dryRun === true;
  const actor = options.actor || 'system';
  const snap = await db.collection('countries').get();
  const summary = {
    countriesTotal: snap.size,
    configured: 0,
    empty: 0,
    missing: 0,
    malformed: 0,
    wouldInitialize: 0,
    initialized: 0,
    preserved: 0,
    results: [],
  };

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const status = classifyRequirements(data.driver_requirements);
    if (status === 'configured') summary.configured++;
    else if (status === 'empty') summary.empty++;
    else if (status === 'missing') summary.missing++;
    else if (status === 'malformed') summary.malformed++;

    const result = await ensureDriverCountryConfiguration(db, doc.ref, {
      dryRun,
      actor,
    });
    summary.results.push(result);
    if (result.action === 'would_initialize') summary.wouldInitialize++;
    if (result.action === 'initialized') summary.initialized++;
    if (result.action === 'preserved' || result.action === 'malformed_preserved') {
      summary.preserved++;
    }
  }

  return summary;
}

function validateTypeCarForMarket(typeCarData, countryPath, iso2) {
  if (!typeCarData) return {ok: false, reasonCode: 'VEHICLE_TYPE_UNAVAILABLE'};
  if (!isActiveTypeCar(typeCarData)) {
    return {ok: false, reasonCode: 'VEHICLE_TYPE_UNAVAILABLE'};
  }
  if (!matchesCountryTypeCar(typeCarData, countryPath, iso2)) {
    return {ok: false, reasonCode: 'VEHICLE_TYPE_MARKET_MISMATCH'};
  }
  return {ok: true, reasonCode: 'ok'};
}

module.exports = {
  DRIVER_REQUIREMENTS_VERSION,
  KNOWN_DOC_TYPES,
  operationalBaseline,
  countEnabledRequirements,
  classifyRequirements,
  sanitizeRequirementsForLog,
  buildInitializationPatch,
  ensureDriverCountryConfiguration,
  ensureAllDriverCountryConfigurations,
  auditCountryMarket,
  auditAllCountriesMarketReadiness: async (db) => {
    const snap = await db.collection('countries').get();
    const rows = [];
    for (const doc of snap.docs) {
      rows.push(await auditCountryMarket(db, doc.id, doc.data() || {}));
    }
    return rows;
  },
  validateTypeCarForMarket,
  resolveCountryIso,
  evaluateMarketReadiness,
  isActiveTypeCar,
  matchesCountryTypeCar,
};
