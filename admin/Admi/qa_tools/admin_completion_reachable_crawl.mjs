/**
 * Admin completion — crawl only reachable (non-legacy/orphan) routes.
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD, BASE_URL
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(
  '/Users/ventura/ara-ban/qa_master_audit/admin_deep_completion',
  'runtime_crawl',
);
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4193';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const reachable = JSON.parse(
  fs.readFileSync(
    '/Users/ventura/ara-ban/qa_master_audit/admin_deep_completion/reachable_routes.json',
    'utf8',
  ),
).reachable;

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}
function appUrl(p) {
  return `${BASE}${p.startsWith('/') ? p : `/${p}`}`;
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

async function settle(page, ms) {
  await page.waitForTimeout(ms);
  await page.evaluate(() => {
    window.__flutter_web_set_semantics_enabled?.(true);
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.waitForTimeout(400);
}

async function probe(page) {
  return page.evaluate(() => {
    const path = location.pathname + location.search + location.hash;
    const sample = (document.body?.innerText || '').replace(/\s+/g, ' ').slice(0, 1200);
    const onLogin =
      path === '/' || path === '' || /\/homePage(?:\/|$|\?)/i.test(path);
    const unauthorized =
      /not authorized for the admin panel|غير مصرح/i.test(sample);
    const blank = sample.trim().length < 8;
    const errorish =
      /Exception:|Error:|Null check operator|was thrown/i.test(sample);
    const loading =
      /جاري تحميل|Loading the control|Loading dashboard|Loading…|Loading\.\.\./i.test(
        sample,
      );
    const hasEmpty =
      /لا يوجد|لا توجد|No data|No results|empty/i.test(sample);
    const hasCount = /العدد|Count:|\d+\s*(من|of)/i.test(sample);
    return {
      path,
      sample,
      onLogin,
      unauthorized,
      blank,
      errorish,
      loading,
      hasEmpty,
      hasCount,
      textLen: sample.trim().length,
    };
  });
}

function classify(route, state) {
  if (state.unauthorized) return 'FAIL';
  if (state.onLogin && route.path !== '/homePage') {
    return route.needsParam ? 'PARTIAL' : 'FAIL';
  }
  if (state.errorish) return 'FAIL';
  if (
    route.needsParam &&
    /تعذر تحميل|Unable to load|missing|رابط ناقص|link_off|تفعيل المندوب|تعديل /i.test(
      state.sample,
    )
  ) {
    return 'PARTIAL';
  }
  if (state.blank) return 'FAIL';
  if (state.loading) return 'PARTIAL';
  if (route.needsParam && /تعذر تحميل|Unable to load|missing/i.test(state.sample)) {
    return 'PARTIAL';
  }
  return 'RUNTIME_PASS';
}

async function main() {
  ensureDir(OUT);
  const email = process.env.ADMIN_QA_EMAIL;
  const password = process.env.ADMIN_QA_PASSWORD;
  if (!email || !password) throw new Error('ADMIN_QA credentials required');

  console.log('[ADMIN COMPLETION STEP 2] Authenticated reachable crawl');
  console.log('STATUS: RUNNING');
  console.log(`ACTION: Crawl ${reachable.length} reachable routes`);

  const signIn = await restSignIn(email, password);
  const authUser = buildAuthUser(signIn);
  console.log('AUTH_OK', String(signIn.localId).slice(0, 8));

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 900 },
  });
  const pageErrors = [];
  page.on('pageerror', (e) => pageErrors.push(String(e).slice(0, 180)));

  await page.goto(appUrl('/homePage'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await settle(page, 2500);
  await writeAuth(page, authUser);
  await page.goto(appUrl('/home22Dashboard'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await settle(page, 8000);
  const boot = await probe(page);
  fs.writeFileSync(path.join(OUT, 'boot.json'), JSON.stringify(boot, null, 2));
  await page.screenshot({ path: path.join(OUT, 'dashboard.png') });

  const results = [];
  let i = 0;
  for (const route of reachable) {
    i += 1;
    pageErrors.length = 0;
    const started = Date.now();
    console.log(`PROGRESS ${i}/${reachable.length} ${route.path}`);
    try {
      await page.goto(appUrl(route.path), {
        waitUntil: 'domcontentloaded',
        timeout: 60000,
      });
      // longer settle for data-heavy pages
      const wait =
        route.path === '/home22Dashboard' ||
        route.path === '/drever' ||
        route.path === '/adminuser' ||
        route.path.includes('Finance') ||
        route.path.includes('finance') ||
        route.path.includes('Wallet')
          ? 10000
          : 4500;
      await settle(page, wait);
      const state = await probe(page);
      const result = classify(route, state);
      results.push({
        path: route.path,
        routeName: route.routeName,
        needsParam: !!route.needsParam,
        result,
        elapsed_ms: Date.now() - started,
        ...state,
        pageErrors: [...pageErrors],
      });
      if (
        result !== 'RUNTIME_PASS' ||
        [
          '/home22Dashboard',
          '/adminuser',
          '/drever',
          '/adminALLhgZ',
          '/adminFinanceHub',
          '/adminDriverWallets',
          '/adminFinancialPeriods',
          '/adminSuport',
        ].includes(route.path)
      ) {
        await page.screenshot({
          path: path.join(OUT, `${route.routeName || i}.png`),
        });
      }
    } catch (e) {
      results.push({
        path: route.path,
        routeName: route.routeName,
        result: 'FAIL',
        error: String(e).slice(0, 300),
        elapsed_ms: Date.now() - started,
      });
    }
  }

  // Responsive spot-check critical routes
  const responsive = [];
  for (const vp of [
    { w: 1280, h: 800 },
    { w: 1024, h: 768 },
  ]) {
    await page.setViewportSize({ width: vp.w, height: vp.h });
    for (const p of ['/home22Dashboard', '/adminuser', '/drever', '/adminFinanceHub']) {
      await page.goto(appUrl(p), { waitUntil: 'domcontentloaded', timeout: 60000 });
      await settle(page, 4000);
      const st = await probe(page);
      responsive.push({
        viewport: `${vp.w}x${vp.h}`,
        path: p,
        result: classify({ path: p, needsParam: false }, st),
        textLen: st.textLen,
      });
      await page.screenshot({
        path: path.join(OUT, `resp_${vp.w}_${p.replace(/\//g, '_')}.png`),
      });
    }
  }

  const pass = results.filter((r) => r.result === 'RUNTIME_PASS').length;
  const fail = results.filter((r) => r.result === 'FAIL').length;
  const partial = results.filter((r) => r.result === 'PARTIAL').length;
  const summary = {
    REACHABLE: reachable.length,
    RUNTIME_PASS: pass,
    FAIL: fail,
    PARTIAL: partial,
    COVERAGE_PCT: Math.round((pass / reachable.length) * 1000) / 10,
    COVERAGE_PASS_PARTIAL_PCT:
      Math.round(((pass + partial) / reachable.length) * 1000) / 10,
    boot,
    responsive,
    results,
  };
  fs.writeFileSync(path.join(OUT, 'summary.json'), JSON.stringify(summary, null, 2));
  console.log(
    'RESULT:',
    JSON.stringify({
      REACHABLE: summary.REACHABLE,
      RUNTIME_PASS: pass,
      FAIL: fail,
      PARTIAL: partial,
      COVERAGE_PCT: summary.COVERAGE_PCT,
    }),
  );
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
