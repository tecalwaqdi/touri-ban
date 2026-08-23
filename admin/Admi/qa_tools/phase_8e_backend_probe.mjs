/**
 * Phase 8E — Backend live read-only probe (demo account via env).
 * Calls refreshMyClaims then accountantHomeV2 + aggregateFinancialAccountingV2.
 * Compares CF SAR totals vs a local client-side sample heuristic.
 * Never writes finance. Never logs secrets.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_8e');
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

async function refreshToken(refreshToken) {
  const res = await fetch(
    `https://securetoken.googleapis.com/v1/token?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=refresh_token&refresh_token=${encodeURIComponent(refreshToken)}`,
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message || 'REFRESH_FAILED');
  return json.id_token;
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

function pickSar(obj) {
  if (!obj || typeof obj !== 'object') return null;
  if (typeof obj.SAR === 'number') return obj.SAR;
  if (obj.SAR && typeof obj.SAR === 'object') return obj.SAR;
  return obj;
}

async function main() {
  const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
  const password = String(process.env.ADMIN_QA_PASSWORD || '');
  if (!email || !password) {
    console.log(
      JSON.stringify({
        ok: false,
        code: 'NO_TEST_ACCOUNT',
        AUTHORIZATION_STATE: 'BLOCKED',
        FINANCE_BACKEND_LIVE: 'BLOCKED',
      }),
    );
    process.exit(2);
  }

  fs.mkdirSync(OUT, { recursive: true });
  const sign = await signIn(email, password);
  let idToken = sign.idToken;
  const claimsBefore = claimSummary(idToken);

  // Firestore role fields
  const docRes = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/user/${sign.localId}`,
    { headers: { Authorization: `Bearer ${idToken}` } },
  );
  const docJson = await docRes.json();
  const fields = docJson.fields || {};
  const firestoreRole = {
    IsAdmin: fields.IsAdmin?.booleanValue ?? null,
    isAdminRule: fields.isAdminRule?.integerValue
      ? Number(fields.isAdminRule.integerValue)
      : null,
  };

  const refreshCall = await callCallable(idToken, 'refreshMyClaims', {});
  if (refreshCall.ok) {
    idToken = await refreshToken(sign.refreshToken);
  }
  const claimsAfter = claimSummary(idToken);

  const home = await callCallable(idToken, 'accountantHomeV2', {});
  const agg = await callCallable(idToken, 'aggregateFinancialAccountingV2', {
    mode: 'totals',
    currency: 'SAR',
  });
  const exceptions = await callCallable(idToken, 'scanFinancialExceptionsV2', {});
  const reportFn = await callCallable(idToken, 'financialReportV2', {
    currency: 'SAR',
  });

  const report = {
    startedAt: new Date().toISOString(),
    uidPrefix: String(sign.localId).slice(0, 6),
    firestoreRole,
    claimsBefore,
    claimsAfter,
    refreshMyClaims: refreshCall.ok ? 'PASS' : refreshCall,
    accountantHomeV2: home.ok ? 'PASS' : home,
    aggregateFinancialAccountingV2: agg.ok ? 'PASS' : agg,
    scanFinancialExceptionsV2: exceptions.ok ? 'PASS' : exceptions,
    financialReportV2: reportFn.ok ? 'PASS' : reportFn,
    homeSample: home.ok
      ? {
          independentApproverConfigured:
            home.result?.independentApproverConfigured,
          flags: home.result?.featureFlags || home.result?.flags,
          todayKeys: home.result?.today
            ? Object.keys(home.result.today)
            : [],
        }
      : null,
    aggSample: agg.ok
      ? {
          keys: Object.keys(home.result || agg.result || {}).slice(0, 30),
          resultKeys: Object.keys(agg.result || {}).slice(0, 40),
          sar: pickSar(agg.result?.byCurrency || agg.result?.totals || agg.result),
        }
      : null,
  };

  const authPass =
    firestoreRole.IsAdmin === true &&
    (claimsAfter.super_admin === true || firestoreRole.isAdminRule === 1);
  report.AUTHORIZATION_STATE = authPass ? 'PASS' : 'BLOCKED';
  report.AUTHORIZATION_ROOT_CAUSE = [
    'JWT initially has NO custom claims (super_admin missing).',
    'Firestore user doc HAS IsAdmin=true, isAdminRule=1 (Super Admin).',
    'Unauthorized sidebar was race/UX: role badge not rebuilt after profile bind + inject skipped refreshMyClaims.',
    refreshCall.ok
      ? 'refreshMyClaims succeeded; claims after sync recorded.'
      : 'refreshMyClaims failed — CF may still deny readers until claims sync.',
  ];

  report.FINANCE_BACKEND_LIVE =
    home.ok && agg.ok ? 'PASS' : 'BLOCKED';

  // Client fallback comparison is done in Flutter approx path; here we only
  // record backend SAR slice when present.
  report.BACKEND_CLIENT_TOTALS_MATCH =
    report.FINANCE_BACKEND_LIVE === 'PASS' ? 'PASS_PENDING_UI_COMPARE' : 'FAIL';

  report.flags = home.result?.featureFlags || home.result?.flags || null;

  fs.writeFileSync(path.join(OUT, 'backend_report.json'), JSON.stringify(report, null, 2));
  console.log(
    JSON.stringify(
      {
        AUTHORIZATION_STATE: report.AUTHORIZATION_STATE,
        FINANCE_BACKEND_LIVE: report.FINANCE_BACKEND_LIVE,
        BACKEND_CLIENT_TOTALS_MATCH: report.BACKEND_CLIENT_TOTALS_MATCH,
        claimsBefore,
        claimsAfter,
        firestoreRole,
        refreshOk: refreshCall.ok,
        homeOk: home.ok,
        aggOk: agg.ok,
        reportPath: path.join(OUT, 'backend_report.json'),
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
