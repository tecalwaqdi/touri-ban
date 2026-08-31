/**
 * Idempotent DRY-RUN / APPLY heal for safe Admin↔Driver mismatches.
 *
 * Safe only:
 * 1) ismndom==true && ismndob!=true → set ismndob:true (additive)
 * 2) pending_review + actev_mndob true + account_status inactive + no approvedAt
 *    → set actev_mndob:false (align CF submit / prevent false "approved" gate)
 *
 * Usage:
 *   node scripts/heal_driver_data_mismatches.js --dry-run
 *   node scripts/heal_driver_data_mismatches.js --apply
 */
const admin = require('firebase-admin');
const path = require('path');

const SA =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  '/Users/ventura/Downloads/tutorial-multi-language-70gx4j-fb851be1eb3e.json';

const apply = process.argv.includes('--apply');
const dryRun = !apply;

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(require(SA)),
  });
}
const db = admin.firestore();

function hasApprovedAt(d) {
  return !!(d.approvedAt || d.approved_at);
}

(async () => {
  const snap = await db.collection('user').get();
  const counts = {
    scanned: snap.size,
    healIsmndob: 0,
    healActevPending: 0,
    skippedRenewalPendingActive: 0,
  };
  const details = [];

  for (const doc of snap.docs) {
    const d = doc.data() || {};
    const patch = {};

    if (d.ismndom === true && d.ismndob !== true) {
      patch.ismndob = true;
      counts.healIsmndob++;
    }

    const reg = String(d.registration_status || '').trim();
    if (
      reg === 'pending_review' &&
      d.actev_mndob === true &&
      d.account_status === 'inactive' &&
      !hasApprovedAt(d)
    ) {
      patch.actev_mndob = false;
      patch.ngl = false;
      if (!d.operational_status) patch.operational_status = 'offline';
      counts.healActevPending++;
    } else if (
      (reg === 'pending_review' || reg === 'submitted') &&
      d.actev_mndob === true &&
      hasApprovedAt(d)
    ) {
      counts.skippedRenewalPendingActive++;
    }

    if (Object.keys(patch).length === 0) continue;
    details.push({id: doc.id, patch, before: {
      ismndob: d.ismndob ?? null,
      ismndom: d.ismndom ?? null,
      registration_status: d.registration_status ?? null,
      actev_mndob: d.actev_mndob ?? null,
      account_status: d.account_status ?? null,
    }});
    if (apply) {
      patch.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      patch._admin_heal = {
        at: admin.firestore.FieldValue.serverTimestamp(),
        source: 'heal_driver_data_mismatches',
        keys: Object.keys(patch).filter((k) => k !== 'updatedAt' && k !== '_admin_heal'),
      };
      await doc.ref.set(patch, {merge: true});
    }
  }

  console.log(JSON.stringify({
    mode: dryRun ? 'DRY_RUN' : 'APPLY',
    counts,
    details,
  }, null, 2));
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
