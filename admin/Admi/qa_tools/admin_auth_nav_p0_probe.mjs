/**
 * AUTH-NAV-P0 — Accountant finance tour probe (Chromium).
 * Proves session retention across Hub → Recon → Channels → Settlements →
 * Agent Finance → Reports → Hub. Reports login redirects + auth persistence.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const BASE = (
  process.env.BASE_URL ||
  'https://tutorial-multi-language-70gx4j--admin-auth-nav-fix.web.app/admin'
).replace(/\/$/, '');
const OUT =
  process.env.OUT_DIR ||
  path.join(__dirname, '..', '..', '..', 'docs', 'admin_ui_recovery', 'auth_nav_p0');
const TOKEN = process.env.CUSTOM_TOKEN_FILE || '/tmp/p2a_custom_token.txt';
const UID = process.env.ACCT_UID || 'jrPITQI0Y2QJNELU43ymS1WJvR43';
const EMAIL = process.env.ACCT_EMAIL || 'accountant.demo@touri-taxi.com';

fs.mkdirSync(OUT, { recursive: true });

function decodeJwt(token) {
  try {
    const part = token.split('.')[1];
    const pad = part + '='.repeat((4 - (part.length % 4)) % 4);
    return JSON.parse(Buffer.from(pad, 'base64url').toString('utf8'));
  } catch {
    return {};
  }
}

async function exchange(customToken) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!data.idToken) throw new Error(data.error?.message || 'auth_fail');
  const payload = decodeJwt(data.idToken);
  return {
    localId: data.localId || payload.user_id || payload.sub || UID,
    email: EMAIL,
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    expiresIn: data.expiresIn || '3600',
  };
}

function buildUser(signIn) {
  return {
    uid: signIn.localId,
    email: signIn.email,
    emailVerified: true,
    displayName: '',
    isAnonymous: false,
    providerData: [
      {
        providerId: 'password',
        uid: signIn.email,
        displayName: null,
        email: signIn.email,
        phoneNumber: null,
        photoURL: null,
      },
    ],
    stsTokenManager: {
      refreshToken: signIn.refreshToken,
      accessToken: signIn.idToken,
      expirationTime: Date.now() + Number(signIn.expiresIn || 3600) * 1000,
    },
    createdAt: String(Date.now()),
    lastLoginAt: String(Date.now()),
    apiKey: API_KEY,
    appName: '[DEFAULT]',
  };
}

async function writeAuth(page, user) {
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
            if (!db.objectStoreNames.contains('firebaseLocalStorage')) return resolve();
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
    { apiKey: API_KEY, user },
  );
}

async function snap(page, label) {
  const s = await page.evaluate(() => {
    const authKeys = Object.keys(localStorage).filter((k) =>
      k.includes('firebase:authUser'),
    );
    let uidPresent = false;
    try {
      const raw = localStorage.getItem(authKeys[0] || '');
      if (raw) uidPresent = !!JSON.parse(raw).uid;
    } catch (_) {}
    const path = location.pathname + location.search;
    const text = (document.body?.innerText || '').replace(/\s+/g, ' ');
    const loginish =
      /sign in|login|تسجيل الدخول|البريد الإلكتروني|كلمة المرور/i.test(text) &&
      path.toLowerCase().includes('homepage');
    const hasData =
      text.length > 40 &&
      !/جاري تحميل لوحة التحكم/i.test(text) &&
      !loginish;
    return {
      path,
      authPresent: authKeys.length > 0,
      uidPresent,
      loginish,
      hasDataHint: hasData,
      sample: text.slice(0, 180),
    };
  });
  return { label, ...s };
}

(async () => {
  const signIn = await exchange(fs.readFileSync(TOKEN, 'utf8').trim());
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForTimeout(800);
  await writeAuth(page, buildUser(signIn));
  await page.goto(`${BASE}/adminFinanceHub`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  await page.waitForTimeout(4500);

  const tour = [
    ['HUB', '/adminFinanceHub'],
    ['RECON', '/adminFinanceReconciliation'],
    ['CHANNELS', '/adminFinanceChannels'],
    ['SETTLEMENTS', '/adminSettlements'],
    ['AGENT_FINANCE', '/adminAgentFinance'],
    ['REPORTS', '/adminFinanceReports'],
    ['HUB_RETURN', '/adminFinanceHub'],
  ];

  const results = [];
  for (const [label, route] of tour) {
    await page.goto(`${BASE}${route}`, {
      waitUntil: 'domcontentloaded',
      timeout: 120000,
    });
    await page.waitForTimeout(2800);
    const row = await snap(page, label);
    results.push(row);
    console.log(label, JSON.stringify(row));
  }

  // Rapid nav
  for (const route of [
    '/adminFinanceHub',
    '/adminFinanceReconciliation',
    '/adminSettlements',
    '/adminFinanceHub',
  ]) {
    await page.goto(`${BASE}${route}`, {
      waitUntil: 'domcontentloaded',
      timeout: 90000,
    });
    await page.waitForTimeout(600);
  }
  results.push(await snap(page, 'RAPID_END'));

  // Hard refresh Settlements
  await page.goto(`${BASE}/adminSettlements`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  await page.reload({ waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForTimeout(4000);
  results.push(await snap(page, 'HARD_REFRESH_SETTLEMENTS'));

  // Finance paint smoke
  await page.evaluate(() => {
    try {
      window.__TOURI_CLEAR_FINANCE_CACHE__?.();
    } catch (_) {}
  });
  await page.goto(`${BASE}/adminFinanceHub`, {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  const t0 = Date.now();
  let paint = null;
  while (Date.now() - t0 < 45000) {
    const raw = await page.evaluate(() => window.__TOURI_PERF_P4B__ || null);
    if (raw) {
      try {
        const j = typeof raw === 'string' ? JSON.parse(raw) : raw;
        if (j?.marks?.FIRST_USEFUL_FRAME_PAINTED != null) {
          paint = j.marks.FIRST_USEFUL_FRAME_PAINTED - (j.marks.ROUTE_ENTER ?? 0);
          break;
        }
      } catch (_) {}
    }
    await page.waitForTimeout(120);
  }

  const loginRedirects = results.filter((r) => r.loginish || /homePage/i.test(r.path));
  const authLost = results.filter((r) => !r.authPresent || !r.uidPresent);
  const out = {
    base: BASE,
    probedAt: new Date().toISOString(),
    results,
    loginRedirectCount: loginRedirects.length,
    authLostCount: authLost.length,
    financePaintMs: paint,
  };
  fs.writeFileSync(path.join(OUT, 'auth_nav_tour_metrics.json'), JSON.stringify(out, null, 2));
  console.log(JSON.stringify(out, null, 2));
  await browser.close();
  if (out.loginRedirectCount > 0 || out.authLostCount > 0) process.exit(2);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
