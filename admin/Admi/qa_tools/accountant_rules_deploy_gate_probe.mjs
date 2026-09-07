/**
 * ACCOUNTANT_FINANCE_RULES_DEPLOY_GATE — read-only Preview tour + screenshots.
 * Auth via custom token (no password). No financial writes.
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
  'https://tutorial-multi-language-70gx4j--accountant-read-access-j188djm9.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR ||
  path.join(__dirname, '..', 'visual_qa_accountant_rules_deploy_gate');
const TOKEN_FILE = process.env.CUSTOM_TOKEN_FILE || '/tmp/accountant_custom_token.txt';
const UID = 'jrPITQI0Y2QJNELU43ymS1WJvR43';
const EMAIL = 'accountant.demo@touri-taxi.com';

const ROUTES = [
  { key: 'finance_hub', path: '/adminFinanceHub', shot: '01_finance_hub.png' },
  {
    key: 'recon',
    path: '/adminFinanceReconciliation',
    shot: '02_reconciliation.png',
  },
  { key: 'money', path: '/adminFinanceChannels', shot: '03_money_movement.png' },
  { key: 'settlements', path: '/adminSettlements', shot: '04_settlements.png' },
  {
    key: 'agent_finance',
    path: '/adminAgentFinance',
    shot: '05_agent_finance.png',
  },
  { key: 'reports', path: '/adminFinanceReports', shot: '06_reports.png' },
  { key: 'audit', path: '/adminFinanceAudit', shot: '07_finance_audit.png' },
  { key: 'settings', path: '/settings', shot: '08_settings_redirect.png' },
  { key: 'hub_return', path: '/adminFinanceHub', shot: '09_hub_return.png' },
];

const BAD = [
  'permission-denied',
  'PERMISSION_DENIED',
  'Bad state',
  'finance_query_unavailable',
  'FirebaseException',
  'ليس لديك صلاحية',
  'تعذر تحميل المالية',
  'تعذر تحميل بيانات المصالحة',
];

fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(path.join(OUT, 'shots'), { recursive: true });

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

function attachFs(page) {
  const events = [];
  page.on('response', async (res) => {
    const u = res.url();
    if (!u.includes('firestore.googleapis.com')) return;
    const status = res.status();
    let denied = false;
    if (status === 403) denied = true;
    try {
      const t = await res.text();
      if (/PERMISSION_DENIED/i.test(t)) denied = true;
    } catch (_) {}
    events.push({ url: u.slice(0, 180), status, denied, at: Date.now() });
  });
  return events;
}

(async () => {
  const customToken = fs.readFileSync(TOKEN_FILE, 'utf8').trim();
  const signIn = await exchangeCustomToken(customToken);
  const authUser = buildAuthUser(signIn);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    locale: 'ar',
  });
  const page = await context.newPage();
  const fsEvents = attachFs(page);

  // Seed auth on origin
  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await writeAuth(page, authUser);
  await page.reload({ waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForTimeout(8000);

  const report = {
    base: BASE,
    login_redirects: 0,
    signouts: 0,
    routes: {},
    sidebar_settings_visible: null,
    permission_denied_network: 0,
    raw_error_hits: [],
  };

  for (const route of ROUTES) {
    const t0 = Date.now();
    const beforeUrl = page.url();
    await page.goto(`${BASE}${route.path}`, {
      waitUntil: 'domcontentloaded',
      timeout: 120000,
    });
    await page.waitForTimeout(10000);
    const url = page.url();
    const bodyText = await page.locator('body').innerText().catch(() => '');
    const badHits = BAD.filter((b) => bodyText.includes(b));
    if (/\/login/i.test(url) && !/adminFinance|adminSettlements|adminAgent|settings/i.test(url)) {
      report.login_redirects += 1;
    }
    // Auth cleared?
    const stillAuthed = await page.evaluate((apiKey) => {
      const key = `firebase:authUser:${apiKey}:[DEFAULT]`;
      return !!localStorage.getItem(key);
    }, API_KEY);
    if (!stillAuthed) report.signouts += 1;

    await page.screenshot({
      path: path.join(OUT, 'shots', route.shot),
      fullPage: false,
    });

    report.routes[route.key] = {
      path: route.path,
      final_url: url,
      ms: Date.now() - t0,
      bad_hits: badHits,
      auth_present: stillAuthed,
      redirected_from: beforeUrl,
    };
    if (badHits.length) report.raw_error_hits.push({ route: route.key, badHits });
  }

  // Sidebar check on hub
  await page.goto(`${BASE}/adminFinanceHub`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  await page.waitForTimeout(6000);
  const sidebarText = await page.locator('body').innerText().catch(() => '');
  report.sidebar_settings_visible =
    sidebarText.includes('الإعدادات') || /Settings/i.test(sidebarText);
  await page.screenshot({
    path: path.join(OUT, 'shots', '10_sidebar_hub.png'),
    fullPage: false,
  });

  report.permission_denied_network = fsEvents.filter((e) => e.denied).length;
  report.fs_sample = fsEvents.slice(0, 30);
  report.fs_denied_sample = fsEvents.filter((e) => e.denied).slice(0, 20);

  fs.writeFileSync(path.join(OUT, 'probe_report.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
