/**
 * PERF-P2A-H — network-timed browser benchmark (Flutter canvas-safe).
 * FIRST USEFUL ≈ first Firestore response after route navigation.
 * SUMMARY ≈ Firestore quiet window after activity.
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
  'https://tutorial-multi-language-70gx4j--admin-perf-p2a-lbc3hkqo.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR ||
  path.join(__dirname, '..', 'visual_qa_perf_p2a_human_gate');
const TOKEN_FILE = process.env.CUSTOM_TOKEN_FILE || '/tmp/p2a_custom_token.txt';
const UID = 'jrPITQI0Y2QJNELU43ymS1WJvR43';
const EMAIL = 'accountant.demo@touri-taxi.com';
const RUNS = Number(process.env.WARM_RUNS || 3);

fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(path.join(OUT, 'runs'), { recursive: true });
const appUrl = (p) => `${BASE}${p.startsWith('/') ? p : `/${p}`}`;
const median = (nums) => {
  const a = nums.filter(Number.isFinite).sort((x, y) => x - y);
  if (!a.length) return null;
  const m = Math.floor(a.length / 2);
  return a.length % 2 ? a[m] : Math.round((a[m - 1] + a[m]) / 2);
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
  return {
    localId: data.localId || UID,
    email: EMAIL,
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
    consoleErrors: [],
    events: [], // {t, kind, url}
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
  page.on('console', (msg) => {
    if (msg.type() === 'error') s.consoleErrors.push(msg.text().slice(0, 220));
  });
  page.on('request', (req) => {
    if (!/firestore\.googleapis\.com/.test(req.url())) return;
    s.starts += 1;
    if (s.routeT0 != null) {
      s.routeStarts += 1;
      s.events.push({ t: Date.now() - s.routeT0, kind: 'start', url: req.url().slice(0, 120) });
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

async function waitFirstFirestore(net, timeoutMs = 20000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (net.firstDoneMs != null) return net.firstDoneMs;
    await new Promise((r) => setTimeout(r, 50));
  }
  return null;
}

async function waitQuiet(net, { quietMs = 1500, timeoutMs = 45000, minActivity = true } = {}) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (minActivity && net.firstDoneMs == null) {
      await new Promise((r) => setTimeout(r, 50));
      continue;
    }
    if (net.lastDoneAt && Date.now() - net.lastDoneAt >= quietMs) {
      return Date.now() - net.routeT0;
    }
    await new Promise((r) => setTimeout(r, 100));
  }
  return Date.now() - net.routeT0;
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
  await page.waitForTimeout(400);
}

async function ariaSample(page) {
  return page.evaluate(() => {
    const nodes = Array.from(
      document.querySelectorAll('[aria-label], [flt-semantics-identifier], flutter-view'),
    );
    return nodes
      .map((n) => n.getAttribute('aria-label') || n.getAttribute('flt-semantics-identifier') || '')
      .filter(Boolean)
      .slice(0, 40)
      .join(' | ')
      .slice(0, 500);
  });
}

async function clickText(page, patterns) {
  return page.evaluate((pats) => {
    const res = pats.map((p) => new RegExp(p, 'i'));
    const nodes = Array.from(document.querySelectorAll('button, [role="button"], [aria-label]'));
    for (const n of nodes) {
      const t = (n.innerText || n.getAttribute('aria-label') || '').trim();
      if (!t || t.length > 64) continue;
      if (res.some((re) => re.test(t))) {
        n.click();
        return t.slice(0, 64);
      }
    }
    // Flutter semantics nodes
    for (const n of Array.from(document.querySelectorAll('flt-semantics'))) {
      const t = (n.getAttribute('aria-label') || '').trim();
      if (t && res.some((re) => re.test(t))) {
        n.click();
        return t.slice(0, 64);
      }
    }
    return null;
  }, patterns);
}

async function hydrate(page, signIn) {
  await page.goto(appUrl('/'), { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(1000);
  await writeAuth(page, buildAuthUser(signIn));
  await page.goto(appUrl('/adminFinanceHub'), {
    waitUntil: 'domcontentloaded',
    timeout: 90000,
  });
  await page.waitForTimeout(2500);
  await enableSemantics(page);
}

async function measure(page, net, route, opts = {}) {
  net.markRoute();
  const navT0 = Date.now();
  await page.goto(appUrl(route), { waitUntil: 'domcontentloaded', timeout: 90000 });
  const loaderMs = Date.now() - navT0;
  const firstUsefulMs = await waitFirstFirestore(net, 20000);
  await enableSemantics(page);
  let periodClick = null;
  let afterPeriodFirstMs = null;
  if (opts.clickPeriod) {
    periodClick = await clickText(page, opts.clickPeriod);
    if (periodClick) {
      net.markRoute();
      afterPeriodFirstMs = await waitFirstFirestore(net, 15000);
      await waitQuiet(net, { quietMs: 1200, timeoutMs: 20000 });
    }
  }
  const summaryMs = await waitQuiet(net, { quietMs: 1500, timeoutMs: 40000 });
  // UI settle buffer for screenshot
  await page.waitForTimeout(800);
  if (opts.shot) {
    await page.screenshot({ path: path.join(OUT, opts.shot), fullPage: true });
  }
  return {
    route,
    loaderMs,
    firstUsefulMs,
    summaryMs,
    firestoreStarts: net.routeStarts,
    periodClick,
    afterPeriodFirstMs,
    aria: await ariaSample(page),
    measurement: 'firestore_network_first_response_and_quiet',
  };
}

const signIn = await exchangeCustomToken(fs.readFileSync(TOKEN_FILE, 'utf8').trim());
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const page = await context.newPage();
const net = attachNet(page);
const report = {
  base: BASE,
  authMode: 'custom_token_injection',
  email: EMAIL,
  cold: null,
  warm: [],
  sequence: [],
  settlements: {},
  medians: {},
};

console.log('hydrate');
await hydrate(page, signIn);

await page.goto(appUrl('/adminFinanceHub'), { waitUntil: 'commit', timeout: 90000 });
await page.waitForTimeout(100);
await page.screenshot({ path: path.join(OUT, '01_finance_hub_loading.png'), fullPage: true });

report.cold = await measure(page, net, '/adminFinanceHub', {
  shot: '01_finance_hub_loaded_cold.png',
});
await page.screenshot({ path: path.join(OUT, '01b_finance_hub_after_cold.png'), fullPage: true });

for (let i = 0; i < RUNS; i++) {
  console.log('warm', i + 1);
  const run = { n: i + 1 };
  run.finance = await measure(page, net, '/adminFinanceHub', {
    shot: i === 0 ? '02_finance_hub_loaded.png' : null,
  });
  if (i === 0) {
    // year preset attempt for denser data
    const year = await measure(page, net, '/adminFinanceHub', {
      clickPeriod: ['هذه السنة', 'This year', 'this year'],
      shot: '02c_finance_hub_this_year.png',
    });
    run.financeYear = year;
  }
  run.reconciliation = await measure(page, net, '/adminFinanceReconciliation', {
    shot: i === 0 ? '03_reconciliation_loaded.png' : null,
  });
  if (i === 0) {
    await page.screenshot({
      path: path.join(OUT, '04_reconciliation_partial_trip.png'),
      fullPage: true,
    });
  }
  run.settlements = await measure(page, net, '/adminSettlements', {
    shot: i === 0 ? '05_settlements_loaded.png' : null,
  });
  report.warm.push(run);
  fs.writeFileSync(path.join(OUT, 'runs', `warm_${i + 1}.json`), JSON.stringify(run, null, 2));
  console.log(
    JSON.stringify({
      n: i + 1,
      fin: run.finance.firstUsefulMs,
      recon: run.reconciliation.firstUsefulMs,
      sett: run.settlements.firstUsefulMs,
    }),
  );
}

console.log('sequence');
const seq0 = { starts: net.starts };
for (const [route, shot] of [
  ['/adminFinanceHub', null],
  ['/adminFinanceReconciliation', null],
  ['/adminFinanceChannels', null],
  ['/adminSettlements', null],
  ['/adminFinanceAgents', '07_agent_finance.png'],
  ['/adminFinanceReports', '08_reports.png'],
]) {
  report.sequence.push(await measure(page, net, route, { shot }));
}
report.sequenceFirestoreStarts = net.starts - seq0.starts;

await page.goto(appUrl('/adminSettlements'), {
  waitUntil: 'domcontentloaded',
  timeout: 90000,
});
await page.waitForTimeout(2000);
await enableSemantics(page);
const tF = Date.now();
report.settlements.filterLabel = await clickText(page, [
  'Pending',
  'Open',
  'Paid',
  'معلق',
  'مفتوح',
  'مدفوع',
  'الكل',
]);
await page.waitForTimeout(600);
report.settlements.filterMs = Date.now() - tF;
await page.screenshot({ path: path.join(OUT, '06_settlements_filter.png'), fullPage: true });
const tN = Date.now();
report.settlements.nextLabel = await clickText(page, [
  'Load more',
  'المزيد',
  'التالي',
  'More',
  'Next',
]);
if (report.settlements.nextLabel) {
  await page.waitForTimeout(900);
  report.settlements.nextPageMs = Date.now() - tN;
} else {
  report.settlements.nextPageMs = null;
}

report.medians = {
  financeFirstUsefulMs: median(report.warm.map((r) => r.finance.firstUsefulMs)),
  financeSummaryMs: median(report.warm.map((r) => r.finance.summaryMs)),
  reconciliationFirstUsefulMs: median(
    report.warm.map((r) => r.reconciliation.firstUsefulMs),
  ),
  reconciliationSummaryMs: median(report.warm.map((r) => r.reconciliation.summaryMs)),
  settlementsFirstUsefulMs: median(report.warm.map((r) => r.settlements.firstUsefulMs)),
  settlementsFilterMs: report.settlements.filterMs,
  settlementsNextPageMs: report.settlements.nextPageMs,
  coldFinanceFirstUsefulMs: report.cold?.firstUsefulMs ?? null,
};
report.indexErrors = net.indexErrors.slice(0, 10);
report.consoleErrors = net.consoleErrors.slice(0, 15);
report.netTotals = { starts: net.starts, dones: net.dones };
report.screenshots = fs.readdirSync(OUT).filter((f) => f.endsWith('.png'));
report.note =
  'firstUsefulMs = ms from route navigation to first Firestore HTTP response; summaryMs = quiet window after Firestore activity (proxy for summary settle). Flutter canvas prevents reliable DOM text timing.';

fs.writeFileSync(path.join(OUT, 'p2a_human_gate_metrics.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify({ ok: true, medians: report.medians }, null, 2));
await browser.close();
