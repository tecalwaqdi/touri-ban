#!/usr/bin/env node
/**
 * AGENT HANDOFF SECURITY DEPLOY GATE — live production probe.
 * Custom-token auth only. No password prints. No rate mutations that succeed.
 * Safe rejected writes only for Agent_total.
 */
import { execSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const SA =
  'firebase-adminsdk-vqcu4@tutorial-multi-language-70gx4j.iam.gserviceaccount.com';
const PROJECT = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';

const AGENTS = [
  {
    label: 'A_INDIA',
    country: 'india',
    countryPath: 'countries/india',
    email: 'bander1@gmail.com',
    uid: 'TmENMz1dO8X7kTYBvJunSL3iX452',
  },
  {
    label: 'B_SPAIN',
    country: 'spain',
    countryPath: 'countries/spain',
    email: 'trial.agent.es.1@touri-taxi.com',
    uid: 'U878AYIvsJV3xlWKhLeXOfUFqqH2',
  },
];

function gcloudAccessToken() {
  return execSync(
    `gcloud auth print-access-token --impersonate-service-account=${SA}`,
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
  ).trim();
}

async function mintCustomToken(accessToken, uid) {
  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: SA,
    sub: SA,
    aud: 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
    iat: now,
    exp: now + 3600,
    uid,
  };
  const res = await fetch(
    `https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${SA}:signJwt`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ payload: JSON.stringify(claims) }),
    },
  );
  const body = await res.json();
  if (!body.signedJwt) {
    throw new Error(`signJwt failed: ${JSON.stringify(body).slice(0, 300)}`);
  }
  return body.signedJwt;
}

async function exchangeCustomToken(customToken) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!data.idToken) {
    throw new Error(`exchange failed: ${JSON.stringify(data).slice(0, 300)}`);
  }
  return data;
}

function decodeJwt(idToken) {
  const payload = idToken.split('.')[1];
  const pad = '='.repeat((4 - (payload.length % 4)) % 4);
  return JSON.parse(Buffer.from(payload + pad, 'base64url').toString('utf8'));
}

async function fsGet(idToken, docPath) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/${docPath}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  const json = await res.json().catch(() => ({}));
  return { http: res.status, json };
}

async function fsPatch(idToken, docPath, fields, updateMask) {
  const mask = updateMask.map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&');
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/${docPath}?${mask}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  const json = await res.json().catch(() => ({}));
  return { http: res.status, json };
}

async function fsList(idToken, collPath, pageSize = 5) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/${collPath}?pageSize=${pageSize}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  const json = await res.json().catch(() => ({}));
  return { http: res.status, json };
}

async function callCallable(idToken, name, data = {}) {
  const url = `https://us-central1-${PROJECT}.cloudfunctions.net/${name}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ data }),
  });
  const json = await res.json().catch(() => ({}));
  return { http: res.status, json };
}

async function paymentStatus(base, idToken, sessionId) {
  const url = `${base.replace(/\/$/, '')}/payments/status?sessionId=${sessionId}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  const json = await res.json().catch(() => ({}));
  return { http: res.status, json };
}

function denied(resp) {
  const st = resp?.json?.error?.status || resp?.json?.error?.message || '';
  const code = resp?.json?.error?.code;
  const msg = JSON.stringify(resp?.json || {}).slice(0, 400);
  const hit =
    resp.http === 403 ||
    String(st).includes('PERMISSION_DENIED') ||
    String(code) === 'permission-denied' ||
    msg.includes('PERMISSION_DENIED') ||
    msg.includes('permission-denied') ||
    msg.includes('FORBIDDEN') ||
    Number(code) === 403;
  return { hit, http: resp.http, detail: msg.slice(0, 180) };
}

function okRead(resp) {
  return resp.http === 200 && !resp.json?.error;
}

async function findOtherCountrySettlement(adminToken, ownCountryPath) {
  // Admin SDK list via REST with SA token — use runQuery broadly then filter.
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/financial_settlements?pageSize=50`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  const json = await res.json();
  const docs = json.documents || [];
  for (const d of docs) {
    const fields = d.fields || {};
    const cid =
      fields.countryId?.stringValue ||
      fields.countryRef?.stringValue ||
      fields.countryRef?.referenceValue ||
      '';
    const norm = String(cid).replace(/^.*documents\//, '');
    if (norm && norm !== ownCountryPath && !norm.endsWith('/' + ownCountryPath.split('/')[1])) {
      const id = d.name.split('/').pop();
      return { id, country: norm };
    }
    // also treat reference path countries/spain
    if (norm.includes('countries/') && !norm.includes(ownCountryPath.split('/')[1])) {
      const id = d.name.split('/').pop();
      return { id, country: norm };
    }
  }
  // fallback: pick any settlement whose countryId field differs loosely
  for (const d of docs) {
    const fields = d.fields || {};
    const raw = JSON.stringify(fields.countryId || fields.countryRef || {});
    if (raw && !raw.includes(ownCountryPath.split('/')[1])) {
      return { id: d.name.split('/').pop(), country: raw.slice(0, 80) };
    }
  }
  return null;
}

async function findDriverInCountry(adminToken, countryDocId) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery`;
  const body = {
    structuredQuery: {
      from: [{ collectionId: 'user' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'ismndob' },
          op: 'EQUAL',
          value: { booleanValue: true },
        },
      },
      limit: 40,
    },
  };
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${adminToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const rows = await res.json();
  if (!Array.isArray(rows)) return null;
  for (const row of rows) {
    const doc = row.document;
    if (!doc) continue;
    const f = doc.fields || {};
    const ref =
      f.Rev_dolh?.referenceValue ||
      f.Rev_dloh_agent?.referenceValue ||
      '';
    if (ref.includes(`/countries/${countryDocId}`)) {
      return doc.name.split('/').pop();
    }
  }
  return null;
}

async function probeAgent(agent, accessToken, adminToken, paymentBases) {
  const custom = await mintCustomToken(accessToken, agent.uid);
  const signed = await exchangeCustomToken(custom);
  const idToken = signed.idToken;
  const claims = decodeJwt(idToken);
  const out = {
    label: agent.label,
    country: agent.country,
    email: agent.email,
    login: Boolean(idToken),
    claims: {
      agent: claims.agent === true,
      country_admin: claims.country_admin === true,
      support: claims.support === true,
      finance: claims.finance === true,
      super_admin: claims.super_admin === true,
      country_id: claims.country_id || null,
    },
    tests: {},
  };

  // Own profile read
  const own = await fsGet(idToken, `user/${agent.uid}`);
  out.tests.own_profile_read = okRead(own) ? 'PASS' : `FAIL:${own.http}`;

  // Agent_total self write attempts (must DENY; do not change production)
  const rateAttempts = [
    ['update_150', { Agent_total: { doubleValue: 150 } }, ['Agent_total']],
    ['update_neg', { Agent_total: { doubleValue: -1 } }, ['Agent_total']],
    ['delete_field', {}, ['Agent_total']], // empty fields + mask delete via updateMask alone may 400; use null
  ];
  // Proper delete via REST uses currentDocument + fields omit — use nullValue replace then check deny on change from existing
  rateAttempts[2] = [
    'clear_null',
    { Agent_total: { nullValue: null } },
    ['Agent_total'],
  ];

  let rateWriteSuccess = 0;
  for (const [name, fields, mask] of rateAttempts) {
    const resp = await fsPatch(idToken, `user/${agent.uid}`, fields, mask);
    const d = denied(resp);
    out.tests[`agent_total_${name}`] = d.hit ? 'DENY' : `LEAK:${resp.http}`;
    if (!d.hit && resp.http >= 200 && resp.http < 300) rateWriteSuccess += 1;
  }
  out.tests.agent_rate_write_success_count = rateWriteSuccess;

  // type_car write DENY
  const typeCarCreate = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/type_car?documentId=f03f07_probe_should_fail`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ fields: { name: { stringValue: 'probe' } } }),
    },
  ).then(async (r) => ({ http: r.status, json: await r.json().catch(() => ({})) }));
  out.tests.type_car_create = denied(typeCarCreate).hit ? 'DENY' : `LEAK:${typeCarCreate.http}`;

  // Cross-country settlement children
  const other = await findOtherCountrySettlement(adminToken, agent.countryPath);
  if (other) {
    const lineList = await fsList(
      idToken,
      `financial_settlements/${other.id}/lines`,
      3,
    );
    const eventList = await fsList(
      idToken,
      `financial_settlements/${other.id}/events`,
      3,
    );
    const lineDenied =
      denied(lineList).hit ||
      (lineList.http === 200 && !(lineList.json.documents || []).length && !lineList.json.error);
    // Empty list with 200 can mean rules filtered all — for list, Firestore returns PERMISSION_DENIED if query not constrained.
    // Treat PERMISSION_DENIED as DENY; treat empty 200 as DENY_SCOPE (no leakage of foreign docs).
    const lineDocs = (lineList.json.documents || []).length;
    const eventDocs = (eventList.json.documents || []).length;
    out.tests.settlement_lines_cross = denied(lineList).hit
      ? 'DENY'
      : lineDocs === 0
        ? 'DENY_EMPTY'
        : `LEAK:${lineDocs}`;
    out.tests.settlement_events_cross = denied(eventList).hit
      ? 'DENY'
      : eventDocs === 0
        ? 'DENY_EMPTY'
        : `LEAK:${eventDocs}`;
    out.tests.other_settlement_id = other.id;
    out.tests.other_settlement_country = other.country;
  } else {
    out.tests.settlement_lines_cross = 'SKIP_NO_OTHER_SETTLEMENT';
    out.tests.settlement_events_cross = 'SKIP_NO_OTHER_SETTLEMENT';
  }

  // Driver financial summary cross-country
  const otherCountry = agent.country === 'india' ? 'spain' : 'india';
  const foreignDriver = await findDriverInCountry(adminToken, otherCountry);
  if (foreignDriver) {
    const sum = await callCallable(idToken, 'getDriverFinancialSummaryV2', {
      driverId: foreignDriver,
      currency: 'SAR',
    });
    const err = sum.json?.error || {};
    const msg = String(err.message || err.status || JSON.stringify(sum.json)).slice(0, 200);
    const isDenied =
      sum.http === 403 ||
      String(err.status).includes('PERMISSION_DENIED') ||
      msg.toLowerCase().includes('permission') ||
      msg.toLowerCase().includes('cross-country');
    out.tests.driver_summary_cross = isDenied ? 'DENY' : `LEAK:${msg}`;
    out.tests.foreign_driver_id_suffix = foreignDriver.slice(0, 8);
  } else {
    out.tests.driver_summary_cross = 'SKIP_NO_FOREIGN_DRIVER';
  }

  // Own-country driver summary (if any)
  const ownDriver = await findDriverInCountry(adminToken, agent.country);
  if (ownDriver) {
    const sum = await callCallable(idToken, 'getDriverFinancialSummaryV2', {
      driverId: ownDriver,
      currency: 'SAR',
    });
    const err = sum.json?.error;
    out.tests.driver_summary_own = err
      ? `DENY_OR_ERR:${String(err.message || err.status).slice(0, 80)}`
      : sum.http === 200
        ? 'PASS'
        : `HTTP_${sum.http}`;
  } else {
    out.tests.driver_summary_own = 'SKIP_NO_OWN_DRIVER';
  }

  // Super admin / settings / global finance — probe forbidden collections
  const saProbe = await fsGet(idToken, 'user/JkYePqE6LkVVkHKbKmdqEmVqDqr1'); // saudi dual — other user
  // country admin may read same-country users only; saudi is other country → expect deny or miss
  out.tests.other_user_saudi_read = denied(saProbe).hit
    ? 'DENY'
    : okRead(saProbe)
      ? 'LEAK'
      : `HTTP_${saProbe.http}`;

  // Payment API — fake session (expect 403/404 not global dump)
  const fakeSession = 'a'.repeat(64);
  for (const [name, base] of Object.entries(paymentBases)) {
    try {
      const st = await paymentStatus(base, idToken, fakeSession);
      const code = st.json?.code || st.json?.error || st.http;
      out.tests[`payment_${name}`] =
        st.http === 403 || st.http === 401 || st.http === 404
          ? `DENY_OR_NOT_FOUND:${st.http}`
          : `HTTP_${st.http}:${String(code).slice(0, 40)}`;
    } catch (e) {
      out.tests[`payment_${name}`] = `ERR:${String(e.message).slice(0, 60)}`;
    }
  }

  return out;
}

async function main() {
  const accessToken = gcloudAccessToken();
  const paymentBases = {
    firebase: 'https://paymentapi-lfsqkiuqkq-uc.a.run.app',
    render: 'https://touri-ban.onrender.com',
  };
  const results = [];
  for (const agent of AGENTS) {
    results.push(await probeAgent(agent, accessToken, accessToken, paymentBases));
  }

  const leakage = [];
  for (const r of results) {
    for (const [k, v] of Object.entries(r.tests)) {
      if (String(v).startsWith('LEAK')) leakage.push(`${r.label}.${k}=${v}`);
      if (k === 'agent_rate_write_success_count' && Number(v) > 0) {
        leakage.push(`${r.label}.rate_writes=${v}`);
      }
    }
  }

  const report = {
    at: new Date().toISOString(),
    project: PROJECT,
    cross_country_leakage: leakage.length,
    leakage,
    agents: results.map((r) => ({
      label: r.label,
      country: r.country,
      email: r.email,
      login: r.login,
      claims: r.claims,
      tests: r.tests,
    })),
  };
  writeFileSync('/tmp/agent_handoff_security_live_qa.json', JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
}

main().catch((e) => {
  console.error('PROBE_FAIL', e.message || e);
  process.exit(1);
});
