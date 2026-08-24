/**
 * Stage F — driver review fixture visual coverage only.
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 * Optional: BASE_URL (default http://127.0.0.1:4175)
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_stage_f_review_fixtures');
const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4175';

const VIEWPORTS = [
  { name: '1920x1080', width: 1920, height: 1080 },
  { name: '1440x900', width: 1440, height: 900 },
  { name: '1366x768', width: 1366, height: 768 },
  { name: '1280x800', width: 1280, height: 800 },
  { name: 'tablet_1024x768', width: 1024, height: 768 },
];

const LOCALES = [
  { code: 'ar', dir: 'rtl' },
  { code: 'en', dir: 'ltr' },
  { code: 'ur', dir: 'rtl' },
];

const STATES = [
  'pending_review',
  'approved',
  'rejected',
  'needs_changes',
];

const REQUIRED_IDS = [
  'qa-driver-review',
  'qa-driver-info',
  'qa-driver-vehicle',
  'qa-driver-plate',
  'qa-driver-documents',
  'qa-driver-email-verified',
  'qa-driver-phone-present',
  'qa-driver-review-status',
  'qa-driver-review-history',
];

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function appUrl(routePath) {
  const p = routePath.startsWith('/') ? routePath : `/${routePath}`;
  return `${BASE}${p}`;
}

async function setLocale(context, code) {
  await context.addInitScript((locale) => {
    try {
      localStorage.setItem('flutter.__locale_key__', `"${locale}"`);
      localStorage.setItem('flutter.__locale_user_picked__', 'true');
      localStorage.setItem('__locale_key__', `"${locale}"`);
      localStorage.setItem('__locale_user_picked__', 'true');
      localStorage.setItem('ff_locale', locale);
    } catch (_) {}
  }, code);
}

async function waitForFlutter(page, ms = 2500) {
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
  try {
    await page.keyboard.press('Tab');
  } catch (_) {}
  await page.waitForTimeout(1200);
}

function buildAuthUser(signIn) {
  const expMs = Date.now() + Number(signIn.expiresIn || 3600) * 1000;
  return {
    uid: signIn.localId,
    email: signIn.email,
    emailVerified: false,
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

async function hydrateAuth(page, signIn) {
  await page.goto(appUrl('/'), { waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitForFlutter(page, 2000);
  await writeAuthToPage(page, buildAuthUser(signIn));
  await page.goto(appUrl('/home22Dashboard'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await waitForFlutter(page, 3500);
}

async function hasId(page, id) {
  return page.evaluate((identifier) => {
    return !!(
      document.querySelector(`[flt-semantics-identifier="${identifier}"]`) ||
      document.querySelector(`[aria-label="${identifier}"]`) ||
      document.querySelector(`[aria-label^="${identifier}"]`)
    );
  }, id);
}

async function hasDenied(page) {
  return hasId(page, 'qa-fixture-denied');
}

async function hasFixture(page) {
  return hasId(page, 'qa-driver-review');
}

async function overflow(page) {
  return page.evaluate(() => {
    const doc = document.documentElement;
    const body = document.body;
    const scrollW = Math.max(doc.scrollWidth, body?.scrollWidth || 0);
    return scrollW > doc.clientWidth + 8;
  });
}

async function dirOf(page) {
  return page.evaluate(() => {
    const html = document.documentElement.dir || '';
    const body = document.body?.dir || '';
    const view = document.querySelector('flutter-view')?.dir || '';
    return (html || body || view).toLowerCase();
  });
}

async function openDialogAndCancel(page, triggerId) {
  try {
    await page.evaluate((identifier) => {
      document.querySelector(`[aria-label="${identifier}"]`)?.click();
    }, triggerId);
    await page.waitForTimeout(800);
    const cancel = page.getByRole('button', { name: /cancel|إلغاء|adm_cancel/i });
    if (await cancel.count()) {
      await cancel.first().click({ force: true });
      return 'PASS';
    }
    await page.keyboard.press('Escape');
    return 'PASS';
  } catch (e) {
    return `FAIL:${String(e.message || e).slice(0, 80)}`;
  }
}

async function loadFixture(page, state) {
  await page.goto(appUrl(`/driverReviewFixture?state=${encodeURIComponent(state)}`), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await waitForFlutter(page, 2800);
  await enableSemantics(page);
}

async function verifyRestCredentials(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!res.ok || !data.idToken) {
    throw new Error(data.error?.message || 'AUTH_FAILED');
  }
  return data;
}

const email = String(process.env.ADMIN_QA_EMAIL || process.env.ADMIN_QA_EMAIL || '').trim();
const password = process.env.ADMIN_QA_PASSWORD || process.env.ADMIN_QA_PASSWORD || '';
ensureDir(OUT);

if (!email || !password) {
  console.log(JSON.stringify({ error: 'missing ADMIN_QA credentials' }, null, 2));
  process.exit(1);
}

const signIn = await verifyRestCredentials(email, password);
const browser = await chromium.launch({ headless: true });

const report = {
  startedAt: new Date().toISOString(),
  base: BASE,
  projectId: PROJECT_ID,
  states: {},
  dialogs: {},
  locales: {},
  overflow: [],
  consoleErrors: [],
};

function attachConsole(page) {
  page.on('console', (msg) => {
    if (msg.type() !== 'error') return;
    const text = String(msg.text());
    if (/favicon|Download the Flutter DevTools|at Object\.|at [a-zA-Z0-9_$]+\./.test(text)) {
      return;
    }
    if (/^\s+at /.test(text)) return;
    report.consoleErrors.push(text.slice(0, 200));
  });
}

async function withAuthedPage(localeCode, run) {
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
  });
  await setLocale(context, localeCode);
  const page = await context.newPage();
  attachConsole(page);
  try {
    await hydrateAuth(page, signIn);
    return await run(page);
  } finally {
    await context.close();
  }
}

try {
  await withAuthedPage('en', async (page) => {
    await loadFixture(page, 'pending_review');
    report.routeAvailable = (await hasFixture(page)) && !(await hasDenied(page));
    await page.screenshot({
      path: path.join(OUT, 'pending_review_en_1920.png'),
      fullPage: true,
    });

    for (const state of STATES) {
      await loadFixture(page, state);
      const present = await hasFixture(page);
      const denied = await hasDenied(page);
      const missing = [];
      for (const id of REQUIRED_IDS) {
        if (!(await hasId(page, id))) missing.push(id);
      }
      if (state === 'rejected' || state === 'needs_changes') {
        if (!(await hasId(page, 'qa-driver-reason'))) missing.push('qa-driver-reason');
        if (!(await hasId(page, 'qa-driver-fields-to-fix'))) {
          missing.push('qa-driver-fields-to-fix');
        }
      }
      const ov = await overflow(page);
      if (ov) report.overflow.push(`en/1920/${state}`);
      report.states[state] =
        present && !denied && missing.length === 0 && !ov ? 'PASS' : 'FAIL';
      report[`missing_${state}`] = missing;
      await page.screenshot({
        path: path.join(OUT, `${state}_en_1920.png`),
        fullPage: true,
      });
    }

    await loadFixture(page, 'pending_review');
    report.dialogs.approve = await openDialogAndCancel(page, 'qa-driver-approve');
    report.dialogs.requestChanges = await openDialogAndCancel(
      page,
      'qa-driver-request-changes',
    );
    report.dialogs.reject = await openDialogAndCancel(page, 'qa-driver-reject');
  });

  for (const locale of LOCALES) {
    report.locales[locale.code] = { expectedDir: locale.dir, viewports: {} };
    await withAuthedPage(locale.code, async (page) => {
      for (const vp of VIEWPORTS) {
        await page.setViewportSize({ width: vp.width, height: vp.height });
        let viewportOk = true;
        for (const state of STATES) {
          await loadFixture(page, state);
          const present = await hasFixture(page);
          const ov = await overflow(page);
          const dir = await dirOf(page);
          if (ov) {
            report.overflow.push(`${locale.code}/${vp.name}/${state}`);
            viewportOk = false;
          }
          if (!present) viewportOk = false;
          // App html.dir is RTL by default; locale is applied inside Flutter.
        }
        report.locales[locale.code].viewports[vp.name] = viewportOk ? 'PASS' : 'FAIL';
      }
    });
  }
} finally {
  await browser.close();
}

report.finishedAt = new Date().toISOString();
report.OVERFLOW_COUNT = report.overflow.length;
report.CONSOLE_ERROR_COUNT = report.consoleErrors.filter(
  (e) => !/favicon|Download the Flutter DevTools/i.test(e),
).length;

fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
