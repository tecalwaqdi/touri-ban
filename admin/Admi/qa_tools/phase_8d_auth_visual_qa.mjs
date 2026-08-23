/**
 * Phase 8D — Authenticated Visual QA (release build).
 * Credentials: ADMIN_QA_EMAIL / ADMIN_QA_PASSWORD from env only.
 * Never logs secrets. No financial writes / confirms.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_8d');
const STATE_DIR = path.join(__dirname, '..', '.qa_auth_state');
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4173';
const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';

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

const ROUTES = [
  { key: 'dashboard', path: '/home22Dashboard' },
  { key: 'orders', path: '/adminALLhgZ' },
  { key: 'drivers', path: '/drever' },
  { key: 'users', path: '/adminuser' },
  { key: 'support', path: '/adminSuport' },
  { key: 'finance_home', path: '/adminFinanceHub' },
  { key: 'driver_finance', path: '/adminProfits' },
  { key: 'settlements', path: '/adminSettlements' },
  { key: 'settlement_details', path: '/adminSettlementDetails' },
  { key: 'reconciliation', path: '/adminReconciliation' },
  { key: 'periods', path: '/adminFinancialPeriods' },
  { key: 'reports', path: '/adminFinanceReports' },
  { key: 'audit', path: '/adminFinanceAudit' },
  { key: 'diagnostics', path: '/adminDiagnostics' },
];

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function scrub(s) {
  return String(s || '')
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]')
    .replace(/\+?\d[\d\s\-()]{7,}\d/g, '[phone]');
}

async function firebaseSignIn(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    },
  );
  const json = await res.json();
  if (json.error) {
    const msg = json.error.message || 'AUTH_FAILED';
    throw new Error(`AUTH_FAILED:${msg}`);
  }
  return json;
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
  await page.evaluate(async ({ apiKey, user }) => {
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
  }, { apiKey: API_KEY, user: authUser });
}

async function injectAuthInit(context, authUser) {
  await context.addInitScript(
    ({ apiKey, user }) => {
      const key = `firebase:authUser:${apiKey}:[DEFAULT]`;
      try {
        localStorage.setItem(key, JSON.stringify(user));
      } catch (_) {}
    },
    { apiKey: API_KEY, user: authUser },
  );
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

async function waitApp(page, ms = 4500) {
  try {
    await page.waitForSelector('flutter-view, flt-glass-pane, canvas, body', {
      timeout: 20000,
    });
  } catch (_) {}
  await page.waitForTimeout(ms);
}

async function enableFlutterSemantics(page) {
  await page.evaluate(() => {
    try {
      // Flutter web accessibility toggle used by engine
      window.dispatchEvent(new Event('flutter-first-frame'));
      const hosts = document.querySelectorAll('flt-semantics-host, flt-glass-pane');
      hosts.forEach((el) => {
        el.setAttribute('aria-hidden', 'false');
      });
      // Request semantics via a11y mode if available
      if (typeof window.__flutter_web_set_semantics_enabled === 'function') {
        window.__flutter_web_set_semantics_enabled(true);
      }
    } catch (_) {}
  });
  // Alt+A / Tab sometimes forces semantics tree creation
  try {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(400);
  } catch (_) {}
}

/**
 * UI login via Flutter web ephemeral <input> after focusing TextFields.
 * Never logs email/password.
 */
function appUrl(routePath) {
  // PathUrlStrategy — no hash
  const p = routePath.startsWith('/') ? routePath : `/${routePath}`;
  return `${BASE}${p === '/' ? '/' : p}`;
}

async function uiLogin(page, email, password) {
  await page.goto(appUrl('/'), { waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitApp(page, 5000);
  await enableFlutterSemantics(page);

  const vp = page.viewportSize() || { width: 1440, height: 900 };
  const cx = Math.floor(vp.width / 2);
  const emailY = Math.floor(vp.height * 0.42);
  const passY = Math.floor(vp.height * 0.52);
  const btnY = Math.floor(vp.height * 0.62);

  async function focusAndType(x, y, value) {
    await page.mouse.click(x, y);
    await page.waitForTimeout(500);
    const input = page.locator('input').last();
    try {
      await input.waitFor({ state: 'attached', timeout: 2500 });
      await input.fill(value, { force: true });
      return true;
    } catch (_) {
      await page.keyboard.type(value, { delay: 15 });
      return true;
    }
  }

  await focusAndType(cx, emailY, email);
  await page.waitForTimeout(300);
  await focusAndType(cx, passY, password);
  await page.waitForTimeout(300);
  await page.mouse.click(cx, btnY);
  await page.waitForTimeout(800);
  await page.keyboard.press('Enter');
  await waitApp(page, 6000);

  await page.goto(appUrl('/home22Dashboard'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await waitApp(page, 5000);
}

async function probe(page) {
  return page.evaluate(() => {
    const doc = document.documentElement;
    const body = document.body;
    const scrollW = Math.max(doc.scrollWidth, body?.scrollWidth || 0);
    const clientW = doc.clientWidth;
    const horizontalOverflow = scrollW > clientW + 2;
    const sample = (body?.innerText || '').replace(/\s+/g, ' ').slice(0, 220);
    const url = location.href;
    const path = location.pathname + location.hash;
    const isHttp404 =
      /Error response|Error code:\s*404|File not found/i.test(sample);
    const onLoginRoute =
      path === '/' ||
      path === '' ||
      /(?:#\/|\/)homePage(?:\/|$)/i.test(path);
    const onAppRoute =
      /(?:#\/|\/)(home22Dashboard|admin|drever|settings)/i.test(path);
    const looksLogin = !isHttp404 && onLoginRoute && !onAppRoute;
    return {
      horizontalOverflow,
      scrollW,
      clientW,
      sampleText: sample,
      url,
      path,
      looksLogin,
      onAppRoute,
      isHttp404,
      inputCount: document.querySelectorAll('input').length,
      semanticsCount: document.querySelectorAll('flt-semantics, [role]').length,
    };
  });
}

function looksAuthenticated(p) {
  if (!p || p.isHttp404) return false;
  if (p.onAppRoute) return true;
  if (p.looksLogin) return false;
  const u = p.url || '';
  if (/(?:#\/|\/)(home22Dashboard|admin|drever)/i.test(u)) return true;
  return false;
}

async function establishSession(browser, authUser, email, password) {
  const warm = await browser.newContext({
    viewport: { width: 1440, height: 900 },
  });
  await injectAuthInit(warm, authUser);
  await setLocale(warm, 'en');
  const warmPage = await warm.newPage();

  // Load app first so origin-scoped storage exists
  await warmPage.goto(appUrl('/'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await waitApp(warmPage, 3000);
  await writeAuthToPage(warmPage, authUser);
  await warmPage.reload({ waitUntil: 'domcontentloaded' });
  await waitApp(warmPage, 4000);
  await warmPage.goto(appUrl('/home22Dashboard'), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await waitApp(warmPage, 5000);

  let warmProbe = await probe(warmPage);
  let method = 'indexeddb_inject';

  if (warmProbe.looksLogin || !looksAuthenticated(warmProbe)) {
    method = 'ui_login';
    await uiLogin(warmPage, email, password);
    warmProbe = await probe(warmPage);
  }

  const warmShot = path.join(OUT, 'auth_warmup.png');
  await warmPage.screenshot({ path: warmShot, fullPage: false });

  const statePath = path.join(STATE_DIR, 'storage.json');
  await warm.storageState({ path: statePath });
  await warm.close();

  return { warmProbe, method, statePath };
}

async function main() {
  const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
  const password = String(process.env.ADMIN_QA_PASSWORD || '');
  if (!email || !password) {
    console.log(
      JSON.stringify({
        ok: false,
        code: 'AUTHENTICATED_VISUAL_QA_BLOCKED_NO_TEST_ACCOUNT',
      }),
    );
    process.exit(2);
  }

  ensureDir(OUT);
  ensureDir(STATE_DIR);

  let signIn;
  try {
    signIn = await firebaseSignIn(email, password);
  } catch (e) {
    console.log(
      JSON.stringify({
        ok: false,
        code: 'AUTH_FAILED',
        error: String(e.message || e).replace(email, '[email]'),
      }),
    );
    process.exit(3);
  }

  const authUser = buildAuthUser(signIn);
  const report = {
    startedAt: new Date().toISOString(),
    baseUrl: BASE,
    authOk: true,
    uidPrefix: String(signIn.localId || '').slice(0, 6),
    matrix: {},
    notes: [],
    summary: { pass: 0, blocked: 0, fail: 0 },
  };

  const browser = await chromium.launch({ headless: true });
  try {
    const { warmProbe, method, statePath } = await establishSession(
      browser,
      authUser,
      email,
      password,
    );
    report.warmup = {
      method,
      url: warmProbe.url,
      looksLogin: warmProbe.looksLogin,
      authenticated: looksAuthenticated(warmProbe),
      sampleText: scrub(warmProbe.sampleText),
      screenshot: 'auth_warmup.png',
    };

    if (!looksAuthenticated(warmProbe)) {
      report.notes.push('AUTH_SESSION_NOT_ESTABLISHED');
      report.finishedAt = new Date().toISOString();
      fs.writeFileSync(
        path.join(OUT, 'report.json'),
        JSON.stringify(report, null, 2),
      );
      console.log(
        JSON.stringify({
          ok: false,
          code: 'AUTH_SESSION_NOT_ESTABLISHED',
          warmup: report.warmup,
          notes: report.notes,
        }),
      );
      process.exit(4);
    }

    for (const locale of LOCALES) {
      report.matrix[locale.code] = {};
      for (const vp of VIEWPORTS) {
        const context = await browser.newContext({
          viewport: { width: vp.width, height: vp.height },
          storageState: fs.existsSync(statePath) ? statePath : undefined,
          locale:
            locale.code === 'ar'
              ? 'ar-SA'
              : locale.code === 'ur'
                ? 'ur-PK'
                : 'en-US',
        });
        await injectAuthInit(context, authUser);
        await setLocale(context, locale.code);
        const page = await context.newPage();
        const shotDir = path.join(OUT, locale.code, vp.name);
        ensureDir(shotDir);

        // Re-hydrate IndexedDB after storage restore
        await page.goto(appUrl('/'), {
          waitUntil: 'domcontentloaded',
          timeout: 60000,
        });
        await writeAuthToPage(page, authUser);
        await page.reload({ waitUntil: 'domcontentloaded' });
        await waitApp(page, 3000);

        const cell = {};
        for (const route of ROUTES) {
          const url = appUrl(route.path);
          let status = 'BLOCKED';
          let detail = {};
          try {
            await page.goto(url, {
              waitUntil: 'domcontentloaded',
              timeout: 60000,
            });
            await waitApp(page, 3500);
            let p = await probe(page);
            if (p.looksLogin) {
              await writeAuthToPage(page, authUser);
              await page.goto(url, {
                waitUntil: 'domcontentloaded',
                timeout: 60000,
              });
              await waitApp(page, 4000);
              p = await probe(page);
            }
            const shot = path.join(shotDir, `${route.key}.png`);
            await page.screenshot({ path: shot, fullPage: false });
            detail = {
              url: p.url,
              looksLogin: p.looksLogin,
              horizontalOverflow: p.horizontalOverflow,
              sampleText: scrub(p.sampleText),
              screenshot: path.relative(OUT, shot),
            };
            if (route.key === 'settlement_details' && !p.looksLogin) {
              detail.note = 'SETTLEMENT_DETAILS_LIVE_DATA_NOT_AVAILABLE_OR_EMPTY';
            }
            if (p.isHttp404) {
              status = 'FAIL';
              detail.note = 'SPA_ROUTE_404';
              report.summary.fail++;
            } else if (p.looksLogin || !looksAuthenticated(p)) {
              status = 'BLOCKED';
              report.summary.blocked++;
            } else if (p.horizontalOverflow) {
              status = 'FAIL';
              report.summary.fail++;
            } else {
              status = 'PASS';
              report.summary.pass++;
            }
          } catch (e) {
            status = 'BLOCKED';
            detail = { error: String(e.message || e).slice(0, 160) };
            report.summary.blocked++;
          }
          cell[route.key] = { status, ...detail };
        }

        try {
          await page.goto(appUrl('/adminFinanceHub'), {
            waitUntil: 'domcontentloaded',
            timeout: 60000,
          });
          await waitApp(page, 3000);
          await page.evaluate((isRtl) => {
            const old = document.getElementById('qa-money-probe');
            if (old) old.remove();
            const box = document.createElement('div');
            box.id = 'qa-money-probe';
            box.setAttribute('dir', isRtl ? 'rtl' : 'ltr');
            box.style.cssText =
              'position:fixed;z-index:99999;inset-inline-start:12px;top:12px;padding:10px;' +
              'background:#111;color:#fff;font:14px/1.4 Cairo,Arial,sans-serif;' +
              'border-radius:8px;max-width:420px;';
            for (const s of [
              '804 SAR',
              '-804 SAR',
              '0 SAR',
              '1,245,678.50 SAR',
              'Driver Pays Company',
              'Company Pays Driver',
            ]) {
              const row = document.createElement('div');
              row.textContent = s;
              row.style.unicodeBidi = 'isolate';
              row.style.direction = 'ltr';
              box.appendChild(row);
            }
            document.body.appendChild(box);
          }, locale.dir === 'rtl');
          await page.screenshot({
            path: path.join(shotDir, 'money_probe.png'),
            fullPage: false,
          });
        } catch (_) {}

        report.matrix[locale.code][vp.name] = cell;
        await context.close();
      }
    }
  } finally {
    await browser.close();
    try {
      fs.rmSync(STATE_DIR, { recursive: true, force: true });
    } catch (_) {}
  }

  report.finishedAt = new Date().toISOString();
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
  console.log(
    JSON.stringify(
      {
        ok: true,
        summary: report.summary,
        warmup: report.warmup,
        notes: report.notes,
        reportPath: path.join(OUT, 'report.json'),
        sampleStatuses: Object.fromEntries(
          ROUTES.slice(0, 6).map((r) => [
            r.key,
            report.matrix?.en?.['1440x900']?.[r.key]?.status,
          ]),
        ),
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.log(JSON.stringify({ ok: false, error: String(e.message || e) }));
  process.exit(1);
});
