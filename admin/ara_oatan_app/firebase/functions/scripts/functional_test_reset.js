'use strict';

/**
 * Safe functional-test reset — allowlisted UIDs only.
 *
 * Requires explicit confirmation:
 *   FUNCTIONAL_RESET_CONFIRM=YES_I_UNDERSTAND
 *
 * Env (comma-separated UIDs, no wildcards):
 *   TEST_CUSTOMER_UIDS
 *   TEST_DRIVER_UIDS
 *   TEST_SUPPORT_TICKET_IDS   (optional)
 *
 * Example:
 *   FUNCTIONAL_RESET_CONFIRM=YES_I_UNDERSTAND \
 *   TEST_CUSTOMER_UIDS=uid1,uid2 \
 *   TEST_DRIVER_UIDS=uid3 \
 *   GOOGLE_APPLICATION_CREDENTIALS=... \
 *   node scripts/functional_test_reset.js
 */

const admin = require('firebase-admin');

const CONFIRM = process.env.FUNCTIONAL_RESET_CONFIRM;
const PROJECT_ID =
  process.env.GCLOUD_PROJECT ||
  process.env.GCP_PROJECT ||
  'tutorial-multi-language-70gx4j';

function parseUidList(name) {
  const raw = process.env[name] || '';
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

function assertAllowlisted(uid, allowlist, label) {
  if (!allowlist.includes(uid)) {
    throw new Error(`Refusing ${label} ${uid}: not in allowlist env`);
  }
}

async function deleteQueryBatch(db, query) {
  const snap = await query.get();
  if (snap.empty) return 0;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  return snap.size;
}

async function resetCustomerBookings(db, uid) {
  let total = 0;
  const orders = db.collection('orders').where('user_ref', '==', db.doc(`users/${uid}`));
  total += await deleteQueryBatch(db, orders.limit(450));

  const notifs = db
    .collection('users')
    .doc(uid)
    .collection('notifications')
    .limit(450);
  total += await deleteQueryBatch(db, notifs);

  return total;
}

async function resetDriverRegistration(db, uid) {
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) return 0;

  await ref.set(
    {
      registration_status: 'draft',
      actev_mndob: false,
      registration_review_reason: admin.firestore.FieldValue.delete(),
      registration_requested_changes: admin.firestore.FieldValue.delete(),
      registration_resubmitted_at: admin.firestore.FieldValue.delete(),
    },
    {merge: true},
  );

  const notifs = ref.collection('notifications').limit(450);
  return deleteQueryBatch(db, notifs);
}

async function resetSupportTickets(db, ticketIds) {
  let total = 0;
  for (const id of ticketIds) {
    const ref = db.collection('support_tickets').doc(id);
    const snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      total += 1;
    }
  }
  return total;
}

async function main() {
  if (CONFIRM !== 'YES_I_UNDERSTAND') {
    console.error(
      'Blocked: set FUNCTIONAL_RESET_CONFIRM=YES_I_UNDERSTAND to run.',
    );
    process.exit(1);
  }

  const customerUids = parseUidList('TEST_CUSTOMER_UIDS');
  const driverUids = parseUidList('TEST_DRIVER_UIDS');
  const ticketIds = parseUidList('TEST_SUPPORT_TICKET_IDS');

  if (customerUids.length === 0 && driverUids.length === 0 && ticketIds.length === 0) {
    console.error('Nothing to reset: provide at least one allowlisted ID env var.');
    process.exit(1);
  }

  if (!admin.apps.length) {
    admin.initializeApp({projectId: PROJECT_ID});
  }
  const db = admin.firestore();

  const report = {
    projectId: PROJECT_ID,
    at: new Date().toISOString(),
    customers: {},
    drivers: {},
    supportTicketsDeleted: 0,
  };

  for (const uid of customerUids) {
    assertAllowlisted(uid, customerUids, 'customer');
    report.customers[uid] = await resetCustomerBookings(db, uid);
  }

  for (const uid of driverUids) {
    assertAllowlisted(uid, driverUids, 'driver');
    report.drivers[uid] = await resetDriverRegistration(db, uid);
  }

  report.supportTicketsDeleted = await resetSupportTickets(db, ticketIds);

  console.log(JSON.stringify(report, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
