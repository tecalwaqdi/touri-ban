'use strict';

/**
 * Operational baseline reset — dry-run by default.
 *
 * Usage:
 *   node scripts/reset_operational_baseline.js
 *   node scripts/reset_operational_baseline.js --dry-run
 *   CONFIRM_PROJECT=tutorial-multi-language-70gx4j \
 *   CONFIRM_OPERATIONAL_RESET=YES \
 *   BACKUP_CREATED=true \
 *   node scripts/reset_operational_baseline.js --execute
 *
 * HARD RULES:
 * - Denylist always wins over allowlist
 * - Default mode is --dry-run
 * - --execute requires CONFIRM_PROJECT + CONFIRM_OPERATIONAL_RESET + BACKUP_CREATED
 * - Never wipe all Auth / all Storage / all collections
 */

process.env.GCLOUD_PROJECT = 'tutorial-multi-language-70gx4j';

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const OUT = '/Users/ventura/ara-ban/qa_master_audit/pre_reset';
const args = process.argv.slice(2);
const EXECUTE = args.includes('--execute');
const DRY_RUN = !EXECUTE || args.includes('--dry-run');

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
  // RESET-0B: landmark category catalog (seeded; admin write)
  'Classification',
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
  // RESET-0B: order sequence counter (system config)
  'auto_num',
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
  // RESET-0B: wallet ledger movements (amount/balance/walletRef)
  'transactions',
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
/** Still ambiguous after RESET-0B — never schedule for delete */
const UNKNOWN_REVIEW_REQUIRED = new Set(['bank', 'suprt']);

const HARD_DENYLIST = new Set([
  ...GEO_PRESERVE,
  ...CATALOG_PRESERVE,
  ...CONFIG_PRESERVE,
  ...FINANCIAL_PRESERVE,
  ...PAYMENT_PRESERVE,
  ...AUDIT_PRESERVE,
  ...UNKNOWN_REVIEW_REQUIRED,
]);

/** Explicit operational allowlist only — never "all collections" */
const OPERATIONAL_COLLECTION_ALLOWLIST = new Set([
  'order',
  'order2',
  'order_mkss',
  'idlistorder',
  'support',
  'ff_user_push_notifications',
  'ff_push_notifications',
  'admin_panel_notifications',
  'fcm_tokens',
  'driver_vehicle_plate_claims',
  'driver_registration_idempotency',
  'driver_registration_notifications',
  'ADRESSUSER',
  'chat',
  'ReviewsUser',
  'cart_maps',
  'mapmap',
  'test',
  // RESET-0B resolved operational
  'ExtraHours',
  'mndob',
  // user docs deleted selectively by auth role — not whole-collection wipe flag alone
]);

const OPERATIONAL_REPORT_ALLOWLIST = new Set([
  // none identified as pure operational report collections yet
]);

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket(
  'tutorial-multi-language-70gx4j.firebasestorage.app',
);

function abortProtected(name) {
  const err = new Error('PROTECTED_REFERENCE_DATA_DELETE_ATTEMPT');
  err.code = 'PROTECTED_REFERENCE_DATA_DELETE_ATTEMPT';
  err.collection = name;
  err.ABORT_RESET = true;
  throw err;
}

function assertNotDenied(name) {
  if (HARD_DENYLIST.has(name)) abortProtected(name);
  const n = name.toLowerCase();
  if (
    n.includes('financial') ||
    n.includes('settlement') ||
    n.includes('wallet') ||
    n.includes('payment') ||
    n.includes('audit') ||
    n.includes('ngenius') ||
    n.includes('webhook')
  ) {
    abortProtected(name);
  }
}

async function countCollection(col) {
  try {
    const agg = await db.collection(col).count().get();
    return agg.data().count;
  } catch (_) {
    const snap = await db.collection(col).select().limit(5000).get();
    return snap.size;
  }
}

async function classifyAuth() {
  const authUsers = [];
  let pageToken;
  do {
    const res = await auth.listUsers(1000, pageToken);
    authUsers.push(...res.users);
    pageToken = res.pageToken;
  } while (pageToken);

  const AUTH_PRESERVE_UIDS = new Set();
  const byRole = {
    CUSTOMER: [],
    DRIVER: [],
    SUPERADMIN: [],
    COUNTRY_ADMIN: [],
    FINANCE: [],
    UNKNOWN: [],
  };

  for (let i = 0; i < authUsers.length; i += 100) {
    const chunk = authUsers.slice(i, i + 100);
    const snaps = await db.getAll(
      ...chunk.map((u) => db.collection('user').doc(u.uid)),
    );
    for (let j = 0; j < chunk.length; j++) {
      const u = chunk[j];
      const doc = snaps[j].data() || {};
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
      if (isSuper) role = 'SUPERADMIN';
      else if (isFinance) role = 'FINANCE';
      else if (isCountry) role = 'COUNTRY_ADMIN';
      else if (isDriver) role = 'DRIVER';
      else if (Object.keys(doc).length > 0 || u.email) role = 'CUSTOMER';

      if (
        role === 'SUPERADMIN' ||
        role === 'FINANCE' ||
        role === 'COUNTRY_ADMIN'
      ) {
        AUTH_PRESERVE_UIDS.add(u.uid);
      }
      byRole[role].push({
        uid: u.uid,
        email: u.email || null,
        functional_test: doc.functional_test === true,
      });
    }
  }

  const deleteCandidates = [...byRole.CUSTOMER, ...byRole.DRIVER].filter(
    (u) => !AUTH_PRESERVE_UIDS.has(u.uid),
  );

  return {
    AUTH_PRESERVE_UIDS: [...AUTH_PRESERVE_UIDS],
    byRole,
    deleteCandidates,
    AUTH_USERS_TOTAL: authUsers.length,
  };
}

async function storagePlan(deleteUids, preserveUids) {
  const deleteSet = new Set(deleteUids);
  const preserveSet = new Set(preserveUids || []);
  let total = 0;
  let toDelete = 0;
  let preserve = 0;
  let unknown = 0;
  const samples = [];
  try {
    const [files] = await bucket.getFiles({maxResults: 5000});
    total = files.length;
    for (const f of files) {
      const n = f.name || '';
      // Never schedule pub/ for delete
      if (n === 'pub/' || n === 'pub') {
        unknown++;
        if (samples.length < 20)
          samples.push({name: 'pub/', action: 'UNKNOWN_NO_DELETE'});
        continue;
      }
      const m = n.match(/^users\/([^/]+)\//);
      if (m && deleteSet.has(m[1])) {
        toDelete++;
        if (samples.length < 20) samples.push({name: n, action: 'DELETE'});
      } else if (m && preserveSet.has(m[1])) {
        preserve++;
        if (samples.length < 20) samples.push({name: n, action: 'PRESERVE'});
      } else if (m) {
        // Orphan uploads (Auth UID gone) — do not schedule delete
        unknown++;
        if (samples.length < 20)
          samples.push({
            name: 'users/[orphan_uid]/…',
            action: 'UNKNOWN_NO_DELETE',
          });
      } else if (
        /countries|mkan\/catalog|type_car\/system|config\//i.test(n)
      ) {
        preserve++;
        if (samples.length < 20) samples.push({name: n, action: 'PRESERVE'});
      } else {
        unknown++;
        if (samples.length < 20)
          samples.push({name: n, action: 'UNKNOWN_NO_DELETE'});
      }
    }
  } catch (e) {
    return {
      error: String(e.message || e),
      total: 0,
      toDelete: 0,
      preserve: 0,
      unknown: 0,
    };
  }
  return {total, toDelete, preserve, unknown, samples, capped: total >= 5000};
}

async function dryRun() {
  const inventoryPath = path.join(OUT, 'firestore_collection_inventory.json');
  const inventory = JSON.parse(fs.readFileSync(inventoryPath, 'utf8'));
  const backupMetaPath = path.join(OUT, 'backup_latest.json');
  const backupMeta = fs.existsSync(backupMetaPath)
    ? JSON.parse(fs.readFileSync(backupMetaPath, 'utf8'))
    : {BACKUP_CREATED: false, RESET_EXECUTION_ALLOWED: false};

  const liveNames = (await db.listCollections()).map((c) => c.id);
  for (const name of liveNames) {
    // Safety: if allowlist somehow includes denied name, abort
    if (OPERATIONAL_COLLECTION_ALLOWLIST.has(name) && HARD_DENYLIST.has(name)) {
      abortProtected(name);
    }
  }

  const authInfo = await classifyAuth();
  const customers = authInfo.byRole.CUSTOMER.filter(
    (u) => !authInfo.AUTH_PRESERVE_UIDS.includes(u.uid),
  );
  const drivers = authInfo.byRole.DRIVER.filter(
    (u) => !authInfo.AUTH_PRESERVE_UIDS.includes(u.uid),
  );

  const countMap = Object.fromEntries(
    inventory.map((i) => [i.COLLECTION, i.COUNT]),
  );

  function liveClass(name) {
    if (GEO_PRESERVE.has(name)) return 'GEO_PRESERVE';
    if (CATALOG_PRESERVE.has(name)) return 'CATALOG_PRESERVE';
    if (CONFIG_PRESERVE.has(name)) return 'CONFIG_PRESERVE';
    if (FINANCIAL_PRESERVE.has(name)) return 'FINANCIAL_PRESERVE';
    if (PAYMENT_PRESERVE.has(name)) return 'PAYMENT_PRESERVE';
    if (AUDIT_PRESERVE.has(name)) return 'AUDIT_PRESERVE';
    if (UNKNOWN_REVIEW_REQUIRED.has(name)) return 'UNKNOWN_REVIEW_REQUIRED';
    if (OPERATIONAL_COLLECTION_ALLOWLIST.has(name)) return 'OPERATIONAL_DELETE';
    return 'UNKNOWN_REVIEW_REQUIRED';
  }

  const plannedCollections = [];
  for (const name of OPERATIONAL_COLLECTION_ALLOWLIST) {
    assertNotDenied(name);
    if (HARD_DENYLIST.has(name)) abortProtected(name);
    if (liveClass(name) === 'UNKNOWN_REVIEW_REQUIRED') continue;
    if (!(name in countMap) && !liveNames.includes(name)) continue;
    plannedCollections.push({
      collection: name,
      count: countMap[name] ?? (await countCollection(name)),
      mode: 'DELETE_ALL_DOCS',
    });
  }

  // Selective user docs: only customer/driver delete candidates
  const userDocsToDelete = customers.length + drivers.length;

  const storage = await storagePlan(
    authInfo.deleteCandidates.map((u) => u.uid),
    authInfo.AUTH_PRESERVE_UIDS,
  );

  const preserveCounts = {
    ADMIN_USERS_TO_PRESERVE: authInfo.byRole.SUPERADMIN.length,
    COUNTRY_ADMINS_TO_PRESERVE: authInfo.byRole.COUNTRY_ADMIN.length,
    FINANCE_USERS_TO_PRESERVE: authInfo.byRole.FINANCE.length,
    COUNTRIES_TO_PRESERVE: countMap.countries || 0,
    REGIONS_TO_PRESERVE: countMap.regions || 0,
    CITIES_TO_PRESERVE: countMap.cities || 0,
    VILLAGES_TO_PRESERVE: countMap.villages || 0,
    AREAS_TO_PRESERVE: countMap.areas || 0,
    LANDMARKS_TO_PRESERVE: countMap.mkan || 0,
    VEHICLE_TYPES_TO_PRESERVE: countMap.type_car || 0,
    SERVICES_TO_PRESERVE: countMap.services || 0,
    FINANCIAL_DOCS_TO_PRESERVE:
      (countMap.wallets || 0) +
      (countMap.financial_aggregation_metrics || 0) +
      (countMap.transactions || 0),
    PAYMENT_DOCS_TO_PRESERVE:
      (countMap.PaymentMethods || 0) +
      (countMap.Paymenthistory || 0) +
      (countMap.payment_sessions || 0) +
      (countMap.company_payments || 0),
    AUDIT_DOCS_TO_PRESERVE: countMap.admin_audit_log || 0,
    CONFIG_DOCS_TO_PRESERVE:
      (countMap.Settings || 0) + (countMap.auto_num || 0),
    CATALOG_EXTRA_PRESERVE: countMap.Classification || 0,
  };

  const deletePlan = {
    CUSTOMERS_TO_DELETE: customers.length,
    DRIVERS_TO_DELETE: drivers.length,
    AUTH_USERS_TO_DELETE: authInfo.deleteCandidates.length,
    BOOKINGS_TO_DELETE:
      (countMap.order || 0) + (countMap.order2 || 0) + (countMap.order_mkss || 0),
    TRIP_RECORDS_TO_DELETE:
      (countMap.order || 0) + (countMap.cart_maps || 0) + (countMap.mapmap || 0),
    DRIVER_APPLICATIONS_TO_DELETE: drivers.length,
    SUPPORT_TICKETS_TO_DELETE: countMap.support || 0,
    NOTIFICATIONS_TO_DELETE:
      (countMap.ff_user_push_notifications || 0) +
      (countMap.ff_push_notifications || 0) +
      (countMap.admin_panel_notifications || 0) +
      (countMap.driver_registration_notifications || 0),
    FCM_TOKENS_TO_DELETE: countMap.fcm_tokens || 0,
    ACTIVE_BOOKING_LOCKS_TO_DELETE:
      (countMap.cart_maps || 0) + (countMap.mapmap || 0),
    PLATE_CLAIMS_TO_DELETE: countMap.driver_vehicle_plate_claims || 0,
    STORAGE_OBJECTS_TO_DELETE: storage.toDelete || 0,
    OPERATIONAL_REPORTS_TO_DELETE: 0,
    OLD_TEST_FIXTURES_TO_DELETE: countMap.test || 0,
    USER_DOCS_TO_DELETE: userDocsToDelete,
    CHAT_TO_DELETE: countMap.chat || 0,
    ADDRESSES_TO_DELETE: countMap.ADRESSUSER || 0,
    REGISTRATION_IDEMPOTENCY_TO_DELETE:
      countMap.driver_registration_idempotency || 0,
    EXTRA_HOURS_TO_DELETE: countMap.ExtraHours || 0,
    MNDOB_LEGACY_TO_DELETE: countMap.mndob || 0,
  };

  const unknownDataScheduled =
    plannedCollections.filter(
      (p) => liveClass(p.collection) === 'UNKNOWN_REVIEW_REQUIRED',
    ).length +
    (OPERATIONAL_COLLECTION_ALLOWLIST.has('bank') ? 1 : 0) +
    (OPERATIONAL_COLLECTION_ALLOWLIST.has('suprt') ? 1 : 0);

  const gates = {
    GEO_DATA_SCHEDULED_FOR_DELETE: 0,
    CATALOG_DATA_SCHEDULED_FOR_DELETE: 0,
    CONFIG_DATA_SCHEDULED_FOR_DELETE: 0,
    FINANCE_DATA_SCHEDULED_FOR_DELETE: 0,
    PAYMENT_DATA_SCHEDULED_FOR_DELETE: 0,
    ADMIN_ACCOUNTS_SCHEDULED_FOR_DELETE: 0,
    UNKNOWN_DATA_SCHEDULED_FOR_DELETE: unknownDataScheduled,
  };

  // Verify no planned collection is denied
  for (const p of plannedCollections) {
    if (HARD_DENYLIST.has(p.collection)) {
      abortProtected(p.collection);
    }
    const cls = liveClass(p.collection);
    if (cls && cls.endsWith('_PRESERVE')) {
      abortProtected(p.collection);
    }
    if (cls === 'UNKNOWN_REVIEW_REQUIRED') {
      abortProtected(p.collection);
    }
  }

  // Catalog readiness (read-only proof)
  const countriesSnap = await db.collection('countries').limit(1).get();
  const citiesSnap = await db.collection('cities').limit(1).get();
  const mkanSnap = await db.collection('mkan').limit(1).get();
  const typeCarSnap = await db.collection('type_car').limit(1).get();
  const settingsSnap = await db.collection('Settings').limit(1).get();
  const catalogReady =
    countriesSnap.size >= 1 &&
    citiesSnap.size >= 1 &&
    mkanSnap.size >= 1 &&
    typeCarSnap.size >= 1 &&
    settingsSnap.size >= 1;

  const managedPath = path.join(OUT, 'managed_firestore_export_verify.json');
  const managedMeta = fs.existsSync(managedPath)
    ? JSON.parse(fs.readFileSync(managedPath, 'utf8'))
    : {};
  const authBackupPath = path.join(OUT, 'auth_backup_0b.json');
  const authBackupOk =
    fs.existsSync(authBackupPath) &&
    JSON.parse(fs.readFileSync(authBackupPath, 'utf8')).AUTH_BACKUP_USERS ===
      704;
  const storageInvPath = path.join(OUT, 'storage_inventory_0b.json');
  const storageBackupOk =
    fs.existsSync(storageInvPath) &&
    JSON.parse(fs.readFileSync(storageInvPath, 'utf8'))
      .STORAGE_INVENTORY_BACKUP === 'PASS';

  const managedOk =
    managedMeta.FIRESTORE_BACKUP_RESTORE_READINESS === 'PASS' &&
    managedMeta.FIRESTORE_EXPORT_OBJECTS_FOUND === true &&
    managedMeta.FIRESTORE_EXPORT_METADATA_FOUND === true &&
    managedMeta.FIRESTORE_EXPORT_NONEMPTY === true;
  const backupCreated =
    backupMeta.BACKUP_CREATED === true || managedOk === true;
  const gcsBackupOk =
    managedOk === true || backupMeta.BACKUP_RELIABLE_FOR_EXECUTE === true;
  const gatesOk = Object.values(gates).every((v) => v === 0);
  const backupGates = {
    MANAGED_FIRESTORE_EXPORT: managedOk ? 'PASS' : 'FAIL',
    AUTH_BACKUP: authBackupOk ? 'PASS' : 'FAIL',
    STORAGE_INVENTORY_BACKUP: storageBackupOk ? 'PASS' : 'FAIL',
    BACKUP_PROJECT_MATCH:
      PROJECT_ID === 'tutorial-multi-language-70gx4j' ? 'PASS' : 'FAIL',
  };
  const backupGatesOk = Object.values(backupGates).every((v) => v === 'PASS');
  const resetExecutionAllowed =
    gcsBackupOk &&
    backupCreated &&
    backupGatesOk &&
    gatesOk &&
    authInfo.byRole.UNKNOWN.length === 0 &&
    authInfo.byRole.SUPERADMIN.length === 6;

  const ambiguous = ['bank', 'suprt']
    .filter((n) => liveNames.includes(n) || n in countMap)
    .map((n) => ({
      COLLECTION: n,
      COUNT: countMap[n] || 0,
      CLASSIFICATION: 'UNKNOWN_REVIEW_REQUIRED',
      DELETE_ON_RESET: 'NO',
    }));

  const report = {
    mode: DRY_RUN ? 'DRY_RUN' : 'EXECUTE',
    PROJECT_MATCH: PROJECT_ID === 'tutorial-multi-language-70gx4j' ? 'PASS' : 'FAIL',
    BACKUP_CREATED: backupCreated,
    BACKUP_RELIABLE_FOR_EXECUTE: !!gcsBackupOk,
    backupGates,
    RESET_EXECUTION_ALLOWED: resetExecutionAllowed,
    AUTH_PRESERVE_UIDS: authInfo.AUTH_PRESERVE_UIDS,
    plannedCollections,
    deletePlan,
    preserveCounts,
    gates,
    CATALOG_READY_FOR_GOLDEN_CYCLE: catalogReady ? 'PASS' : 'FAIL',
    catalogNotes: {
      SERVICES_COLLECTION_COUNT: countMap.services || 0,
      VEHICLE_TYPES_AS_SERVICE_PROXY: countMap.type_car || 0,
      REGIONS_COUNT: countMap.regions || 0,
      note:
        'services collection empty; type_car + Settings used as service/pricing proxy',
    },
    AUTH: {
      AUTH_USERS_TOTAL: authInfo.AUTH_USERS_TOTAL,
      CUSTOMER_AUTH_USERS: authInfo.byRole.CUSTOMER.length,
      DRIVER_AUTH_USERS: authInfo.byRole.DRIVER.length,
      SUPERADMIN_AUTH_USERS: authInfo.byRole.SUPERADMIN.length,
      COUNTRY_ADMIN_AUTH_USERS: authInfo.byRole.COUNTRY_ADMIN.length,
      FINANCE_AUTH_USERS: authInfo.byRole.FINANCE.length,
      UNKNOWN_AUTH_USERS: authInfo.byRole.UNKNOWN.length,
      AUTH_USERS_TO_DELETE: authInfo.deleteCandidates.length,
      AUTH_USERS_TO_PRESERVE: authInfo.AUTH_PRESERVE_UIDS.length,
    },
    STORAGE: storage,
    WHAT_IS_AMBIGUOUS: ambiguous,
    dependencyGraph: {
      Customer: [
        'Auth',
        'user profile',
        'orders',
        'active lock (cart_maps/mapmap)',
        'notifications',
        'FCM tokens',
        'support',
        'uploads (Storage users/{uid}/)',
      ],
      Driver: [
        'Auth',
        'user profile',
        'registration fields on user',
        'documents (Storage)',
        'plate claim',
        'notifications',
        'FCM tokens',
        'availability on user',
        'assigned orders',
      ],
      Booking: [
        'customer',
        'driver',
        'active lock',
        'notifications',
        'route snapshots',
        'operational reports (none discrete)',
      ],
      deleteOrderSuggested: [
        '1 notifications / FCM / locks',
        '2 bookings/orders',
        '3 support / chat / addresses / reviews',
        '4 plate claims / registration idempotency',
        '5 Storage user uploads for delete UIDs',
        '6 user docs (customer/driver only)',
        '7 Auth users (customer/driver only, not preserve)',
      ],
    },
    expectedCleanBaseline: {
      Customers: 0,
      Drivers: 0,
      Bookings: 0,
      ActiveBookings: 0,
      DriverApplications: 0,
      SupportTickets: 0,
      OperationalNotifications: 0,
      preserved: [
        'Admin access',
        'Countries/Regions/Cities/Villages/Landmarks',
        'Vehicle types',
        'Settings/config',
        'Finance/Payment/Audit',
      ],
    },
  };

  fs.mkdirSync(OUT, {recursive: true});
  fs.writeFileSync(
    path.join(OUT, 'reset_dry_run_report.json'),
    JSON.stringify(report, null, 2),
  );

  return report;
}

async function deleteCollectionAllDocs(collectionName, progress) {
  assertNotDenied(collectionName);
  if (HARD_DENYLIST.has(collectionName)) abortProtected(collectionName);
  if (!OPERATIONAL_COLLECTION_ALLOWLIST.has(collectionName)) {
    throw new Error(`Collection not on operational allowlist: ${collectionName}`);
  }
  let deleted = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db.collection(collectionName).limit(400).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted += snap.size;
    if (progress) {
      progress(collectionName, deleted);
    }
  }
  return deleted;
}

async function deleteDocsByIds(collectionName, ids, progress) {
  assertNotDenied(collectionName);
  if (HARD_DENYLIST.has(collectionName)) abortProtected(collectionName);
  let deleted = 0;
  for (let i = 0; i < ids.length; i += 400) {
    const chunk = ids.slice(i, i + 400);
    const batch = db.batch();
    for (const id of chunk) {
      batch.delete(db.collection(collectionName).doc(id));
    }
    await batch.commit();
    deleted += chunk.length;
    if (progress) progress(collectionName, deleted, ids.length);
  }
  return deleted;
}

async function deleteStorageForUids(uids, progress) {
  const deleteSet = new Set(uids);
  let deleted = 0;
  let skippedUnknown = 0;
  let skippedPreserve = 0;
  const [files] = await bucket.getFiles({maxResults: 5000});
  for (const f of files) {
    const n = f.name || '';
    if (n === 'pub/' || n === 'pub') {
      skippedUnknown++;
      continue;
    }
    const m = n.match(/^users\/([^/]+)\//);
    if (!m) {
      skippedUnknown++;
      continue;
    }
    if (!deleteSet.has(m[1])) {
      skippedPreserve++;
      continue;
    }
    try {
      await f.delete();
      deleted++;
      if (progress && deleted % 20 === 0) progress('storage', deleted);
    } catch (e) {
      // ignore already-deleted
      if (!String(e.message || e).includes('No such object')) {
        throw e;
      }
    }
  }
  return {deleted, skippedUnknown, skippedPreserve};
}

async function deleteAuthUsers(candidates, preserveUids, progress) {
  const preserve = new Set(preserveUids);
  let deleted = 0;
  const aborted = [];
  for (const u of candidates) {
    if (preserve.has(u.uid)) {
      aborted.push({uid: u.uid, reason: 'IN_PRESERVE'});
      continue;
    }
    // Safety: re-read user doc + claims before each auth delete
    const [userRecord, userSnap] = await Promise.all([
      auth.getUser(u.uid).catch((e) => ({error: e})),
      db.collection('user').doc(u.uid).get(),
    ]);
    if (userRecord.error && userRecord.error.code === 'auth/user-not-found') {
      continue;
    }
    if (userRecord.error) throw userRecord.error;
    const claims = userRecord.customClaims || {};
    const doc = userSnap.data() || {};
    const isSuper =
      claims.super_admin === true ||
      doc.IsAdmin === true ||
      doc.isAdminRule === 1;
    const isFinance = claims.finance === true;
    const isCountry =
      claims.country_admin === true ||
      doc.IsAgent === true ||
      (claims.admin === true && !isSuper);
    if (isSuper || isFinance || isCountry || preserve.has(u.uid)) {
      aborted.push({
        uid: u.uid,
        reason: 'NON_CUSTOMER_DRIVER_OR_PRESERVE',
        isSuper,
        isFinance,
        isCountry,
      });
      continue;
    }
    await auth.deleteUser(u.uid);
    deleted++;
    if (progress && deleted % 25 === 0) progress('auth', deleted, candidates.length);
  }
  return {deleted, aborted};
}

async function executeReset(report) {
  if (process.env.CONFIRM_PROJECT !== PROJECT_ID) {
    throw new Error('CONFIRM_PROJECT mismatch — abort');
  }
  if (process.env.CONFIRM_OPERATIONAL_RESET !== 'YES') {
    throw new Error('CONFIRM_OPERATIONAL_RESET must be YES — abort');
  }
  if (process.env.BACKUP_CREATED !== 'true') {
    throw new Error('BACKUP_CREATED must be true — abort');
  }
  if (process.env.OWNER_APPROVED_OPERATIONAL_RESET !== 'true') {
    throw new Error('OWNER_APPROVED_OPERATIONAL_RESET must be true — abort');
  }
  if (!report.RESET_EXECUTION_ALLOWED) {
    throw new Error('RESET_EXECUTION_ALLOWED=false — abort');
  }

  const APPROVED = {
    CUSTOMERS_TO_DELETE: 457,
    DRIVERS_TO_DELETE: 241,
    AUTH_USERS_TO_DELETE: 698,
    BOOKINGS_TO_DELETE: 887,
    SUPPORT_TICKETS_TO_DELETE: 101,
    NOTIFICATIONS_TO_DELETE: 1632,
    FCM_TOKENS_TO_DELETE: 1,
    ACTIVE_BOOKING_LOCKS_TO_DELETE: 15,
    PLATE_CLAIMS_TO_DELETE: 3,
    STORAGE_OBJECTS_TO_DELETE: 182,
    OPERATIONAL_REPORTS_TO_DELETE: 0,
    OLD_TEST_FIXTURES_TO_DELETE: 19,
    EXTRA_HOURS_TO_DELETE: 1,
    MNDOB_LEGACY_TO_DELETE: 2,
  };
  for (const [k, v] of Object.entries(APPROVED)) {
    if (report.deletePlan[k] !== v) {
      throw new Error(
        `ABORT: deletePlan drift on ${k}: approved=${v} current=${report.deletePlan[k]}`,
      );
    }
  }
  if (report.AUTH.SUPERADMIN_AUTH_USERS !== 6) {
    throw new Error('ABORT: SUPERADMIN count != 6');
  }
  if ((report.AUTH_PRESERVE_UIDS || []).length !== 6) {
    throw new Error('ABORT: AUTH_PRESERVE_UIDS length != 6');
  }
  for (const g of Object.values(report.gates || {})) {
    if (g !== 0) throw new Error('ABORT: protected gate non-zero');
  }

  const authInfo = await classifyAuth();
  if (authInfo.AUTH_PRESERVE_UIDS.length !== 6) {
    throw new Error('ABORT: live preserve UIDs != 6');
  }
  const preserveSet = new Set(authInfo.AUTH_PRESERVE_UIDS);
  const deleteUids = authInfo.deleteCandidates.map((u) => u.uid);
  if (deleteUids.length !== 698) {
    throw new Error(
      `ABORT: live AUTH delete candidates=${deleteUids.length} approved=698`,
    );
  }
  for (const uid of deleteUids) {
    if (preserveSet.has(uid)) {
      throw new Error(`ABORT: preserve UID in delete set ${uid}`);
    }
  }

  const startedAt = new Date().toISOString();
  const results = {
    startedAt,
    project: PROJECT_ID,
    deleted: {},
    abortedAuth: [],
  };

  const logProgress = (task, done, total) => {
    const elapsed = Math.round((Date.now() - Date.parse(startedAt)) / 1000);
    process.stderr.write(
      `STILL_RUNNING:\nCurrent task: ${task}\nProgress: ${done}${total != null ? '/' + total : ''}\nElapsed_s: ${elapsed}\n`,
    );
  };

  // 1) Notifications / FCM / locks / extras / fixtures
  process.stderr.write('[EXECUTE] notifications/FCM/locks/extras/fixtures\n');
  results.deleted.ff_user_push_notifications = await deleteCollectionAllDocs(
    'ff_user_push_notifications',
    logProgress,
  );
  results.deleted.ff_push_notifications = await deleteCollectionAllDocs(
    'ff_push_notifications',
    logProgress,
  );
  results.deleted.admin_panel_notifications = await deleteCollectionAllDocs(
    'admin_panel_notifications',
    logProgress,
  );
  results.deleted.driver_registration_notifications =
    await deleteCollectionAllDocs(
      'driver_registration_notifications',
      logProgress,
    );
  results.deleted.fcm_tokens = await deleteCollectionAllDocs(
    'fcm_tokens',
    logProgress,
  );
  results.deleted.cart_maps = await deleteCollectionAllDocs(
    'cart_maps',
    logProgress,
  );
  results.deleted.mapmap = await deleteCollectionAllDocs('mapmap', logProgress);
  results.deleted.ExtraHours = await deleteCollectionAllDocs(
    'ExtraHours',
    logProgress,
  );
  results.deleted.test = await deleteCollectionAllDocs('test', logProgress);

  // 2) Bookings
  process.stderr.write('[EXECUTE] bookings/orders\n');
  results.deleted.order = await deleteCollectionAllDocs('order', logProgress);
  results.deleted.order2 = await deleteCollectionAllDocs('order2', logProgress);
  results.deleted.order_mkss = await deleteCollectionAllDocs(
    'order_mkss',
    logProgress,
  );
  results.deleted.idlistorder = await deleteCollectionAllDocs(
    'idlistorder',
    logProgress,
  );

  // 3) Support / chat / addresses / reviews (NOT suprt)
  process.stderr.write('[EXECUTE] support/chat/addresses/reviews\n');
  results.deleted.support = await deleteCollectionAllDocs(
    'support',
    logProgress,
  );
  results.deleted.chat = await deleteCollectionAllDocs('chat', logProgress);
  results.deleted.ADRESSUSER = await deleteCollectionAllDocs(
    'ADRESSUSER',
    logProgress,
  );
  results.deleted.ReviewsUser = await deleteCollectionAllDocs(
    'ReviewsUser',
    logProgress,
  );

  // 4) Plate claims / registration / legacy mndob
  process.stderr.write('[EXECUTE] plates/registration/mndob\n');
  results.deleted.driver_vehicle_plate_claims = await deleteCollectionAllDocs(
    'driver_vehicle_plate_claims',
    logProgress,
  );
  results.deleted.driver_registration_idempotency =
    await deleteCollectionAllDocs(
      'driver_registration_idempotency',
      logProgress,
    );
  results.deleted.mndob = await deleteCollectionAllDocs('mndob', logProgress);

  // Hard assert denylist collections untouched
  for (const denied of HARD_DENYLIST) {
    // no-op safety: ensure we never call delete on these names
    if (OPERATIONAL_COLLECTION_ALLOWLIST.has(denied)) {
      abortProtected(denied);
    }
  }

  // 5) Storage for delete UIDs only
  process.stderr.write('[EXECUTE] storage user objects\n');
  results.deleted.storage = await deleteStorageForUids(deleteUids, logProgress);

  // 6) user docs for delete UIDs only
  process.stderr.write('[EXECUTE] user docs (selective)\n');
  results.deleted.userDocs = await deleteDocsByIds(
    'user',
    deleteUids,
    logProgress,
  );
  // Verify preserve user docs still exist
  for (const uid of authInfo.AUTH_PRESERVE_UIDS) {
    const snap = await db.collection('user').doc(uid).get();
    if (!snap.exists) {
      throw new Error(`ABORT: preserve user doc missing after delete: ${uid}`);
    }
  }

  // 7) Auth delete
  process.stderr.write('[EXECUTE] auth users (customer/driver only)\n');
  const authDel = await deleteAuthUsers(
    authInfo.deleteCandidates,
    authInfo.AUTH_PRESERVE_UIDS,
    logProgress,
  );
  results.deleted.authUsers = authDel.deleted;
  results.abortedAuth = authDel.aborted;
  if (authDel.aborted.length) {
    process.stderr.write(
      `AUTH_ABORT_SKIPPED=${authDel.aborted.length} (preserve/non-customer-driver)\n`,
    );
  }

  results.finishedAt = new Date().toISOString();
  fs.writeFileSync(
    path.join(OUT, 'reset_1_execute_raw.json'),
    JSON.stringify(results, null, 2),
  );
  console.log(JSON.stringify({EXECUTE_COMPLETE: true, results}, null, 2));
  return results;
}

async function main() {
  if (EXECUTE && DRY_RUN === false) {
    // still compute plan first
    const report = await dryRun();
    // Do not dump full dry-run JSON during execute (huge); write plan snapshot
    fs.writeFileSync(
      path.join(OUT, 'reset_1_pre_execute_plan.json'),
      JSON.stringify(
        {
          PROJECT_MATCH: report.PROJECT_MATCH,
          RESET_EXECUTION_ALLOWED: report.RESET_EXECUTION_ALLOWED,
          backupGates: report.backupGates,
          gates: report.gates,
          deletePlan: report.deletePlan,
          AUTH_PRESERVE_UIDS: report.AUTH_PRESERVE_UIDS,
          AUTH: report.AUTH,
        },
        null,
        2,
      ),
    );
    await executeReset(report);
    return;
  }

  const report = await dryRun();
  console.log(JSON.stringify(report, null, 2));

  if (EXECUTE) {
    console.error(
      'EXECUTE requested but blocked: RESET_EXECUTION_ALLOWED=',
      report.RESET_EXECUTION_ALLOWED,
    );
    process.exit(2);
  }
}

main().catch((e) => {
  if (e.ABORT_RESET) {
    console.error(
      JSON.stringify({
        ABORT_RESET: true,
        ERROR: 'PROTECTED_REFERENCE_DATA_DELETE_ATTEMPT',
        collection: e.collection,
      }),
    );
  } else {
    console.error(e);
  }
  process.exit(1);
});
