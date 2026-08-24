'use strict';

/**
 * Pre-reset inventory — write evidence under qa_master_audit/pre_reset/
 * NO DELETES.
 */

process.env.GCLOUD_PROJECT = 'tutorial-multi-language-70gx4j';

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const OUT = '/Users/ventura/ara-ban/qa_master_audit/pre_reset';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket(
  'tutorial-multi-language-70gx4j.firebasestorage.app',
);

fs.mkdirSync(OUT, {recursive: true});

const GEO_PRESERVE = new Set([
  'countries',
  'regions',
  'cities',
  'cities_user',
  'villages',
  'mkan',
  'mkan_partners',
  'areas',
  'districts',
  'governorates',
  'places',
  'landmarks',
]);
const CATALOG_PRESERVE = new Set([
  'type_car',
  'services',
  'service_types',
  'transport_types',
  'tour_guides',
  'transport_companies',
  'transport_company',
  'companies',
  'partners',
  'agents',
]);
const CONFIG_PRESERVE = new Set([
  'settings',
  'Settings',
  'config',
  'app_config',
  'feature_flags',
  'admin_config',
  'system_config',
  'i18n',
  'localization',
  'pricing',
  'price',
  'prices',
]);
const FINANCIAL_PRESERVE = new Set([
  'financial_settlements',
  'financial_settlement_payments',
  'financial_periods',
  'financial_adjustments',
  'financial_audit',
  'financial_aggregation_metrics',
  'reconciliation',
  'wallets',
  'wallet_transactions',
  'wallet_ledger',
  'payouts',
  'settlements',
]);
const PAYMENT_PRESERVE = new Set([
  'payments',
  'PaymentMethods',
  'Paymenthistory',
  'payment_sessions',
  'payment_ledger',
  'company_payments',
  'ngenius',
  'ngenius_orders',
  'payment_webhooks',
  'gateway_audit',
  'webhook_audit',
]);
const AUDIT_PRESERVE = new Set([
  'admin_audit_log',
  'audit_log',
  'audit',
  'finance_audit',
]);
const OPERATIONAL_DELETE = new Set([
  'order',
  'orders',
  'order2',
  'order_mkss',
  'idlistorder',
  'support',
  'Support',
  'tickets',
  'support_tickets',
  'suport',
  'ff_user_push_notifications',
  'ff_push_notifications',
  'notification_outbox',
  'notifications',
  'admin_panel_notifications',
  'fcm_tokens',
  'user_tokens',
  'driver_vehicle_plate_claims',
  'plate_claims',
  'driver_plates',
  'plates',
  'driver_registration_idempotency',
  'driver_registration_notifications',
  'user',
  'users',
  'test',
  'ADRESSUSER',
  'chat',
  'ReviewsUser',
  'cart_maps',
  'mapmap',
]);

const HARD_DENYLIST = new Set([
  ...GEO_PRESERVE,
  ...CATALOG_PRESERVE,
  ...CONFIG_PRESERVE,
  ...FINANCIAL_PRESERVE,
  ...PAYMENT_PRESERVE,
  ...AUDIT_PRESERVE,
]);

function classify(name) {
  if (HARD_DENYLIST.has(name)) {
    if (GEO_PRESERVE.has(name)) return 'GEO_PRESERVE';
    if (CATALOG_PRESERVE.has(name)) return 'CATALOG_PRESERVE';
    if (CONFIG_PRESERVE.has(name)) return 'CONFIG_PRESERVE';
    if (FINANCIAL_PRESERVE.has(name)) return 'FINANCIAL_PRESERVE';
    if (PAYMENT_PRESERVE.has(name)) return 'PAYMENT_PRESERVE';
    if (AUDIT_PRESERVE.has(name)) return 'AUDIT_PRESERVE';
  }
  const n = name.toLowerCase();
  if (n.includes('financial') || n.includes('settlement') || n.includes('wallet'))
    return 'FINANCIAL_PRESERVE';
  if (n.includes('payment') || n.includes('ngenius') || n.includes('webhook'))
    return 'PAYMENT_PRESERVE';
  if (n.includes('audit')) return 'AUDIT_PRESERVE';
  if (GEO_PRESERVE.has(name) || ['countries','regions','cities','villages','mkan'].includes(n))
    return 'GEO_PRESERVE';
  if (OPERATIONAL_DELETE.has(name)) return 'OPERATIONAL_DELETE';
  return 'UNKNOWN_REVIEW_REQUIRED';
}

async function countCollection(col) {
  try {
    const agg = await db.collection(col).count().get();
    return agg.data().count;
  } catch (e) {
    const snap = await db.collection(col).select().limit(5000).get();
    return snap.size;
  }
}

function fingerprintDocs(docs, fields) {
  const rows = docs.map((d) => {
    const data = d.data() || {};
    const row = {id: d.id};
    for (const f of fields) {
      const v = data[f];
      if (v && v.path) row[f] = v.path;
      else if (v && typeof v === 'object' && v._latitude != null)
        row[f] = `${v._latitude},${v._longitude}`;
      else row[f] = v == null ? null : String(v).slice(0, 80);
    }
    return row;
  });
  rows.sort((a, b) => a.id.localeCompare(b.id));
  return {
    hash: crypto.createHash('sha256').update(JSON.stringify(rows)).digest('hex'),
    count: rows.length,
  };
}

async function main() {
  const names = (await db.listCollections()).map((c) => c.id).sort();
  const inventory = [];
  for (const name of names) {
    let count = -1;
    let err = null;
    try {
      count = await countCollection(name);
    } catch (e) {
      err = String(e.message || e);
    }
    const classification = classify(name);
    // Denylist always wins
    const denied = HARD_DENYLIST.has(name) ||
      classification === 'GEO_PRESERVE' ||
      classification === 'CATALOG_PRESERVE' ||
      classification === 'CONFIG_PRESERVE' ||
      classification === 'FINANCIAL_PRESERVE' ||
      classification === 'PAYMENT_PRESERVE' ||
      classification === 'AUDIT_PRESERVE' ||
      classification === 'UNKNOWN_REVIEW_REQUIRED';
    inventory.push({
      COLLECTION: name,
      COUNT: count,
      ERROR: err,
      CLASSIFICATION: classification,
      DELETE_ON_RESET: denied ? 'NO' : classification === 'OPERATIONAL_DELETE' ? 'YES_CANDIDATE' : 'NO',
      REASON: denied
        ? classification === 'UNKNOWN_REVIEW_REQUIRED'
          ? 'unknown — review required'
          : 'protected by denylist'
        : 'operational candidate',
    });
    console.error(`${name}\t${count}\t${classification}`);
  }

  const authUsers = [];
  let pageToken;
  do {
    const res = await auth.listUsers(1000, pageToken);
    authUsers.push(...res.users);
    pageToken = res.pageToken;
  } while (pageToken);

  const AUTH_PRESERVE_UIDS = new Set();
  const counts = {
    CUSTOMER: 0,
    DRIVER: 0,
    SUPERADMIN: 0,
    COUNTRY_ADMIN: 0,
    FINANCE: 0,
    UNKNOWN: 0,
  };
  const authClass = [];

  // Batch user docs
  const userSnaps = new Map();
  for (let i = 0; i < authUsers.length; i += 100) {
    const chunk = authUsers.slice(i, i + 100);
    const refs = chunk.map((u) => db.collection('user').doc(u.uid));
    const snaps = await db.getAll(...refs);
    for (const s of snaps) userSnaps.set(s.id, s.data() || {});
  }

  for (const u of authUsers) {
    const doc = userSnaps.get(u.uid) || {};
    const claims = u.customClaims || {};
    const isSuper =
      claims.super_admin === true ||
      doc.IsAdmin === true ||
      doc.isAdminRule === 1;
    const isFinance = claims.finance === true;
    const isCountry =
      claims.country_admin === true ||
      doc.IsAgent === true ||
      (claims.admin === true && !isSuper);
    const isDriver =
      doc.registration_status != null ||
      doc.actev_mndob === true ||
      doc.registration_flow_version != null ||
      doc.mndobTypeCar != null;

    let role = 'UNKNOWN';
    if (isSuper) {
      role = 'SUPERADMIN';
      counts.SUPERADMIN++;
      AUTH_PRESERVE_UIDS.add(u.uid);
    } else if (isFinance) {
      role = 'FINANCE';
      counts.FINANCE++;
      AUTH_PRESERVE_UIDS.add(u.uid);
    } else if (isCountry) {
      role = 'COUNTRY_ADMIN';
      counts.COUNTRY_ADMIN++;
      AUTH_PRESERVE_UIDS.add(u.uid);
    } else if (isDriver) {
      role = 'DRIVER';
      counts.DRIVER++;
    } else if (Object.keys(doc).length > 0 || u.email) {
      role = 'CUSTOMER';
      counts.CUSTOMER++;
    } else {
      role = 'UNKNOWN';
      counts.UNKNOWN++;
    }

    authClass.push({
      uid: u.uid,
      email: u.email || null,
      role,
      functional_test: doc.functional_test === true,
      preserve: AUTH_PRESERVE_UIDS.has(u.uid),
      deleteCandidate:
        (role === 'CUSTOMER' || role === 'DRIVER') &&
        !AUTH_PRESERVE_UIDS.has(u.uid),
    });
  }

  async function snapCol(name, fields) {
    const snap = await db.collection(name).limit(2000).get();
    return {count: snap.size, fp: fingerprintDocs(snap.docs, fields)};
  }

  const countries = await snapCol('countries', [
    'naim',
    'name',
    'iso2',
    'actev',
    'currency_code',
  ]);
  const regions = await snapCol('regions', ['naim', 'name', 'dolh', 'actev']);
  const cities = await snapCol('cities', [
    'naim',
    'name',
    'region',
    'dolh',
    'actev',
  ]);
  const villages = await snapCol('villages', [
    'naim',
    'name',
    'cities',
    'dolh',
    'actev',
  ]);
  const mkan = await snapCol('mkan', ['naim', 'name', 'dolh', 'loceshn', 'actev']);
  const typeCar = await snapCol('type_car', [
    'naim',
    'name',
    'actev',
    'codeCar',
    'dolh',
  ]);

  const geoFingerprint = crypto
    .createHash('sha256')
    .update(
      JSON.stringify({
        c: countries.fp.hash,
        r: regions.fp.hash,
        ci: cities.fp.hash,
        v: villages.fp.hash,
        m: mkan.fp.hash,
        t: typeCar.fp.hash,
      }),
    )
    .digest('hex');

  let storageTotal = 0;
  let storageOperational = 0;
  let storagePreserve = 0;
  let storageUnknown = 0;
  const storageSamples = [];
  let storageError = null;
  try {
    const [files] = await bucket.getFiles({maxResults: 5000});
    storageTotal = files.length;
    for (const f of files) {
      const n = f.name || '';
      if (
        /countries|mkan\/catalog|type_car\/system|config\//i.test(n) &&
        !/user\//i.test(n)
      ) {
        storagePreserve++;
        if (storageSamples.length < 30)
          storageSamples.push({name: n, class: 'PRESERVE'});
      } else if (
        /user\/|drivers\/|driver|documents|uploads|profiles|order\//i.test(n)
      ) {
        storageOperational++;
        if (storageSamples.length < 30)
          storageSamples.push({name: n, class: 'OPERATIONAL'});
      } else {
        storageUnknown++;
        if (storageSamples.length < 30)
          storageSamples.push({name: n, class: 'UNKNOWN'});
      }
    }
  } catch (e) {
    storageError = String(e.message || e);
  }

  const authReport = {
    AUTH_USERS_TOTAL: authUsers.length,
    CUSTOMER_AUTH_USERS: counts.CUSTOMER,
    DRIVER_AUTH_USERS: counts.DRIVER,
    SUPERADMIN_AUTH_USERS: counts.SUPERADMIN,
    COUNTRY_ADMIN_AUTH_USERS: counts.COUNTRY_ADMIN,
    FINANCE_AUTH_USERS: counts.FINANCE,
    UNKNOWN_AUTH_USERS: counts.UNKNOWN,
    AUTH_PRESERVE_UIDS: [...AUTH_PRESERVE_UIDS],
    AUTH_DELETE_CANDIDATES: authClass.filter((a) => a.deleteCandidate).length,
    users: authClass,
  };

  const geo = {
    COUNTRIES_BEFORE: countries.count,
    REGIONS_BEFORE: regions.count,
    CITIES_BEFORE: cities.count,
    VILLAGES_BEFORE: villages.count,
    AREAS_BEFORE: 0,
    LANDMARKS_BEFORE: mkan.count,
    VEHICLE_TYPES_BEFORE: typeCar.count,
    SERVICES_BEFORE: 0,
    GEO_CATALOG_FINGERPRINT_BEFORE: geoFingerprint,
    hashes: {
      countries: countries.fp.hash,
      regions: regions.fp.hash,
      cities: cities.fp.hash,
      villages: villages.fp.hash,
      mkan: mkan.fp.hash,
      type_car: typeCar.fp.hash,
    },
  };

  const storage = {
    STORAGE_OBJECTS_TOTAL: storageTotal,
    STORAGE_OBJECTS_OPERATIONAL_DELETE: storageOperational,
    STORAGE_OBJECTS_PRESERVE: storagePreserve,
    STORAGE_OBJECTS_UNKNOWN: storageUnknown,
    error: storageError,
    samples: storageSamples,
    note: storageTotal >= 5000 ? 'LIST_CAPPED_AT_5000' : 'OK',
  };

  fs.writeFileSync(
    path.join(OUT, 'firestore_collection_inventory.json'),
    JSON.stringify(inventory, null, 2),
  );
  fs.writeFileSync(
    path.join(OUT, 'auth_inventory.json'),
    JSON.stringify(authReport, null, 2),
  );
  fs.writeFileSync(
    path.join(OUT, 'geo_catalog_fingerprint.json'),
    JSON.stringify(geo, null, 2),
  );
  fs.writeFileSync(
    path.join(OUT, 'storage_inventory.json'),
    JSON.stringify(storage, null, 2),
  );
  fs.writeFileSync(
    path.join(OUT, 'hard_denylist.json'),
    JSON.stringify([...HARD_DENYLIST].sort(), null, 2),
  );

  const summary = {
    project: PROJECT_ID,
    generatedAt: new Date().toISOString(),
    collectionCount: inventory.length,
    auth: {
      total: authReport.AUTH_USERS_TOTAL,
      preserve: AUTH_PRESERVE_UIDS.size,
      deleteCandidates: authReport.AUTH_DELETE_CANDIDATES,
      ...counts,
    },
    geo,
    storage,
    operationalCandidates: inventory.filter(
      (i) => i.DELETE_ON_RESET === 'YES_CANDIDATE',
    ),
    unknown: inventory.filter(
      (i) => i.CLASSIFICATION === 'UNKNOWN_REVIEW_REQUIRED',
    ),
  };
  fs.writeFileSync(
    path.join(OUT, 'pre_reset_inventory_report.json'),
    JSON.stringify(summary, null, 2),
  );
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
