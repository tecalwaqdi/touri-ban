/**
 * Read-only live driver counter sanity check (Production).
 * Compares aggregate counts — no writes, no PII.
 */
'use strict';

const admin = require('firebase-admin');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();

async function countQuery(q) {
  const snap = await q.count().get();
  return snap.data().count;
}

async function main() {
  const base = db.collection('user').where('ismndob', '==', true);
  const total = await countQuery(base);
  const v2Total = await countQuery(
    base.where('registration_flow_version', '==', 2),
  );
  const legacyTotal = total >= v2Total ? total - v2Total : 0;
  const pendingReview = await countQuery(
    base.where('registration_status', 'in', ['pending_review', 'submitted']),
  );
  const approved = await countQuery(base.where('registration_status', '==', 'approved'));
  const rejected = await countQuery(base.where('registration_status', '==', 'rejected'));
  const needsChanges = await countQuery(
    base.where('registration_status', 'in', ['needs_changes', 'changes_requested']),
  );
  const activated = await countQuery(base.where('actev_mndob', '==', true));
  const deactivated = await countQuery(base.where('actev_mndob', '==', false));

  console.log(
    JSON.stringify(
      {
        PROJECT_MATCH: PROJECT_ID,
        COUNTERS_LIVE: {
          total,
          v2Total,
          legacyTotal,
          v2LegacyBalance: total === v2Total + legacyTotal,
          pendingReview,
          approved,
          rejected,
          needsChanges,
          activated,
          deactivated,
        },
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error('COUNTERS_LIVE_BLOCKED', String(e.message).slice(0, 200));
  process.exit(1);
});
