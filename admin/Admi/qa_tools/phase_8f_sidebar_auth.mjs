/**
 * Phase 8F — Sidebar auth regression (release build).
 * Uses IndexedDB auth inject + Flutter semantics (same pattern as 8D).
 * Env: ADMIN_QA_EMAIL / ADMIN_QA_PASSWORD. No finance writes.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_8f');
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4174';
const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';

async function signIn(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message || 'AUTH_FAILED');
  return json;
}

async function callRefresh(idToken) {
  await fetch(
    'https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/refreshMyClaims',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({ data: {} }),
    },
  );
}

async function refreshToken(rt) {
  const res = await fetch(
    `https://securetoken.googleapis.com/v1/token?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=refresh_token&refresh_token=${encodeURIComponent(rt)}`,
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message || 'REFRESH_FAILED');
  return json;
}

function buildAuthUser(sign, idToken, refreshTok) {
  return {
    uid: sign.localId,
    email: sign.email,
    emailVerified: true,
    isAnonymous: false,
    stsTokenManager: {
      refreshToken: refreshTok,
      accessToken: idToken,
      expirationTime: Date.now() + 55 * 60 * 1000,
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

async function enableSemantics(page) {
  await page.evaluate(() => {
    try {
      if (typeof window.__flutter_web_set_semantics_enabled === 'function') {
        window.__flutter_web_set_semantics_enabled(true);
      }
    } catch (_) {}
  });
  await page.keyboard.press('Tab');
  await page.waitForTimeout(500);
}

async function collectText(page) {
  return page.evaluate(() => {
    const body = (document.body?.innerText || '').replace(/\s+/g, ' ');
    const aria = Array.from(
      document.querySelectorAll(
        'flt-semantics, [role], [aria-label], flt-semantics-container',
      ),
    )
      .map((el) => el.getAttribute('aria-label') || el.innerText || '')
      .join(' ')
      .replace(/\s+/g, ' ');
    return `${body} ${aria}`.trim();
  });
}

async function main() {
  const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
  const password = String(process.env.ADMIN_QA_PASSWORD || '');
  if (!email || !password) {
    console.log(JSON.stringify({ SIDEBAR_AUTH: 'BLOCKED', reason: 'NO_TEST_ACCOUNT' }));
    process.exit(2);
  }
  fs.mkdirSync(OUT, { recursive: true });

  const sign = await signIn(email, password);
  await callRefresh(sign.idToken);
  const refreshed = await refreshToken(sign.refreshToken);
  const idToken = refreshed.id_token;
  const refreshTok = refreshed.refresh_token || sign.refreshToken;
  const authUser = buildAuthUser(sign, idToken, refreshTok);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1366, height: 768 } });
  await context.addInitScript(
    ({ apiKey, user }) => {
      try {
        localStorage.setItem(
          `firebase:authUser:${apiKey}:[DEFAULT]`,
          JSON.stringify(user),
        );
      } catch (_) {}
    },
    { apiKey: API_KEY, user: authUser },
  );

  const page = await context.newPage();
  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await writeAuthToPage(page, authUser);
  await page.goto(`${BASE}/adminFinanceHub`, {
    waitUntil: 'domcontentloaded',
    timeout: 90000,
  });
  await writeAuthToPage(page, authUser);
  await page.reload({ waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(7000);
  await enableSemantics(page);
  await page.waitForTimeout(2500);

  let text = await collectText(page);
  // One more pass if still empty/login
  if (!/Super Admin|Unauthorized|Resolving role|Finance|محاسب/i.test(text)) {
    await page.waitForTimeout(5000);
    await enableSemantics(page);
    text = await collectText(page);
  }

  const hasResolving = /Resolving role/i.test(text);
  const hasSuperAdmin = /Super Admin|سوبر أدمن|مشرف أعلى/i.test(text);
  const hasUnauthorized = /\bUnauthorized\b|غير مصرح/i.test(text);
  const looksLogin =
    /Sign in|تسجيل الدخول|Email|Password/i.test(text) &&
    !/adminFinanceHub|Finance Hub/i.test(page.url());

  const SIDEBAR_AUTH =
    hasSuperAdmin && !hasUnauthorized && !looksLogin ? 'PASS' : 'FAIL';

  await page.screenshot({
    path: path.join(OUT, 'sidebar_finance_hub.png'),
    fullPage: false,
  });

  const report = {
    SIDEBAR_AUTH,
    hasResolvingSeen: hasResolving,
    hasSuperAdmin,
    hasUnauthorized,
    looksLogin,
    url: page.url(),
    sample: text.slice(0, 500),
  };
  fs.writeFileSync(path.join(OUT, 'sidebar_auth.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
  process.exit(SIDEBAR_AUTH === 'PASS' ? 0 : 1);
}

main().catch((e) => {
  console.log(JSON.stringify({ SIDEBAR_AUTH: 'FAIL', error: String(e.message || e) }));
  process.exit(1);
});
