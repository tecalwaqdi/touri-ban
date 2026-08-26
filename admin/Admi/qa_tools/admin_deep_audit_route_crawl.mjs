/**
 * Admin deep audit — authenticated crawl of all active routes.
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 * Optional: BASE_URL (default http://127.0.0.1:4173)
 * Read-only: load each route, capture blank/crash/login-bounce.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(
  '/Users/ventura/ara-ban/qa_master_audit/admin_deep_audit',
  'runtime_crawl',
);
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4173';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';

const ROUTES = [
  { id: 'home22Dashboard', path: '/home22Dashboard', critical: true },
  { id: 'adminHome', path: '/adminHome', critical: true },
  { id: 'home', path: '/home', critical: false },
  { id: 'home3', path: '/home3', critical: false },
  { id: 'adminuser', path: '/adminuser', critical: true },
  { id: 'adminDrivers', path: '/adminDrivers', critical: true },
  { id: 'drever', path: '/drever', critical: true },
  { id: 'adminDriversCopy', path: '/adminDriversCopy', critical: false },
  { id: 'driverActivation', path: '/driverActivation', critical: false },
  { id: 'driverReviewFixture', path: '/driverReviewFixture', critical: false },
  { id: 'adminALLhgZ', path: '/adminALLhgZ', critical: true },
  { id: 'adminSuport', path: '/adminSuport', critical: true },
  { id: 'adminDol', path: '/adminDol', critical: true },
  { id: 'adminregion', path: '/adminregion', critical: true },
  { id: 'admincite', path: '/admincite', critical: true },
  { id: 'adminvill', path: '/adminvill', critical: true },
  { id: 'adminaddMkan', path: '/adminaddMkan', critical: true },
  { id: 'adminM3alm', path: '/adminM3alm', critical: true },
  { id: 'adminPartners', path: '/adminPartners', critical: false },
  { id: 'admintypecar', path: '/admintypecar', critical: true },
  { id: 'adminTourGuides', path: '/adminTourGuides', critical: false },
  { id: 'adminTransportCompanies', path: '/adminTransportCompanies', critical: false },
  { id: 'adminAgent', path: '/adminAgent', critical: false },
  { id: 'adminAgentReport', path: '/adminAgentReport', critical: false },
  { id: 'adminAgentCopy', path: '/adminAgentCopy', critical: false },
  { id: 'adminSuperAdmins', path: '/adminSuperAdmins', critical: true },
  { id: 'adminUserManagementSystem', path: '/adminUserManagementSystem', critical: false },
  { id: 'adminRegesr', path: '/adminRegesr', critical: false },
  { id: 'adminFinanceHub', path: '/adminFinanceHub', critical: true },
  { id: 'adminDriverWallets', path: '/adminDriverWallets', critical: true },
  { id: 'adminSettlements', path: '/adminSettlements', critical: true },
  { id: 'adminReconciliation', path: '/adminReconciliation', critical: true },
  { id: 'adminFinancialPeriods', path: '/adminFinancialPeriods', critical: true },
  { id: 'adminFinanceReports', path: '/adminFinanceReports', critical: true },
  { id: 'adminFinanceAudit', path: '/adminFinanceAudit', critical: true },
  { id: 'adminProfits', path: '/adminProfits', critical: false },
  { id: 'adminAuditLog', path: '/adminAuditLog', critical: false },
  { id: 'adminReportsHub', path: '/adminReportsHub', critical: true },
  { id: 'adminDiagnostics', path: '/adminDiagnostics', critical: false },
  { id: 'settings', path: '/settings', critical: true },
  { id: 'addPlace', path: '/addPlace', critical: false },
  { id: 'addDolh', path: '/addDolh', critical: false },
  { id: 'addReg', path: '/addReg', critical: false },
  { id: 'addVill', path: '/addVill', critical: false },
  { id: 'addUser', path: '/addUser', critical: false },
  { id: 'addDrev', path: '/addDrev', critical: false },
  { id: 'addTransportCompany', path: '/addTransportCompany', critical: false },
  { id: 'adminAddPartner', path: '/adminAddPartner', critical: false },
  { id: 'adminAddAgent', path: '/adminAddAgent', critical: false },
  { id: 'adminAddSuperAdmin', path: '/adminAddSuperAdmin', critical: false },
  { id: 'carTypeAddition', path: '/carTypeAddition', critical: false },
  { id: 'adminEdetMkan', path: '/adminEdetMkan', critical: false },
  // Param-heavy — expect graceful empty/error, not crash
  { id: 'adminBookingDetails', path: '/adminBookingDetails', critical: false, needsParam: true },
  { id: 'driverProfile', path: '/driverProfile', critical: false, needsParam: true },
  { id: 'edetAgent', path: '/edetAgent', critical: false, needsParam: true },
  { id: 'edetDolh', path: '/edetDolh', critical: false, needsParam: true },
  { id: 'edetReg', path: '/edetReg', critical: false, needsParam: true },
  { id: 'edetVill', path: '/edetVill', critical: false, needsParam: true },
  { id: 'edetSuperAdmin', path: '/edetSuperAdmin', critical: false, needsParam: true },
  { id: 'edetTransportCompany', path: '/edetTransportCompany', critical: false, needsParam: true },
  { id: 'companyDrivers', path: '/companyDrivers', critical: false, needsParam: true },
  { id: 'partnerBookings', path: '/partnerBookings', critical: false, needsParam: true },
  { id: 'adminSettlementDetails', path: '/adminSettlementDetails', critical: false, needsParam: true },
  { id: 'adminSettlementReceipt', path: '/adminSettlementReceipt', critical: false, needsParam: true },
  { id: 'homePage', path: '/homePage', critical: false },
];

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function appUrl(routePath) {
  const p = routePath.startsWith('/') ? routePath : `/${routePath}`;
  return `${BASE}${p}`;
}

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
        displayName: signIn.displayName || null,
        email: signIn.email,
        phoneNumber: null,
        photoURL: null,
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
    { apiKey: API_KEY, user: authUser },
  );
}

async function restSignIn(email, password) {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(JSON.stringify(json));
  return json;
}

async function waitForFlutter(page, ms = 2000) {
  try {
    await page.waitForSelector('flutter-view, flt-glass-pane, canvas, body', {
      timeout: 20000,
    });
  } catch (_) {}
  if (ms > 0) await page.waitForTimeout(ms);
}

async function enableSemantics(page) {
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
    window.__flutter_web_set_semantics_enabled?.(true);
  });
  await page.waitForTimeout(400);
}

async function probe(page) {
  return page.evaluate(() => {
    const body = document.body;
    const path = location.pathname + location.search + location.hash;
    const sample = (body?.innerText || '').replace(/\s+/g, ' ').slice(0, 800);
    const onLogin =
      path === '/' || path === '' || /\/homePage(?:\/|$|\?)/i.test(path);
    const unauthorized =
      /not authorized for the admin panel|غير مصرح/i.test(sample);
    const blank =
      sample.trim().length < 12 &&
      !document.querySelector('flt-semantics, [aria-label]');
    const errorish =
      /Exception:|Error:|Null check operator|was thrown|RenderFlex overflowed/i.test(
        sample,
      );
    const loading = /جاري تحميل|Loading the control|Loading dashboard|Loading…|Loading\.\.\./i.test(
      sample,
    );
    const hasSemantics = !!document.querySelector('flt-semantics');
    return {
      path,
      sample,
      onLogin,
      unauthorized,
      blank,
      errorish,
      loading,
      hasSemantics,
      textLen: sample.trim().length,
    };
  });
}

function classify(route, state) {
  if (state.unauthorized) return 'FAIL_UNAUTHORIZED';
  if (state.onLogin && route.path !== '/homePage' && route.path !== '/') {
    return route.needsParam ? 'PARTIAL_PARAM_OR_AUTH_BOUNCE' : 'FAIL_LOGIN_BOUNCE';
  }
  if (state.errorish) return 'FAIL_ERROR_TEXT';
  if (state.blank) return 'FAIL_BLANK';
  if (state.loading) return 'PARTIAL_STILL_LOADING';
  if (state.textLen < 20 && !state.hasSemantics) return 'PARTIAL_LOW_CONTENT';
  return 'RUNTIME_PASS';
}

async function main() {
  ensureDir(OUT);
  const email = process.env.ADMIN_QA_EMAIL;
  const password = process.env.ADMIN_QA_PASSWORD;
  if (!email || !password) {
    throw new Error('ADMIN_QA_EMAIL and ADMIN_QA_PASSWORD required');
  }

  console.log('[ADMIN DEEP AUDIT STEP 108] Runtime route crawl');
  console.log('STATUS: RUNNING');
  console.log(`ACTION: Crawl ${ROUTES.length} routes at ${BASE}`);

  const signIn = await restSignIn(email, password);
  const authUser = buildAuthUser(signIn);
  console.log('AUTH_OK uid_prefix=', String(signIn.localId).slice(0, 8));

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    locale: 'ar',
  });
  const page = await context.newPage();
  const pageErrors = [];
  page.on('pageerror', (e) => pageErrors.push(String(e).slice(0, 200)));

  // Seed auth
  await page.goto(appUrl('/homePage'), { waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitForFlutter(page, 2500);
  await writeAuthToPage(page, authUser);
  await page.reload({ waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitForFlutter(page, 4000);
  await enableSemantics(page);

  // Navigate to dashboard first to confirm session
  await page.goto(appUrl('/home22Dashboard'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await waitForFlutter(page, 5000);
  await enableSemantics(page);
  const boot = await probe(page);
  fs.writeFileSync(path.join(OUT, 'boot_probe.json'), JSON.stringify(boot, null, 2));
  console.log('BOOT', boot.path, 'onLogin=', boot.onLogin, 'textLen=', boot.textLen);

  const results = [];
  let i = 0;
  for (const route of ROUTES) {
    i += 1;
    const started = Date.now();
    pageErrors.length = 0;
    console.log(`PROGRESS ${i}/${ROUTES.length} ${route.id}`);
    try {
      await page.goto(appUrl(route.path), {
        waitUntil: 'domcontentloaded',
        timeout: 60000,
      });
      await waitForFlutter(page, 3500);
      await enableSemantics(page);
      // second settle for streams
      await page.waitForTimeout(1500);
      const state = await probe(page);
      const result = classify(route, state);
      const row = {
        ...route,
        result,
        elapsed_ms: Date.now() - started,
        final_path: state.path,
        onLogin: state.onLogin,
        unauthorized: state.unauthorized,
        blank: state.blank,
        errorish: state.errorish,
        loading: state.loading,
        textLen: state.textLen,
        sample: state.sample.slice(0, 240),
        pageErrors: [...pageErrors],
      };
      results.push(row);
      // screenshot critical failures
      if (String(result).startsWith('FAIL') || route.critical) {
        await page.screenshot({
          path: path.join(OUT, `${route.id}.png`),
          fullPage: false,
        });
      }
    } catch (e) {
      results.push({
        ...route,
        result: 'FAIL_NAV',
        error: String(e).slice(0, 300),
        elapsed_ms: Date.now() - started,
      });
    }
  }

  const pass = results.filter((r) => r.result === 'RUNTIME_PASS').length;
  const fail = results.filter((r) => String(r.result).startsWith('FAIL')).length;
  const partial = results.filter((r) => String(r.result).startsWith('PARTIAL')).length;
  const summary = {
    TOTAL_ROUTES: ROUTES.length,
    RUNTIME_PASS: pass,
    FAIL: fail,
    PARTIAL: partial,
    COVERAGE_PCT: Math.round((pass / ROUTES.length) * 1000) / 10,
    COVERAGE_PASS_OR_PARTIAL_PCT:
      Math.round(((pass + partial) / ROUTES.length) * 1000) / 10,
    boot,
    results,
  };
  fs.writeFileSync(path.join(OUT, 'summary.json'), JSON.stringify(summary, null, 2));
  console.log('RESULT:', JSON.stringify({
    TOTAL_ROUTES: summary.TOTAL_ROUTES,
    RUNTIME_PASS: pass,
    FAIL: fail,
    PARTIAL: partial,
    COVERAGE_PCT: summary.COVERAGE_PCT,
  }));
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
