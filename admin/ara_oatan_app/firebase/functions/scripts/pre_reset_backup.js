'use strict';

/**
 * Pre-reset local backup (Admin SDK JSON export).
 * Used when gcloud firestore export is unavailable.
 * Does NOT delete anything.
 *
 * Writes under:
 *   qa_master_audit/pre_reset/backup/<timestamp>/
 */

process.env.GCLOUD_PROJECT = 'tutorial-multi-language-70gx4j';

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const ROOT = '/Users/ventura/ara-ban/qa_master_audit/pre_reset';
const TS = new Date().toISOString().replace(/[:.]/g, '-');
const OUT = path.join(ROOT, 'backup', TS);

const PRESERVE_COLLECTIONS = [
  'countries',
  'regions',
  'cities',
  'villages',
  'mkan',
  'type_car',
  'transport_company',
  'Settings',
  'wallets',
  'financial_aggregation_metrics',
  'PaymentMethods',
  'Paymenthistory',
  'payment_sessions',
  'company_payments',
  'admin_audit_log',
  // UNKNOWN kept for safety snapshot (not delete targets)
  'Classification',
  'ExtraHours',
  'auto_num',
  'bank',
  'mndob',
  'suprt',
  'transactions',
];

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();
const auth = admin.auth();

function serializeValue(v) {
  if (v == null) return v;
  if (typeof v.toDate === 'function') return {_ts: v.toDate().toISOString()};
  if (v._latitude != null && v._longitude != null) {
    return {_geo: {lat: v._latitude, lng: v._longitude}};
  }
  if (v.path && typeof v.path === 'string') return {_ref: v.path};
  if (Array.isArray(v)) return v.map(serializeValue);
  if (typeof v === 'object') {
    const out = {};
    for (const [k, val] of Object.entries(v)) out[k] = serializeValue(val);
    return out;
  }
  return v;
}

async function exportCollection(name) {
  const snap = await db.collection(name).get();
  const docs = {};
  for (const d of snap.docs) {
    docs[d.id] = serializeValue(d.data());
  }
  return {count: snap.size, docs};
}

async function exportAuth() {
  const users = [];
  let pageToken;
  do {
    const res = await auth.listUsers(1000, pageToken);
    for (const u of res.users) {
      users.push({
        uid: u.uid,
        email: u.email || null,
        phoneNumber: u.phoneNumber || null,
        disabled: u.disabled === true,
        customClaims: u.customClaims || {},
        createdAt: u.metadata?.creationTime || null,
        lastSignIn: u.metadata?.lastSignInTime || null,
      });
    }
    pageToken = res.pageToken;
  } while (pageToken);
  return users;
}

async function exportStorageInventory() {
  try {
    const bucket = admin.storage().bucket(
      'tutorial-multi-language-70gx4j.firebasestorage.app',
    );
    const [files] = await bucket.getFiles({maxResults: 5000});
    return {
      bucket: bucket.name,
      count: files.length,
      capped: files.length >= 5000,
      objects: files.map((f) => ({
        name: f.name,
        size: f.metadata?.size || null,
        contentType: f.metadata?.contentType || null,
        updated: f.metadata?.updated || null,
      })),
    };
  } catch (e) {
    return {error: String(e.message || e)};
  }
}

async function main() {
  fs.mkdirSync(OUT, {recursive: true});
  const manifest = {
    BACKUP_CREATED: true,
    BACKUP_TYPE: 'LOCAL_ADMIN_SDK_JSON_EXPORT',
    BACKUP_PROJECT: PROJECT_ID,
    BACKUP_TIMESTAMP: new Date().toISOString(),
    BACKUP_LOCATION: OUT,
    NOTE:
      'gcloud firestore export failed (auth reauth required). This is a local Admin SDK dump of preserve/unknown collections + full Auth metadata + Storage object inventory. Not a GCS managed export. RESET_EXECUTION_ALLOWED remains false until Owner confirms or GCS export succeeds.',
    FIRESTORE_BACKUP: null,
    AUTH_BACKUP_OR_EXPORT_REFERENCE: null,
    STORAGE_BACKUP_OR_INVENTORY: null,
    collections: {},
  };

  for (const name of PRESERVE_COLLECTIONS) {
    process.stderr.write(`export ${name}...\n`);
    try {
      const data = await exportCollection(name);
      fs.writeFileSync(
        path.join(OUT, `firestore_${name}.json`),
        JSON.stringify(data, null, 2),
      );
      manifest.collections[name] = {count: data.count, ok: true};
    } catch (e) {
      manifest.collections[name] = {ok: false, error: String(e.message || e)};
    }
  }

  process.stderr.write('export auth...\n');
  const authUsers = await exportAuth();
  fs.writeFileSync(
    path.join(OUT, 'auth_users_export.json'),
    JSON.stringify({count: authUsers.length, users: authUsers}, null, 2),
  );
  manifest.AUTH_BACKUP_OR_EXPORT_REFERENCE = path.join(
    OUT,
    'auth_users_export.json',
  );

  process.stderr.write('export storage inventory...\n');
  const storage = await exportStorageInventory();
  fs.writeFileSync(
    path.join(OUT, 'storage_inventory_export.json'),
    JSON.stringify(storage, null, 2),
  );
  manifest.STORAGE_BACKUP_OR_INVENTORY = path.join(
    OUT,
    'storage_inventory_export.json',
  );

  // Copy latest inventory evidence into backup folder
  for (const f of [
    'firestore_collection_inventory.json',
    'auth_inventory.json',
    'geo_catalog_fingerprint.json',
    'storage_inventory.json',
    'hard_denylist.json',
    'pre_reset_inventory_report.json',
    'pre_reset_manifest.json',
    'functional_baseline_snapshot.json',
  ]) {
    const src = path.join(ROOT, f);
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, path.join(OUT, f));
    }
  }

  manifest.FIRESTORE_BACKUP = {
    type: 'local_json_per_collection',
    location: OUT,
    collectionFiles: Object.keys(manifest.collections).map(
      (c) => `firestore_${c}.json`,
    ),
    gcsManagedExport: false,
    gcsError:
      'gcloud firestore export blocked: Reauthentication failed (non-interactive)',
  };

  // Reliable for dry-run evidence; NOT sufficient to allow --execute
  manifest.BACKUP_RELIABLE_FOR_EXECUTE = false;
  manifest.BACKUP_RELIABLE_FOR_DRY_RUN_EVIDENCE = true;

  fs.writeFileSync(
    path.join(OUT, 'backup_manifest.json'),
    JSON.stringify(manifest, null, 2),
  );
  fs.writeFileSync(
    path.join(ROOT, 'backup_latest.json'),
    JSON.stringify(
      {
        BACKUP_CREATED: true,
        BACKUP_PROJECT: PROJECT_ID,
        BACKUP_TIMESTAMP: manifest.BACKUP_TIMESTAMP,
        BACKUP_LOCATION: OUT,
        FIRESTORE_BACKUP: manifest.FIRESTORE_BACKUP,
        AUTH_BACKUP_OR_EXPORT_REFERENCE:
          manifest.AUTH_BACKUP_OR_EXPORT_REFERENCE,
        STORAGE_BACKUP_OR_INVENTORY: manifest.STORAGE_BACKUP_OR_INVENTORY,
        BACKUP_RELIABLE_FOR_EXECUTE: false,
        RESET_EXECUTION_ALLOWED: false,
        REASON:
          'No GCS managed Firestore export. Local JSON preserve dump only.',
      },
      null,
      2,
    ),
  );

  console.log(JSON.stringify(manifest, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
