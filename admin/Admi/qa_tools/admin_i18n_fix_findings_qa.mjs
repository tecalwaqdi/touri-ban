/**
 * Admin i18n fix-findings authenticated visual QA (Flutter canvas-safe).
 * Auth via custom token injection (no passwords). Screenshots only.
 */
import { chromium, webkit } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = (
  process.env.BASE_URL ||
  'https://tutorial-multi-language-70gx4j--admin-i18n-az-iuasprdq.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR || '/tmp/admin_i18n_fix_qa';
const LOCALES = (process.env.LOCALES || 'ar,en,ru,ky,fr,ur,pt').split(',');
const VIEWPORTS = [
  { name: '1440', width: 1440, height: 900 },
  { name: '1280', width: 1280, height: 800 },
  { name: '1024', width: 1024, height: 768 },
  { name: '768', width: 768, height: 1024 },
];

const ROLES = [
  {
    name: 'accountant',
    tokenFile: '/tmp/admin_i18n_token_accountant.txt',
    email: 'accountant.demo@touri-taxi.com',
    routes: [
      { id: 'dashboard', path: '/' },
      { id: 'finance', path: '/accountantFinance' },
      { id: 'reconciliation', path: '/adminReconciliation' },
      { id: 'money', path: '/accountantMoneyMovement' },
      { id: 'settlements', path: '/adminSettlements' },
      { id: 'reports', path: '/adminReportsHub' },
      { id: 'settings', path: '/settings' },
    ],
  },
  {
    name: 'super',
    tokenFile: '/tmp/admin_i18n_token_super.txt',
    email: 'admin@arawatan.app',
    routes: [
      { id: 'dashboard', path: '/' },
      { id: 'drivers', path: '/admindrever' },
      { id: 'agents', path: '/edetAgent' },
      { id: 'users', path: '/adminuser' },
      { id: 'landmarks', path: '/adminMkan' },
      { id: 'bookings', path: '/adminALlhgZ' },
      { id: 'finance', path: '/accountantFinance' },
      { id: 'profile', path: '/profile' },
    ],
  },
  {
    name: 'agent',
    tokenFile: '/tmp/admin_i18n_token_agent.txt',
    email: 'demo.agent.ng.1@touri-taxi.com',
    routes: [
      { id: 'dashboard', path: '/' },
      { id: 'drivers', path: '/admindrever' },
      { id: 'bookings', path: '/adminALlhgZ' },
    ],
  },
];

fs.mkdirSync(OUT, { recursive: true });

async function exchangeCustomToken(customToken, email) {
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
    localId: data.localId,
    email: email || data.email || '',
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
            const tx = db.transaction('firebaseLocalStorage', 'readwrite');
            tx.objectStore('firebaseLocalStorage').put({
              fbase_key: key,
              value: user,
            });
            tx.oncomplete = () => resolve();
            tx.onerror = () => resolve();
          } catch (_) {
            resolve();
          }
        };
      });
    },
    { apiKey: API_KEY, user },
  );
}

async function setLocalePrefs(page, locale) {
  await page.evaluate((locale) => {
    // FFLocalizations uses SharedPreferences key __locale_key__ (web: flutter.__locale_key__).
    const pairs = [
      ['flutter.__locale_key__', locale],
      ['__locale_key__', locale],
      ['flutter.ff_locale', locale],
      ['ff_locale', locale],
    ];
    for (const [k, v] of pairs) localStorage.setItem(k, v);
  }, locale);
}

async function shot(page, file) {
  const dest = path.join(OUT, file);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  await page.screenshot({ path: dest, fullPage: false });
  return dest;
}

async function runBrowser(browserType, label) {
  const browser = await browserType.launch({ headless: true });
  const summary = { browser: label, login: {}, auth: {}, viewports: {} };

  // Login-only locale matrix
  for (const locale of LOCALES) {
    const context = await browser.newContext({
      viewport: { width: 1280, height: 800 },
      locale: locale === 'ar' || locale === 'ur' ? `${locale}` : locale,
    });
    const page = await context.newPage();
    await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await setLocalePrefs(page, locale);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(4500);
    await shot(page, `login/${label}_${locale}_1280.png`);
    summary.login[locale] = 'captured';
    await context.close();
  }

  // Authenticated: accountant for all locales (dashboard/table/finance)
  const role = ROLES[0];
  const token = fs.readFileSync(role.tokenFile, 'utf8').trim();
  const signIn = await exchangeCustomToken(token, role.email);
  const user = buildAuthUser(signIn);

  for (const locale of LOCALES) {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await writeAuth(page, user);
    await setLocalePrefs(page, locale);
    await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(6000);
    await shot(page, `auth/${label}_${locale}_dashboard.png`);

    await page.goto(`${BASE}/accountantFinance`, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(6000);
    await shot(page, `auth/${label}_${locale}_finance.png`);

    await page.goto(`${BASE}/adminSettlements`, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(5000);
    await shot(page, `auth/${label}_${locale}_table.png`);
    summary.auth[locale] = 'captured';
    await context.close();
  }

  // Role route smoke (EN)
  for (const role of ROLES) {
    if (!fs.existsSync(role.tokenFile)) continue;
    const token = fs.readFileSync(role.tokenFile, 'utf8').trim();
    const signIn = await exchangeCustomToken(token, role.email);
    const user = buildAuthUser(signIn);
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await writeAuth(page, user);
    await setLocalePrefs(page, 'en');
    for (const route of role.routes) {
      await page.goto(`${BASE}${route.path}`, { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(4500);
      await shot(page, `roles/${label}_${role.name}_${route.id}.png`);
    }
    await context.close();
  }

  // Viewport matrix on AR authenticated dashboard
  {
    const token = fs.readFileSync(ROLES[0].tokenFile, 'utf8').trim();
    const signIn = await exchangeCustomToken(token, ROLES[0].email);
    const user = buildAuthUser(signIn);
    for (const vp of VIEWPORTS) {
      const context = await browser.newContext({
        viewport: { width: vp.width, height: vp.height },
      });
      const page = await context.newPage();
      await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
      await writeAuth(page, user);
      await setLocalePrefs(page, 'ar');
      await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(5000);
      await shot(page, `viewport/${label}_ar_${vp.name}.png`);
      summary.viewports[vp.name] = 'captured';
      await context.close();
    }
  }

  await browser.close();
  return summary;
}

const results = {};
results.chromium = await runBrowser(chromium, 'chromium');
results.webkit = await runBrowser(webkit, 'webkit');
fs.writeFileSync(path.join(OUT, 'summary.json'), JSON.stringify(results, null, 2));
console.log('OUT', OUT);
console.log(JSON.stringify(results, null, 2));
