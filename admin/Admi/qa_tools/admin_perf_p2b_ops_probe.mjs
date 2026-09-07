/**
 * PERF-P2B — operational list first-data probe (Chromium).
 * Flutter canvas-safe: FIRST USEFUL ≈ first Firestore response after route nav
 * (same methodology as PERF-P2A-H). Accountant finance uses __TOURI_PERF_P4B__.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = (
  process.env.BASE_URL ||
  'https://tutorial-multi-language-70gx4j--admin-perf-p2b.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR ||
  path.join(__dirname, '..', '..', '..', 'docs', 'admin_performance', 'p2b_probe');
const SUPER_TOKEN = process.env.SUPER_TOKEN_FILE || '/tmp/p2b_super_token.txt';
const ACCT_TOKEN = process.env.CUSTOM_TOKEN_FILE || '/tmp/p2a_custom_token.txt';
const SUPER_UID = process.env.SUPER_UID || 'ApTyCSt4C9QbJALdvVGeoFmzlXP2';
const SUPER_EMAIL = process.env.SUPER_EMAIL || 'demo.super@arawatan.sa';
const ACCT_UID = process.env.ACCT_UID || 'jrPITQI0Y2QJNELU43ymS1WJvR43';
const ACCT_EMAIL = process.env.ACCT_EMAIL || 'accountant.demo@touri-taxi.com';
const RUNS = Number(process.env.WARM_RUNS || 3);

fs.mkdirSync(OUT, { recursive: true });
const appUrl = (p) => `${BASE}${p.startsWith('/') ? p : `/${p}`}`;

const median = (nums) => {
  const a = nums.filter(Number.isFinite).sort((x, y) => x - y);
  if (!a.length) return null;
  const m = Math.floor(a.length / 2);
  return a.length % 2 ? a[m] : Math.round((a[m - 1] + a[m]) / 2);
};

function decodeJwtPayload(token) {
  try {
    const part = token.split('.')[1];
    const pad = part + '='.repeat((4 - (part.length % 4)) % 4);
    return JSON.parse(Buffer.from(pad, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
}

async function exchange(customToken, fallbackUid, email) {
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
  const payload = decodeJwtPayload(data.idToken) || {};
  return {
    localId: data.localId || payload.user_id || payload.sub || fallbackUid,
    email: email || payload.email || '',
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    expiresIn: data.expiresIn || '3600',
  };
}

function buildAuthUser(signIn) {
  return {
    uid: signIn.localId,
    email: signIn.email,
    emailVerified: true,
    displayName: '',
    isAnonymous: false,
    providerData: [
      {
        providerId: 'password',
        uid: signIn.email,
        displayName: null,
        email: signIn.email,
        phoneNumber: null,
        photoURL: null,
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

function attachNet(page) {
  const s = {
    starts: 0,
    dones: 0,
    indexErrors: [],
    events: [],
    markRoute() {
      this.routeT0 = Date.now();
      this.events = [];
      this.firstDoneMs = null;
      this.lastDoneAt = null;
      this.routeStarts = 0;
    },
    routeT0: null,
    firstDoneMs: null,
    lastDoneAt: null,
    routeStarts: 0,
  };
  page.on('request', (req) => {
    if (!/firestore\.googleapis\.com/.test(req.url())) return;
    s.starts += 1;
    if (s.routeT0 != null) {
      s.routeStarts += 1;
      s.events.push({
        t: Date.now() - s.routeT0,
        kind: 'start',
        url: req.url().slice(0, 140),
      });
    }
  });
  page.on('response', async (res) => {
    if (!/firestore\.googleapis\.com/.test(res.url())) return;
    s.dones += 1;
    if (s.routeT0 != null) {
      const ms = Date.now() - s.routeT0;
      if (s.firstDoneMs == null) s.firstDoneMs = ms;
      s.lastDoneAt = Date.now();
      s.events.push({ t: ms, kind: 'done', status: res.status() });
    }
    try {
      const txt = await res.text().catch(() => '');
      if (/FAILED_PRECONDITION|requires an index/i.test(txt)) {
        s.indexErrors.push(txt.slice(0, 240));
      }
    } catch (_) {}
  });
  return s;
}

async function waitFirstFirestore(net, timeoutMs = 25000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (net.firstDoneMs != null) return net.firstDoneMs;
    await new Promise((r) => setTimeout(r, 50));
  }
  return null;
}

async function waitQuiet(net, { quietMs = 1200, timeoutMs = 35000 } = {}) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (net.firstDoneMs == null) {
      await new Promise((r) => setTimeout(r, 50));
      continue;
    }
    if (net.lastDoneAt && Date.now() - net.lastDoneAt >= quietMs) {
      return Date.now() - net.routeT0;
    }
    await new Promise((r) => setTimeout(r, 80));
  }
  return net.routeT0 != null ? Date.now() - net.routeT0 : null;
}

async function enableSemantics(page) {
  await page.evaluate(() => {
    try {
      window.__flutter_web_set_semantics_enabled?.(true);
    } catch (_) {}
  });
  try {
    await page.keyboard.press('Tab');
  } catch (_) {}
  await page.waitForTimeout(300);
}

async function ariaSample(page) {
  return page.evaluate(() => {
    const nodes = Array.from(
      document.querySelectorAll(
        '[aria-label], [flt-semantics-identifier], flt-semantics, flutter-view',
      ),
    );
    return nodes
      .map(
        (n) =>
          n.getAttribute('aria-label') ||
          n.getAttribute('flt-semantics-identifier') ||
          '',
      )
      .filter(Boolean)
      .slice(0, 50)
      .join(' | ')
      .slice(0, 600);
  });
}

async function hydrate(page, signIn) {
  await page.goto(appUrl('/'), { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForTimeout(1000);
  await writeAuth(page, buildAuthUser(signIn));
  await page.goto(appUrl('/'), { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForTimeout(2500);
  await enableSemantics(page);
  const sample = await ariaSample(page);
  const authKeys = await page.evaluate(() =>
    Object.keys(localStorage).filter((k) => k.includes('firebase')),
  );
  return { sample, authKeys };
}

async function measureRoute(page, net, routePath) {
  net.markRoute();
  const navT0 = Date.now();
  await page.goto(appUrl(routePath), {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  const loaderMs = Date.now() - navT0;
  const firstUsefulMs = await waitFirstFirestore(net, 25000);
  await enableSemantics(page);
  const summaryMs = await waitQuiet(net, { quietMs: 1200, timeoutMs: 30000 });
  const aria = await ariaSample(page);
  return {
    routePath,
    loaderMs,
    firstUsefulMs,
    summaryMs,
    routeStarts: net.routeStarts,
    indexErrors: net.indexErrors.slice(),
    aria: aria.slice(0, 280),
  };
}

function summarize(runs) {
  return {
    n: runs.length,
    medianFirstUseful: median(runs.map((r) => r.firstUsefulMs)),
    medianSummary: median(runs.map((r) => r.summaryMs)),
    medianRouteStarts: median(runs.map((r) => r.routeStarts)),
    samples: runs,
  };
}

(async () => {
  if (!fs.existsSync(SUPER_TOKEN)) throw new Error(`Missing ${SUPER_TOKEN}`);
  const superSign = await exchange(
    fs.readFileSync(SUPER_TOKEN, 'utf8').trim(),
    SUPER_UID,
    SUPER_EMAIL,
  );
  console.log('super uid', superSign.localId);

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const net = attachNet(page);

  const hydrated = await hydrate(page, superSign);
  console.log('hydrate', JSON.stringify(hydrated).slice(0, 500));

  // Warm: one ops route so Flutter/main.dart.js + auth session are hot.
  net.markRoute();
  await page.goto(appUrl('/drever'), {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  await waitFirstFirestore(net, 25000);
  await page.waitForTimeout(1500);

  const routes = [
    ['drivers', '/drever'],
    ['agents', '/adminAgent'],
    ['users', '/adminUserManagementSystem'],
    ['landmarks', '/adminM3alm'],
    ['bookings', '/adminALLhgZ'],
  ];

  const results = {};
  for (const [key, route] of routes) {
    const runs = [];
    for (let i = 1; i <= RUNS; i++) {
      console.log(key, i);
      const m = await measureRoute(page, net, route);
      console.log(
        ' ',
        'firstUseful',
        m.firstUsefulMs,
        'summary',
        m.summaryMs,
        'starts',
        m.routeStarts,
      );
      runs.push(m);
      await page.waitForTimeout(500);
    }
    results[key] = summarize(runs);
  }

  let finance = null;
  if (fs.existsSync(ACCT_TOKEN)) {
    const acctSign = await exchange(
      fs.readFileSync(ACCT_TOKEN, 'utf8').trim(),
      ACCT_UID,
      ACCT_EMAIL,
    );
    await hydrate(page, acctSign);
    const finRuns = [];
    for (let i = 1; i <= RUNS; i++) {
      console.log('finance', i);
      await page.evaluate(() => {
        try {
          if (typeof window.__TOURI_CLEAR_FINANCE_CACHE__ === 'function') {
            window.__TOURI_CLEAR_FINANCE_CACHE__();
          }
        } catch (_) {}
      });
      await page.goto(appUrl('/adminFinanceHub'), {
        waitUntil: 'domcontentloaded',
        timeout: 120000,
      });
      const t0 = Date.now();
      let paint = null;
      let routeToPaint = null;
      while (Date.now() - t0 < 45000) {
        const raw = await page.evaluate(() => window.__TOURI_PERF_P4B__ || null);
        if (raw) {
          try {
            const j = typeof raw === 'string' ? JSON.parse(raw) : raw;
            if (j?.marks?.FIRST_USEFUL_FRAME_PAINTED != null) {
              paint = j.marks.FIRST_USEFUL_FRAME_PAINTED;
              const enter = j.marks.ROUTE_ENTER ?? 0;
              routeToPaint = paint - enter;
              break;
            }
          } catch (_) {}
        }
        await page.waitForTimeout(120);
      }
      // Network fallback if marks missing
      if (routeToPaint == null) {
        net.markRoute();
        await page.reload({ waitUntil: 'domcontentloaded', timeout: 120000 });
        routeToPaint = await waitFirstFirestore(net, 25000);
      }
      finRuns.push({ paint, routeToPaint });
      await page.waitForTimeout(400);
    }
    finance = {
      medianPaint: median(finRuns.map((r) => r.paint)),
      medianRouteToPaint: median(finRuns.map((r) => r.routeToPaint)),
      runs: finRuns,
    };
    console.log('finance medianRouteToPaint', finance.medianRouteToPaint);
  }

  const out = {
    base: BASE,
    probedAt: new Date().toISOString(),
    method: 'first_firestore_response_after_route (P2A-compatible)',
    superUid: superSign.localId,
    results,
    finance,
  };
  fs.writeFileSync(path.join(OUT, 'p2b_ops_metrics.json'), JSON.stringify(out, null, 2));
  console.log(JSON.stringify({ results, finance }, null, 2));
  await browser.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
