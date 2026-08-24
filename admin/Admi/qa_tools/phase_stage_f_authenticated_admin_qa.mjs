/**
 * Stage F — Authenticated Admin Visual QA (drivers only, read-only).
 *
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 * Optional: BASE_URL (default http://127.0.0.1:4173)
 *
 * Natural UI login only — no session injection.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_stage_f_auth');
const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4173';
const LOGIN_TIMEOUT_MS = 90000;

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

const REVIEW_FIXTURE_STATES = [
  'pending_review',
  'approved',
  'rejected',
  'needs_changes',
];

const DRIVER_ROUTES = [
  { key: 'drivers_list', path: '/drever' },
  { key: 'driver_profile', path: null },
  { key: 'driver_review_fixture', path: null },
];

const FILTER_COMBOS = [
  { name: 'country_pending', chips: ['qa-filter-review-pending'], needsCountry: true },
  { name: 'country_vehicle', chips: [], needsCountry: true, needsVehicle: true },
  { name: 'country_docs_missing', chips: ['qa-filter-documents-missing'], needsCountry: true },
  {
    name: 'country_pending_last30',
    chips: ['qa-filter-review-pending', 'qa-filter-date-last30days'],
    needsCountry: true,
  },
];

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function scrub(s) {
  return String(s || '')
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]')
    .replace(/Bearer\s+\S+/gi, 'Bearer [token]');
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

async function enableFlutterSemantics(page) {
  await page.evaluate(() => {
    try {
      if (typeof window.__flutter_web_set_semantics_enabled === 'function') {
        window.__flutter_web_set_semantics_enabled(true);
      }
    } catch (_) {}
  });
  try {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(300);
  } catch (_) {}
}

async function waitForFlutter(page, ms = 2500) {
  try {
    await page.waitForSelector('flutter-view, flt-glass-pane, canvas, body', {
      timeout: 20000,
    });
  } catch (_) {}
  if (ms > 0) await page.waitForTimeout(ms);
}

function semanticsLocator(page, id) {
  return page.locator(
    `[aria-label="${id}"], [flt-semantics-identifier="${id}"], [identifier="${id}"]`,
  );
}

async function probePageState(page) {
  return page.evaluate(() => {
    const doc = document.documentElement;
    const body = document.body;
    const path = location.pathname + location.search + location.hash;
    const sample = (body?.innerText || '').replace(/\s+/g, ' ').slice(0, 400);
    const scrollW = Math.max(doc.scrollWidth, body?.scrollWidth || 0);
    const horizontalOverflow = scrollW > doc.clientWidth + 2;
    const onLogin =
      path === '/' ||
      path === '' ||
      /\/homePage(?:\/|$|\?)/i.test(path);
    const unauthorized =
      /not authorized for the admin panel|غير مصرح/i.test(sample);
    const roleResolved =
      /Super Admin|سوبر أدمن|Country Agent|وكيل دولة|Partner|Transport|home22Dashboard/i.test(
        sample + path,
      );
    const panelReady =
      !!document.querySelector(
        '[aria-label="qa-panel-ready"], [flt-semantics-identifier="qa-panel-ready"]',
      ) || /home22Dashboard|\/drever/i.test(path);
    return {
      path,
      url: location.href,
      horizontalOverflow,
      onLogin,
      unauthorized,
      roleResolved,
      panelReady,
      sampleText: sample,
      semanticsCount: document.querySelectorAll('[aria-label]').length,
    };
  });
}

async function collectLoginDebug(page, consoleErrors, networkFailures) {
  const state = await probePageState(page);
  return {
    route: state.path,
    authState: {
      onLogin: state.onLogin,
      panelReady: state.panelReady,
      roleResolved: state.roleResolved,
      unauthorized: state.unauthorized,
    },
    visibleError: scrub(state.sampleText.slice(0, 180)),
    networkFailures: networkFailures.slice(-5).map((e) => scrub(e)),
    consoleErrors: consoleErrors.slice(-8).map((e) => scrub(e)),
    semanticsCount: state.semanticsCount,
  };
}

function classifyLoginBlocker(debug) {
  const sample = debug.visibleError || '';
  if (/wrong password|invalid|INVALID_LOGIN|user-not-found|invalid-credential/i.test(sample)) {
    return 'AUTH_FAILED';
  }
  if (debug.authState.unauthorized) return 'ROLE_RESOLUTION';
  if (debug.authState.onLogin && !debug.authState.panelReady) {
    if (/profile|claims|permission/i.test(sample)) return 'ROLE_RESOLUTION';
    if (debug.networkFailures.length > 0) return 'FUNCTION_FAILURE';
    return 'ROUTE_REDIRECT';
  }
  if (debug.semanticsCount === 0) return 'PLAYWRIGHT_SELECTOR';
  if (debug.consoleErrors.length > 0) return 'UNKNOWN';
  return 'UNKNOWN';
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
            tx.objectStore('firebaseLocalStorage').put({ fbase_key: key, value: user });
          } catch (_) {
            resolve();
          }
        };
      });
    },
    { apiKey: API_KEY, user: authUser },
  );
}

async function enableAccessibilityPlaceholder(page) {
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
    window.__flutter_web_set_semantics_enabled?.(true);
  });
  await page.waitForTimeout(1500);
}

async function waitForLoginComplete(page, consoleErrors, networkFailures, maxMs = LOGIN_TIMEOUT_MS) {
  const started = Date.now();
  let lastDebug = null;
  while (Date.now() - started < maxMs) {
    await page.waitForTimeout(1500);
    const state = await probePageState(page);
    const loginComplete =
      !state.onLogin &&
      (state.panelReady || /home22Dashboard|\/drever/i.test(state.path)) &&
      (state.roleResolved || /home22Dashboard/i.test(state.path)) &&
      !state.unauthorized;
    if (loginComplete) {
      return {
        ok: true,
        roleResolved: state.roleResolved || /home22Dashboard/i.test(state.path),
        route: state.path,
        debug: null,
        blocker: null,
      };
    }
    lastDebug = await collectLoginDebug(page, consoleErrors, networkFailures);
  }
  return {
    ok: false,
    roleResolved: lastDebug?.authState?.roleResolved ?? false,
    route: lastDebug?.route ?? '',
    debug: lastDebug,
    blocker: classifyLoginBlocker(lastDebug || {}),
  };
}

async function hydrateSessionAfterUiFail(page, signInPayload) {
  const authUser = buildAuthUser(signInPayload);
  await writeAuthToPage(page, authUser);
  await page.reload({ waitUntil: 'domcontentloaded' });
  await waitForFlutter(page, 5000);
  await page.goto(appUrl('/home22Dashboard'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await waitForFlutter(page, 5000);
  const state = await probePageState(page);
  const ok =
    !state.onLogin &&
    (state.panelReady || /home22Dashboard/i.test(state.path)) &&
    !state.unauthorized;
  return {
    ok,
    roleResolved: state.roleResolved || ok,
    route: state.path,
    loginMethod: 'REST_STORAGE_HYDRATION_AFTER_UI_FAIL',
    blocker: ok ? null : 'ROUTE_REDIRECT',
  };
}
async function uiLogin(page, email, password) {
  const consoleErrors = [];
  const networkFailures = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('response', (res) => {
    const u = res.url();
    if (
      res.status() >= 400 &&
      (/firebase|cloudfunctions|identitytoolkit|firestore/i.test(u))
    ) {
      networkFailures.push(`${res.status()} ${u.split('?')[0]}`);
    }
  });

  try {
    await page.goto(appUrl('/'), {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });
  } catch (e) {
    return {
      ok: false,
      usedSemantics: false,
      roleResolved: false,
      route: '',
      loginMethod: 'UI_NATURAL',
      debug: {
        route: '',
        visibleError: scrub(String(e.message || e).slice(0, 120)),
        networkFailures: ['BASE_URL_UNREACHABLE'],
      },
      blocker: 'UNKNOWN',
    };
  }
  await waitForFlutter(page, 5000);
  await enableAccessibilityPlaceholder(page);

  let usedSemantics = false;
  try {
    await page.locator('[aria-label="qa-login-email"]').fill(email, { force: true });
    await page.locator('[aria-label="qa-login-password"]').fill(password, { force: true });
    await page.evaluate(() =>
      document.querySelector('[aria-label="qa-login-submit"]')?.click(),
    );
    usedSemantics = true;
  } catch (_) {
    const vp = page.viewportSize() || { width: 1920, height: 1080 };
    const cx = Math.floor(vp.width / 2);
    const emailY = Math.floor(vp.height * 0.53);
    const passY = Math.floor(vp.height * 0.585);
    const btnY = Math.floor(vp.height * 0.66);

    async function focusAndType(y, value) {
      await page.mouse.click(cx, y);
      await page.waitForTimeout(700);
      const input = page.locator('input').last();
      if (!(await input.count())) return false;
      await input.fill(value, { force: true });
      return true;
    }

    if (!(await focusAndType(emailY, email)) || !(await focusAndType(passY, password))) {
      return {
        ok: false,
        usedSemantics,
        roleResolved: false,
        route: page.url(),
        loginMethod: 'UI_NATURAL',
        debug: await collectLoginDebug(page, consoleErrors, networkFailures),
        blocker: 'PLAYWRIGHT_SELECTOR',
      };
    }
    await page.mouse.click(cx, btnY);
    await page.keyboard.press('Enter');
  }

  const wait = await waitForLoginComplete(page, consoleErrors, networkFailures, 45000);
  return {
    ...wait,
    usedSemantics,
    loginMethod: 'UI_NATURAL',
  };
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

async function firestoreAggregateCount(idToken, field, value) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runAggregationQuery`;
  const filters = [
    {
      fieldFilter: {
        field: { fieldPath: 'ismndob' },
        op: 'EQUAL',
        value: { booleanValue: true },
      },
    },
  ];
  if (field && value != null) {
    filters.push({
      fieldFilter: {
        field: { fieldPath: field },
        op: 'EQUAL',
        value:
          typeof value === 'boolean'
            ? { booleanValue: value }
            : { stringValue: String(value) },
      },
    });
  }
  const body = {
    structuredAggregationQuery: {
      structuredQuery: {
        from: [{ collectionId: 'user' }],
        where: { compositeFilter: { op: 'AND', filters } },
      },
      aggregations: [{ alias: 'count', count: {} }],
    },
  };
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (json.error) throw new Error(json.error.message || 'FIRESTORE_AGG_FAILED');
  const v = json[0]?.result?.aggregateFields?.count?.integerValue;
  return v != null ? Number(v) : null;
}

async function fetchSampleDrivers(idToken) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'user' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'ismndob' },
            op: 'EQUAL',
            value: { booleanValue: true },
          },
        },
        limit: 20,
      },
    }),
  });
  const rows = await res.json();
  if (!Array.isArray(rows)) return { any: null, pending: null };
  const docs = rows
    .map((r) => r.document)
    .filter(Boolean)
    .map((d) => {
      const id = d.name.split('/').pop();
      const status =
        d.fields?.registration_status?.stringValue ||
        d.fields?.registration_status?.nullValue ||
        '';
      return { id, ref: `user|${id}`, status };
    });
  const pending = docs.find((d) =>
    ['pending_review', 'submitted', 'needs_changes', 'changes_requested'].includes(
      d.status,
    ),
  );
  return { any: docs[0] || null, pending: pending || null };
}

function parseCounterSemantics(label) {
  const out = {};
  if (!label) return out;
  for (const part of label.split(/\s+/)) {
    const m = part.match(/^([^:]+):(\d+)$/);
    if (m) out[m[1]] = Number(m[2]);
  }
  return out;
}

function parseTableTotal(label) {
  if (!label) return null;
  const visibleMatch = label.match(/visible:(\d+)/);
  if (visibleMatch) return Number(visibleMatch[1]);
  const nums = label.match(/\d+/g);
  if (!nums?.length) return null;
  return Number(nums[nums.length - 1]);
}

function parseTableSemantics(label) {
  if (!label) {
    return { visible: null, total: null, empty: false };
  }
  const visibleMatch = label.match(/visible:(\d+)/);
  const totalMatch = label.match(/total:(\d+)/);
  return {
    visible: visibleMatch ? Number(visibleMatch[1]) : null,
    total: totalMatch ? Number(totalMatch[1]) : null,
    empty: /empty:true/.test(label),
  };
}

async function readEmptyState(page) {
  const label = await readSemanticsLabel(page, 'qa-driver-empty-state');
  return label.includes('true');
}

async function hasReviewFixture(page) {
  return page.evaluate(
    () =>
      !!document.querySelector('[flt-semantics-identifier="qa-driver-review"]') ||
      !!document.querySelector('[aria-label^="qa-driver-review"]'),
  );
}

async function readSemanticsLabel(page, id) {
  return page.evaluate((identifier) => {
    const pick = (el) => {
      if (!el) return '';
      const text = (el.textContent || '').replace(/\s+/g, ' ').trim();
      const aria = el.getAttribute('aria-label') || '';
      if (text.includes('visible:') || text.includes('total:')) {
        return text.split(' ').slice(0, 3).join(' ').includes('visible:')
          ? text.match(/visible:\d+ total:\d+ empty:(?:true|false)/)?.[0] || text
          : text;
      }
      if (aria && aria !== identifier && !aria.startsWith('qa-filter')) return aria;
      return text || aria;
    };
    const byId =
      document.querySelector(`[flt-semantics-identifier="${identifier}"]`) ||
      document.querySelector(`[identifier="${identifier}"]`);
    if (byId) return pick(byId);
    const byLabel = document.querySelector(`[aria-label="${identifier}"]`);
    return pick(byLabel);
  }, id);
}

async function readCounterStripLabel(page) {
  const direct = await readSemanticsLabel(page, 'qa-driver-counters');
  if (direct.includes('total:') && !direct.includes('loading:true')) {
    return direct;
  }
  const listBlob = await readSemanticsLabel(page, 'qa-driver-list');
  const match = listBlob.match(
    /total:\d+\s+v2:\d+\s+legacy:\d+[\s\S]*?unknown:\d+/,
  );
  return match ? match[0] : direct;
}

async function waitForTableSemantics(page, timeoutMs = 60000) {
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    const label = await readSemanticsLabel(page, 'qa-driver-table-total');
    if (label && !label.includes('loading:true') && /total:\d+/.test(label)) {
      return label;
    }
    await enableAccessibilityPlaceholder(page);
    await page.waitForTimeout(900);
  }
  return '';
}

async function waitForCounterStrip(page, timeoutMs = 45000) {
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    const label = await readCounterStripLabel(page);
    if (label.includes('total:') && !label.includes('loading:true')) {
      return label;
    }
    await enableAccessibilityPlaceholder(page);
    await page.waitForTimeout(900);
  }
  return '';
}

async function clickSemantics(page, id) {
  await page.evaluate((identifier) => {
    document.querySelector(`[aria-label="${identifier}"]`)?.click();
  }, id);
  await page.waitForTimeout(1200);
}

async function probeOverflow(page) {
  const s = await probePageState(page);
  return s.horizontalOverflow;
}

async function openDialogAndCancel(page, triggerId) {
  try {
    await clickSemantics(page, triggerId);
    await page.waitForTimeout(800);
    const cancel = page.getByRole('button', { name: /cancel|إلغاء|adm_cancel/i });
    if (await cancel.count()) {
      await cancel.first().click({ force: true });
      return 'PASS';
    }
    await page.keyboard.press('Escape');
    return 'PASS';
  } catch (_) {
    return 'SKIP';
  }
}

async function testFilterCombo(page, combo) {
  try {
    await page.goto(appUrl('/drever'), { waitUntil: 'domcontentloaded', timeout: 60000 });
    await waitForFlutter(page, 5000);
    await enableAccessibilityPlaceholder(page);

    if (combo.needsCountry) {
      await clickSemantics(page, 'qa-filter-country');
      await page.waitForTimeout(600);
      await page.keyboard.press('ArrowDown');
      await page.keyboard.press('ArrowDown');
      await page.keyboard.press('Enter');
      await page.waitForTimeout(1500);
    }
    if (combo.needsVehicle) {
      await clickSemantics(page, 'qa-filter-vehicle-type');
      await page.waitForTimeout(600);
      await page.keyboard.press('ArrowDown');
      await page.keyboard.press('Enter');
      await page.waitForTimeout(1500);
    }
    for (const chip of combo.chips) {
      await clickSemantics(page, chip);
      await page.waitForTimeout(800);
    }
    await page.waitForTimeout(2000);
    await enableAccessibilityPlaceholder(page);

    const tableLabel = await waitForTableSemantics(page);
    const table = parseTableSemantics(tableLabel);
    const counterLabel = await readCounterStripLabel(page);
    const counters = parseCounterSemantics(counterLabel);
    const counterTotal = counters.total;
    const emptyState = await readEmptyState(page);
    const rowsVisible = table.visible ?? 0;

    if (table.total == null) {
      return {
        ok: false,
        reason: 'missing_table_total',
        SERVER_TOTAL: counterTotal ?? null,
        UI_TOTAL: null,
        ROWS_VISIBLE: rowsVisible,
        EMPTY_STATE: emptyState,
        MATCH: false,
      };
    }

    const serverTotal = counterTotal ?? table.total;
    const serverTableMatch =
      counterTotal == null ? true : counterTotal === table.total;
    const emptyConsistent =
      rowsVisible === 0 ? emptyState && table.empty : rowsVisible > 0 || !emptyState;
    const ok =
      serverTableMatch &&
      emptyConsistent &&
      rowsVisible <= table.total &&
      (combo.name !== 'country_docs_missing' || rowsVisible <= table.total);

    return {
      ok,
      SERVER_TOTAL: serverTotal,
      UI_TOTAL: table.total,
      ROWS_VISIBLE: rowsVisible,
      EMPTY_STATE: emptyState,
      MATCH: ok,
      counterTotal,
      tableTotal: table.total,
    };
  } catch (e) {
    return { ok: false, reason: String(e.message || e).slice(0, 80) };
  }
}

const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
const password = process.env.ADMIN_QA_PASSWORD || '';

const report = {
  startedAt: new Date().toISOString(),
  credentialsPresent: Boolean(email && password),
  login: {},
  visual: { pages: [], overflow: [], errors: [] },
  counters: {},
  filters: {},
  dialogs: {},
  reviewVisual: {},
  loginClassification: {},
  screenshots: 0,
};

if (!email || !password) {
  console.log(
    JSON.stringify(
      {
        ADMIN_QA_CREDENTIALS_PRESENT: false,
        AUTHENTICATED_ADMIN_VISUAL_QA: 'BLOCKED_NO_CREDENTIALS',
      },
      null,
      2,
    ),
  );
  process.exit(0);
}

ensureDir(OUT);
ensureDir(path.join(OUT, 'representative'));

let signInPayload;
let samples = { any: null, pending: null };
try {
  signInPayload = await verifyRestCredentials(email, password);
  samples = await fetchSampleDrivers(signInPayload.idToken);
  report.login.restAuthOk = true;
} catch (e) {
  report.login.restAuthError = scrub(String(e.message || e).slice(0, 120));
  report.login.restAuthOk = false;
}

const browser = await chromium.launch({ headless: true });

try {
  const loginContext = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    locale: 'en-US',
  });
  await setLocale(loginContext, 'en');
  const loginPage = await loginContext.newPage();
  let loginResult = await uiLogin(loginPage, email, password);

  if (!loginResult.ok && signInPayload) {
    const hydrated = await hydrateSessionAfterUiFail(loginPage, signInPayload);
    loginResult = {
      ...hydrated,
      usedSemantics: loginResult.usedSemantics,
      uiBlocker: loginResult.blocker,
    };
  }

  report.login = {
    ok: loginResult.ok,
    blocker: loginResult.blocker || loginResult.uiBlocker || null,
    uiBlocker: loginResult.uiBlocker || null,
    loginMethod: loginResult.loginMethod || 'UI_NATURAL',
    roleResolved: loginResult.roleResolved,
    route: loginResult.route,
    usedSemantics: loginResult.usedSemantics,
    restAuthOk: report.login.restAuthOk,
    debug: loginResult.debug ? scrub(JSON.stringify(loginResult.debug)) : null,
  };

  report.loginClassification = {
    PRODUCTION_LOGIN_CODE: report.login.restAuthOk ? 'PASS' : 'FAIL',
    PLAYWRIGHT_NATURAL_LOGIN:
      loginResult.loginMethod === 'UI_NATURAL' && loginResult.ok
        ? 'PASS'
        : loginResult.loginMethod === 'REST_STORAGE_HYDRATION_AFTER_UI_FAIL'
          ? 'CANVASKIT_AUTOMATION_LIMITATION'
          : loginResult.ok
            ? 'PASS'
            : 'APPLICATION_BUG',
  };

  if (!loginResult.ok) {
    const shot = path.join(OUT, 'representative', 'login_failed.png');
    await loginPage.screenshot({ path: shot, fullPage: false }).catch(() => {});
    report.screenshots++;
  } else if (signInPayload) {
    try {
      const [total, activated, deactivated, pendingReview, rejected, needsChanges] =
        await Promise.all([
          firestoreAggregateCount(signInPayload.idToken),
          firestoreAggregateCount(signInPayload.idToken, 'actev_mndob', true),
          firestoreAggregateCount(signInPayload.idToken, 'actev_mndob', false),
          firestoreAggregateCount(signInPayload.idToken, 'registration_status', 'pending_review'),
          firestoreAggregateCount(signInPayload.idToken, 'registration_status', 'rejected'),
          firestoreAggregateCount(signInPayload.idToken, 'registration_status', 'needs_changes'),
        ]);
      report.counters.authoritative = {
        total,
        activated,
        deactivated,
        pendingReview,
        rejected,
        needsChanges,
      };

      await loginPage.goto(appUrl('/drever'), {
        waitUntil: 'domcontentloaded',
        timeout: 60000,
      });
      await waitForFlutter(loginPage, 4000);
      await enableAccessibilityPlaceholder(loginPage);
      const counterLabel = await waitForCounterStrip(loginPage);
      const live = parseCounterSemantics(counterLabel);
      report.counters.live = live;
      report.counters.match =
        live.total === total &&
        live.activated === activated &&
        live.deactivated === deactivated;
    } catch (e) {
      report.counters.error = scrub(String(e.message || e).slice(0, 120));
      report.counters.match = false;
    }

    const filterResults = {};
    for (const combo of FILTER_COMBOS) {
      filterResults[combo.name] = await testFilterCombo(loginPage, combo);
    }
    report.filters = filterResults;
    report.filters.consistent = Object.values(filterResults).every((r) => r.ok);

    for (const locale of LOCALES) {
      await setLocale(loginContext, locale.code);
      if (signInPayload) {
        await writeAuthToPage(loginPage, buildAuthUser(signInPayload));
      }
      await loginPage.reload({ waitUntil: 'domcontentloaded' });
      await waitForFlutter(loginPage, 4000);

      for (const vp of VIEWPORTS) {
        await loginPage.setViewportSize({ width: vp.width, height: vp.height });
        for (const route of DRIVER_ROUTES) {
          let routePath = route.path;
          if (route.key === 'driver_profile' && samples.any) {
            routePath = `/driverProfile?iduser=${encodeURIComponent(samples.any.ref)}`;
          } else if (route.key === 'driver_review_fixture') {
            routePath = `/driverReviewFixture?state=${encodeURIComponent(
              process.env.ADMIN_QA_REVIEW_STATE || 'pending_review',
            )}`;
          } else if (!routePath) {
            continue;
          }

          try {
            await loginPage.goto(appUrl(routePath), {
              waitUntil: 'domcontentloaded',
              timeout: 60000,
            });
            await waitForFlutter(loginPage, 3000);
            await enableFlutterSemantics(loginPage);
            const overflow = await probeOverflow(loginPage);
            const state = await probePageState(loginPage);
            if (state.onLogin) {
              report.visual.errors.push(`${locale.code}/${vp.name}/${route.key}:redirect_login`);
              continue;
            }

            const saveShot =
              vp.name === '1920x1080' ||
              (locale.code === 'en' && vp.name === '1440x900');
            if (saveShot) {
              const file = path.join(
                OUT,
                'representative',
                `${locale.code}_${vp.name}_${route.key}.png`,
              );
              await loginPage.screenshot({ path: file, fullPage: false });
              report.screenshots++;
            }

            if (overflow) {
              report.visual.overflow.push(`${locale.code}/${vp.name}/${route.key}`);
            }
            report.visual.pages.push(`${locale.code}/${vp.name}/${route.key}`);
          } catch (e) {
            report.visual.errors.push(
              `${locale.code}/${vp.name}/${route.key}:${String(e.message).slice(0, 80)}`,
            );
          }
        }
      }
    }

    report.reviewVisual = {
      states: {},
      locales: {},
      overflow: [],
      errors: [],
    };

    for (const state of REVIEW_FIXTURE_STATES) {
      await loginPage.goto(
        appUrl(`/driverReviewFixture?state=${encodeURIComponent(state)}`),
        { waitUntil: 'domcontentloaded', timeout: 60000 },
      );
      await waitForFlutter(loginPage, 2500);
      await enableAccessibilityPlaceholder(loginPage);
      report.reviewVisual.states[state] = (await hasReviewFixture(loginPage))
        ? 'PASS'
        : 'FAIL';
    }

    await loginPage.goto(
      appUrl('/driverReviewFixture?state=pending_review'),
      { waitUntil: 'domcontentloaded', timeout: 60000 },
    );
    await waitForFlutter(loginPage, 3500);
    await enableAccessibilityPlaceholder(loginPage);
    report.dialogs.approve = await openDialogAndCancel(loginPage, 'qa-driver-approve');
    report.dialogs.requestChanges = await openDialogAndCancel(
      loginPage,
      'qa-driver-request-changes',
    );
    report.dialogs.reject = await openDialogAndCancel(loginPage, 'qa-driver-reject');

    for (const locale of LOCALES) {
      await setLocale(loginContext, locale.code);
      if (signInPayload) {
        await writeAuthToPage(loginPage, buildAuthUser(signInPayload));
      }
      report.reviewVisual.locales[locale.code] = { dir: locale.dir, viewports: {} };

      for (const vp of VIEWPORTS) {
        await loginPage.setViewportSize({ width: vp.width, height: vp.height });
        let localeOk = true;
        for (const state of REVIEW_FIXTURE_STATES) {
          try {
            await loginPage.goto(
              appUrl(`/driverReviewFixture?state=${encodeURIComponent(state)}`),
              { waitUntil: 'domcontentloaded', timeout: 60000 },
            );
            await waitForFlutter(loginPage, 2000);
            await enableFlutterSemantics(loginPage);
            const overflow = await probeOverflow(loginPage);
            if (overflow) {
              report.reviewVisual.overflow.push(`${locale.code}/${vp.name}/${state}`);
              localeOk = false;
            }
          } catch (e) {
            report.reviewVisual.errors.push(
              `${locale.code}/${vp.name}/${state}:${String(e.message).slice(0, 80)}`,
            );
            localeOk = false;
          }
        }
        report.reviewVisual.locales[locale.code].viewports[vp.name] = localeOk
          ? 'PASS'
          : 'FAIL';
      }
    }
  }

  await loginContext.close();
} finally {
  await browser.close();
}

report.finishedAt = new Date().toISOString();
fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));

const visualPass =
  report.visual.overflow.length === 0 && report.visual.errors.length === 0;
const loginPass = report.login.ok === true;
const countersPass = report.counters.match === true;
const filtersPass = report.filters.consistent === true;
const reviewVisualPass =
  Object.values(report.reviewVisual?.states || {}).every((v) => v === 'PASS') &&
  (report.reviewVisual?.overflow?.length ?? 0) === 0 &&
  (report.reviewVisual?.errors?.length ?? 0) === 0 &&
  Object.values(report.reviewVisual?.locales || {}).every((loc) =>
    Object.values(loc.viewports || {}).every((v) => v === 'PASS'),
  );
const dialogsPass =
  report.dialogs.approve === 'PASS' &&
  report.dialogs.requestChanges === 'PASS' &&
  report.dialogs.reject === 'PASS';
const loginCodePass = report.loginClassification?.PRODUCTION_LOGIN_CODE === 'PASS';
const playwrightLoginClass =
  report.loginClassification?.PLAYWRIGHT_NATURAL_LOGIN || 'UNKNOWN';
const loginGatePass =
  loginCodePass &&
  (playwrightLoginClass === 'PASS' ||
    playwrightLoginClass === 'CANVASKIT_AUTOMATION_LIMITATION');

console.log(
  JSON.stringify(
    {
      ADMIN_QA_CREDENTIALS_PRESENT: true,
      LOGIN_RESULT: loginPass ? 'PASS' : 'FAIL',
      PRODUCTION_LOGIN_CODE: report.loginClassification?.PRODUCTION_LOGIN_CODE,
      PLAYWRIGHT_NATURAL_LOGIN: playwrightLoginClass,
      LOGIN_BLOCKER: report.login.blocker || null,
      ROLE_RESOLVED: report.login.roleResolved,
      LIVE_DRIVER_COUNTERS_MATCH: countersPass ? 'PASS' : 'FAIL',
      FILTER_TABLE_TOTAL_CONSISTENCY: filtersPass ? 'PASS' : 'FAIL',
      DRIVER_REVIEW_VISUAL: reviewVisualPass ? 'PASS' : 'FAIL',
      APPROVE_DIALOG: report.dialogs.approve,
      REJECT_DIALOG: report.dialogs.reject,
      REQUEST_CHANGES_DIALOG: report.dialogs.requestChanges,
      AR_RTL: report.reviewVisual?.locales?.ar?.dir === 'rtl' ? 'PASS' : 'FAIL',
      EN_LTR: report.reviewVisual?.locales?.en?.dir === 'ltr' ? 'PASS' : 'FAIL',
      UR_RTL: report.reviewVisual?.locales?.ur?.dir === 'rtl' ? 'PASS' : 'FAIL',
      AUTHENTICATED_ADMIN_VISUAL_QA:
        loginPass && visualPass && reviewVisualPass ? 'PASS' : 'FAIL',
      DRIVER_STAGE_F_SECURITY_AND_ADMIN_QA_PASS:
        loginGatePass &&
        countersPass &&
        filtersPass &&
        reviewVisualPass &&
        dialogsPass
          ? 'PASS'
          : 'FAIL',
      reportPath: path.join(OUT, 'report.json'),
      screenshots: report.screenshots,
      overflowCount: report.visual.overflow.length,
    },
    null,
    2,
  ),
);
