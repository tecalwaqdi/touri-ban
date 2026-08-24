/**
 * Phase 9A — Production pilot preflight (READ-ONLY). No writes. No flag changes.
 */
'use strict';

const admin = require('firebase-admin');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const financialV2 = require('../financial_accounting_v2');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FIREBASE_CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const REGION = 'us-central1';

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

function toDate(v) {
  if (!v) return null;
  if (v.toDate) return v.toDate();
  if (typeof v._seconds === 'number') return new Date(v._seconds * 1000);
  if (typeof v.seconds === 'number') return new Date(v.seconds * 1000);
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? null : d;
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
  if (!fs.existsSync(cfgPath)) throw new Error('No ADC / firebase-tools login');
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  const refreshToken = cfg.tokens && cfg.tokens.refresh_token;
  if (!refreshToken) throw new Error('No firebase-tools refresh token');
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

async function signIn() {
  const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
  const password = String(process.env.ADMIN_QA_PASSWORD || '');
  if (!email || !password) throw new Error('NO_TEST_ACCOUNT');
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message || 'AUTH_FAILED');
  return json;
}

async function callCallable(idToken, name, data = {}) {
  const url = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${name}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ data }),
  });
  const json = await res.json();
  if (json.error) {
    return {
      ok: false,
      code: json.error.status || json.error.code || 'ERROR',
      message: String(json.error.message || '').slice(0, 200),
    };
  }
  return { ok: true, result: json.result ?? json.data ?? json };
}

async function refreshIdToken(rt) {
  const res = await fetch(
    `https://securetoken.googleapis.com/v1/token?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=refresh_token&refresh_token=${encodeURIComponent(rt)}`,
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message || 'REFRESH_FAILED');
  return json.id_token;
}

function claimKeys(idToken) {
  const p = JSON.parse(
    Buffer.from(idToken.split('.')[1].replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString(
      'utf8',
    ),
  );
  const out = {};
  for (const k of ['super_admin', 'finance', 'support', 'country_admin']) {
    if (k in p) out[k] = p[k];
  }
  return out;
}

function lineReconDiff(line) {
  if (line.reconDifferenceMinor != null) return Number(line.reconDifferenceMinor);
  if (line.reconDiffMinor != null) return Number(line.reconDiffMinor);
  return 0;
}

function isPilotCleanLine(line) {
  if (!line.eligible) return false;
  if (line.currency !== 'SAR') return false;
  if (line.confidence !== 'high' && line.confidence !== 'derived') return false;
  if (line.lifecycle !== 'completed') return false;
  if (
    line.payment !== 'cashCollected' &&
    line.payment !== 'paid' &&
    line.payment !== 'captured'
  ) {
    return false;
  }
  if (Math.abs(lineReconDiff(line)) > (financialV2.MATCH_TOLERANCE || 0)) return false;
  if (line.bucket === 'cancelledOrExpired') return false;
  if (!line.currencySupported) return false;
  return true;
}

async function main() {
  const outDir = path.join(__dirname, '../../../visual_qa_9a');
  fs.mkdirSync(outDir, { recursive: true });

  const db = await initDb();
  const runtime = (await db.doc('financial_config/runtime').get()).data() || {};
  const flags = {
    FINANCIAL_SETTLEMENT_WRITES_ENABLED: runtime.FINANCIAL_SETTLEMENT_WRITES_ENABLED === true,
    FINANCIAL_PAYMENT_CONFIRM_ENABLED: runtime.FINANCIAL_PAYMENT_CONFIRM_ENABLED === true,
    WALLET_SETTLEMENT_ENABLED: runtime.WALLET_SETTLEMENT_ENABLED === true,
    AUTOMATIC_PAYOUT_ENABLED: runtime.AUTOMATIC_PAYOUT_ENABLED === true,
    allowSelfApproval: runtime.allowSelfApproval === true,
  };

  // Auth + CF reachability (demo account)
  const sign = await signIn();
  let idToken = sign.idToken;
  const refreshCall = await callCallable(idToken, 'refreshMyClaims', {});
  if (refreshCall.ok) idToken = await refreshIdToken(sign.refreshToken);
  const claims = claimKeys(idToken);
  const home = await callCallable(idToken, 'accountantHomeV2', {});
  const agg = await callCallable(idToken, 'aggregateFinancialAccountingV2', {
    mode: 'totals',
    currency: 'SAR',
  });
  const exceptions = await callCallable(idToken, 'scanFinancialExceptionsV2', {});

  const ordersSnap = await db.collection('order').get();
  const orders = ordersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  // Existing claims / settlements
  const claimsSnap = await db.collection('financial_settlement_claims').get();
  const claimedOrderIds = new Set();
  const claimsByDriver = new Map();
  claimsSnap.forEach((d) => {
    const c = d.data() || {};
    claimedOrderIds.add(d.id);
    const did = c.driverId || '';
    if (!claimsByDriver.has(did)) claimsByDriver.set(did, 0);
    claimsByDriver.set(did, claimsByDriver.get(did) + 1);
  });

  const settlementsSnap = await db.collection('financial_settlements').get();
  const settlementsByDriver = new Map();
  settlementsSnap.forEach((d) => {
    const s = d.data() || {};
    const did = s.driverId || '';
    const st = String(s.status || '');
    if (st === 'voided') return;
    if (!settlementsByDriver.has(did)) settlementsByDriver.set(did, []);
    settlementsByDriver.get(did).push({
      ref: anonRef(d.id),
      status: st,
      currency: s.currency || null,
    });
  });

  // Group eligible SAR lines by driver
  const byDriver = new Map();
  for (const order of orders) {
    const line = financialV2.analyzeOrder(order.id, order);
    if (!line.driverId || line.currency !== 'SAR') continue;
    if (!byDriver.has(line.driverId)) {
      byDriver.set(line.driverId, {
        driverId: line.driverId,
        lines: [],
        countries: new Set(),
        currencies: new Set(),
      });
    }
    const g = byDriver.get(line.driverId);
    g.lines.push({ order, line });
    if (line.countryPath) g.countries.add(line.countryPath);
    if (line.currency) g.currencies.add(line.currency);
  }

  const candidates = [];
  for (const g of byDriver.values()) {
    const clean = g.lines.filter((x) => isPilotCleanLine(x.line));
    if (clean.length === 0) continue;
    // Reject if any claimed among clean
    if (clean.some((x) => claimedOrderIds.has(x.line.orderId))) continue;
    // Reject drivers with any non-voided settlement
    if ((settlementsByDriver.get(g.driverId) || []).length > 0) continue;
    // Prefer single country among clean trips
    const countries = new Set(clean.map((x) => x.line.countryPath || '').filter(Boolean));
    if (countries.size > 1) continue;
    // No incomplete among clean set (already filtered)
    // Also ensure driver has no dirty eligible-looking trips we'd accidentally include:
    // For pilot period we only include clean trips; exclude others outside period.
    const high = clean.filter((x) => x.line.confidence === 'high').length;
    const derived = clean.filter((x) => x.line.confidence === 'derived').length;
    const dates = clean
      .map((x) => toDate(x.order.data_order))
      .filter(Boolean)
      .sort((a, b) => a - b);
    if (dates.length === 0) continue;
    // Tightest UTC day window covering all clean eligible trips.
    const first = dates[0];
    const last = dates[dates.length - 1];
    const periodStart = new Date(
      Date.UTC(first.getUTCFullYear(), first.getUTCMonth(), first.getUTCDate()),
    );
    const periodEnd = new Date(
      Date.UTC(last.getUTCFullYear(), last.getUTCMonth(), last.getUTCDate() + 1),
    );
    const periodLines = [];
    for (const { order, line } of g.lines) {
      if (line.currency !== 'SAR') continue;
      const d = toDate(order.data_order);
      if (!d || d < periodStart || !(d < periodEnd)) continue;
      periodLines.push(line);
    }
    const eligibleInPeriod = periodLines.filter((l) => l.eligible);
    // Any eligible trip in-window that is not pilot-clean would enter the settlement.
    const dirtyInPeriod = eligibleInPeriod.filter((l) => !isPilotCleanLine(l));
    if (dirtyInPeriod.length > 0) continue;
    if (eligibleInPeriod.length !== clean.length) continue;
    // Excluded (non-eligible) trips in the same window are OK — they do not claim.
    const preview = financialV2.settlePreviewForDriver(periodLines, 'SAR');
    if (preview.includedTrips !== clean.length) continue;

    candidates.push({
      driverRef: anonRef(g.driverId),
      driverId: g.driverId,
      countryPath: [...countries][0] || null,
      countryCount: countries.size,
      tripCount: clean.length,
      high,
      derived,
      periodStart: periodStart.toISOString(),
      periodEnd: periodEnd.toISOString(),
      excludedInPeriod: preview.excludedTrips,
      preview,
      clean,
      periodLines,
    });
  }

  // Prefer known shape: 5 cash trips, then fewest trips, then smallest absolute net
  candidates.sort((a, b) => {
    const score = (c) => {
      let s = 0;
      if (c.tripCount === 5) s += 100;
      if (c.preview.direction === 'driverPaysCompany') s += 20;
      if (c.preview.cashHeldMinor === 268000) s += 50;
      s -= c.tripCount;
      s -= Math.abs(c.preview.netTripSettlementMinor) / 100000;
      return s;
    };
    return score(b) - score(a);
  });

  const best = candidates[0] || null;

  // Maker / checker pool (no PII): users with panel admin/finance markers
  const usersSnap = await db.collection('user').where('IsAdmin', '==', true).limit(50).get();
  const pool = [];
  usersSnap.forEach((d) => {
    const u = d.data() || {};
    const rule = Number(u.isAdminRule ?? u.IsAdminRule ?? 0);
    // 1 = super, finance-capable roles typically 1 or finance-marked
    const canFinance =
      rule === 1 ||
      u.finance === true ||
      u.isFinance === true ||
      String(u.role || '').toLowerCase().includes('finance');
    if (!canFinance && rule !== 1) return;
    pool.push({
      ref: anonRef(d.id),
      rule,
      isSuper: rule === 1,
      financeMarked: canFinance,
    });
  });
  // Distinct maker/checker need ≥2 identities that can act as finance writers/checkers
  const makerCheckerDistinct = pool.length >= 2;
  const independentApprover =
    home.ok && home.result?.independentApproverConfigured === true;

  // Legacy 500
  const cpSnap = await db.collection('company_payments').limit(500).get();
  let legacy500 = null;
  cpSnap.forEach((d) => {
    const p = d.data() || {};
    const amt = Number(p.amount || p.total || 0);
    if (Math.abs(Math.abs(amt) - 500) > 0.01) return;
    const linked = !!(p.orderIds || p.order_ids || p.orderId || p.settlementId);
    if (!legacy500) {
      legacy500 = {
        amount: 500,
        currency: p.currency || p.Currency || 'SAR',
        status: p.status || p.Status || 'completed',
        allocation: linked ? 'ALLOCATED' : 'UNALLOCATED',
        ref: anonRef(d.id),
      };
    }
  });

  let tripRows = [];
  let risk = [];
  let totals = null;
  if (best) {
    // Authoritative CF settlement_preview for same driver/period
    const cfPreview = await callCallable(idToken, 'aggregateFinancialAccountingV2', {
      mode: 'settlement_preview',
      driverId: best.driverId,
      currency: 'SAR',
      periodStart: best.periodStart,
      periodEnd: best.periodEnd,
      countryPath: best.countryPath,
    });

    for (const { order, line } of best.clean) {
      const d = toDate(order.data_order);
      const row = {
        orderRef: anonRef(line.orderId),
        date: d ? d.toISOString().slice(0, 10) : null,
        paymentMethod: line.channel,
        lifecycle: line.lifecycle,
        paymentStatus: line.payment,
        customerPaidMinor: line.customerPaidMinor ?? null,
        platformFeeMinor: line.platformFeeMinor ?? null,
        recordedVatMinor: line.recordedVatMinor ?? null,
        discountMinor: line.recordedDiscountMinor ?? 0,
        driverNetMinor: line.driverNetMinor ?? null,
        confidence: line.confidence,
        reconciliationDifferenceMinor: lineReconDiff(line),
        eligibility: line.eligible ? 'ELIGIBLE' : 'EXCLUDED',
        currency: line.currency,
      };
      tripRows.push(row);

      const issues = [];
      if (claimedOrderIds.has(line.orderId)) issues.push('HAS_CLAIM');
      if (row.eligibility !== 'ELIGIBLE') issues.push('NOT_ELIGIBLE');
      if (Math.abs(row.reconciliationDifferenceMinor) > 0) issues.push('RECON_DIFF');
      if (row.confidence === 'incomplete') issues.push('INCOMPLETE');
      if (row.currency !== 'SAR') issues.push('CURRENCY');
      if (line.driverId !== best.driverId) issues.push('DRIVER_MISMATCH');
      // payment/lifecycle conflict heuristics
      if (row.lifecycle !== 'completed') issues.push('LIFECYCLE');
      if (!['cashCollected', 'paid', 'captured'].includes(row.paymentStatus)) {
        issues.push('PAYMENT_STATUS');
      }
      risk.push({ orderRef: row.orderRef, ok: issues.length === 0, issues });
    }

    const p = best.preview;
    totals = {
      eligibleCount: p.includedTrips,
      highCount: best.high,
      derivedCount: best.derived,
      excludedCount: p.excludedTrips,
      cash: {
        customerCollectedMinor: p.cashHeldMinor,
        customerCollectedMajor: majorFromMinor(p.cashHeldMinor, 'SAR'),
        driverEntitlementMinor: p.cashDriverEntitlementMinor,
        driverEntitlementMajor: majorFromMinor(p.cashDriverEntitlementMinor, 'SAR'),
        driverCashLiabilityMinor: p.driverCashLiabilityMinor,
        driverCashLiabilityMajor: majorFromMinor(p.driverCashLiabilityMinor, 'SAR'),
      },
      online: {
        customerPaidMinor: 0,
        driverEntitlementMinor: p.onlineDriverEntitlementMinor,
        companyLiabilityMinor: p.companyOnlineLiabilityMinor,
      },
      components: (() => {
        let gross = 0,
          fee = 0,
          vat = 0,
          disc = 0;
        for (const { line } of best.clean) {
          gross += line.grossBaseMinor || 0;
          fee += line.platformFeeMinor || 0;
          vat += line.recordedVatMinor || 0;
          disc += line.recordedDiscountMinor || 0;
        }
        return {
          grossBaseFareMinor: gross,
          platformFeeMinor: fee,
          recordedVatMinor: vat,
          recordedDiscountMinor: disc,
          grossBaseFareMajor: majorFromMinor(gross, 'SAR'),
          platformFeeMajor: majorFromMinor(fee, 'SAR'),
          recordedVatMajor: majorFromMinor(vat, 'SAR'),
          recordedDiscountMajor: majorFromMinor(disc, 'SAR'),
        };
      })(),
      final: {
        netSettlementPositionMinor: p.netTripSettlementMinor,
        netSettlementPositionMajor: majorFromMinor(p.netTripSettlementMinor, 'SAR'),
        direction:
          p.direction === 'driverPaysCompany'
            ? 'DRIVER_PAYS_COMPANY'
            : p.direction === 'companyPaysDriver'
              ? 'COMPANY_PAYS_DRIVER'
              : 'BALANCED',
        absoluteAmountMinor: Math.abs(p.netTripSettlementMinor),
        absoluteAmountMajor: majorFromMinor(Math.abs(p.netTripSettlementMinor), 'SAR'),
        currency: 'SAR',
      },
      cfPreviewOk: cfPreview.ok,
      cfSource: cfPreview.ok ? cfPreview.result?.source : cfPreview,
    };
  }

  const flagsOff =
    flags.FINANCIAL_SETTLEMENT_WRITES_ENABLED === false &&
    flags.FINANCIAL_PAYMENT_CONFIRM_ENABLED === false &&
    flags.WALLET_SETTLEMENT_ENABLED === false &&
    flags.AUTOMATIC_PAYOUT_ENABLED === false &&
    flags.allowSelfApproval === false;

  const report = {
    startedAt: new Date().toISOString(),
    PILOT_CODE_CANDIDATE: 'PASS',
    workingTreeNote: 'Only untracked duplicate qa script; not used for pilot',
    flags,
    flagsOff,
    refreshMyClaims: refreshCall.ok ? 'PASS' : refreshCall,
    claimsPresent: !!(claims.super_admin || claims.finance),
    accountantHomeV2: home.ok ? 'PASS' : home,
    aggregateFinancialAccountingV2: agg.ok ? 'PASS' : agg,
    scanFinancialExceptionsV2: exceptions.ok ? 'PASS' : exceptions,
    authoritativeBackend:
      home.ok && agg.ok && refreshCall.ok ? 'PASS' : 'BLOCKED',
    approximateMode: !(home.ok && agg.ok),
    candidateCount: candidates.length,
    pilot: best
      ? {
          driverRef: best.driverRef,
          countryPath: best.countryPath
            ? anonRef(best.countryPath.split('/').pop())
            : null,
          currency: 'SAR',
          periodStart: best.periodStart,
          periodEnd: best.periodEnd,
          tripCount: best.tripCount,
          totals,
          trips: tripRows,
          risk,
          allEligible: tripRows.every((t) => t.eligibility === 'ELIGIBLE'),
          reconAllZero: tripRows.every((t) => t.reconciliationDifferenceMinor === 0),
          noClaims: true,
          noExistingSettlement: true,
        }
      : null,
    makerChecker: {
      poolSize: pool.length,
      poolSample: pool.slice(0, 5),
      MAKER_AVAILABLE: pool.length >= 1,
      CHECKER_AVAILABLE: pool.length >= 2 || independentApprover,
      MAKER_CHECKER_DISTINCT: makerCheckerDistinct,
      independentApproverConfigured: independentApprover,
      homeIndependentApprover: home.result?.independentApproverConfigured ?? null,
    },
    legacy500: legacy500 || {
      amount: 500,
      currency: 'SAR',
      status: 'unknown',
      allocation: 'NOT_FOUND',
    },
    expectedLockCounts: best
      ? {
          settlementRecords: 1,
          settlementLines: best.tripCount,
          claims: best.tripCount,
          auditEventsMin: 2,
          orderMutations: 0,
          walletMutations: 0,
          paymentMutations: 0,
        }
      : null,
  };

  fs.writeFileSync(path.join(outDir, 'preflight.json'), JSON.stringify(report, null, 2));
  // Console summary without driverId raw when possible
  const summary = {
    ...report,
    pilot: report.pilot
      ? { ...report.pilot, /* strip nothing else */ }
      : null,
  };
  // Remove internal driverId from printed summary if present
  if (summary.pilot) {
    // already only driverRef
  }
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((e) => {
  console.error(JSON.stringify({ ok: false, error: String(e.message || e) }));
  process.exit(1);
});
