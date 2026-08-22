/**
 * Live read-only profile of company_payments + transactions (no PII dump).
 * Usage: node scripts/profile_legacy_finance.js
 * Requires Firebase Admin credentials via GOOGLE_APPLICATION_CREDENTIALS
 * or `firebase login` ADC.
 */
'use strict';

const admin = require('firebase-admin');

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({projectId: 'tutorial-multi-language-70gx4j'});
  }
  const db = admin.firestore();

  const cpSnap = await db.collection('company_payments').limit(2000).get();
  const currencies = {};
  const statuses = {};
  const drivers = new Set();
  const creators = new Set();
  let withOrderIds = 0;
  let withIdempotency = 0;
  let amountByCurrency = {};
  let minTs = null;
  let maxTs = null;

  for (const doc of cpSnap.docs) {
    const d = doc.data();
    const cur = String(d.currency || d.Currency || 'UNKNOWN').toUpperCase();
    currencies[cur] = (currencies[cur] || 0) + 1;
    const st = String(d.status || d.Status || 'unknown');
    statuses[st] = (statuses[st] || 0) + 1;
    if (d.driverId || d.driver_id || d.mndob_user) {
      const id = d.driverId || d.driver_id || (d.mndob_user && d.mndob_user.id);
      if (id) drivers.add(String(id));
    }
    if (d.createdBy || d.created_by || d.adminId) {
      creators.add(String(d.createdBy || d.created_by || d.adminId));
    }
    if (d.orderIds || d.order_ids || d.orderId || d.settlementId) withOrderIds++;
    if (d.idempotencyKey || d.idempotency_key) withIdempotency++;
    const amt = Number(d.amount || d.total || 0);
    amountByCurrency[cur] = (amountByCurrency[cur] || 0) + amt;
    const ts = d.createdAt || d.created_at || d.data || d.timestamp;
    if (ts && ts.toDate) {
      const dt = ts.toDate();
      if (!minTs || dt < minTs) minTs = dt;
      if (!maxTs || dt > maxTs) maxTs = dt;
    }
  }

  console.log(JSON.stringify({
    company_payments: {
      scanned: cpSnap.size,
      currencies,
      statuses,
      distinctDrivers: drivers.size,
      distinctCreators: creators.size,
      withOrderOrSettlementRef: withOrderIds,
      withIdempotency,
      amountMajorByCurrency: amountByCurrency,
      dateMin: minTs && minTs.toISOString(),
      dateMax: maxTs && maxTs.toISOString(),
      allocation: withOrderIds === 0 ? 'UNALLOCATED' : 'SOME_LINKED',
    },
  }, null, 2));

  const txSnap = await db.collection('transactions').limit(3000).get();
  const types = {};
  const typeAmount = {};
  let txWithOrder = 0;
  let txWithDriver = 0;
  let txWithCp = 0;
  let txIdem = 0;

  for (const doc of txSnap.docs) {
    const d = doc.data();
    const type = String(d.type || d.Type || 'unknown');
    types[type] = (types[type] || 0) + 1;
    const cur = String(d.currency || 'UNKNOWN').toUpperCase();
    if (!typeAmount[type]) typeAmount[type] = {};
    typeAmount[type][cur] = (typeAmount[type][cur] || 0) + Number(d.amount || 0);
    if (d.orderId || d.order_id || d.orderIds) txWithOrder++;
    if (d.driverId || d.userId || d.mndob_user) txWithDriver++;
    if (d.companyPaymentId || d.company_payment_id) txWithCp++;
    if (d.idempotencyKey || d.idempotency_key) txIdem++;
  }

  console.log(JSON.stringify({
    transactions: {
      scanned: txSnap.size,
      types,
      typeAmountMajorByCurrency: typeAmount,
      withOrder: txWithOrder,
      withDriver: txWithDriver,
      withCompanyPayment: txWithCp,
      withIdempotency: txIdem,
      note: 'Cash movement vs wallet movement is type-dependent; company_payment often wallet; admin_adjustment wallet.',
    },
  }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
