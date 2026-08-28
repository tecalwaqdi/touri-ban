/**
 * Admin Control Panel — Production authenticated route crawl + count/list signals.
 *
 * Env:
 *   ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 *   BASE_URL (default https://touri-ban-1.onrender.com)
 *
 * Does not print secrets. Read-only UI navigation.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_data_recovery');
const BASE = process.env.BASE_URL || 'https://touri-ban-1.onrender.com';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const EMAIL = process.env.ADMIN_QA_EMAIL || '';
const PASSWORD = process.env.ADMIN_QA_PASSWORD || '';

const ROUTES = [
  '/home22Dashboard',
  '/drever',
  '/adminALLhgZ',
  '/adminuser',
  '/adminDol',
  '/adminregion',
  '/adminvill',
  '/adminM3alm',
  '/admintypecar',
  '/adminTransportCompanies',
  '/adminSuport',
  '/adminDriverWallets',
  '/adminFinanceHub',
  '/adminAgent',
  '/adminPartners',
  '/adminTourGuides',
  '/settings',
];

fs.mkdirSync(OUT, { recursive: true });

async function restSignIn(email, password) {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(json?.error?.message || 'signIn failed');
  return json;
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
      { providerId: 'password', uid: signIn.email, email: signIn.email },
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

async function writeAuth(page, authUser) {
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

function scrub(s) {
  return String(s || '')
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]')
    .replace(/Bearer\s+\S+/gi, 'Bearer [token]')
    .replace(/idToken[^,\s]*/gi, 'idToken=[redacted]');
}

async function settle(page, ms = 4500) {
  await page.waitForTimeout(ms);
}

async function probeRoute(page, routePath) {
  const consoleErrors = [];
  const pageErrors = [];
  const netFails = [];
  const onConsole = (msg) => {
    if (msg.type() === 'error') consoleErrors.push(scrub(msg.text()).slice(0, 300));
  };
  const onPageError = (err) => pageErrors.push(scrub(err.message).slice(0, 300));
  const onRequestFailed = (req) => {
    netFails.push({
      url: scrub(req.url()).slice(0, 180),
      error: scrub(req.failure()?.errorText || ''),
    });
  };
  page.on('console', onConsole);
  page.on('pageerror', onPageError);
  page.on('requestfailed', onRequestFailed);

  const t0 = Date.now();
  let http = null;
  try {
    const res = await page.goto(`${BASE}${routePath}`, {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });
    http = res?.status() ?? null;
  } catch (e) {
    http = `NAV_FAIL:${scrub(e.message).slice(0, 120)}`;
  }
  await settle(page, 6000);

  const shot = path.join(
    OUT,
    `route_${routePath.replace(/\W+/g, '_').replace(/^_/, '')}.png`,
  );
  await page.screenshot({ path: shot, fullPage: true }).catch(() => {});

  const ui = await page.evaluate(() => {
    const body = document.body?.innerText || '';
    const text = body.replace(/\s+/g, ' ').trim().slice(0, 4000);
    const nums = [...text.matchAll(/\b(\d{1,5})\b/g)].map((m) => Number(m[1]));
    const hasEmpty =
      /لا توجد|لا يوجد|Empty|No data|No results|فارغ/i.test(text);
    const hasError =
      /permission-denied|FAILED_PRECONDITION|حدث خطأ|تعذر|غير مصرح|Unauthorized|Index/i.test(
        text,
      );
    const hasLoading = /جاري|Loading|…|spinner/i.test(text);
    // rough table/list row heuristic
    const rowish = document.querySelectorAll(
      'flt-semantics[role="listitem"], [role="row"], table tr, .admin-list-row',
    ).length;
    return {
      textSample: text.slice(0, 800),
      numberHits: nums.slice(0, 40),
      hasEmpty,
      hasError,
      hasLoading,
      rowish,
      title: document.title,
    };
  });

  page.off('console', onConsole);
  page.off('pageerror', onPageError);
  page.off('requestfailed', onRequestFailed);

  const blockingConsole = consoleErrors.filter((e) =>
    /permission-denied|FAILED_PRECONDITION|FirebaseError|TypeError|Null check/i.test(
      e,
    ),
  );

  return {
    route: routePath,
    http,
    ms: Date.now() - t0,
    screenshot: shot,
    ...ui,
    consoleErrors: consoleErrors.slice(0, 12),
    blockingConsole: blockingConsole.slice(0, 12),
    pageErrors: pageErrors.slice(0, 8),
    netFails: netFails.slice(0, 12),
  };
}

async function main() {
  if (!EMAIL || !PASSWORD) {
    console.error('ADMIN_QA_EMAIL / ADMIN_QA_PASSWORD required');
    process.exit(2);
  }
  const signIn = await restSignIn(EMAIL, PASSWORD);
  const authUser = buildAuthUser(signIn);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    locale: 'ar',
  });
  const page = await context.newPage();

  await page.goto(`${BASE}/homePage`, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await writeAuth(page, authUser);
  await page.reload({ waitUntil: 'domcontentloaded' });
  await settle(page, 5000);

  const results = [];
  for (const route of ROUTES) {
    process.stderr.write(`crawl ${route}\n`);
    results.push(await probeRoute(page, route));
  }

  const summary = {
    BASE,
    AUTH_UID_REDACTED: true,
    emailRedacted: EMAIL.replace(/(.{2}).+(@.+)/, '$1***$2'),
    crawledAt: new Date().toISOString(),
    routes: results,
    blockingRoutes: results.filter(
      (r) =>
        r.hasError ||
        (r.blockingConsole && r.blockingConsole.length) ||
        String(r.http).startsWith('NAV_FAIL') ||
        (r.http && r.http >= 400),
    ).map((r) => r.route),
  };

  const outFile = path.join(OUT, 'prod_crawl_summary.json');
  fs.writeFileSync(outFile, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify({ outFile, blocking: summary.blockingRoutes, count: results.length }, null, 2));
  await browser.close();
}

main().catch((e) => {
  console.error(scrub(e.stack || e.message));
  process.exit(1);
});
