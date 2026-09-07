/**
 * PERF-P4C — Finance transport probe (get/default/snap + hub/recon/settlements).
 * Reuses P4B auth injection + AdminFinanceRouteTrace window JSON.
 *
 * Order: Settlements early (avoid Listen-channel saturation bias), then Hub/Recon,
 * then fetch-mode matrix. Clears P3 finance cache between sections when bridge
 * exposes `__TOURI_CLEAR_FINANCE_CACHE__`.
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
  'https://tutorial-multi-language-70gx4j--admin-perf-p4c.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR ||
  path.join(__dirname, '..', 'visual_qa_perf_p4c');
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

async function clearFinanceCache(page) {
  await page.evaluate(() => {
    try {
      if (typeof window.__TOURI_CLEAR_FINANCE_CACHE__ === 'function') {
        window.__TOURI_CLEAR_FINANCE_CACHE__();
      }
    } catch (_) {}
  });
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

function classifyUrl(url) {
  const u = url.toLowerCase();
  if (u.includes('listen') || u.includes('channel') || u.includes('gsessionid')) {
    return 'listen_webchannel';
  }
  if (u.includes('runquery') || u.includes(':runquery')) return 'run_query';
  if (u.includes('firestore.googleapis.com')) return 'firestore_other';
  return 'other';
}

async function measureRoute(page, routePath, netBuf) {
  const startIdx = netBuf.length;
  const navStart = Date.now();
  await page.goto(`${BASE}${routePath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  const trace = await waitTracePaint(page);
  const slice = netBuf.slice(startIdx);
  const firstFs = slice.find((e) => e.kind === 'start');
  const firstDone = slice.find((e) => e.kind === 'done');
  return {
    routePath,
    trace,
    net: {
      starts: slice.filter((e) => e.kind === 'start').length,
      dones: slice.filter((e) => e.kind === 'done').length,
      classes: slice
        .filter((e) => e.kind === 'start')
        .map((e) => e.cls)
        .reduce((acc, c) => {
          acc[c] = (acc[c] || 0) + 1;
          return acc;
        }, {}),
      firstStartOffsetMs: firstFs ? firstFs.t - navStart : null,
      firstDoneOffsetMs: firstDone ? firstDone.t - navStart : null,
      firstUrl: firstFs?.url || null,
    },
  };
}

(async () => {
  if (!fs.existsSync(TOKEN_FILE)) {
    throw new Error(`Missing custom token file: ${TOKEN_FILE}`);
  }
  const custom = fs.readFileSync(TOKEN_FILE, 'utf8').trim();
  const signIn = await exchangeCustomToken(custom);
  const user = buildAuthUser(signIn);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  const netBuf = [];
  let fails = 0;

  page.on('request', (req) => {
    if (!/firestore\.googleapis\.com|firestore\.googleapis|webchannel|google\.firestore/i.test(req.url())) {
      return;
    }
    netBuf.push({
      kind: 'start',
      t: Date.now(),
      cls: classifyUrl(req.url()),
      url: req.url().slice(0, 200),
      method: req.method(),
    });
  });
  page.on('response', (res) => {
    if (!/firestore\.googleapis\.com|webchannel|google\.firestore/i.test(res.url())) {
      return;
    }
    if (res.status() >= 400) fails += 1;
    netBuf.push({
      kind: 'done',
      t: Date.now(),
      cls: classifyUrl(res.url()),
      status: res.status(),
      url: res.url().slice(0, 200),
    });
  });

  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await writeAuth(page, user);
  await page.goto(`${BASE}/adminPerfP4bStatic`, { waitUntil: 'networkidle', timeout: 180000 }).catch(() => {});
  await page.waitForTimeout(2500);
  await clearFinanceCache(page);

  const rest = await restModernPage(signIn.idToken);
  console.log('REST_CONTROL', rest);

  const settRuns = [];
  for (let i = 1; i <= RUNS; i++) {
    console.log('warm settlements', i);
    settRuns.push(await measureRoute(page, '/adminSettlements', netBuf));
    await page.waitForTimeout(1200);
  }

  await clearFinanceCache(page);
  const hubRuns = [];
  const reconRuns = [];
  for (let i = 1; i <= RUNS; i++) {
    console.log('warm finance', i);
    await clearFinanceCache(page);
    hubRuns.push(await measureRoute(page, '/adminFinanceHub', netBuf));
    await page.waitForTimeout(1200);
    reconRuns.push(await measureRoute(page, '/adminFinanceReconciliation', netBuf));
    await page.waitForTimeout(1200);
  }

  await clearFinanceCache(page);
  await measureRoute(page, '/adminFinanceHub', netBuf);
  await page.waitForTimeout(500);
  const cacheRun = await measureRoute(page, '/adminFinanceHub', netBuf);

  await clearFinanceCache(page);
  const modes = ['server', 'default', 'snap'];
  const modeRuns = {};
  for (const mode of modes) {
    modeRuns[mode] = [];
    for (let i = 1; i <= RUNS; i++) {
      console.log('mode', mode, i);
      await clearFinanceCache(page);
      modeRuns[mode].push(
        await measureRoute(page, `/adminPerfP4cFetchBench?mode=${mode}`, netBuf),
      );
      await page.waitForTimeout(800);
    }
  }

  const deltasFrom = (marks) => {
    const firstPageLikelyCache =
      marks.CACHE_HIT != null &&
      marks.FIRESTORE_GET_START == null &&
      marks.FIRESTORE_LISTEN_START == null;
    return {
      route_to_query:
        (marks.QUERY_START ?? marks.FIRESTORE_GET_START ?? marks.FIRESTORE_LISTEN_START) -
        (marks.ROUTE_ENTER ?? 0),
      query_to_snap:
        (marks.FIRESTORE_FIRST_SNAPSHOT ?? 0) -
        (marks.QUERY_START ?? marks.FIRESTORE_GET_START ?? marks.FIRESTORE_LISTEN_START ?? 0),
      state_to_paint:
        (marks.FIRST_USEFUL_FRAME_PAINTED ?? 0) - (marks.STATE_EMIT ?? 0),
      total: (marks.FIRST_USEFUL_FRAME_PAINTED ?? 0) - (marks.ROUTE_ENTER ?? 0),
      cacheHitMark: marks.CACHE_HIT != null,
      firstPageLikelyCache,
      hasGetStart: marks.FIRESTORE_GET_START != null,
      hasListenStart: marks.FIRESTORE_LISTEN_START != null,
    };
  };

  const summarize = (runs, label) => {
    const marksList = runs.map((r) => r.trace?.marks || {}).filter((m) => Object.keys(m).length);
    const d = marksList.map(deltasFrom);
    const col = (k) => d.map((x) => x[k]).filter((v) => Number.isFinite(v) && v >= 0);
    const netClasses = runs.reduce((acc, r) => {
      for (const [k, v] of Object.entries(r.net?.classes || {})) {
        acc[k] = (acc[k] || 0) + v;
      }
      return acc;
    }, {});
    return {
      label,
      n: d.length,
      median: {
        route_to_query: median(col('route_to_query')),
        query_to_snap: median(col('query_to_snap')),
        state_to_paint: median(col('state_to_paint')),
        total: median(col('total')),
      },
      p90: {
        total: p90(col('total')),
        query_to_snap: p90(col('query_to_snap')),
      },
      cacheHitMarks: d.filter((x) => x.cacheHitMark).length,
      firstPageLikelyCache: d.filter((x) => x.firstPageLikelyCache).length,
      getStarts: d.filter((x) => x.hasGetStart).length,
      listenStarts: d.filter((x) => x.hasListenStart).length,
      netClasses,
      sampleConfig: runs[0]?.trace?.firestoreWebConfig || null,
      sampleFirstUrl: runs[0]?.net?.firstUrl || null,
    };
  };

  const out = {
    base: BASE,
    restControl: rest,
    netFails: fails,
    settlements: summarize(settRuns, 'settlements'),
    finance: summarize(hubRuns, 'finance_hub'),
    recon: summarize(reconRuns, 'reconciliation'),
    fetchModes: Object.fromEntries(
      Object.entries(modeRuns).map(([k, runs]) => [k, summarize(runs, `mode_${k}`)]),
    ),
    cachedHub: cacheRun
      ? {
          marks: cacheRun.trace?.marks || null,
          deltas: cacheRun.trace?.marks ? deltasFrom(cacheRun.trace.marks) : null,
          netStarts: cacheRun.net?.starts ?? null,
        }
      : null,
    firebaseInit: cacheRun?.trace?.firebaseInitCount ?? hubRuns[0]?.trace?.firebaseInitCount,
    settingsApply:
      cacheRun?.trace?.firestoreSettingsApplyCount ??
      hubRuns[0]?.trace?.firestoreSettingsApplyCount,
  };

  fs.writeFileSync(path.join(OUT, 'p4c_trace_metrics.json'), JSON.stringify(out, null, 2));
  console.log(JSON.stringify(out, null, 2));
  await browser.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
