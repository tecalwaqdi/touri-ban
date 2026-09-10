/**
 * Admin Finance hotfix smoke — authenticated Chromium (Firebase Hosting).
 * Checks Agent Finance load, Bookings completed KPI, Settlement Detail labels.
 */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';

const require = createRequire(import.meta.url);
const playwrightPath = path.dirname(
  require.resolve('playwright/package.json', {
    paths: [path.join(path.dirname(fileURLToPath(import.meta.url)), '..')],
  }),
);

const BASE = process.env.BASE_URL || 'https://tutorial-multi-language-70gx4j.web.app/admin';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const EMAIL = process.env.ADMIN_QA_EMAIL || '';
const PASSWORD = process.env.ADMIN_QA_PASSWORD || '';
const OUT = '/tmp/admin_hotfix_smoke';
fs.mkdirSync(OUT, {recursive: true});

async function restSignIn() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      }),
    },
  );
  const body = await res.json();
  if (!body.idToken) throw new Error(`signIn failed: ${JSON.stringify(body)}`);
  return body;
}

async function hydrateAuth(page, session) {
  await page.addInitScript(
    ({session, apiKey}) => {
      const key = `firebase:authUser:${apiKey}:[DEFAULT]`;
      const user = {
        uid: session.localId,
        email: session.email,
        emailVerified: true,
        isAnonymous: false,
        stsTokenManager: {
          refreshToken: session.refreshToken,
          accessToken: session.idToken,
          expirationTime: Date.now() + Number(session.expiresIn || 3600) * 1000,
        },
        createdAt: String(Date.now()),
        lastLoginAt: String(Date.now()),
        apiKey,
        appName: '[DEFAULT]',
      };
      localStorage.setItem(key, JSON.stringify(user));
    },
    {session, apiKey: API_KEY},
  );
}

function pageText(page) {
  return page.locator('flt-semantics, body').innerText({timeout: 5000}).catch(async () => {
    return page.evaluate(() => document.body?.innerText || '');
  });
}

async function waitFlutter(page) {
  await page.waitForTimeout(4500);
  for (let i = 0; i < 20; i++) {
    const t = await page.evaluate(() => document.body?.innerText || '');
    if (t && !t.includes('جاري تحميل لوحة التحكم')) return;
    await page.waitForTimeout(1000);
  }
}

async function gotoRoute(page, route) {
  const url = `${BASE.replace(/\/$/, '')}${route.startsWith('/') ? route : `/${route}`}`;
  await page.goto(url, {waitUntil: 'domcontentloaded', timeout: 90000});
  await waitFlutter(page);
  return url;
}

async function main() {
  if (!EMAIL || !PASSWORD) throw new Error('ADMIN_QA_EMAIL/PASSWORD required');
  const session = await restSignIn();
  const browser = await chromium.launch({headless: true});
  const context = await browser.newContext({
    viewport: {width: 1440, height: 900},
    locale: 'ar',
  });
  const page = await context.newPage();
  const consoleErrors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', (e) => consoleErrors.push(String(e)));

  await hydrateAuth(page, session);

  const report = {
    version: null,
    agentFinance: {},
    bookings: {},
    settlement: {},
    consoleBlocking: [],
  };

  const ver = await (await fetch(`${BASE.replace(/\/$/, '')}/version.json`)).json();
  report.version = ver;

  // --- Agent Finance ---
  await gotoRoute(page, '/adminFinanceAgents');
  await page.waitForTimeout(8000);
  await page.screenshot({path: `${OUT}/agent_finance.png`, fullPage: true});
  let text = await page.evaluate(() => document.body?.innerText || '');
  report.agentFinance = {
    url: page.url(),
    hasError: text.includes('تعذر تحميل البيانات'),
    hasStuckSpinnerOnly:
      (text.includes('جاري') || text.trim().length < 40) &&
      !text.includes('وكيل') &&
      !text.includes('عمولة'),
    hasContent:
      text.includes('مالية') ||
      text.includes('وكيل') ||
      text.includes('عمولة') ||
      text.includes('لا يوجد'),
    snippet: text.slice(0, 500),
  };

  // --- Bookings KPI ---
  await gotoRoute(page, '/adminALLhgZ');
  await page.waitForTimeout(10000);
  await page.screenshot({path: `${OUT}/bookings.png`, fullPage: true});
  text = await page.evaluate(() => document.body?.innerText || '');
  const completedMatch = text.match(/المكتملة\s*(\d+)/);
  report.bookings = {
    completedKpi: completedMatch ? Number(completedMatch[1]) : null,
    hasQaToggle: text.includes('إظهار سجلات الاختبار'),
    snippet: text.slice(0, 800),
  };

  // Try click completed chip via text
  try {
    await page.getByText('المكتملة', {exact: false}).first().click({timeout: 3000});
    await page.waitForTimeout(5000);
    text = await page.evaluate(() => document.body?.innerText || '');
    const resultsMatch = text.match(/النتائج\s*(\d+)/);
    report.bookings.drillDownResults = resultsMatch
      ? Number(resultsMatch[1])
      : null;
    report.bookings.afterClickSnippet = text.slice(0, 600);
  } catch (e) {
    report.bookings.clickError = String(e);
  }

  // --- Settlements list → first detail ---
  await gotoRoute(page, '/adminSettlements');
  await page.waitForTimeout(6000);
  text = await page.evaluate(() => document.body?.innerText || '');
  report.settlement.listHasSettledAr = text.includes('مسددة');
  report.settlement.listRawSettled = /\bsettled\b/.test(text);
  report.settlement.listRawDirection = /DRIVER_PAYS_COMPANY/.test(text);

  // Open STL if present
  try {
    const stl = page.getByText(/STL-2026-000001|STL-/).first();
    if (await stl.count()) {
      await stl.click({timeout: 5000});
      await page.waitForTimeout(6000);
    } else {
      await gotoRoute(page, '/adminSettlementDetails?settlementId=STL-2026-000001');
      await page.waitForTimeout(6000);
    }
  } catch (_) {
    await gotoRoute(page, '/adminSettlementDetails');
    await page.waitForTimeout(6000);
  }
  await page.screenshot({path: `${OUT}/settlement_detail.png`, fullPage: true});
  text = await page.evaluate(() => document.body?.innerText || '');
  report.settlement.detail = {
    hasMusadada: text.includes('مسددة'),
    hasDirectionAr: text.includes('مستحق للشركة على المندوب'),
    rawSettled: /\bsettled\b/.test(text),
    rawDirection: /DRIVER_PAYS_COMPANY/.test(text),
    hasSarCode: /\bSAR\b/.test(text) && !text.includes('ر.س'),
    snippet: text.slice(0, 900),
  };

  report.consoleBlocking = consoleErrors
    .filter(
      (e) =>
        !/favicon|Deprecated|Flutter|CanvasKit|skwasm|Google Maps|NetInfo|CORS policy/i.test(
          e,
        ),
    )
    .slice(0, 20);

  fs.writeFileSync(`${OUT}/report.json`, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
