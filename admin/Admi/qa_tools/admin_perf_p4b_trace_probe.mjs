/**
 * PERF-P4B — collect AdminFinanceRouteTrace console lines + window JSON.
 * Also compares SDK network first-response vs REST RunQuery for modern_page.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT = 'tutorial-multi-language-70gx4j';
const BASE = (
  process.env.BASE_URL ||
  'https://tutorial-multi-language-70gx4j--admin-perf-p4b.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR ||
  path.join(__dirname, '..', 'visual_qa_perf_p4b');
const TOKEN_FILE = process.env.CUSTOM_TOKEN_FILE || '/tmp/p2a_custom_token.txt';
const UID = 'jrPITQI0Y2QJNELU43ymS1WJvR43';
const EMAIL = 'accountant.demo@touri-taxi.com';
const RUNS = Number(process.env.WARM_RUNS || 5);

fs.mkdirSync(OUT, { recursive: true });

const median = (nums) => {
  const a = nums.filter(Number.isFinite).sort((x, y) => x - y);
  if (!a.length) return null;
  const m = Math.floor(a.length / 2);
  return a.length % 2 ? a[m] : Math.round((a[m - 1] + a[m]) / 2);
};
const p90 = (nums) => {
  const a = nums.filter(Number.isFinite).sort((x, y) => x - y);
  if (!a.length) return null;
  return a[Math.min(a.length - 1, Math.ceil(a.length * 0.9) - 1)];
};

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
  if (!res.ok || !data.idToken) throw new Error(data.error?.message || 'auth_fail');
  return data;
}

function buildAuthUser(signIn) {
  return {
    uid: signIn.localId || UID,
    email: EMAIL,
    emailVerified: true,
    displayName: '',
    isAnonymous: false,
    providerData: [
      {
        providerId: 'password',
        uid: EMAIL,
        email: EMAIL,
      },
    ],
    stsTokenManager: {
      refreshToken: signIn.refreshToken,
      accessToken: signIn.idToken,
      expirationTime: Date.now() + Number(signIn.expiresIn || 3600) * 1000,
    },
    createdAt: String(Date.now()),
    lastLoginAt: String(Date.now()),
    apiKey: API_KEY,
    appName: '[DEFAULT]',
  };
}

async function writeAuth(page, user) {
  await page.evaluate(
    async ({ apiKey, user }) => {
      const key = `firebase:authUser:${apiKey}:[DEFAULT]`;
      localStorage.setItem(key, JSON.stringify(user));
      await new Promise((resolve) => {
        const openReq = indexedDB.open('firebaseLocalStorageDb', 1);
        openReq.onerror = () => resolve();
        openReq.onupgradeneeded = () => {
          const db = openReq.result;
          if (!db.objectStoreNames.contains('firebaseLocalStorage')) {
            db.createObjectStore('firebaseLocalStorage', { keyPath: 'fbase_key' });
          }
        };
        openReq.onsuccess = () => {
          try {
            const db = openReq.result;
            if (!db.objectStoreNames.contains('firebaseLocalStorage')) return resolve();
            const tx = db.transaction('firebaseLocalStorage', 'readwrite');
            tx.oncomplete = () => resolve();
            tx.onerror = () => resolve();
            tx.objectStore('firebaseLocalStorage').put({ fbase_key: key, value: user });
          } catch (_) {
            resolve();
          }
        };
      });
    },
    { apiKey: API_KEY, user },
  );
}

function parseP4bLine(text) {
  if (!text.startsWith('P4B|')) return null;
  const parts = text.split('|');
  return {
    traceId: parts[1],
    route: parts[2],
    event: parts[3],
    ms: Number(parts[4]),
    extra: parts[5] || '',
  };
}

async function waitTracePaint(page, { timeoutMs = 45000 } = {}) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    const raw = await page.evaluate(() => window.__TOURI_PERF_P4B__ || null);
    if (raw) {
      try {
        const j = typeof raw === 'string' ? JSON.parse(raw) : raw;
        if (j?.marks?.FIRST_USEFUL_FRAME_PAINTED != null) return j;
      } catch (_) {}
    }
    await page.waitForTimeout(100);
  }
  const raw = await page.evaluate(() => window.__TOURI_PERF_P4B__ || null);
  try {
    return raw ? (typeof raw === 'string' ? JSON.parse(raw) : raw) : null;
  } catch {
    return null;
  }
}

async function restModernPage(idToken) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  const body = {
    structuredQuery: {
      from: [{ collectionId: 'order' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            {
              fieldFilter: {
                field: { fieldPath: 'status_code' },
                op: 'IN',
                value: {
                  arrayValue: {
                    values: [
                      { stringValue: 'completed' },
                      { stringValue: 'trip_completed' },
                    ],
                  },
                },
              },
            },
            {
              fieldFilter: {
                field: { fieldPath: 'data_order' },
                op: 'GREATER_THAN_OR_EQUAL',
                value: { timestampValue: start.toISOString() },
              },
            },
            {
              fieldFilter: {
                field: { fieldPath: 'data_order' },
                op: 'LESS_THAN',
                value: { timestampValue: end.toISOString() },
              },
            },
          ],
        },
      },
      orderBy: [{ field: { fieldPath: 'data_order' }, direction: 'DESCENDING' }],
      limit: 40,
    },
  };
  const t0 = Date.now();
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    },
  );
  const ms = Date.now() - t0;
  const txt = await res.text();
  return { ms, status: res.status, bytes: txt.length };
}

async function measureRoute(page, consoleBuf, routePath) {
  consoleBuf.length = 0;
  await page.goto(`${BASE}${routePath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  const trace = await waitTracePaint(page);
  const events = consoleBuf
    .map(parseP4bLine)
    .filter(Boolean)
    .filter((e) => !trace?.traceId || e.traceId === trace.traceId);
  return { trace, events, routePath };
}

(async () => {
  const custom = fs.readFileSync(TOKEN_FILE, 'utf8').trim();
  const signIn = await exchangeCustomToken(custom);
  const user = buildAuthUser(signIn);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  const consoleBuf = [];
  page.on('console', (msg) => {
    const t = msg.text();
    if (t.startsWith('P4B|')) consoleBuf.push(t);
  });

  // Network classify
  const net = { starts: [], dones: [], retries: 0, fails: 0 };
  page.on('request', (req) => {
    if (/firestore\.googleapis\.com/.test(req.url())) {
      net.starts.push({ t: Date.now(), url: req.url().slice(0, 160) });
    }
  });
  page.on('response', (res) => {
    if (!/firestore\.googleapis\.com/.test(res.url())) return;
    net.dones.push({ t: Date.now(), status: res.status(), url: res.url().slice(0, 160) });
    if (res.status() >= 400) net.fails += 1;
  });

  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await writeAuth(page, user);
  await page.goto(`${BASE}/adminFinanceHub`, { waitUntil: 'networkidle', timeout: 180000 }).catch(() => {});
  await page.waitForTimeout(4000);

  const rest = await restModernPage(signIn.idToken);
  console.log('REST_CONTROL', rest);

  const hubRuns = [];
  const reconRuns = [];
  const settRuns = [];
  const staticRuns = [];
  const controlRuns = [];
  let cacheRun = null;

  for (let i = 1; i <= RUNS; i++) {
    console.log('warm', i);
    hubRuns.push(await measureRoute(page, consoleBuf, '/adminFinanceHub'));
    await page.waitForTimeout(1500);
    reconRuns.push(await measureRoute(page, consoleBuf, '/adminFinanceReconciliation'));
    await page.waitForTimeout(1500);
    settRuns.push(await measureRoute(page, consoleBuf, '/adminSettlements'));
    await page.waitForTimeout(1200);
  }

  // cached hub: visit hub, then recon, then hub again quickly
  await measureRoute(page, consoleBuf, '/adminFinanceHub');
  await page.waitForTimeout(500);
  await measureRoute(page, consoleBuf, '/adminFinanceReconciliation');
  await page.waitForTimeout(500);
  cacheRun = await measureRoute(page, consoleBuf, '/adminFinanceHub');

  for (let i = 0; i < 3; i++) {
    staticRuns.push(await measureRoute(page, consoleBuf, '/adminPerfP4bStatic'));
    await page.waitForTimeout(400);
    controlRuns.push(await measureRoute(page, consoleBuf, '/adminPerfP4bControlQuery'));
    await page.waitForTimeout(800);
  }

  const pick = (runs, pathExpr) =>
    runs
      .map((r) => r.trace?.marks || {})
      .filter((m) => Object.keys(m).length);

  const deltasFrom = (marks) => ({
    route_to_query: (marks.QUERY_START ?? marks.FIRESTORE_GET_START ?? marks.FIRESTORE_LISTEN_START) - (marks.ROUTE_ENTER ?? 0),
    query_to_snap:
      (marks.FIRESTORE_FIRST_SNAPSHOT ?? 0) -
      (marks.QUERY_START ?? marks.FIRESTORE_GET_START ?? marks.FIRESTORE_LISTEN_START ?? 0),
    snap_to_model:
      (marks.MODEL_BUILD_END ?? marks.REPOSITORY_COMPLETE ?? 0) -
      (marks.FIRESTORE_FIRST_SNAPSHOT ?? 0),
    model_to_state:
      (marks.STATE_EMIT ?? 0) - (marks.MODEL_BUILD_END ?? marks.REPOSITORY_COMPLETE ?? 0),
    state_to_paint:
      (marks.FIRST_USEFUL_FRAME_PAINTED ?? 0) - (marks.STATE_EMIT ?? 0),
    total: (marks.FIRST_USEFUL_FRAME_PAINTED ?? 0) - (marks.ROUTE_ENTER ?? 0),
    auth:
      marks.AUTH_TOKEN_REQUEST_END != null && marks.AUTH_TOKEN_REQUEST_START != null
        ? marks.AUTH_TOKEN_REQUEST_END - marks.AUTH_TOKEN_REQUEST_START
        : null,
    cacheHit: marks.CACHE_HIT != null,
    fromCacheExtra: null,
  });

  const summarize = (runs, label) => {
    const marksList = pick(runs);
    const d = marksList.map(deltasFrom);
    const col = (k) => d.map((x) => x[k]).filter((v) => Number.isFinite(v) && v >= 0);
    return {
      label,
      n: d.length,
      median: {
        route_to_query: median(col('route_to_query')),
        query_to_snap: median(col('query_to_snap')),
        snap_to_model: median(col('snap_to_model')),
        model_to_state: median(col('model_to_state')),
        state_to_paint: median(col('state_to_paint')),
        total: median(col('total')),
        auth: median(col('auth')),
      },
      p90: {
        total: p90(col('total')),
        query_to_snap: p90(col('query_to_snap')),
        route_to_query: p90(col('route_to_query')),
      },
      cacheHits: d.filter((x) => x.cacheHit).length,
      sampleMarks: marksList[0] || null,
    };
  };

  const out = {
    base: BASE,
    restControl: rest,
    netFails: net.fails,
    finance: summarize(hubRuns, 'finance_hub'),
    recon: summarize(reconRuns, 'reconciliation'),
    settlements: summarize(settRuns, 'settlements'),
    staticRoute: summarize(staticRuns, 'static'),
    controlQuery: summarize(controlRuns, 'control_query'),
    cachedHub: cacheRun
      ? {
          marks: cacheRun.trace?.marks || null,
          deltas: cacheRun.trace?.marks ? deltasFrom(cacheRun.trace.marks) : null,
          cacheHit: cacheRun.trace?.marks?.CACHE_HIT != null,
        }
      : null,
    firebaseInit: cacheRun?.trace?.firebaseInitCount ?? null,
  };

  fs.writeFileSync(path.join(OUT, 'p4b_trace_metrics.json'), JSON.stringify(out, null, 2));
  console.log(JSON.stringify(out, null, 2));
  await browser.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
