/**
 * Admin Final — dashboard cold load + parameterized routes runtime.
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD, BASE_URL, FIXTURES_JSON
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(
  __dirname,
  '../../../qa_master_audit/admin_final_closure',
);
const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4193';
const EMAIL = process.env.ADMIN_QA_EMAIL;
const PASSWORD = process.env.ADMIN_QA_PASSWORD;

fs.mkdirSync(OUT, { recursive: true });

function appUrl(routePath) {
  const p = routePath.startsWith('/') ? routePath : `/${routePath}`;
  return `${BASE}${p}`;
}

async function signIn() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      }),
    },
  );
  const body = await res.json();
  if (!res.ok) throw new Error(JSON.stringify(body));
  return body;
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

async function injectAuth(context, signInBody) {
  const user = buildAuthUser(signInBody);
  const key = `firebase:authUser:${API_KEY}:[DEFAULT]`;
  await context.addInitScript(
    ({ authKey, authUser, projectId }) => {
      try {
        localStorage.setItem(authKey, JSON.stringify(authUser));
        localStorage.setItem('ff_user_uid', authUser.uid);
        localStorage.setItem('__ff_project_id__', projectId);
      } catch (_) {}
    },
    { authKey: key, authUser: user, projectId: PROJECT_ID },
  );
}

async function waitFlutter(page, ms = 3000) {
  try {
    await page.waitForSelector('flutter-view, flt-glass-pane, canvas, body', {
      timeout: 25000,
    });
  } catch (_) {}
  if (ms > 0) await page.waitForTimeout(ms);
}

async function pageText(page) {
  return page.evaluate(() => document.body?.innerText || '');
}

async function hasSpinner(page) {
  return page.evaluate(() => {
    const t = (document.body?.innerText || '').toLowerCase();
    const aria = Array.from(document.querySelectorAll('[role="progressbar"]'));
    return {
      progressbars: aria.length,
      textHasLoading:
        t.includes('loading') ||
        t.includes('جار') ||
        t.includes('تحميل') ||
        t.includes('please wait'),
    };
  });
}

async function main() {
  if (!EMAIL || !PASSWORD) {
    throw new Error('ADMIN_QA_EMAIL / ADMIN_QA_PASSWORD required');
  }
  const fixturesPath = path.join(OUT, 'backend_runtime.json');
  const fixtures = fs.existsSync(fixturesPath)
    ? JSON.parse(fs.readFileSync(fixturesPath, 'utf8'))
    : {};
  const refs = fixtures.PARAM_ROUTE_REFS || {};
  const signInBody = await signIn();

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
  });
  await injectAuth(context, signInBody);
  const page = await context.newPage();

  const report = {
    BASE,
    DASHBOARD_TIMELINE: {},
    DASHBOARD_STATS_LOAD_TIME: null,
    DASHBOARD_STATS_FINAL_STATE: 'UNKNOWN',
    DASHBOARD_INFINITE_SPINNER: true,
    DASHBOARD_READY: 'FAIL',
    PARAM_ROUTES: {},
    MISSING_PARAM_UX: {},
    RESPONSIVE_SPOT: {},
  };

  // Cold dashboard
  const t0 = Date.now();
  await page.goto(appUrl('/'), { waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitFlutter(page, 1500);

  const marks = [0, 3000, 5000, 10000, 15000, 30000];
  for (const m of marks) {
    const elapsed = Date.now() - t0;
    if (elapsed < m) await page.waitForTimeout(m - elapsed);
    const spin = await hasSpinner(page);
    const text = (await pageText(page)).slice(0, 1200);
    report.DASHBOARD_TIMELINE[`T+${m / 1000}s`] = {
      elapsed_ms: Date.now() - t0,
      spin,
      text_sample: text.replace(/\s+/g, ' ').slice(0, 400),
    };
    await page.screenshot({
      path: path.join(OUT, `dashboard_t${m}.png`),
      fullPage: false,
    });
  }

  const last = report.DASHBOARD_TIMELINE['T+30s'];
  const stillSpinning =
    last?.spin?.progressbars > 0 &&
    !(last?.text_sample || '').match(/\d+/);
  // Prefer: numbers visible and no endless-only loading
  const hasNumbers = /\b\d+\b/.test(last?.text_sample || '');
  const errorShown = /timeout|error|تعذر|فشل|retry|إعادة/i.test(
    last?.text_sample || '',
  );
  report.DASHBOARD_INFINITE_SPINNER = stillSpinning && !hasNumbers && !errorShown;
  if (hasNumbers) {
    report.DASHBOARD_STATS_FINAL_STATE = 'DATA';
    report.DASHBOARD_STATS_LOAD_TIME = '<30s';
    report.DASHBOARD_READY = report.DASHBOARD_INFINITE_SPINNER
      ? 'FAIL'
      : 'RUNTIME_PASS';
  } else if (errorShown) {
    report.DASHBOARD_STATS_FINAL_STATE = 'ERROR_OR_RETRY';
    report.DASHBOARD_STATS_LOAD_TIME = '<=30s';
    report.DASHBOARD_READY = report.DASHBOARD_INFINITE_SPINNER
      ? 'FAIL'
      : 'PARTIAL';
  } else if (!report.DASHBOARD_INFINITE_SPINNER) {
    report.DASHBOARD_STATS_FINAL_STATE = 'LOADED_NO_SPIN';
    report.DASHBOARD_READY = 'PARTIAL';
  } else {
    report.DASHBOARD_STATS_FINAL_STATE = 'LOADING_OR_BLANK';
    report.DASHBOARD_READY = 'FAIL';
  }

  // Param routes with fixtures
  const routes = [
    ['edetDolh', refs.edetDolh || '/edetDolh'],
    ['edetReg', refs.edetReg || '/edetReg'],
    ['edetVill', refs.edetVill || '/edetVill'],
    ['adminEdetMkan', refs.adminEdetMkan || '/adminEdetMkan'],
    [
      'driverActivation',
      refs.driverActivation ||
        (fixtures.FIXTURE_IDS?.APPROVE_UID
          ? `/driverActivation?dre=${fixtures.FIXTURE_IDS.APPROVE_UID}`
          : '/driverActivation'),
    ],
  ];

  for (const [name, route] of routes) {
    try {
      await page.goto(appUrl(route), {
        waitUntil: 'domcontentloaded',
        timeout: 45000,
      });
      await waitFlutter(page, 3500);
      const text = (await pageText(page)).replace(/\s+/g, ' ').slice(0, 600);
      const crashed = /null check|exception|error occurred|Something went wrong/i.test(
        text,
      );
      const blank = text.trim().length < 20;
      const notFound = /not found|غير موجود|missing|لا يوجد/i.test(text);
      let result = 'RUNTIME_PASS';
      if (crashed) result = 'FAIL';
      else if (blank) result = 'PARTIAL';
      else if (notFound && !route.includes('=')) result = 'PARTIAL';
      report.PARAM_ROUTES[name] = {
        route,
        result,
        text_sample: text.slice(0, 300),
      };
      await page.screenshot({
        path: path.join(OUT, `param_${name}.png`),
        fullPage: false,
      });
    } catch (e) {
      report.PARAM_ROUTES[name] = {
        route,
        result: 'FAIL',
        error: String(e && e.message),
      };
    }
  }

  // Missing param UX
  for (const [name, route] of [
    ['edetDolh_missing', '/edetDolh?iddolhe=DOES_NOT_EXIST_AF'],
    ['driverActivation_missing', '/driverActivation?dre=DOES_NOT_EXIST_AF'],
  ]) {
    try {
      await page.goto(appUrl(route), {
        waitUntil: 'domcontentloaded',
        timeout: 45000,
      });
      await waitFlutter(page, 3000);
      const text = (await pageText(page)).replace(/\s+/g, ' ').slice(0, 500);
      const crashed = /null check operator|Unhandled|EXCEPTION/i.test(text);
      report.MISSING_PARAM_UX[name] = {
        result: crashed ? 'FAIL' : 'PASS_NO_CRASH',
        text_sample: text.slice(0, 250),
      };
    } catch (e) {
      report.MISSING_PARAM_UX[name] = {
        result: 'FAIL',
        error: String(e && e.message),
      };
    }
  }

  // Responsive spot: dashboard + support at 1024
  await page.setViewportSize({ width: 1024, height: 768 });
  for (const route of ['/', '/adminSuport', '/adminuser']) {
    await page.goto(appUrl(route), {
      waitUntil: 'domcontentloaded',
      timeout: 45000,
    });
    await waitFlutter(page, 2500);
    const name = route === '/' ? 'dashboard' : route.replace('/', '');
    await page.screenshot({
      path: path.join(OUT, `responsive_1024_${name}.png`),
      fullPage: false,
    });
    report.RESPONSIVE_SPOT[name] = 'CAPTURED_1024';
  }

  fs.writeFileSync(
    path.join(OUT, 'ui_runtime.json'),
    JSON.stringify(report, null, 2),
  );
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
}

main().catch((e) => {
  console.error('FATAL', e);
  process.exit(1);
});
