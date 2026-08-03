'use strict';

/**
 * Emulator-only Firestore importer.
 * HARD RULE: refuses to write unless FIRESTORE_EMULATOR_HOST is set
 * and --target=emulator is passed. Never touches Production.
 */

const fs = require('fs');
const path = require('path');
const { buildImportPlan } = require('./firestore_mapper');

const ROOT = path.join(__dirname, '..');
const COLLECTED = path.join(ROOT, 'datasets', 'collected');
const REPORTS = path.join(ROOT, 'reports');

function loadCollected(countryKey) {
  const p = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function assertEmulatorSafe(args) {
  if (args.environment === 'production' || args.target === 'production') {
    throw new Error('Refusing production write. Use --target=emulator only.');
  }
  if (args.target !== 'emulator') {
    throw new Error(
      'Import requires --target=emulator. Production and staging cloud writes are blocked in this toolkit.',
    );
  }
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error(
      'FIRESTORE_EMULATOR_HOST is not set. Start emulators first, e.g. 127.0.0.1:8080',
    );
  }
}

function toAdminValue(db, admin, value, fieldHint) {
  if (value == null) return value;
  if (
    typeof value === 'object' &&
    typeof value.latitude === 'number' &&
    typeof value.longitude === 'number' &&
    Object.keys(value).length === 2
  ) {
    return new admin.firestore.GeoPoint(value.latitude, value.longitude);
  }
  // Document path strings for relation fields → DocumentReference
  if (
    typeof value === 'string' &&
    /^(countries|cities|villages|mkan|type_car)\//.test(value) &&
    ['dolh', 'cities', 'id_cit', 'id_vill', 'Rev_dolh'].includes(fieldHint)
  ) {
    return db.doc(value);
  }
  return value;
}

function prepareData(db, admin, data) {
  const out = {};
  for (const [k, v] of Object.entries(data)) {
    out[k] = toAdminValue(db, admin, v, k);
  }
  out.dataAdd = admin.firestore.FieldValue.serverTimestamp();
  out.verified_at = admin.firestore.FieldValue.serverTimestamp();
  return out;
}

async function writePlan(plan, { merge = true } = {}) {
  // Prefer local firebase-admin from functions, then geo_import node_modules
  let admin;
  const candidates = [
    path.join(ROOT, '..', '..', 'functions', 'node_modules', 'firebase-admin'),
    path.join(ROOT, 'node_modules', 'firebase-admin'),
    'firebase-admin',
  ];
  let lastErr;
  for (const c of candidates) {
    try {
      admin = require(c);
      break;
    } catch (e) {
      lastErr = e;
    }
  }
  if (!admin) throw lastErr || new Error('firebase-admin not found');

  if (!admin.apps.length) {
    admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'touri-geo-emulator' });
  }
  const db = admin.firestore();

  let written = 0;
  let batches = 0;
  const BATCH_SIZE = 400;
  let batch = db.batch();
  let inBatch = 0;

  for (const doc of plan.docs) {
    const [collection, ...idParts] = doc.path.split('/');
    const id = idParts.join('/');
    const ref = db.collection(collection).doc(id);
    const data = prepareData(db, admin, doc.data);
    if (merge) batch.set(ref, data, { merge: true });
    else batch.set(ref, data);
    inBatch += 1;
    written += 1;
    if (inBatch >= BATCH_SIZE) {
      await batch.commit();
      batches += 1;
      batch = db.batch();
      inBatch = 0;
      process.stdout.write(`  committed ${written}/${plan.docs.length}\n`);
    }
  }
  if (inBatch > 0) {
    await batch.commit();
    batches += 1;
  }

  return { written, batches, emulatorHost: process.env.FIRESTORE_EMULATOR_HOST };
}

function buildPlanFromDisk(countries) {
  const collectedByCountry = {};
  for (const key of countries) {
    const data = loadCollected(key);
    if (data) collectedByCountry[key] = data;
  }
  return buildImportPlan({
    collectedByCountry,
    countries,
    includeVehicles: true,
  });
}

async function importToEmulator(args = {}) {
  assertEmulatorSafe(args);
  const countries = String(args.country || 'ALL')
    .toUpperCase()
    .split(',')
    .flatMap((c) => (c === 'ALL' ? ['SA', 'KG', 'UZ', 'RU'] : [c.trim()]));

  const plan = buildPlanFromDisk(countries);
  fs.mkdirSync(REPORTS, { recursive: true });
  const previewPath = path.join(REPORTS, 'emulator_import_plan.json');
  fs.writeFileSync(
    previewPath,
    JSON.stringify(
      {
        ...plan,
        docs: plan.docs.map((d) => ({ path: d.path, keys: Object.keys(d.data) })),
      },
      null,
      2,
    ),
    'utf8',
  );

  if (args['dry-run'] || args.previewOnly) {
    return {
      mode: 'preview',
      wouldWriteToFirestore: false,
      planFile: previewPath,
      stats: plan.stats,
      docCount: plan.docs.length,
    };
  }

  const result = await writePlan(plan, { merge: true });
  const report = {
    mode: 'emulator-write',
    wouldWriteToProduction: false,
    emulatorHost: result.emulatorHost,
    stats: plan.stats,
    written: result.written,
    batches: result.batches,
    planFile: previewPath,
    finishedAt: new Date().toISOString(),
  };
  const out = path.join(REPORTS, 'emulator_import_result.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  report.resultFile = out;
  return report;
}

module.exports = {
  importToEmulator,
  buildPlanFromDisk,
  assertEmulatorSafe,
};
