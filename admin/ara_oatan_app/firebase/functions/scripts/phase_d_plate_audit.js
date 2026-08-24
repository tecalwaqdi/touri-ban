/**
 * Read-only plate uniqueness audit (no PII printed).
 *
 * Auth: Google Application Default Credentials (firebase-admin default).
 *   gcloud auth application-default login --project tutorial-multi-language-70gx4j
 *
 * Usage:
 *   node scripts/phase_d_plate_audit.js
 */
'use strict';

const crypto = require('crypto');
const admin = require('firebase-admin');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();

function normalize(raw) {
  return String(raw || '')
    .trim()
    .toUpperCase()
    .replace(/[\s-]/g, '');
}

function plateHashPrefix(plate) {
  return crypto.createHash('sha256').update(plate).digest('hex').slice(0, 8);
}

function isV2(data) {
  return Number(data.registration_flow_version || 0) === 2;
}

function classifyDuplicateGroup(entries) {
  const v2 = entries.filter((e) => e.v2).length;
  const legacy = entries.length - v2;
  if (v2 >= 2 && legacy === 0) return 'v2_v2';
  if (v2 >= 1 && legacy >= 1) return 'v2_legacy';
  return 'legacy_legacy';
}

async function main() {
  const snap = await db.collection('user').where('ismndob', '==', true).get();

  const byPlate = new Map();
  let missingPlate = 0;
  let withPlate = 0;
  let normalizedFieldPresent = 0;
  let normalizedFieldMissing = 0;

  for (const doc of snap.docs) {
    const d = doc.data() || {};
    const rawPlate = String(d.normalized_plate || d.number_lohh_car || '').trim();
    if (String(d.normalized_plate || '').trim()) {
      normalizedFieldPresent++;
    } else {
      normalizedFieldMissing++;
    }

    const plate = normalize(rawPlate);
    if (!plate) {
      missingPlate++;
      continue;
    }
    withPlate++;

    const entry = {
      idPrefix: doc.id.slice(0, 6),
      v2: isV2(d),
    };
    if (!byPlate.has(plate)) byPlate.set(plate, []);
    byPlate.get(plate).push(entry);
  }

  const duplicateGroups = [...byPlate.entries()].filter(([, ids]) => ids.length > 1);
  const classification = {v2_v2: 0, v2_legacy: 0, legacy_legacy: 0};
  let affectedLegacyDrivers = 0;

  for (const [, entries] of duplicateGroups) {
    const kind = classifyDuplicateGroup(entries);
    classification[kind]++;
    affectedLegacyDrivers += entries.filter((e) => !e.v2).length;
  }

  const report = {
    ADC_AUTH: 'PASS',
    PROJECT_MATCH: PROJECT_ID,
    TOTAL_DRIVER_RECORDS_WITH_PLATE: withPlate,
    MISSING_PLATE: missingPlate,
    NORMALIZED_PLATE_PRESENT: normalizedFieldPresent,
    NORMALIZED_PLATE_MISSING: normalizedFieldMissing,
    UNIQUE_NORMALIZED_PLATES: byPlate.size,
    DUPLICATE_NORMALIZED_PLATE_GROUPS: duplicateGroups.length,
    AFFECTED_LEGACY_DRIVERS: affectedLegacyDrivers,
    DUPLICATE_CLASSIFICATION: classification,
    LEGACY_DUPLICATE_PLATES_REVIEW_REQUIRED: duplicateGroups.length > 0,
    sampleDuplicateHashes: duplicateGroups.slice(0, 20).map(([plate, entries]) => ({
      plateHashPrefix: plateHashPrefix(plate),
      count: entries.length,
      kind: classifyDuplicateGroup(entries),
    })),
    totalDriversQueried: snap.size,
  };

  console.log(JSON.stringify(report, null, 2));
}

main().catch((e) => {
  const msg = String((e && e.message) || e);
  if (/invalid_grant|reauth|Getting metadata from plugin/i.test(msg)) {
    console.error(
      JSON.stringify(
        {
          ADC_AUTH: 'BLOCKED_INTERACTIVE_REAUTH_REQUIRED',
          PROJECT_MATCH: PROJECT_ID,
          hint: 'Run: gcloud auth application-default login --project tutorial-multi-language-70gx4j',
        },
        null,
        2,
      ),
    );
  } else {
    console.error('PLATE_AUDIT_BLOCKED', msg.slice(0, 200));
  }
  process.exit(1);
});
