'use strict';

/**
 * Canonical country doc resolution for driver registration submit.
 * Keeps client Rev_dolh aliases aligned with countries/{preferredId}.
 */

const PREFERRED_ID_BY_ISO = {
  SA: 'saudi_arabia',
  KG: 'kyrgyzstan',
  RU: 'russia',
  UZ: 'uzbekistan',
};

const ALIAS_IDS_BY_ISO = {
  SA: new Set(['country_sa', 'saudi_arabia', 'saudi-arabia', 'saudiarabia']),
  KG: new Set(['country_kg', 'kyrgyzstan']),
  RU: new Set(['country_ru', 'russia']),
  UZ: new Set(['country_uz', 'uzbekistan']),
};

function normalizeIso(raw) {
  if (!raw || typeof raw !== 'string') return null;
  const t = raw.trim();
  if (!t) return null;
  const upper = t.toUpperCase();
  if (/^[A-Z]{2}$/.test(upper)) return upper;
  const lower = t.toLowerCase();
  for (const [iso, ids] of Object.entries(ALIAS_IDS_BY_ISO)) {
    if (ids.has(lower)) return iso;
  }
  if (lower.includes('saudi')) return 'SA';
  if (lower.includes('kyrgyz') || lower.includes('kg')) return 'KG';
  return null;
}

function candidateCountryPaths(countryRef) {
  if (!countryRef || !countryRef.path) return [];
  const paths = new Set([countryRef.path]);
  const id = countryRef.id || countryRef.path.split('/').pop();
  const iso = normalizeIso(id);
  if (iso && PREFERRED_ID_BY_ISO[iso]) {
    paths.add(`countries/${PREFERRED_ID_BY_ISO[iso]}`);
  }
  if (iso && ALIAS_IDS_BY_ISO[iso]) {
    for (const alias of ALIAS_IDS_BY_ISO[iso]) {
      paths.add(`countries/${alias}`);
    }
  }
  return [...paths];
}

/**
 * @param {FirebaseFirestore.Transaction} tx
 * @param {FirebaseFirestore.Firestore} db
 * @param {FirebaseFirestore.DocumentReference} countryRef
 * @param {(reqs: object|null) => boolean} isEnabled
 */
async function resolveCountryRequirements(tx, db, countryRef, isEnabled) {
  if (!countryRef) {
    return {countryRef: null, countryReqs: null, countryPath: null};
  }
  const paths = candidateCountryPaths(countryRef);
  let lastReqs = null;
  let lastPath = countryRef.path;
  for (const path of paths) {
    const snap = await tx.get(db.doc(path));
    const reqs = snap.exists ? (snap.data() || {}).driver_requirements : null;
    lastReqs = reqs;
    lastPath = path;
    if (isEnabled(reqs)) {
      return {
        countryRef: db.doc(path),
        countryReqs: reqs,
        countryPath: path,
      };
    }
  }
  return {
    countryRef,
    countryReqs: lastReqs,
    countryPath: lastPath,
  };
}

module.exports = {
  normalizeIso,
  candidateCountryPaths,
  resolveCountryRequirements,
  PREFERRED_ID_BY_ISO,
};
