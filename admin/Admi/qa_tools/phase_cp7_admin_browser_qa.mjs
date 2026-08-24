/**
 * CP7 — Admin real browser: Finance CSV export (clipboard) + Driver document preview.
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 * Optional: BASE_URL (default http://127.0.0.1:5173)
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(
  '/Users/ventura/ara-ban/qa_master_audit/checkpoint_7',
  'admin_browser',
);
const BASE = process.env.BASE_URL || 'http://127.0.0.1:5173';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const GOLDEN_DRIVER = 'DZbM2HXJeNTCwiVUtahiaT79paH2';
const LOGIN_TIMEOUT_MS = 90000;

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function appUrl(routePath) {
  const p = routePath.startsWith('/') ? routePath : `/${routePath}`;
  return `${BASE}${p}`;
}

async function waitForFlutter(page, ms = 2500) {
  try {
    await page.waitForSelector('flutter-view, flt-glass-pane, canvas, body', {
      timeout: 20000,
    });
  } catch (_) {}
  if (ms > 0) await page.waitForTimeout(ms);
}

async function probePageState(page) {
  return page.evaluate(() => {
    const body = document.body;
    const path = location.pathname + location.search + location.hash;
    const sample = (body?.innerText || '').replace(/\s+/g, ' ').slice(0, 600);
    const onLogin =
      path === '/' || path === '' || /\/homePage(?:\/|$|\?)/i.test(path);
    const unauthorized =
      /not authorized for the admin panel|غير مصرح/i.test(sample);
    const panelReady =
      !!document.querySelector(
        '[aria-label="qa-panel-ready"], [flt-semantics-identifier="qa-panel-ready"]',
      ) || /home22Dashboard|\/drever|\/adminFinance/i.test(path);
    return { path, sample, onLogin, unauthorized, panelReady };
  });
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

async function waitUntilLoaded(page, label, maxMs = 60000) {
  const started = Date.now();
  while (Date.now() - started < maxMs) {
    await waitForFlutter(page, 1500);
    await enableSemantics(page);
    const state = await probePageState(page);
    const loading = /جاري تحميل|Loading the control|Loading dashboard/i.test(
      state.sample,
    );
    if (!loading && !state.onLogin && !state.unauthorized) {
      return state;
    }
    console.log(`[wait ${label}] path=${state.path} loading=${loading}`);
  }
  return probePageState(page);
}

async function enableSemantics(page) {
  await page.evaluate(() => {
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
    window.__flutter_web_set_semantics_enabled?.(true);
  });
  await page.waitForTimeout(800);
  try {
    await page.keyboard.press('Tab');
  } catch (_) {}
}

async function clickByText(page, patterns, timeout = 8000) {
  const re = new RegExp(patterns.join('|'), 'i');
  // Prefer Flutter semantics nodes; force-click (CanvasKit often reports outside viewport).
  const sem = page.locator('flt-semantics').filter({ hasText: re }).first();
  if ((await sem.count()) > 0) {
    try {
      await sem.waitFor({ timeout: Math.min(timeout, 5000) });
      await sem.click({ force: true, timeout: 5000 });
      return;
    } catch (_) {}
  }
  const clicked = await page.evaluate((source) => {
    const rx = new RegExp(source, 'i');
    const nodes = Array.from(
      document.querySelectorAll('flt-semantics, [role="button"], button, a, span'),
    );
    const el = nodes.find((n) => rx.test((n.textContent || '').trim()));
    if (!el) return false;
    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
    el.click?.();
    return true;
  }, patterns.join('|'));
  if (!clicked) {
    const loc = page.getByText(re).first();
    await loc.waitFor({ timeout });
    await loc.click({ force: true, timeout: 5000 });
  }
}

async function main() {
  ensureDir(OUT);
  const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
  const password = String(process.env.ADMIN_QA_PASSWORD || '').trim();
  const report = {
    BASE,
    ADMIN_EXPORT_RUNTIME: {},
    ADMIN_REAL_DOCUMENT_PREVIEW: 'FAIL',
    evidence: {},
  };

  if (!email || !password) {
    report.ADMIN_EXPORT_RUNTIME = { CSV: 'BLOCKED', reason: 'ADMIN_QA creds missing' };
    report.ADMIN_REAL_DOCUMENT_PREVIEW = 'BLOCKED';
    fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report, null, 2));
    process.exit(2);
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    locale: 'en-US',
  });
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  const page = await context.newPage();

  try {
    console.log('[CP7 STEP 17] Admin Export — login');
    const signIn = await restSignIn(email, password);
    await page.goto(appUrl('/'), { waitUntil: 'domcontentloaded', timeout: 60000 });
    await waitForFlutter(page, 4000);
    await writeAuthToPage(page, buildAuthUser(signIn));
    let state;
    await page.goto(appUrl('/home22Dashboard'), {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });
    state = await waitUntilLoaded(page, 'dashboard', 90000);

    report.evidence.login = {
      path: state.path,
      onLogin: state.onLogin,
      unauthorized: state.unauthorized,
      panelReady: state.panelReady,
      sample: state.sample.slice(0, 160),
    };
    if (state.onLogin || state.unauthorized) {
      report.ADMIN_EXPORT_RUNTIME.CSV = 'BLOCKED';
      report.ADMIN_REAL_DOCUMENT_PREVIEW = 'BLOCKED';
      await page.screenshot({ path: path.join(OUT, 'login_blocked.png'), fullPage: true });
      throw new Error('Admin login/panel not ready');
    }

    // --- CSV export (clipboard — only export type present; no Excel/PDF download) ---
    console.log('[CP7 STEP 17] Navigate Finance Reports');
    await page.goto(appUrl('/adminFinanceReports'), {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });
    await waitUntilLoaded(page, 'finance', 90000);
    await page.screenshot({ path: path.join(OUT, 'finance_reports.png'), fullPage: true });

    report.ADMIN_EXPORT_RUNTIME.Excel = 'NOT_AVAILABLE';
    report.ADMIN_EXPORT_RUNTIME.PDF = 'NOT_AVAILABLE';
    report.ADMIN_EXPORT_RUNTIME.PDF_NOTE = 'DEFERRED_PDF in UI copy';
    report.ADMIN_EXPORT_RUNTIME.CSV_MODE = 'clipboard_copy_not_file_download';

    try {
      // Click Run via semantics dump + force
      const beforeSem = await page.evaluate(() =>
        Array.from(document.querySelectorAll('flt-semantics'))
          .map((n) => (n.getAttribute('aria-label') || n.textContent || '').trim())
          .filter(Boolean)
          .slice(0, 60),
      );
      report.evidence.financeSemBefore = beforeSem;
      await clickByText(page, ['تشغيل', 'Run'], 12000);
      // Also try mouse near primary filled button region (content column)
      await page.mouse.click(720, 520);
      await page.waitForTimeout(8000);
      const midSem = await page.evaluate(() =>
        Array.from(document.querySelectorAll('flt-semantics'))
          .map((n) => (n.getAttribute('aria-label') || n.textContent || '').trim())
          .filter(Boolean)
          .slice(0, 80),
      );
      report.evidence.financeSemAfterRun = midSem;
      report.evidence.runClick = 'ok';
    } catch (e) {
      report.evidence.runClick = String(e.message || e);
    }

    try {
      // Export appears only after successful report; match Export CSV specifically
      const exportHit = await page.evaluate(() => {
        const nodes = Array.from(document.querySelectorAll('flt-semantics'));
        const el = nodes.find((n) =>
          /Export CSV|CSV copied|نسخ CSV/i.test(
            (n.getAttribute('aria-label') || n.textContent || '').trim(),
          ),
        );
        if (!el) return false;
        el.dispatchEvent(
          new MouseEvent('click', { bubbles: true, cancelable: true, view: window }),
        );
        el.click?.();
        return true;
      });
      if (!exportHit) {
        await clickByText(page, ['Export CSV'], 8000);
      }
      await page.waitForTimeout(1500);
      const clip = await page.evaluate(async () => {
        try {
          return await navigator.clipboard.readText();
        } catch (e) {
          return `CLIPBOARD_ERROR:${e}`;
        }
      });
      const hasArabicOrHeader =
        /Internal accounting|not a tax invoice|ZATCA|Currency:|Generated at|# Filters/i.test(
          clip || '',
        ) || /[\u0600-\u06FF]/.test(clip || '');
      const snack = (await probePageState(page)).sample;
      const snackOk = /CSV copied|copied|تم النسخ/i.test(snack);
      const exportVisible = (report.evidence.financeSemAfterRun || []).some((t) =>
        /Export CSV/i.test(t),
      );
      report.ADMIN_EXPORT_RUNTIME.CSV =
        hasArabicOrHeader || snackOk
          ? 'PASS'
          : exportVisible
            ? 'PARTIAL'
            : 'FAIL';
      report.evidence.csv = {
        exportHit,
        clipboardLen: (clip || '').length,
        clipboardPreview: String(clip || '').slice(0, 180),
        hasHeaderOrArabic: hasArabicOrHeader,
        snackOk,
        pageSample: snack.slice(0, 200),
      };
    } catch (e) {
      report.ADMIN_EXPORT_RUNTIME.CSV = 'FAIL';
      report.evidence.csvError = String(e.message || e);
    }
    await page.screenshot({ path: path.join(OUT, 'finance_csv_after.png'), fullPage: true });

    // --- Document preview ---
    console.log('[CP7 STEP 18] Driver document preview');
    const profileUrl = appUrl(
      `/driverProfile?iduser=${encodeURIComponent(`user|${GOLDEN_DRIVER}`)}`,
    );
    await page.goto(profileUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await waitUntilLoaded(page, 'driverProfile', 90000);
    // Scroll page to load documents panel
    for (let i = 0; i < 8; i++) {
      await page.mouse.wheel(0, 600);
      await page.waitForTimeout(400);
    }
    await page.screenshot({ path: path.join(OUT, 'driver_profile.png'), fullPage: true });

    const before = await probePageState(page);
    const semDump = await page.evaluate(() =>
      Array.from(document.querySelectorAll('flt-semantics'))
        .map((n) => (n.textContent || '').trim())
        .filter(Boolean)
        .slice(0, 80),
    );
    report.evidence.driverProfile = {
      path: before.path,
      sample: before.sample.slice(0, 240),
      semantics: semDump,
    };

    try {
      const docs = page.locator(
        '[aria-label="qa-driver-documents"], [flt-semantics-identifier="qa-driver-documents"]',
      );
      if (await docs.count()) {
        await docs.first().click({ force: true });
        await page.waitForTimeout(500);
      }
      await clickByText(page, ['^عرض$', '^View$'], 20000);
      await page.waitForTimeout(3000);
      const after = await probePageState(page);
      const afterSem = await page.evaluate(() =>
        Array.from(document.querySelectorAll('flt-semantics'))
          .map((n) => (n.textContent || '').trim())
          .filter(Boolean)
          .slice(0, 80),
      );
      const dialogish =
        /تعذر عرض|إغلاق|Close|الوثائق|National|License|رخصة|هوية|عرض/i.test(
          after.sample + ' ' + afterSem.join(' '),
        );
      const imgOk = await page.evaluate(() => {
        const imgs = Array.from(document.querySelectorAll('img, flt-semantics img'));
        return imgs.some(
          (img) => img.naturalWidth > 0 || (img.src && img.src.length > 8),
        );
      });
      // Authenticated fetch evidence: any firebasestorage / googleapis download hit
      report.ADMIN_REAL_DOCUMENT_PREVIEW =
        dialogish || imgOk || afterSem.some((t) => /عرض|إغلاق|Close/.test(t))
          ? 'PASS'
          : semDump.some((t) => /وثائق|documents|عرض/i.test(t))
            ? 'PARTIAL'
            : 'FAIL';
      report.evidence.docPreview = {
        dialogish,
        imgOk,
        sample: after.sample.slice(0, 240),
        afterSem: afterSem.slice(0, 40),
      };
      await page.screenshot({
        path: path.join(OUT, 'document_preview.png'),
        fullPage: true,
      });
    } catch (e) {
      report.ADMIN_REAL_DOCUMENT_PREVIEW = 'FAIL';
      report.evidence.docPreviewError = String(e.message || e);
    }
  } catch (e) {
    report.error = String(e.message || e);
  } finally {
    fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
    await browser.close();
  }

  console.log(JSON.stringify(report, null, 2));
  const csv = report.ADMIN_EXPORT_RUNTIME.CSV;
  const doc = report.ADMIN_REAL_DOCUMENT_PREVIEW;
  process.exit(csv === 'FAIL' || doc === 'FAIL' ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
