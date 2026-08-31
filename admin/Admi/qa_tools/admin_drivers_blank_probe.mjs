/**
 * Focused Super Admin drivers blank-panel probe (auth hydrate + UI settle).
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD, BASE_URL
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';

const OUT = path.join(
  '/Users/ventura/ara-ban/qa_master_audit/admin_exhaustive',
  'drivers_blank_probe',
);
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4173';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const EMAIL = process.env.ADMIN_QA_EMAIL || 'info@touri-taxi.com';
const PASSWORD = process.env.ADMIN_QA_PASSWORD || '';
const PROJECT_ID = 'tutorial-multi-language-70gx4j';

fs.mkdirSync(OUT, { recursive: true });

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
    providerData: [{ providerId: 'password', uid: signIn.email, email: signIn.email }],
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

async function firestoreDriverCount(idToken) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runAggregationQuery`;
  const body = {
    structuredAggregationQuery: {
      aggregations: [{ alias: 'count', count: {} }],
      structuredQuery: {
        from: [{ collectionId: 'user' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'ismndob' },
            op: 'EQUAL',
            value: { booleanValue: true },
          },
        },
      },
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
  if (!res.ok) throw new Error(JSON.stringify(json));
  return Number(json?.[0]?.result?.aggregateFields?.count?.integerValue ?? NaN);
}

async function settle(page, ms) {
  await page.waitForTimeout(ms);
  await page.evaluate(() => {
    window.__flutter_web_set_semantics_enabled?.(true);
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.waitForTimeout(500);
}

function collectSemantics(page) {
  return page.evaluate(() => {
    const nodes = [...document.querySelectorAll('[id^="flt-semantic-node"]')];
    const labels = nodes
      .map((n) => ({
        id: n.id,
        label: n.getAttribute('aria-label') || '',
        role: n.getAttribute('role') || '',
      }))
      .filter((n) => n.label);
    const driverLabels = labels.filter((n) =>
      /qa-driver|visible:|total:|empty:|loading:|المندوب|لا يوجد|المناديب|الإجمالي|qa-row|Resolving role|غير مصرح/.test(
        n.label,
      ),
    );
    const rowLabels = labels.filter((n) =>
      /qa-driver|qa-row|ismndob|مندوب/i.test(n.label),
    );
    const tableQa = labels.find((n) => /visible:\d+/.test(n.label));
    const sample = (document.body?.innerText || '').replace(/\s+/g, ' ').slice(0, 1200);
    return {
      path: location.pathname,
      bodyTextSample: sample,
      totalSemanticNodes: nodes.length,
      tableQaLabel: tableQa?.label || null,
      driverLabels,
      rowLabels: rowLabels.slice(0, 50),
      hasResolvingRole: /Resolving role/i.test(sample) ||
        labels.some((l) => /Resolving role/i.test(l.label)),
      unauthorized: /not authorized|غير مصرح/i.test(sample),
      onLogin:
        location.pathname === '/' ||
        /homePage/i.test(location.pathname) ||
        /تسجيل الدخول/.test(sample.slice(0, 200)),
    };
  });
}

async function main() {
  if (!PASSWORD) {
    console.error('ADMIN_QA_PASSWORD required');
    process.exit(2);
  }
  console.log('[ADMIN EXHAUSTIVE STEP 14/62] Drivers blank probe');
  console.log('STATUS: RUNNING');

  const signIn = await restSignIn(EMAIL, PASSWORD);
  const queryCount = await firestoreDriverCount(signIn.idToken);
  console.log('AUTH_OK uid=', signIn.localId);
  console.log('DRIVERS_QUERY_COUNT=', queryCount);

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 900 },
  });
  const consoleErrors = [];
  const pageErrors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text().slice(0, 240));
  });
  page.on('pageerror', (err) => pageErrors.push(String(err).slice(0, 240)));

  // Proven hydrate path used by completion crawl
  await page.goto(`${BASE}/homePage`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await settle(page, 2500);
  await writeAuth(page, buildAuthUser(signIn));
  await page.goto(`${BASE}/drever`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await settle(page, 12000);

  let snap = await collectSemantics(page);
  const deadline = Date.now() + 35000;
  while (Date.now() < deadline) {
    const stillLoading =
      snap.hasResolvingRole ||
      /loading:true/.test(snap.tableQaLabel || '') ||
      snap.onLogin;
    if (!stillLoading && snap.tableQaLabel) break;
    if (!stillLoading && snap.rowLabels.length > 0) break;
    await settle(page, 2500);
    snap = await collectSemantics(page);
  }

  await page.screenshot({
    path: path.join(OUT, 'drever_after_fix.png'),
    fullPage: true,
  });
  fs.writeFileSync(path.join(OUT, 'snap_after_fix.json'), JSON.stringify(snap, null, 2));

  const visibleMatch = /visible:(\d+)/.exec(snap.tableQaLabel || '');
  const totalMatch = /total:(\d+)/.exec(snap.tableQaLabel || '');
  const visible = visibleMatch ? Number(visibleMatch[1]) : snap.rowLabels.length;
  const total = totalMatch ? Number(totalMatch[1]) : null;
  const blank =
    snap.unauthorized ||
    snap.onLogin ||
    snap.hasResolvingRole ||
    ((visible === 0 || snap.rowLabels.length === 0) &&
      queryCount > 0 &&
      !/empty:true/.test(snap.tableQaLabel || ''));

  const report = {
    email: EMAIL,
    uid: signIn.localId,
    DRIVERS_QUERY_COUNT: queryCount,
    DRIVERS_RENDERED_COUNT: visible,
    DISPLAYED_TOTAL: total,
    BLANK_DRIVER_PANEL: blank,
    consoleErrors: consoleErrors.slice(0, 40),
    pageErrors: pageErrors.slice(0, 20),
    snap,
  };
  fs.writeFileSync(
    path.join(OUT, 'report_after_fix.json'),
    JSON.stringify(report, null, 2),
  );

  console.log('RESULT:');
  console.log(blank ? 'FAIL' : 'PASS');
  console.log('EVIDENCE:');
  console.log('DRIVERS_QUERY_COUNT=', queryCount);
  console.log('DRIVERS_RENDERED_COUNT=', visible);
  console.log('DISPLAYED_TOTAL=', total);
  console.log('BLANK_DRIVER_PANEL=', blank);
  console.log('TABLE_QA=', snap.tableQaLabel);
  console.log('ROW_LABELS=', snap.rowLabels.length);
  console.log('PATH=', snap.path);
  console.log('RESOLVING=', snap.hasResolvingRole);
  console.log('ON_LOGIN=', snap.onLogin);
  console.log('SAMPLE=', snap.bodyTextSample.slice(0, 300));
  console.log('CONSOLE_ERRORS=', consoleErrors.length);
  console.log('RESULT_PATH=', OUT);
  await browser.close();
  process.exit(blank ? 1 : 0);
}

main().catch((e) => {
  console.error('FAIL', e);
  process.exit(1);
});
