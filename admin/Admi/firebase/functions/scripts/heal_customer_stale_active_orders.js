/**
 * DRY-RUN: find customers whose active_order_id points at a missing/terminal order.
 *
 * Usage:
 *   node scripts/heal_customer_stale_active_orders.js
 *   node scripts/heal_customer_stale_active_orders.js --apply
 *
 * Safe: --apply only clears active_order_id (+ active_order_updated_at) when the
 * referenced order is missing or terminal (completed/cancelled/expired).
 * Never deletes historical order docs.
 */
const admin = require('firebase-admin');

const APPLY = process.argv.includes('--apply');
const TERMINAL = new Set([
  'completed',
  'trip_completed',
  'cancelled',
  'canceled',
  'cancelled_by_admin',
  'cancelled_by_customer',
  'cancelled_by_driver',
  'expired',
]);

function isTerminal(order) {
  if (!order) return true;
  const code = String(order.status_code || '').trim().toLowerCase();
  if (code && TERMINAL.has(code)) return true;
  if (code.startsWith('cancelled') || code.startsWith('canceled')) return true;
  const halh = String(order.halh_text || order.halh || '').trim();
  if (['مكتمل', 'مكتملة', 'ملغي', 'ملغى', 'ملغية', 'منتهية الصلاحية'].includes(halh)) {
    return true;
  }
  return false;
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: 'tutorial-multi-language-70gx4j' });
  }
  const db = admin.firestore();
  const snap = await db.collection('user').limit(500).get();
  const candidates = [];

  for (const doc of snap.docs) {
    const u = doc.data() || {};
    if (u.ismndob === true || u.ismndom === true || u.Isagent === true) continue;
    const lock = String(u.active_order_id || u.activeOrderId || '').trim();
    if (!lock) continue;
    const orderSnap = await db.collection('order').doc(lock).get();
    const order = orderSnap.exists ? orderSnap.data() : null;
    if (!isTerminal(order)) continue;
    candidates.push({
      userId: doc.id,
      active_order_id: lock,
      orderExists: orderSnap.exists,
      status_code: order ? order.status_code || null : null,
      halh_text: order ? order.halh_text || null : null,
    });
  }

  console.log(JSON.stringify({
    mode: APPLY ? 'APPLY' : 'DRY_RUN',
    scannedUsers: snap.size,
    staleLocks: candidates.length,
    candidates,
  }, null, 2));

  if (!APPLY || candidates.length === 0) return;

  let batch = db.batch();
  let n = 0;
  for (const c of candidates) {
    batch.update(db.collection('user').doc(c.userId), {
      active_order_id: admin.firestore.FieldValue.delete(),
      active_order_updated_at: admin.firestore.FieldValue.delete(),
    });
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
