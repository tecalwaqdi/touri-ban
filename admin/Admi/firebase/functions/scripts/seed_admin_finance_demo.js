#!/usr/bin/env node
/**
 * TOURi Admin — SAFE finance UI demo dataset (cash-only).
 *
 * Usage:
 *   ALLOW_TOURI_DEMO_SEED=YES node scripts/seed_admin_finance_demo.js --dry-run
 *   ALLOW_TOURI_DEMO_SEED=YES node scripts/seed_admin_finance_demo.js --apply
 *   ALLOW_TOURI_DEMO_SEED=YES node scripts/seed_admin_finance_demo.js --cleanup
 *
 * Safety:
 *  - Requires ALLOW_TOURI_DEMO_SEED=YES
 *  - Requires Firebase project tutorial-multi-language-70gx4j
 *  - Deterministic demo_fin_* IDs (idempotent)
 *  - Cleanup deletes ONLY admin_demo_fixture + demo_seed_group match
 *  - Never modifies real wallets / users / agents / ActiveOrder
 */
'use strict';

const admin = require('firebase-admin');
const {execSync} = require('child_process');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const SEED_VERSION = 'finance_ui_v1';
const SEED_GROUP = 'TOURI_ADMIN_FINANCE_DEMO';
const SA =
  'firebase-adminsdk-vqcu4@tutorial-multi-language-70gx4j.iam.gserviceaccount.com';

const MARKERS = Object.freeze({
  is_demo: true,
  admin_demo_fixture: true,
  demo_seed_version: SEED_VERSION,
  demo_seed_group: SEED_GROUP,
  exclude_from_real_reporting: true,
});

function parseArgs(argv) {
  return {
    dryRun: argv.includes('--dry-run') || (!argv.includes('--apply') && !argv.includes('--cleanup')),
    apply: argv.includes('--apply'),
    cleanup: argv.includes('--cleanup'),
  };
}

function assertSafetyGate() {
  if (process.env.ALLOW_TOURI_DEMO_SEED !== 'YES') {
    console.error('ABORT: set ALLOW_TOURI_DEMO_SEED=YES');
    process.exit(2);
  }
  const project =
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    PROJECT_ID;
  if (project !== PROJECT_ID) {
    console.error(`ABORT: project must be ${PROJECT_ID}, got ${project}`);
    process.exit(2);
  }
}

function daysAgo(n, hour = 12) {
  const d = new Date();
  d.setUTCHours(hour, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() - n);
  return d;
}

function money50() {
  return {
    total: 50,
    total_mndob2: 50,
    total_app: 7.5,
    total_vat: 0,
    total_mndob: 42.5,
    currency: 'SAR',
  };
}

function moneyVat() {
  return {
    total: 800,
    total_mndob2: 800,
    total_app: 120,
    total_vat: 120,
    total_mndob: 560,
    currency: 'SAR',
  };
}

function agentSnap({rate = 5, platformFee = 7.5} = {}) {
  const agentAmount = Math.round(platformFee * (rate / 100) * 100) / 100;
  const agentAmountMinor = Math.round(platformFee * 100 * (rate / 100));
  return {
    agent_id: 'demo_fin_agent_001',
    agent_display_name: 'Demo Agent (Finance UI)',
    agent_scope: 'country',
    agent_rate: rate,
    agent_rate_type: 'percent_of_platform_fee',
    agent_amount: agentAmount,
    agent_amount_minor: agentAmountMinor,
    agent_currency: 'SAR',
    agent_snapshot_at: new Date().toISOString(),
    agent_snapshot_version: 'FIN-9',
    agent_attribution_status: 'attributed',
  };
}

/** @returns {Array<{id:string, collection:string, data:object}>} */
function buildPlan(db) {
  const countryPath = 'countries/saudi_arabia';
  const countryRef = db.doc(countryPath);
  const driverRef = db.doc('user/demo_fin_driver_001');
  const docs = [];

  docs.push({
    collection: 'user',
    id: 'demo_fin_driver_001',
    data: {
      ...MARKERS,
      display_name: 'Demo Driver Finance',
      email: 'demo.driver.finance@touri-taxi.invalid',
      actev_user: false,
      IsAdmin: false,
      isAdminRule: 0,
      Isagent: false,
      isagent: false,
      created_by_qa: false,
      panel_persona: 'demo_driver_stub',
      note: 'Stub identity for Admin finance demo trips only — not an operational driver.',
    },
  });

  const tripDefs = [
    {
      id: 'demo_fin_trip_001',
      scenario: 'A_complete_collected_unsettled',
      daysAgo: 0,
      money: money50(),
      collected: true,
      agent: false,
      settlementStatus: 'unsettled',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_002',
      scenario: 'B_complete_collected_partial',
      daysAgo: 1,
      money: money50(),
      collected: true,
      agent: false,
      settlementStatus: 'partially_paid',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_003',
      scenario: 'C_complete_collected_settled',
      daysAgo: 2,
      money: money50(),
      collected: true,
      agent: false,
      settlementStatus: 'settled',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_004',
      scenario: 'D_complete_uncollected',
      daysAgo: 3,
      money: money50(),
      collected: false,
      agent: false,
      settlementStatus: 'unsettled',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_005',
      scenario: 'E_partial_missing_money',
      daysAgo: 4,
      money: {total: 50, total_mndob2: 50, currency: 'SAR'},
      collected: true,
      agent: false,
      settlementStatus: 'unsettled',
      financialState: 'PARTIAL',
      omitFields: ['total_app', 'total_vat', 'total_mndob'],
    },
    {
      id: 'demo_fin_trip_006',
      scenario: 'F_partial_missing_agent_snapshot',
      daysAgo: 5,
      money: money50(),
      collected: true,
      agent: false,
      forceMissingAgent: true,
      settlementStatus: 'unsettled',
      financialState: 'PARTIAL',
    },
    {
      id: 'demo_fin_trip_007',
      scenario: 'G_complete_agent_unsettled',
      daysAgo: 6,
      money: money50(),
      collected: true,
      agent: true,
      settlementStatus: 'unsettled',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_008',
      scenario: 'H_complete_agent_settled',
      daysAgo: 8,
      money: money50(),
      collected: true,
      agent: true,
      settlementStatus: 'settled',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_009',
      scenario: 'I_vat_800',
      daysAgo: 10,
      money: moneyVat(),
      collected: true,
      agent: false,
      settlementStatus: 'unsettled',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_010',
      scenario: 'J_standard_50',
      daysAgo: 12,
      money: money50(),
      collected: true,
      agent: true,
      settlementStatus: 'unsettled',
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_011',
      scenario: 'K_needs_review',
      daysAgo: 20,
      money: money50(),
      collected: true,
      agent: false,
      settlementStatus: 'unsettled',
      financialState: 'COMPLETE',
      needsReview: true,
    },
    {
      id: 'demo_fin_trip_012',
      scenario: 'L_non_completed_filter_proof',
      daysAgo: 1,
      money: money50(),
      collected: false,
      agent: false,
      completed: false,
      financialState: 'COMPLETE',
    },
    {
      id: 'demo_fin_trip_013',
      scenario: 'prev_month_complete',
      daysAgo: 40,
      money: money50(),
      collected: true,
      agent: true,
      settlementStatus: 'partially_paid',
      financialState: 'COMPLETE',
    },
  ];

  for (const t of tripDefs) {
    const when = daysAgo(t.daysAgo, 10 + (t.daysAgo % 5));
    const completed = t.completed !== false;
    const data = {
      ...MARKERS,
      demo_scenario: t.scenario,
      financial_demo_state: t.financialState,
      status_code: completed ? 'completed' : 'pending_driver',
      halh: completed ? 'مكتمل' : 'بإنتظار قبول المندوب',
      ALLNOW: false,
      ActiveOrder: false,
      PaymentMethod: 'cash',
      payment_status: t.collected ? 'cash_collected' : 'pending_cash',
      cash_collection_status: t.collected ? 'collected' : 'pending',
      Rev_dolh: countryRef,
      mndob_user: driverRef,
      data_order: admin.firestore.Timestamp.fromDate(when),
      created_time: admin.firestore.Timestamp.fromDate(when),
      order_display_id: `DEMO-${t.id.slice(-3).toUpperCase()}`,
      ...t.money,
    };
    if (t.collected) {
      data.cash_collected_at = admin.firestore.Timestamp.fromDate(when);
    }
    if (t.agent) {
      Object.assign(data, agentSnap({
        rate: 5,
        platformFee: Number(t.money.total_app || 7.5),
      }));
    }
    if (t.forceMissingAgent) {
      data.agent_attribution_status = 'none';
    }
    if (t.needsReview) {
      data.recon_demo_flag = 'NEEDS_REVIEW';
      data.settlement_status = 'mismatch_demo';
    }
    if (t.settlementStatus) {
      data.settlement_status = t.settlementStatus;
    }
    if (t.omitFields) {
      for (const f of t.omitFields) delete data[f];
    }
    docs.push({collection: 'order', id: t.id, data});
  }

  // Settlements — cash DRIVER_PAYS_COMPANY
  const settlements = [
    {
      id: 'demo_fin_settlement_001',
      status: 'locked',
      absoluteSettlementAmountMinor: 750,
      paidConfirmedMinor: 0,
      outstandingMinor: 750,
      eligibleOrderIds: ['demo_fin_trip_001', 'demo_fin_trip_007'],
      label: 'unsettled_7_50',
    },
    {
      id: 'demo_fin_settlement_002',
      status: 'partially_paid',
      absoluteSettlementAmountMinor: 750,
      paidConfirmedMinor: 300,
      outstandingMinor: 450,
      eligibleOrderIds: ['demo_fin_trip_002', 'demo_fin_trip_013'],
      label: 'partial_3_of_7_50',
    },
    {
      id: 'demo_fin_settlement_003',
      status: 'settled',
      absoluteSettlementAmountMinor: 750,
      paidConfirmedMinor: 750,
      outstandingMinor: 0,
      eligibleOrderIds: ['demo_fin_trip_003', 'demo_fin_trip_008'],
      label: 'settled_7_50',
    },
  ];

  for (const s of settlements) {
    const created = daysAgo(2);
    docs.push({
      collection: 'financial_settlements',
      id: s.id,
      data: {
        ...MARKERS,
        demo_scenario: s.label,
        settlementCode: `DEMO-STL-${s.id.slice(-3).toUpperCase()}`,
        status: s.status,
        direction: 'DRIVER_PAYS_COMPANY',
        currency: 'SAR',
        countryId: countryPath,
        countryRef: countryPath,
        driverId: 'demo_fin_driver_001',
        driverDisplayName: 'Demo Driver Finance',
        absoluteSettlementAmountMinor: s.absoluteSettlementAmountMinor,
        paidConfirmedMinor: s.paidConfirmedMinor,
        outstandingMinor: s.outstandingMinor,
        paymentCount: s.paidConfirmedMinor > 0 ? 1 : 0,
        eligibleOrderIds: s.eligibleOrderIds,
        orderIds: s.eligibleOrderIds,
        periodStart: daysAgo(45).toISOString(),
        periodEnd: daysAgo(0).toISOString(),
        createdAt: admin.firestore.Timestamp.fromDate(created),
        updatedAt: admin.firestore.Timestamp.fromDate(created),
        idempotencyKey: `demo_fin_${s.id}`,
      },
    });
  }

  // Payment / movement rows (read model only — no wallet writes)
  docs.push({
    collection: 'financial_settlement_payments',
    id: 'demo_fin_payment_001',
    data: {
      ...MARKERS,
      settlementId: 'demo_fin_settlement_002',
      settlementCode: 'DEMO-STL-002',
      amountMinor: 300,
      currency: 'SAR',
      direction: 'DRIVER_PAYS_COMPANY',
      status: 'confirmed',
      externalRef: 'DEMO-PAY-001',
      actorUid: 'demo_fin_seed',
      actorRole: 'seed_script',
      createdAt: admin.firestore.Timestamp.fromDate(daysAgo(1)),
      confirmedAt: admin.firestore.Timestamp.fromDate(daysAgo(1)),
    },
  });
  docs.push({
    collection: 'financial_settlement_payments',
    id: 'demo_fin_payment_002',
    data: {
      ...MARKERS,
      settlementId: 'demo_fin_settlement_003',
      settlementCode: 'DEMO-STL-003',
      amountMinor: 750,
      currency: 'SAR',
      direction: 'DRIVER_PAYS_COMPANY',
      status: 'confirmed',
      externalRef: 'DEMO-PAY-002',
      actorUid: 'demo_fin_seed',
      actorRole: 'seed_script',
      createdAt: admin.firestore.Timestamp.fromDate(daysAgo(2)),
      confirmedAt: admin.firestore.Timestamp.fromDate(daysAgo(2)),
    },
  });

  // Audit events (Admin Finance Audit search surface)
  const auditEvents = [
    {
      id: 'demo_fin_audit_001',
      eventType: 'DEMO_SETTLEMENT_CREATED',
      settlementId: 'demo_fin_settlement_001',
      settlementCode: 'DEMO-STL-001',
    },
    {
      id: 'demo_fin_audit_002',
      eventType: 'DEMO_SETTLEMENT_PARTIAL_PAYMENT',
      settlementId: 'demo_fin_settlement_002',
      settlementCode: 'DEMO-STL-002',
    },
    {
      id: 'demo_fin_audit_003',
      eventType: 'DEMO_SETTLEMENT_COMPLETED',
      settlementId: 'demo_fin_settlement_003',
      settlementCode: 'DEMO-STL-003',
    },
  ];
  for (const a of auditEvents) {
    docs.push({
      collection: 'financial_audit_events',
      id: a.id,
      data: {
        ...MARKERS,
        eventType: a.eventType,
        settlementId: a.settlementId,
        settlementCode: a.settlementCode,
        driverId: 'demo_fin_driver_001',
        actorUid: 'demo_fin_seed',
        timestamp: daysAgo(1).toISOString(),
        createdAt: admin.firestore.Timestamp.fromDate(daysAgo(1)),
      },
    });
  }

  return docs;
}

async function initAdmin() {
  if (admin.apps.length) return admin.app();
  admin.initializeApp({projectId: PROJECT_ID});
  return admin.app();
}

function encodeFirestoreValue(value) {
  if (value === null || value === undefined) return {nullValue: null};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return {integerValue: String(value)};
    return {doubleValue: value};
  }
  if (typeof value === 'string') return {stringValue: value};
  if (value instanceof admin.firestore.Timestamp) {
    return {timestampValue: value.toDate().toISOString()};
  }
  if (value instanceof Date) {
    return {timestampValue: value.toISOString()};
  }
  if (value && typeof value.path === 'string' && typeof value.id === 'string') {
    // DocumentReference
    return {
      referenceValue:
        `projects/${PROJECT_ID}/databases/(default)/documents/${value.path}`,
    };
  }
  if (Array.isArray(value)) {
    return {arrayValue: {values: value.map(encodeFirestoreValue)}};
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      fields[k] = encodeFirestoreValue(v);
    }
    return {mapValue: {fields}};
  }
  return {stringValue: String(value)};
}

function toFirestoreDocument(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] = encodeFirestoreValue(v);
  }
  return {fields};
}

function impersonatedAccessToken() {
  return execSync(
    `gcloud auth print-access-token --impersonate-service-account=${SA}`,
    {encoding: 'utf8'},
  ).trim();
}

async function restCommit(docs) {
  const access = impersonatedAccessToken();
  // Firestore commit max 500 writes; we have ~22.
  const writes = docs.map((doc) => ({
    update: {
      name:
        `projects/${PROJECT_ID}/databases/(default)/documents/${doc.collection}/${doc.id}`,
      ...toFirestoreDocument(doc.data),
    },
  }));
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:commit`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${access}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({writes}),
    },
  );
  const json = await res.json();
  if (!res.ok || json.error) {
    throw new Error(
      `Firestore REST commit failed: ${JSON.stringify(json.error || json).slice(0, 400)}`,
    );
  }
  return json;
}

async function restCleanup() {
  const access = impersonatedAccessToken();
  const collections = [
    'order',
    'financial_settlements',
    'financial_settlement_payments',
    'financial_audit_events',
    'user',
  ];
  let scanned = 0;
  let deleted = 0;
  const deletedIds = [];

  for (const col of collections) {
    const url =
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
    const body = {
      structuredQuery: {
        from: [{collectionId: col}],
        where: {
          fieldFilter: {
            field: {fieldPath: 'demo_seed_group'},
            op: 'EQUAL',
            value: {stringValue: SEED_GROUP},
          },
        },
      },
    };
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${access}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
    const rows = await res.json();
    if (!Array.isArray(rows)) {
      throw new Error(`cleanup query failed for ${col}: ${JSON.stringify(rows).slice(0, 200)}`);
    }
    const deletes = [];
    for (const row of rows) {
      const name = row.document?.name;
      if (!name) continue;
      scanned += 1;
      const fields = row.document.fields || {};
      const isDemo = fields.admin_demo_fixture?.booleanValue === true;
      const group = fields.demo_seed_group?.stringValue;
      if (!isDemo || group !== SEED_GROUP) continue;
      deletes.push({delete: name});
      deletedIds.push(name.split('/documents/')[1]);
    }
    if (deletes.length) {
      const delRes = await fetch(
        `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:commit`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${access}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({writes: deletes}),
        },
      );
      const delJson = await delRes.json();
      if (!delRes.ok || delJson.error) {
        throw new Error(`cleanup commit failed: ${JSON.stringify(delJson.error || delJson).slice(0, 300)}`);
      }
      deleted += deletes.length;
    }
  }

  console.log(JSON.stringify({
    MODE: 'CLEANUP',
    SCANNED_BEFORE: scanned,
    DELETED: deleted,
    FILTER: {
      admin_demo_fixture: true,
      demo_seed_group: SEED_GROUP,
    },
    IDS: deletedIds,
  }, null, 2));
  return {scanned, deleted};
}

async function applyDocs(docs, {dryRun}) {
  const counts = {
    order: 0,
    financial_settlements: 0,
    financial_settlement_payments: 0,
    financial_audit_events: 0,
    user: 0,
    other: 0,
  };
  console.log(JSON.stringify({
    MODE: dryRun ? 'DRY_RUN' : 'APPLY',
    PROJECT: PROJECT_ID,
    SEED_VERSION,
    SEED_GROUP,
    PLANNED_DOCS: docs.length,
  }, null, 2));

  for (const doc of docs) {
    counts[doc.collection] = (counts[doc.collection] || 0) + 1;
    console.log(`  ${dryRun ? 'PLAN' : 'SET'} ${doc.collection}/${doc.id}`);
  }

  if (!dryRun) {
    await restCommit(docs);
  }
  console.log(JSON.stringify({COUNTS: counts}, null, 2));
  return counts;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  assertSafetyGate();
  // Admin SDK only needed for Timestamp/FieldValue helpers + DocumentReference.
  if (!admin.apps.length) {
    admin.initializeApp({projectId: PROJECT_ID});
  }
  const db = admin.firestore();

  if (args.cleanup) {
    await restCleanup();
    return;
  }

  const docs = buildPlan(db);
  const dryRun = !args.apply || args.dryRun;
  const counts = await applyDocs(docs, {dryRun});

  if (!dryRun) {
    // Second apply proves idempotency (same IDs → overwrite, no duplicates).
    await applyDocs(docs, {dryRun: false});
    console.log(JSON.stringify({
      VERIFY: {
        planned_orders: counts.order,
        planned_settlements: counts.financial_settlements,
        planned_movements: counts.financial_settlement_payments,
        planned_audit: counts.financial_audit_events,
        planned_users: counts.user,
        duplicate_docs_on_rerun: 0,
      },
    }, null, 2));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
