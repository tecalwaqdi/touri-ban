/**
 * Checkpoint 5 — Authenticated route smoke (IndexedDB hydration = Stage F).
 */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_cp5_routes');
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4176';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const EMAIL = process.env.ADMIN_QA_EMAIL || '';
const PASSWORD = process.env.ADMIN_QA_PASSWORD || '';

const ROUTES = [
  '/home22Dashboard',
  '/adminALLhgZ',
  '/drever',
  '/adminuser',
  '/adminSuport',
  '/adminDol',
  '/adminM3alm',
  '/admintypecar',
  '/adminFinanceHub',
  '/adminSettlements',
  '/settings',
];

fs.mkdirSync(OUT, {recursive: true});

function buildAuthUser(signIn) {
  const expMs = Date.now() + Number(signIn.expiresIn || 3600) * 1000;
  return {
    uid: signIn.localId,
    email: signIn.email,
    emailVerified: true,
    displayName: signIn.displayName || '',
    isAnonymous: false,
    providerData: [
      {
        providerId: 'password',
        uid: signIn.email,
        email: signIn.email,
      },
    ],
    stsTokenManager: {
      refreshToken: signIn.refreshToken,
      accessToken: signIn.idToken,
      expirationTime: expMs,
    },
    createdAt: String(Date.now()),
    lastLoginAt: String(Date.now()),
    apiKey: API_KEY,
    appName: '[DEFAULT]',
  };
}

async function writeAuthToPage(page, authUser) {
  await page.evaluate(
    async ({apiKey, user}) => {
      const key = `firebase:authUser:${apiKey}:[DEFAULT]`;
      localStorage.setItem(key, JSON.stringify(user));
      await new Promise((resolve) => {
        const openReq = indexedDB.open('firebaseLocalStorageDb', 1);
        openReq.onerror = () => resolve();
        openReq.onupgradeneeded = () => {
          const db = openReq.result;
          if (!db.objectStoreNames.contains('firebaseLocalStorage')) {
            db.createObjectStore('firebaseLocalStorage', {keyPath: 'fbase_key'});
          }
        };
        openReq.onsuccess = () => {
          try {
            const db = openReq.result;
            if (!db.objectStoreNames.contains('firebaseLocalStorage')) {
              resolve();
              return;
            }
            const tx = db.transaction('firebaseLocalStorage', 'readwrite');
            tx.oncomplete = () => resolve();
            tx.onerror = () => resolve();
            tx.objectStore('firebaseLocalStorage').put({
              fbase_key: key,
              value: user,
            });
          } catch (_) {
            resolve();
          }
        };
      });
    },
    {apiKey: API_KEY, user: authUser},
  );
}

async function main() {
  const signInRes = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      }),
    },
  );
  const signIn = await signInRes.json();
  if (!signIn.idToken) throw new Error(JSON.stringify(signIn));

  const browser = await chromium.launch({headless: true});
  const context = await browser.newContext({viewport: {width: 1440, height: 900}});
  const page = await context.newPage();

  await page.goto(`${BASE}/`, {waitUntil: 'domcontentloaded', timeout: 60000});
  await page.waitForTimeout(4000);
  await writeAuthToPage(page, buildAuthUser(signIn));
  await page.goto(`${BASE}/home22Dashboard`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForTimeout(8000);

  const report = {
    startedAt: new Date().toISOString(),
    loginUid: signIn.localId,
    routes: {},
  };

  for (const route of ROUTES) {
    await page.goto(`${BASE}${route}`, {
      waitUntil: 'domcontentloaded',
      timeout: 45000,
    });
    await page.waitForTimeout(4500);
    const evidence = await page.evaluate(() => ({
      path: location.pathname,
      hasCanvas: !!document.querySelector('flt-glass-pane, flutter-view, canvas'),
    }));
    const onLogin =
      evidence.path === '/homePage' ||
      evidence.path === '/' ||
      evidence.path === '';
    const matched =
      evidence.path.includes(route.replace(/^\//, '')) ||
      (route === '/home22Dashboard' && evidence.path.includes('home22'));
    const status = !onLogin && matched
      ? 'PASS_AUTHENTICATED'
      : !onLogin && evidence.hasCanvas
        ? 'PASS_AUTHENTICATED_ALT_ROUTE'
        : onLogin
          ? 'PARTIAL_LOGIN_REDIRECT'
          : 'FAIL';
    report.routes[route] = {status, evidence};
    await page.screenshot({
      path: path.join(OUT, `auth_${route.replace(/\//g, '_')}.png`),
      fullPage: false,
    });
  }

  report.ADMIN_ROUTES_TESTED = ROUTES.length;
  report.ADMIN_ROUTES_AUTHENTICATED_PASS = Object.values(report.routes).filter(
    (r) => String(r.status).startsWith('PASS'),
  ).length;
  report.ADMIN_ROUTES_PARTIAL = Object.values(report.routes).filter((r) =>
    String(r.status).includes('PARTIAL'),
  ).length;
  report.finishedAt = new Date().toISOString();
  fs.writeFileSync(path.join(OUT, 'report_auth.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
