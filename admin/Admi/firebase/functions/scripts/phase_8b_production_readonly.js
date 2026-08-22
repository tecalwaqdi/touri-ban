'use strict';

/**
 * Phase 8B — Production READ-ONLY audit (no writes, no PII dumps).
 * Project: tutorial-multi-language-70gx4j
 *
 * Auth:
 * 1) ADC / GOOGLE_APPLICATION_CREDENTIALS
 * 2) Firebase CLI refresh token from ~/.config/configstore/firebase-tools.json
 *
 * Usage: node scripts/phase_8b_production_readonly.js
 */

const admin = require('firebase-admin');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const financialV2 = require('../financial_accounting_v2');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FIREBASE_CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function anonRef(id) {
  if (!id) return '—';
  const s = String(id);
  if (s.length <= 8) return `${s.slice(0, 2)}…${s.slice(-2)}`;
  return `${s.slice(0, 4)}…${s.slice(-4)}`;
}

function majorFromMinor(minor, currency) {
  const exp =
    {SAR: 2, KWD: 3, BHD: 3, OMR: 3, JOD: 3}[String(currency || 'SAR').toUpperCase()] ?? 2;
  let f = 1;
  for (let i = 0; i < exp; i++) f *= 10;
  return Number(minor || 0) / f;
}

async function initDb() {
  try {
    admin.initializeApp({projectId: PROJECT_ID});
    await admin.firestore().doc('financial_config/runtime').get();
    return admin.firestore();
  } catch (_) {
    try {
      admin.app().delete();
    } catch (e2) {
      /* ignore */
    }
  }

  const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(cfgPath)) {
    throw new Error('ADC failed and firebase-tools login not found.');
  }
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  const refreshToken = cfg.tokens && cfg.tokens.refresh_token;
  if (!refreshToken) {
    throw new Error('ADC failed and no Firebase CLI refresh token.');
  }

  const {GoogleAuth} = require('google-auth-library');
  const auth = new GoogleAuth({
    credentials: {
      type: 'authorized_user',
      client_id: FIREBASE_CLI_CLIENT_ID,
      client_secret: FIREBASE_CLI_CLIENT_SECRET,
      refresh_token: refreshToken,
    },
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    projectId: PROJECT_ID,
  });
  const authClient = await auth.getClient();
  const {Firestore} = require('@google-cloud/firestore');
  return new Firestore({projectId: PROJECT_ID, authClient});
}

function paymentMethodBucket(o) {
  const m = String(o.PaymentMethod || o.paymentMethod || o.payment_method || '')
    .trim()
    .toLowerCase();
  if (m.includes('cash')) return 'cash';
  if (m.includes('online') || m.includes('card') || m.includes('ngenius')) return 'online';
  return 'unknown';
}

function scanFinance(orders) {
  const byCurrency = {};
  const lines = [];
  let missingPaymentStatus = 0;
  let missingLifecycle = 0;
  let missingDriver = 0;
  let unsupportedCurrency = 0;
  let cashOrders = 0;
  let onlineOrders = 0;
  let unknownMethod = 0;
  const lifecycle = {
    missingStatusCode: 0,
    completed: 0,
    active: 0,
    cancelled: 0,
    expired: 0,
    other: 0,
  };
  const paymentQuality = {
    missingPaymentStatus: 0,
    cashCollected: 0,
    pendingCash: 0,
    paid: 0,
    unpaid: 0,
    refunded: 0,
    other: 0,
  };
  let eligible = 0;
  let excluded = 0;

  for (const order of orders) {
    const pm = paymentMethodBucket(order);
    if (pm === 'cash') cashOrders++;
    else if (pm === 'online') onlineOrders++;
    else unknownMethod++;

    const line = financialV2.analyzeOrder(order.id, order);
    if (!order.payment_status) missingPaymentStatus++;
    if (!order.status_code) missingLifecycle++;
    if (!line.driverId) missingDriver++;
    if (!line.currencySupported) unsupportedCurrency++;

    if (!line.hasStatusCode) lifecycle.missingStatusCode++;
    else if (line.lifecycle === 'completed') lifecycle.completed++;
    else if (line.lifecycle === 'active') lifecycle.active++;
    else if (line.lifecycle === 'cancelled') lifecycle.cancelled++;
    else if (line.lifecycle === 'expired') lifecycle.expired++;
    else lifecycle.other++;

    const pay = line.payment;
    if (!line.hasPaymentStatus) paymentQuality.missingPaymentStatus++;
    else if (pay === 'cashCollected') paymentQuality.cashCollected++;
    else if (pay === 'pendingCash') paymentQuality.pendingCash++;
    else if (pay === 'paid' || pay === 'captured') paymentQuality.paid++;
    else if (pay === 'unpaid') paymentQuality.unpaid++;
    else if (pay === 'refunded') paymentQuality.refunded = (paymentQuality.refunded || 0) + 1;
    else paymentQuality.other++;

    lines.push(line);
    financialV2.accumulate(byCurrency, line);
    if (line.eligible) eligible++;
    else excluded++;
  }

  const exposure = {};
  for (const [code, t] of Object.entries(byCurrency)) {
    exposure[code] = {
      driversOweCompanyMajor: majorFromMinor(t.cashDriversOweCompanyMinor, code),
      companyOwesDriversMajor: majorFromMinor(
        t.cashCompanyOwesDriversMinor + t.onlineCompanyOwesDriversMinor,
        code,
      ),
      netTripExposureMajor: majorFromMinor(
        t.cashDriversOweCompanyMinor -
          t.cashCompanyOwesDriversMinor -
          t.onlineCompanyOwesDriversMinor,
        code,
      ),
    };
  }

  return {
    ordersTotal: orders.length,
    paymentMethod: {cash: cashOrders, online: onlineOrders, unknown: unknownMethod},
    quality: {
      high: lines.filter((l) => l.confidence === 'high').length,
      derived: lines.filter((l) => l.confidence === 'derived').length,
      incomplete: lines.filter((l) => l.confidence === 'incomplete').length,
    },
    lifecycle,
    paymentQuality,
    exposure,
    eligibility: {eligible, excluded},
    docsScanned: orders.length,
    missingPaymentStatus,
    missingLifecycle,
    missingDriver,
    unsupportedCurrency,
  };
}

async function main() {
  const out = {
    projectId: PROJECT_ID,
    readAt: new Date().toISOString(),
    PRODUCTION_READ_AUTH: 'BLOCKED',
    PROJECT_MATCH: 'PASS',
  };

  let db;
  try {
    db = await initDb();
    await db.doc('financial_config/runtime').get();
    out.PRODUCTION_READ_AUTH = 'PASS';
  } catch (e) {
    out.authError = String(e.message || e).slice(0, 240);
    console.log(JSON.stringify(out, null, 2));
    process.exit(2);
  }

  const cfgSnap = await db.doc('financial_config/runtime').get();
  const flags = cfgSnap.exists ? cfgSnap.data() : {};
  out.featureFlags = {
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: flags.FINANCIAL_SETTLEMENT_WRITES_ENABLED === true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: flags.FINANCIAL_PAYMENT_CONFIRM_ENABLED === true,
    WALLET_SETTLEMENT_ENABLED: flags.WALLET_SETTLEMENT_ENABLED === true,
    AUTOMATIC_PAYOUT_ENABLED: flags.AUTOMATIC_PAYOUT_ENABLED === true,
    allowSelfApproval: flags.allowSelfApproval === true,
    hasIndependentApprover: flags.hasIndependentApprover === true,
    independentApproverUidCount: Array.isArray(flags.independentApproverUids)
      ? flags.independentApproverUids.length
      : 0,
  };
  out.featureFlagsAllOff =
    !out.featureFlags.FINANCIAL_SETTLEMENT_WRITES_ENABLED &&
    !out.featureFlags.FINANCIAL_PAYMENT_CONFIRM_ENABLED &&
    !out.featureFlags.WALLET_SETTLEMENT_ENABLED &&
    !out.featureFlags.AUTOMATIC_PAYOUT_ENABLED;

  let superAdminCapable = 0;
  let financeCapable = 0;
  let bothCapable = 0;
  const userSnap = await db
    .collection('user')
    .select(
      'super_admin',
      'finance',
      'role',
      'superAdmin',
      'IsAdmin',
      'isAdmin',
      'isAdminRule',
      'IsAdminRule',
    )
    .get();
  userSnap.forEach((d) => {
    const x = d.data() || {};
    const rule = x.isAdminRule ?? x.IsAdminRule ?? 0;
    const ruleNum = typeof rule === 'string' ? parseInt(rule, 10) : rule;
    const sa =
      x.super_admin === true ||
      x.superAdmin === true ||
      x.IsAdmin === true ||
      x.isAdmin === true ||
      ruleNum === 1 ||
      String(x.role || '').toLowerCase().includes('super');
    const fin =
      x.finance === true ||
      String(x.role || '').toLowerCase() === 'finance' ||
      (sa && ruleNum === 1);
    if (sa) superAdminCapable++;
    if (fin) financeCapable++;
    if (sa && fin) bothCapable++;
  });
  out.roles = {
    usersScanned: userSnap.size,
    superAdminCapableCount: superAdminCapable,
    financeCapableCount: financeCapable,
    bothCapableCount: bothCapable,
  };
  const configured =
    flags.hasIndependentApprover === true ||
    (Array.isArray(flags.independentApproverUids) && flags.independentApproverUids.length >= 1);
  const distinctApprovers = superAdminCapable + financeCapable - bothCapable;
  out.INDEPENDENT_FINANCE_APPROVER_AVAILABLE =
    configured || (financeCapable >= 2) || (distinctApprovers >= 2 && (superAdminCapable >= 1 || financeCapable >= 1));

  const collections = [
    'financial_settlements',
    'financial_settlement_claims',
    'financial_settlement_payments',
    'financial_payment_allocations',
    'financial_periods',
    'financial_adjustments',
    'financial_audit_events',
  ];
  out.integrityCounts = {};
  for (const c of collections) {
    out.integrityCounts[c] = (await db.collection(c).count().get()).data().count;
  }

  const settlements = await db.collection('financial_settlements').get();
  const settlementById = new Map();
  settlements.forEach((d) => settlementById.set(d.id, d.data()));

  const claims = await db.collection('financial_settlement_claims').get();
  const payments = await db.collection('financial_settlement_payments').get();
  const allocations = await db.collection('financial_payment_allocations').get();
  const issues = [];
  const claimOrders = new Map();

  claims.forEach((d) => {
    const c = d.data() || {};
    const sid = String(c.settlementId || '');
    if (!settlementById.has(sid)) {
      issues.push({severity: 'high', type: 'claim_without_settlement', ref: anonRef(d.id)});
    }
    const oid = String(c.orderId || '');
    if (oid) {
      if (claimOrders.has(oid)) {
        issues.push({severity: 'high', type: 'duplicate_claim', ref: anonRef(oid)});
      } else claimOrders.set(oid, sid);
    }
    const st = settlementById.get(sid);
    if (st && String(st.status || '') === 'voided' && c.active !== false) {
      issues.push({severity: 'medium', type: 'claim_on_voided_settlement', ref: anonRef(d.id)});
    }
  });

  const receiptCodes = new Map();
  payments.forEach((d) => {
    const p = d.data() || {};
    const sid = String(p.settlementId || '');
    const st = settlementById.get(sid);
    if (!st) {
      issues.push({severity: 'high', type: 'payment_without_settlement', ref: anonRef(d.id)});
      return;
    }
    const due = Number(st.absoluteSettlementAmountMinor || 0);
    const amt = Number(p.amountMinor || 0);
    if (String(p.status || '') === 'confirmed' && amt > due) {
      issues.push({severity: 'high', type: 'payment_exceeds_due', ref: anonRef(d.id)});
    }
    if (p.currency && st.currency && p.currency !== st.currency) {
      issues.push({severity: 'high', type: 'currency_mismatch', ref: anonRef(d.id)});
    }
    if (p.driverId && st.driverId && p.driverId !== st.driverId) {
      issues.push({severity: 'high', type: 'driver_mismatch', ref: anonRef(d.id)});
    }
    const rc = String(p.receiptCode || p.receiptId || '');
    if (rc) {
      if (receiptCodes.has(rc)) {
        issues.push({severity: 'medium', type: 'duplicate_receipt', ref: anonRef(rc)});
      } else receiptCodes.set(rc, d.id);
    }
  });

  const allocKeys = new Map();
  allocations.forEach((d) => {
    const a = d.data() || {};
    const k = `${a.paymentId || ''}:${a.settlementId || ''}:${a.amountMinor || 0}`;
    if (allocKeys.has(k)) {
      issues.push({severity: 'medium', type: 'duplicate_allocation', ref: anonRef(d.id)});
    } else allocKeys.set(k, d.id);
  });

  out.integrityIssues = issues;
  out.integrityIssueCount = issues.length;

  const ordersSnap = await db.collection('order').get();
  const orders = ordersSnap.docs.map((d) => ({id: d.id, ...d.data()}));
  out.financeRescan = scanFinance(orders);

  const cpSnap = await db.collection('company_payments').limit(500).get();
  const legacy500 = [];
  let unallocatedCompanyPayments = 0;
  cpSnap.forEach((d) => {
    const p = d.data() || {};
    const linked = !!(p.orderIds || p.order_ids || p.orderId || p.settlementId);
    if (!linked) unallocatedCompanyPayments++;
    const amt = Number(p.amount || p.total || 0);
    if (Math.abs(Math.abs(amt) - 500) > 0.01) return;
    legacy500.push({
      ref: anonRef(d.id),
      amount: amt,
      currency: p.currency || p.Currency || null,
      status: p.status || p.Status || null,
      allocated: linked,
      hasDriver: !!(p.driverId || p.driver_id || p.mndob_user),
      direction: amt >= 0 ? 'credit' : 'debit',
    });
  });
  out.legacy500 = legacy500;
  out.unallocatedCompanyPayments = unallocatedCompanyPayments;

  const dueMajor = out.financeRescan.exposure.SAR
    ? out.financeRescan.exposure.SAR.driversOweCompanyMajor
    : null;
  const pay500 = legacy500.find(
    (x) => x.currency === 'SAR' && Math.abs(Math.abs(x.amount) - 500) < 0.01,
  );
  out.dryRun = {
    settlementDueMajor: dueMajor,
    paymentMajor: pay500 ? 500 : null,
    paymentDirection: pay500 ? pay500.direction : null,
    outstandingMajor: dueMajor != null && pay500 ? Math.max(0, dueMajor - 500) : null,
    note: 'hypothetical only — no allocation performed',
  };

  // Pilot dry-run preview (no writes): best SAR driver with eligible trips
  const driverEligible = new Map();
  for (const order of orders) {
    const line = financialV2.analyzeOrder(order.id, order);
    if (!line.eligible || line.currency !== 'SAR' || !line.driverId) continue;
    const cur = driverEligible.get(line.driverId) || {
      driverId: line.driverId,
      trips: 0,
      high: 0,
      derived: 0,
      excluded: 0,
      cashHeldMinor: 0,
      driverNetMinor: 0,
      platformMinor: 0,
      vatMinor: 0,
      discountMinor: 0,
    };
    cur.trips++;
    if (line.confidence === 'high') cur.high++;
    if (line.confidence === 'derived') cur.derived++;
    cur.cashHeldMinor += line.cashHeldMinor || 0;
    cur.driverNetMinor += line.driverNetMinor || 0;
    cur.platformMinor += line.platformFeeMinor || 0;
    cur.vatMinor += line.recordedVatMinor || 0;
    cur.discountMinor += line.recordedDiscountMinor || 0;
    driverEligible.set(line.driverId, cur);
  }
  let best = null;
  for (const v of driverEligible.values()) {
    if (!best || v.trips > best.trips) best = v;
  }
  if (best) {
    const preview = financialV2.settlePreviewForDriver(
      orders.map((o) => financialV2.analyzeOrder(o.id, o)),
      best.driverId,
      'SAR',
    );
    out.pilotDryRun = {
      driverRef: anonRef(best.driverId),
      currency: 'SAR',
      eligibleTrips: best.trips,
      high: best.high,
      derived: best.derived,
      cashHeldMajor: majorFromMinor(best.cashHeldMinor, 'SAR'),
      driverEntitlementMajor: majorFromMinor(best.driverNetMinor, 'SAR'),
      platformFeeMajor: majorFromMinor(best.platformMinor, 'SAR'),
      vatMajor: majorFromMinor(best.vatMinor, 'SAR'),
      discountMajor: majorFromMinor(best.discountMinor, 'SAR'),
      netSettlementMajor: majorFromMinor(preview.netTripSettlementMinor, 'SAR'),
      direction: preview.direction,
      makerCheckerAccountsRequired: 2,
      makerCheckerAccountsAvailable: out.INDEPENDENT_FINANCE_APPROVER_AVAILABLE,
      expectedLock: 'Creates immutable settlement snapshot + order claims (not executed)',
      expectedPayment: 'Pending → confirm workflow; no wallet movement (not executed)',
    };
  } else {
    out.pilotDryRun = {note: 'No SAR eligible driver trips found for dry-run preview'};
  }

  console.log(JSON.stringify(out, null, 2));
}

main().catch((e) => {
  console.error(JSON.stringify({ok: false, error: String(e.message || e)}));
  process.exit(1);
});
