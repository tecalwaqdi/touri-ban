/**
 * DRY-RUN: heal driver-schema support tickets missing legacy `data`/`halh`.
 *
 * Usage:
 *   node scripts/heal_support_driver_schema.js
 *   node scripts/heal_support_driver_schema.js --apply
 */
const admin = require('firebase-admin');

const APPLY = process.argv.includes('--apply');

function mapStatus(status) {
  const s = String(status || '').trim().toLowerCase();
  if (s === 'resolved') return 'Resolved';
  if (s === 'closed') return 'Closed';
  return 'Open';
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: 'tutorial-multi-language-70gx4j' });
  }
  const db = admin.firestore();
  const snap = await db.collection('support').limit(500).get();
  const candidates = [];

  for (const doc of snap.docs) {
    const d = doc.data() || {};
    const isDriver =
      d.user && typeof d.user === 'object' && d.user.path &&
      (!d.RefUser || !d.data);
    if (!isDriver) continue;
    const needsData = !d.data && d.created_at;
    const needsHalh = !d.halh && d.status;
    if (!needsData && !needsHalh) continue;
    candidates.push({
      id: doc.id,
      needsData,
      needsHalh,
      status: d.status || null,
    });
  }

  console.log(JSON.stringify({
    mode: APPLY ? 'APPLY' : 'DRY_RUN',
    scanned: snap.size,
    candidates: candidates.length,
    sample: candidates.slice(0, 20),
  }, null, 2));

  if (!APPLY || candidates.length === 0) return;

  let batch = db.batch();
  let n = 0;
  for (const c of candidates) {
    const ref = db.collection('support').doc(c.id);
    const snapDoc = await ref.get();
    const d = snapDoc.data() || {};
    const patch = {};
    if (!d.data && d.created_at) patch.data = d.created_at;
    if (!d.halh && d.status) patch.halh = mapStatus(d.status);
    if (Object.keys(patch).length === 0) continue;
    batch.update(ref, patch);
    n++;
    if (n % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (n % 400 !== 0) await batch.commit();
  console.log(JSON.stringify({ healed: n }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
