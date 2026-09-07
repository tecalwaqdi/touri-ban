/**
 * PERF-P4C-H — Human gate: Chromium regression + WebKit/Safari-engine smoke
 * + summary timing. No transport changes. Preview P4C only.
 *
 * BROWSER=chromium|webkit (default both via RUN_BOTH=1)
 * Note: Playwright WebKit is the Safari engine on macOS; Safari.app WebDriver
 * is attempted separately when SAFARI_APP=1 and safaridriver works.
 */
import { chromium, webkit } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = (
  process.env.BASE_URL ||
  'https://tutorial-multi-language-70gx4j--admin-perf-p4c-rnrkev0q.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR ||
  path.join(__dirname, '..', '..', '..', 'docs', 'admin_performance', 'p4c_human_gate');
const TOKEN_FILE = process.env.CUSTOM_TOKEN_FILE || '/tmp/p2a_custom_token.txt';
const UID = 'jrPITQI0Y2QJNELU43ymS1WJvR43';
const EMAIL = 'accountant.demo@touri-taxi.com';
const BROWSER = (process.env.BROWSER || 'chromium').toLowerCase();
const RUNS = Number(process.env.WARM_RUNS || (BROWSER === 'chromium' ? 3 : 5));
const WAIT_SUMMARY = process.env.WAIT_SUMMARY !== '0';

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

function envInfo() {
  let safariVer = null;
  let macos = null;
  try {
    macos = execSync('sw_vers -productVersion', { encoding: 'utf8' }).trim();
  } catch (_) {}
  try {
    safariVer = execSync(
      '/usr/bin/defaults read /Applications/Safari.app/Contents/Info CFBundleShortVersionString',
      { encoding: 'utf8' },
    ).trim();
  } catch (_) {}
  return { macos, safariVer, node: process.version };
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
      { providerId: 'password', uid: EMAIL, email: EMAIL },
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

async function waitTrace(page, { needSummary = false, timeoutMs = 90000 } = {}) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    const raw = await page.evaluate(() => window.__TOURI_PERF_P4B__ || null);
    if (raw) {
      try {
        const j = typeof raw === 'string' ? JSON.parse(raw) : raw;
        const marks = j?.marks || {};
        if (marks.FIRST_USEFUL_FRAME_PAINTED != null) {
          if (!needSummary || marks.SUMMARY_COMPLETE != null) return j;
        }
      } catch (_) {}
    }
    await page.waitForTimeout(120);
  }
  const raw = await page.evaluate(() => window.__TOURI_PERF_P4B__ || null);
  try {
    return raw ? (typeof raw === 'string' ? JSON.parse(raw) : raw) : null;
  } catch {
    return null;
  }
}

async function visualSnapshot(page) {
  return page.evaluate(() => {
    const bodyText = (document.body?.innerText || '').slice(0, 4000);
    const html = document.body?.innerHTML || '';
    const lower = bodyText.toLowerCase();
    const blank =
      !bodyText.trim() ||
      bodyText.trim().length < 40 ||
      !!document.querySelector('flt-semantics-placeholder');
    const rawError =
      /permission[- ]denied|firebaseerror|cloud_firestore\/|index.*required|missing or insufficient permissions/i.test(
        bodyText + html,
      );
    const fakeZeroRisk =
      /completed trips\s*0|إجمالي\s*0|0\s*SAR/.test(bodyText) &&
      !/loading|جاري|—|–/.test(lower);
    const flt = document.querySelector('flt-glass-pane, flutter-view, flt-scene-host');
    return {
      hasFlutter: !!flt,
      textLen: bodyText.trim().length,
      blankLikely: blank && !flt,
      rawErrorLikely: rawError,
      fakeZeroLikely: fakeZeroRisk,
      sample: bodyText.replace(/\s+/g, ' ').slice(0, 240),
    };
  });
}

function deltasFrom(marks, events) {
  const enter = marks.ROUTE_ENTER ?? 0;
  const paint = marks.FIRST_USEFUL_FRAME_PAINTED;
  const qStart =
    marks.QUERY_START ?? marks.FIRESTORE_GET_START ?? marks.FIRESTORE_LISTEN_START;
  // Prefer first FIRESTORE_FIRST_SNAPSHOT event (summary may overwrite marks map).
  let snap = marks.FIRESTORE_FIRST_SNAPSHOT;
  if (Array.isArray(events)) {
    const firstSnap = events.find((e) => e.event === 'FIRESTORE_FIRST_SNAPSHOT');
    if (firstSnap && Number.isFinite(firstSnap.ms)) snap = firstSnap.ms;
  }
  let q0 = qStart;
  if (Array.isArray(events)) {
    const firstQ = events.find(
      (e) =>
        e.event === 'QUERY_START' ||
        e.event === 'FIRESTORE_GET_START' ||
        e.event === 'FIRESTORE_LISTEN_START',
    );
    if (firstQ && Number.isFinite(firstQ.ms)) q0 = firstQ.ms;
  }
  return {
    route_to_paint: paint != null ? paint - enter : null,
    query_to_snap: q0 != null && snap != null ? snap - q0 : null,
    route_to_summary:
      marks.SUMMARY_COMPLETE != null ? marks.SUMMARY_COMPLETE - enter : null,
    summary_only:
      marks.SUMMARY_START != null && marks.SUMMARY_COMPLETE != null
        ? marks.SUMMARY_COMPLETE - marks.SUMMARY_START
        : null,
    first_before_summary:
      paint != null &&
      marks.SUMMARY_COMPLETE != null &&
      paint <= marks.SUMMARY_COMPLETE,
  };
}

async function measureRoute(page, routePath, { needSummary = false } = {}) {
  await page.goto(`${BASE}${routePath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  const trace = await waitTrace(page, {
    needSummary: needSummary && WAIT_SUMMARY,
    timeoutMs: needSummary ? 120000 : 60000,
  });
  const visual = await visualSnapshot(page);
  return { routePath, trace, visual, deltas: trace?.marks ? deltasFrom(trace.marks, trace.events) : null };
}

function summarize(runs, label) {
  const ds = runs.map((r) => r.deltas).filter(Boolean);
  const col = (k) => ds.map((d) => d[k]).filter((v) => Number.isFinite(v) && v >= 0);
  const visuals = runs.map((r) => r.visual).filter(Boolean);
  return {
    label,
    n: ds.length,
    median: {
      route_to_paint: median(col('route_to_paint')),
      query_to_snap: median(col('query_to_snap')),
      route_to_summary: median(col('route_to_summary')),
      summary_only: median(col('summary_only')),
    },
    p90: {
      route_to_paint: p90(col('route_to_paint')),
      query_to_snap: p90(col('query_to_snap')),
      route_to_summary: p90(col('route_to_summary')),
    },
    firstBeforeSummary: ds.filter((d) => d.first_before_summary).length,
    visual: {
      blank: visuals.filter((v) => v.blankLikely).length,
      rawError: visuals.filter((v) => v.rawErrorLikely).length,
      fakeZero: visuals.filter((v) => v.fakeZeroLikely).length,
      samples: visuals.slice(0, 2).map((v) => v.sample),
    },
  };
}

async function runBrowser(browserType, name) {
  const custom = fs.readFileSync(TOKEN_FILE, 'utf8').trim();
  const signIn = await exchangeCustomToken(custom);
  const user = buildAuthUser(signIn);

  const browser = await browserType.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  const net = { fails: 0, tokenish: 0, retries: 0, channels: 0 };
  const consoleErrs = [];
  page.on('console', (msg) => {
    const t = msg.text();
    if (msg.type() === 'error') consoleErrs.push(t.slice(0, 200));
  });
  page.on('request', (req) => {
    const u = req.url();
    if (/securetoken\.googleapis|identitytoolkit/.test(u)) net.tokenish += 1;
    if (/Listen\/channel|gsessionid/i.test(u)) net.channels += 1;
  });
  page.on('response', (res) => {
    if (!/firestore|identitytoolkit|securetoken/i.test(res.url())) return;
    if (res.status() >= 400) net.fails += 1;
  });

  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await writeAuth(page, user);
  await page
    .goto(`${BASE}/adminPerfP4bStatic`, { waitUntil: 'networkidle', timeout: 180000 })
    .catch(() => {});
  await page.waitForTimeout(2000);

  const settRuns = [];
  for (let i = 1; i <= RUNS; i++) {
    console.log(name, 'settlements', i);
    settRuns.push(await measureRoute(page, '/adminSettlements', { needSummary: false }));
    await page.waitForTimeout(900);
  }

  const hubRuns = [];
  const reconRuns = [];
  for (let i = 1; i <= RUNS; i++) {
    console.log(name, 'finance/recon', i);
    await clearFinanceCache(page);
    hubRuns.push(await measureRoute(page, '/adminFinanceHub', { needSummary: true }));
    await page.waitForTimeout(1000);
    reconRuns.push(
      await measureRoute(page, '/adminFinanceReconciliation', { needSummary: true }),
    );
    await page.waitForTimeout(1000);
  }

  // Accountant smoke routes (visual only, 1 each)
  const smoke = {};
  for (const [key, route] of [
    ['moneyMovement', '/adminFinanceChannels'],
    ['agentFinance', '/adminAgentFinance'],
    ['reports', '/adminFinanceReports'],
  ]) {
    console.log(name, 'smoke', key);
    try {
      await page.goto(`${BASE}${route}`, {
        waitUntil: 'domcontentloaded',
        timeout: 90000,
      });
      await page.waitForTimeout(2500);
      smoke[key] = await visualSnapshot(page);
      const url = page.url();
      smoke[key].url = url;
      smoke[key].stayedOnRoute = url.includes(route.replace(/^\//, '')) || url.includes(route);
    } catch (e) {
      smoke[key] = { error: String(e).slice(0, 200) };
    }
  }

  // Non-finance rejection smoke (drivers) — expect redirect away
  try {
    await page.goto(`${BASE}/adminDrivers`, {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });
    await page.waitForTimeout(2000);
    smoke.nonFinanceDrivers = {
      url: page.url(),
      rejected: !/adminDrivers/i.test(page.url()),
      visual: await visualSnapshot(page),
    };
  } catch (e) {
    smoke.nonFinanceDrivers = { error: String(e).slice(0, 200) };
  }

  await browser.close();

  return {
    browser: name,
    runs: RUNS,
    settlements: summarize(settRuns, 'settlements'),
    finance: summarize(hubRuns, 'finance_hub'),
    recon: summarize(reconRuns, 'reconciliation'),
    net,
    consoleErrorCount: consoleErrs.length,
    consoleErrorSample: consoleErrs.slice(0, 5),
    smoke,
    sampleConfig: hubRuns[0]?.trace?.firestoreWebConfig || null,
  };
}

(async () => {
  if (!fs.existsSync(TOKEN_FILE)) {
    throw new Error(`Missing custom token: ${TOKEN_FILE}`);
  }
  const info = envInfo();
  const out = {
    base: BASE,
    env: info,
    engineNote:
      BROWSER === 'webkit'
        ? 'Playwright WebKit (Safari engine on macOS) — not Safari.app UI process'
        : 'Playwright Chromium',
    results: {},
  };

  if (BROWSER === 'webkit' || BROWSER === 'both') {
    out.results.webkit = await runBrowser(webkit, 'webkit');
  }
  if (BROWSER === 'chromium' || BROWSER === 'both') {
    out.results.chromium = await runBrowser(chromium, 'chromium');
  }

  const file = path.join(OUT, `p4c_h_${BROWSER}_metrics.json`);
  fs.writeFileSync(file, JSON.stringify(out, null, 2));
  console.log(JSON.stringify(out, null, 2));
  console.log('WROTE', file);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
