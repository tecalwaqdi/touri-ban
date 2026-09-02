#!/usr/bin/env node
/**
 * FIN-9 — Controlled new order Agent snapshot (read/create → verify → optional cleanup flag).
 */
'use strict';

const admin = require('firebase-admin');
const path = require('path');
const agentSnap = require(path.join(__dirname, '..', 'agent_order_snapshot.js'));

const SA =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(process.env.HOME, 'Downloads/tutorial-multi-language-70gx4j-fb851be1eb3e.json');

const ORDER_ID = process.env.FIN9_ORDER_ID || `fin9_ctrl_${Date.now()}`;
const COUNTRY = process.env.FIN9_COUNTRY || 'countries/saudi_arabia';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SA)) });
}

const db = admin.firestore();

async function main() {
  const report = {
    orderId: ORDER_ID,
    country: COUNTRY,
    snapshot: {},
    pass: false,
    errors: [],
  };

  const existing = await db.collection('order').doc(ORDER_ID).get();
  if (!existing.exists) {
    const countryRef = db.doc(COUNTRY);
    await db.collection('order').doc(ORDER_ID).set({
      IDorder: ORDER_ID,
      Rev_dolh: countryRef,
      total: 50,
      total_app: 7.5,
      total_vat: 0,
      total_mndob: 42.5,
      total_mndob2: 50,
      status_code: 'completed',
      payment_status: 'pending_cash',
      payment_method: 'cash',
      data_order: admin.firestore.Timestamp.now(),
      fin9_controlled: true,
    });
    await agentSnap.applyAgentSnapshotOnCreate({
      db,
      orderId: ORDER_ID,
      order: (await db.collection('order').doc(ORDER_ID).get()).data(),
    });
  }

  const order = (await db.collection('order').doc(ORDER_ID).get()).data();
  report.snapshot = {
    agent_id: order.agent_id || null,
    agent_scope: order.agent_scope || null,
    agent_rate: order.agent_rate ?? null,
    agent_rate_type: order.agent_rate_type || null,
    agent_amount_minor: order.agent_amount_minor ?? null,
    agent_amount: order.agent_amount ?? null,
    agent_currency: order.agent_currency || null,
    agent_snapshot_at: order.agent_snapshot_at || null,
    agent_attribution_status: order.agent_attribution_status || null,
  };

  const platformMinor = 750;
  const expectedMinor = Math.round((platformMinor * order.agent_rate) / 100);
  const ok =
    order.agent_id &&
    order.agent_rate > 0 &&
    order.agent_rate_type === 'percent_of_platform_fee' &&
    order.agent_amount_minor === expectedMinor &&
    order.agent_currency === 'SAR' &&
    order.agent_snapshot_at &&
    order.agent_attribution_status === 'attributed';

  report.expectedMinor = expectedMinor;

  report.pass = !!ok;
  if (!ok) report.errors.push('SNAPSHOT_INCOMPLETE');

  console.log(JSON.stringify(report, null, 2));
  process.exit(ok ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
