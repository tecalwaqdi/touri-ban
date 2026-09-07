/**
 * PERF-P4C-H — Real Safari.app smoke via safaridriver (macOS).
 * Measures AdminFinanceRouteTrace window JSON. No passwords logged.
 */
const { Builder, By, until } = require('/tmp/node_modules/selenium-webdriver');
const safari = require('/tmp/node_modules/selenium-webdriver/safari');
const fs = require('fs');
const path = require('path');

const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = (
  process.env.BASE_URL ||
  'https://tutorial-multi-language-70gx4j--admin-perf-p4c-rnrkev0q.web.app/admin'
).replace(/\/$/, '');
const TOKEN_FILE = process.env.CUSTOM_TOKEN_FILE || '/tmp/p2a_custom_token.txt';
const OUT =
  process.env.OUT_DIR ||
  '/Users/ventura/ara-ban-f3c1/docs/admin_performance/p4c_human_gate';
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

async function exchange(customToken) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!data.idToken) throw new Error(data.error?.message || 'auth_fail');
  return data;
}

function buildUser(signIn) {
  return {
    uid: signIn.localId || UID,
    email: EMAIL,
    emailVerified: true,
    displayName: '',
    isAnonymous: false,
    providerData: [{ providerId: 'password', uid: EMAIL, email: EMAIL }],
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

async function injectAuth(driver, user) {
  await driver.executeScript(
    `
    const apiKey = arguments[0];
    const user = arguments[1];
    const key = 'firebase:authUser:' + apiKey + ':[DEFAULT]';
    localStorage.setItem(key, JSON.stringify(user));
    return key;
  `,
    API_KEY,
    user,
  );
}

async function waitTrace(driver, { needSummary = false, timeoutMs = 90000 } = {}) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    const raw = await driver.executeScript('return window.__TOURI_PERF_P4B__ || null;');
    if (raw) {
      const j = typeof raw === 'string' ? JSON.parse(raw) : raw;
      const marks = j.marks || {};
      if (marks.FIRST_USEFUL_FRAME_PAINTED != null) {
        if (!needSummary || marks.SUMMARY_COMPLETE != null) return j;
      }
    }
    await driver.sleep(150);
  }
  const raw = await driver.executeScript('return window.__TOURI_PERF_P4B__ || null;');
  try {
    return raw ? (typeof raw === 'string' ? JSON.parse(raw) : raw) : null;
  } catch {
    return null;
  }
}

function deltas(trace) {
  const marks = trace?.marks || {};
  const events = trace?.events || [];
  const enter = marks.ROUTE_ENTER ?? 0;
  const paint = marks.FIRST_USEFUL_FRAME_PAINTED;
  let q0 = marks.QUERY_START ?? marks.FIRESTORE_GET_START ?? marks.FIRESTORE_LISTEN_START;
  let snap = marks.FIRESTORE_FIRST_SNAPSHOT;
  const firstQ = events.find((e) =>
    ['QUERY_START', 'FIRESTORE_GET_START', 'FIRESTORE_LISTEN_START'].includes(e.event),
  );
  const firstSnap = events.find((e) => e.event === 'FIRESTORE_FIRST_SNAPSHOT');
  if (firstQ) q0 = firstQ.ms;
  if (firstSnap) snap = firstSnap.ms;
  return {
    route_to_paint: paint != null ? paint - enter : null,
    query_to_snap: q0 != null && snap != null ? snap - q0 : null,
    route_to_summary:
      marks.SUMMARY_COMPLETE != null ? marks.SUMMARY_COMPLETE - enter : null,
  };
}

async function measure(driver, route, needSummary) {
  await driver.get(`${BASE}${route}`);
  const trace = await waitTrace(driver, { needSummary, timeoutMs: needSummary ? 120000 : 60000 });
  return { route, deltas: deltas(trace), hasPaint: !!trace?.marks?.FIRST_USEFUL_FRAME_PAINTED };
}

function summarize(runs) {
  const ds = runs.map((r) => r.deltas).filter(Boolean);
  const col = (k) => ds.map((d) => d[k]).filter((v) => Number.isFinite(v) && v >= 0);
  return {
    n: ds.length,
    median: {
      route_to_paint: median(col('route_to_paint')),
      query_to_snap: median(col('query_to_snap')),
      route_to_summary: median(col('route_to_summary')),
    },
    p90: {
      route_to_paint: p90(col('route_to_paint')),
      query_to_snap: p90(col('query_to_snap')),
      route_to_summary: p90(col('route_to_summary')),
    },
  };
}

(async () => {
  const custom = fs.readFileSync(TOKEN_FILE, 'utf8').trim();
  const signIn = await exchange(custom);
  const user = buildUser(signIn);

  const options = new safari.Options();
  let driver;
  try {
    driver = await new Builder().forBrowser('safari').setSafariOptions(options).build();
  } catch (e) {
    const out = {
      engine: 'Safari.app',
      error: String(e.message || e).slice(0, 500),
      note: 'safaridriver failed — enable Develop > Allow Remote Automation',
    };
    fs.writeFileSync(path.join(OUT, 'p4c_h_safari_app_metrics.json'), JSON.stringify(out, null, 2));
    console.error(JSON.stringify(out, null, 2));
    process.exit(2);
  }

  try {
    await driver.get(`${BASE}/`);
    await injectAuth(driver, user);
    await driver.get(`${BASE}/adminPerfP4bStatic`);
    await driver.sleep(2500);

    const sett = [];
    for (let i = 1; i <= RUNS; i++) {
      console.log('safari settlements', i);
      sett.push(await measure(driver, '/adminSettlements', false));
      await driver.sleep(800);
    }
    const hub = [];
    const recon = [];
    for (let i = 1; i <= RUNS; i++) {
      console.log('safari finance/recon', i);
      await driver.executeScript(
        'try{ if (typeof window.__TOURI_CLEAR_FINANCE_CACHE__==="function") window.__TOURI_CLEAR_FINANCE_CACHE__(); }catch(e){}',
      );
      hub.push(await measure(driver, '/adminFinanceHub', true));
      await driver.sleep(900);
      recon.push(await measure(driver, '/adminFinanceReconciliation', true));
      await driver.sleep(900);
    }

    const out = {
      engine: 'Safari.app + safaridriver',
      safariVersion: '26.6',
      macos: '26.6',
      base: BASE,
      settlements: summarize(sett),
      finance: summarize(hub),
      recon: summarize(recon),
    };
    fs.writeFileSync(path.join(OUT, 'p4c_h_safari_app_metrics.json'), JSON.stringify(out, null, 2));
    console.log(JSON.stringify(out, null, 2));
  } finally {
    await driver.quit().catch(() => {});
  }
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
