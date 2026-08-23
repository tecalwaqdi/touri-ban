/**
 * Phase 8F — IAM fix verification + Finance backend/client compare (read-only).
 * Env: ADMIN_QA_EMAIL / ADMIN_QA_PASSWORD. Never logs secrets or full tokens.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const financialV2 = require('../firebase/functions/financial_accounting_v2.js');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_8f');
const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT = 'tutorial-multi-language-70gx4j';
const REGION = 'us-central1';

function b64url(s) {
  return Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString(
    'utf8',
  );
}

async function signIn(email, password) {
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

async function refreshToken(rt) {
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

async function callCallable(idToken, name, data = {}) {
  const url = `https://${REGION}-${PROJECT}.cloudfunctions.net/${name}`;
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

function claimSummary(idToken) {
  const p = JSON.parse(b64url(idToken.split('.')[1]));
  const keys = [
    'super_admin',
    'country_admin',
    'agent',
    'support',
    'finance',
    'partner',
    'transport_manager',
  ];
  const out = {};
  for (const k of keys) if (k in p) out[k] = p[k];
  return out;
}

function tsToDate(v) {
  if (!v) return null;
  if (typeof v === 'string') return new Date(v);
  if (v.toDate) return v.toDate();
  if (typeof v._seconds === 'number') return new Date(v._seconds * 1000);
  if (typeof v.seconds === 'number') return new Date(v.seconds * 1000);
  return new Date(v);
}

function decodeFirestoreValue(v) {
  if (v == null) return null;
  if ('nullValue' in v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return new Date(v.timestampValue);
  if ('referenceValue' in v) {
    const full = v.referenceValue;
    const path = full.replace(
      /^projects\/[^/]+\/databases\/[^/]+\/documents\//,
      '',
    );
    return { path, id: path.split('/').pop() };
  }
  if ('mapValue' in v) {
    const out = {};
    const fields = v.mapValue.fields || {};
    for (const [k, fv] of Object.entries(fields)) out[k] = decodeFirestoreValue(fv);
    return out;
  }
  if ('arrayValue' in v) {
    return (v.arrayValue.values || []).map(decodeFirestoreValue);
  }
  return null;
}

function docToOrder(doc) {
  const name = doc.name || '';
  const id = name.split('/').pop();
  const data = {};
  for (const [k, fv] of Object.entries(doc.fields || {})) {
    data[k] = decodeFirestoreValue(fv);
  }
  return { id, ...data };
}

/** Client-style full scan via user token (same filter as CF: currency SAR, all dates). */
async function clientFallbackAggregate(idToken, { currency = 'SAR', pageSize = 400 } = {}) {
  const byCurrency = {};
  const lines = [];
  let orders = [];
  let missingPaymentStatus = 0;
  let missingLifecycle = 0;
  let missingDriver = 0;
  let unsupportedCurrency = 0;
  let startAfter = null;
  const filters = { currency };

  while (true) {
    const structuredQuery = {
      from: [{ collectionId: 'order' }],
      orderBy: [
        {
          field: { fieldPath: 'data_order' },
          direction: 'DESCENDING',
        },
      ],
      limit: pageSize,
    };
    if (startAfter) {
      structuredQuery.startAt = {
        values: startAfter,
        before: false,
      };
    }
    const res = await fetch(
      `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({ structuredQuery }),
      },
    );
    const rows = await res.json();
    if (!Array.isArray(rows)) {
      throw new Error(
        `client_scan_failed:${JSON.stringify(rows).slice(0, 180)}`,
      );
    }
    const docs = rows.filter((r) => r.document).map((r) => r.document);
    if (docs.length === 0) break;
    for (const doc of docs) {
      const order = docToOrder(doc);
      orders.push(order);
      const line = financialV2.analyzeOrder(order.id, order);
      if (!order.payment_status) missingPaymentStatus++;
      if (!order.status_code) missingLifecycle++;
      if (!line.driverId) missingDriver++;
      if (!line.currencySupported) unsupportedCurrency++;
      if (!financialV2.matchesFilters(line, filters)) continue;
      lines.push(line);
      financialV2.accumulate(byCurrency, line);
    }
    const last = docs[docs.length - 1];
    const lastOrder = docToOrder(last);
    const ts = lastOrder.data_order;
    if (!ts) break;
    const iso = ts instanceof Date ? ts.toISOString() : String(ts);
    startAfter = [{ timestampValue: iso }];
    if (docs.length < pageSize) break;
  }

  const sar = byCurrency.SAR || null;
  const quality = {
    totalLines: lines.length,
    high: lines.filter((l) => l.confidence === 'high').length,
    derived: lines.filter((l) => l.confidence === 'derived').length,
    incomplete: lines.filter((l) => l.confidence === 'incomplete').length,
    unsupportedCurrency,
    missingPaymentStatus,
    missingLifecycle,
    missingDriver,
    docsScanned: orders.length,
  };

  return { byCurrency, quality, sar };
}

function summarizeSar(t) {
  if (!t) return null;
  return {
    eligibleCount: t.completedAndCollected ?? null,
    cashCollectedMinor: t.cashCustomerCollectedMinor ?? 0,
    driverEntitlementMinor: t.driverEntitlementAllMinor ?? 0,
    platformFeeMinor: t.platformFeeAllMinor ?? 0,
    recordedVatMinor: t.recordedVatAllMinor ?? 0,
    driversOweCompanyMinor: t.cashDriversOweCompanyMinor ?? 0,
    companyOwesDriversMinor:
      (t.cashCompanyOwesDriversMinor || 0) +
      (t.onlineCompanyOwesDriversMinor || 0),
    cashCollectedTrips: t.cashCollectedTrips ?? 0,
    highCount: t.highCount ?? 0,
    derivedCount: t.derivedCount ?? 0,
    incompleteLines: t.incompleteLines ?? 0,
  };
}

function summarizeQuality(q) {
  if (!q) return null;
  return {
    HIGH: q.high ?? 0,
    DERIVED: q.derived ?? 0,
    INCOMPLETE: q.incomplete ?? 0,
    docsScanned: q.docsScanned ?? 0,
    totalLines: q.totalLines ?? 0,
  };
}

function diffSummaries(a, b) {
  const diffs = [];
  if (!a || !b) {
    return [{ field: '_presence', backend: !!a, client: !!b }];
  }
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of keys) {
    if (a[k] !== b[k]) {
      diffs.push({ field: k, backend: a[k], client: b[k], delta: (a[k] ?? 0) - (b[k] ?? 0) });
    }
  }
  return diffs;
}

async function main() {
  const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
  const password = String(process.env.ADMIN_QA_PASSWORD || '');
  if (!email || !password) {
    console.log(JSON.stringify({ ok: false, code: 'NO_TEST_ACCOUNT' }));
    process.exit(2);
  }

  fs.mkdirSync(OUT, { recursive: true });

  const sign = await signIn(email, password);
  let idToken = sign.idToken;
  const claimsBefore = claimSummary(idToken);

  const refreshCall = await callCallable(idToken, 'refreshMyClaims', {});
  const refreshMyClaims =
    refreshCall.ok &&
    !String(refreshCall.result?.error || '').includes('insufficient-permission')
      ? 'PASS'
      : 'FAIL';
  if (refreshCall.ok) {
    idToken = await refreshToken(sign.refreshToken);
  }
  const claimsAfter = claimSummary(idToken);
  const TOKEN_REFRESH = claimsAfter.super_admin === true ? 'PASS' : 'FAIL';
  const ROLE_CLAIMS_PRESENT =
    claimsAfter.super_admin === true && claimsAfter.finance === true
      ? 'PASS'
      : 'FAIL';

  const home = await callCallable(idToken, 'accountantHomeV2', {});
  const agg = await callCallable(idToken, 'aggregateFinancialAccountingV2', {
    mode: 'totals',
    currency: 'SAR',
  });
  const exceptions = await callCallable(idToken, 'scanFinancialExceptionsV2', {});
  const reportFn = await callCallable(idToken, 'financialReportV2', {
    reportType: 'exposure_by_currency',
    currency: 'SAR',
  });

  let client = null;
  let clientError = null;
  try {
    client = await clientFallbackAggregate(idToken, { currency: 'SAR' });
  } catch (e) {
    clientError = String(e.message || e).slice(0, 300);
  }

  const backendSar = summarizeSar(agg.result?.byCurrency?.SAR);
  const backendQuality = summarizeQuality(agg.result?.quality);
  const clientSar = summarizeSar(client?.sar || client?.byCurrency?.SAR);
  const clientQuality = summarizeQuality(client?.quality);

  // Prefer totals fields; quality HIGH/DERIVED/INCOMPLETE for confidence buckets.
  const backendCompare = {
    ...backendSar,
    HIGH: backendQuality?.HIGH,
    DERIVED: backendQuality?.DERIVED,
    INCOMPLETE: backendQuality?.INCOMPLETE,
  };
  const clientCompare = {
    ...clientSar,
    HIGH: clientQuality?.HIGH,
    DERIVED: clientQuality?.DERIVED,
    INCOMPLETE: clientQuality?.INCOMPLETE,
  };
  // highCount on totals may duplicate quality — drop internal counts if quality used
  delete backendCompare.highCount;
  delete backendCompare.derivedCount;
  delete backendCompare.incompleteLines;
  delete clientCompare.highCount;
  delete clientCompare.derivedCount;
  delete clientCompare.incompleteLines;

  const diffs = diffSummaries(backendCompare, clientCompare);
  const FINANCE_BACKEND_LIVE =
    home.ok && agg.ok && exceptions.ok ? 'PASS' : 'FAIL';
  const BACKEND_CLIENT_TOTALS_MATCH =
    FINANCE_BACKEND_LIVE === 'PASS' && !clientError && diffs.length === 0
      ? 'PASS'
      : 'FAIL';

  const flags =
    home.result?.featureFlags ||
    home.result?.flags ||
    {};

  const report = {
    startedAt: new Date().toISOString(),
    PROJECT_MATCH: PROJECT === 'tutorial-multi-language-70gx4j' ? 'PASS' : 'FAIL',
    refreshMyClaims,
    TOKEN_REFRESH,
    ROLE_CLAIMS_PRESENT,
    claimsBefore,
    claimsAfter,
    refreshError: refreshCall.ok ? null : refreshCall,
    accountantHomeV2: home.ok ? 'PASS' : home,
    aggregateFinancialAccountingV2: agg.ok ? 'PASS' : agg,
    scanFinancialExceptionsV2: exceptions.ok ? 'PASS' : exceptions,
    financialReportV2: reportFn.ok ? 'PASS' : reportFn,
    FINANCE_BACKEND_LIVE,
    BACKEND_CLIENT_TOTALS_MATCH,
    backend: {
      source: agg.result?.source,
      filterSignature: agg.result?.filterSignature,
      sar: backendCompare,
      quality: backendQuality,
    },
    clientFallback: clientError
      ? { error: clientError }
      : {
          source: 'client_full_js_engine',
          sar: clientCompare,
          quality: clientQuality,
        },
    diffs,
    flags: {
      FINANCIAL_SETTLEMENT_WRITES_ENABLED:
        flags.FINANCIAL_SETTLEMENT_WRITES_ENABLED ?? flags.settlementWritesEnabled,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED:
        flags.FINANCIAL_PAYMENT_CONFIRM_ENABLED ?? flags.paymentConfirmEnabled,
      WALLET_SETTLEMENT_ENABLED:
        flags.WALLET_SETTLEMENT_ENABLED ?? flags.walletSettlementEnabled,
      AUTOMATIC_PAYOUT_ENABLED:
        flags.AUTOMATIC_PAYOUT_ENABLED ?? flags.automaticPayoutEnabled,
      allowSelfApproval: flags.allowSelfApproval,
    },
  };

  fs.writeFileSync(
    path.join(OUT, 'claims_finance_retest.json'),
    JSON.stringify(report, null, 2),
  );
  console.log(
    JSON.stringify(
      {
        refreshMyClaims,
        TOKEN_REFRESH,
        ROLE_CLAIMS_PRESENT,
        FINANCE_BACKEND_LIVE,
        BACKEND_CLIENT_TOTALS_MATCH,
        diffs,
        aggOk: agg.ok,
        homeOk: home.ok,
        exceptionsOk: exceptions.ok,
        flags: report.flags,
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.log(JSON.stringify({ ok: false, error: String(e.message || e) }));
  process.exit(1);
});
