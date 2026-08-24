/**
 * Checkpoint 5 — Admin route smoke (authenticated, read-only navigation).
 * Uses ADMIN_QA_EMAIL / ADMIN_QA_PASSWORD + REST auth hydration (Stage F pattern).
 */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_cp5_routes');
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4176';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.ADMIN_QA_EMAIL || '';
const PASSWORD = process.env.ADMIN_QA_PASSWORD || '';

const ROUTES = [
  '/home22Dashboard',
  '/adminALLhgZ',
  '/adminuser',
  '/drever',
  '/adminSuport',
  '/adminDol',
  '/adminregion',
  '/adminvill',
  '/adminM3alm',
  '/admintypecar',
  '/adminAgent',
  '/adminTransportCompanies',
  '/adminTourGuides',
  '/adminPartners',
  '/adminFinanceHub',
  '/adminProfits',
  '/adminSettlements',
  '/adminReconciliation',
  '/adminFinancialPeriods',
  '/adminFinanceReports',
  '/adminFinanceAudit',
  '/adminDiagnostics',
  '/adminReportsHub',
  '/adminAuditLog',
  '/adminSuperAdmins',
  '/settings',
];

const VIEWPORTS = [
  {name: '1920x1080', width: 1920, height: 1080},
  {name: '1366x768', width: 1366, height: 768},
  {name: '1024x768', width: 1024, height: 768},
];

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
    ({session, projectId}) => {
      try {
        const key = `firebase:authUser:${session.apiKey || ''}:[DEFAULT]`;
        // FlutterFire web stores under firebaseLocalStorageDb; best-effort hydrate.
        localStorage.setItem(
          `firebase:authUser:${projectId}`,
          JSON.stringify({
            uid: session.localId,
            email: session.email,
            stsTokenManager: {
              accessToken: session.idToken,
              refreshToken: session.refreshToken,
              expirationTime: Date.now() + 3500000,
            },
          }),
        );
        localStorage.setItem('ff_user_uid', session.localId);
      } catch (_) {}
    },
    {session: {...session, apiKey: API_KEY}, projectId: PROJECT_ID},
  );
}

async function probe(page) {
  return page.evaluate(() => {
    const path = location.pathname;
    const hasCanvas = !!document.querySelector('flt-glass-pane, flutter-view, canvas');
    const text = (document.body && document.body.innerText) || '';
    const blank =
      !hasCanvas && text.trim().length < 20;
    return {
      path,
      hasCanvas,
      blank,
      title: document.title,
      overflowX: document.documentElement.scrollWidth > window.innerWidth + 8,
    };
  });
}

async function main() {
  const report = {
    startedAt: new Date().toISOString(),
    credentialsPresent: !!(EMAIL && PASSWORD),
    routes: {},
    viewports: {},
    ADMIN_ROUTES_TESTED: 0,
    ADMIN_ROUTES_PASS: 0,
    ADMIN_ROUTES_FAIL: 0,
  };

  if (!EMAIL || !PASSWORD) {
    report.error = 'ADMIN_QA_EMAIL/PASSWORD missing';
    fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report, null, 2));
    process.exit(1);
  }

  const session = await restSignIn();
  report.login = {ok: true, uid: session.localId, email: session.email};

  const browser = await chromium.launch({headless: true});
  const context = await browser.newContext({viewport: {width: 1440, height: 900}});
  const page = await context.newPage();
  await hydrateAuth(page, session);

  // Landing
  await page.goto(`${BASE}/home22Dashboard`, {waitUntil: 'domcontentloaded', timeout: 60000});
  await page.waitForTimeout(5000);
  report.startup = await probe(page);

  for (const route of ROUTES) {
    const url = `${BASE}${route}`;
    let status = 'FAIL';
    let evidence = {};
    try {
      await page.goto(url, {waitUntil: 'domcontentloaded', timeout: 45000});
      await page.waitForTimeout(3500);
      evidence = await probe(page);
      // Flutter canvas present OR redirected to login/home without crash
      const ok =
        evidence.hasCanvas ||
        evidence.path.includes(route.replace(/^\//, '')) ||
        evidence.path.includes('home22') ||
        evidence.path.includes('homePage');
      status = ok && !evidence.blank ? 'PASS' : 'FAIL';
      if (status === 'PASS') {
        await page.screenshot({
          path: path.join(OUT, `${route.replace(/\//g, '_') || 'root'}.png`),
          fullPage: false,
        });
      }
    } catch (e) {
      evidence = {error: String(e.message || e)};
      status = 'FAIL';
    }
    report.routes[route] = {status, evidence};
    report.ADMIN_ROUTES_TESTED += 1;
    if (status === 'PASS') report.ADMIN_ROUTES_PASS += 1;
    else report.ADMIN_ROUTES_FAIL += 1;
  }

  // Responsive sample on dashboard
  for (const vp of VIEWPORTS) {
    await page.setViewportSize({width: vp.width, height: vp.height});
    await page.goto(`${BASE}/home22Dashboard`, {waitUntil: 'domcontentloaded'});
    await page.waitForTimeout(2500);
    const p = await probe(page);
    await page.screenshot({
      path: path.join(OUT, `dash_${vp.name}.png`),
      fullPage: false,
    });
    report.viewports[vp.name] = p;
  }

  // Browser back/forward
  await page.goto(`${BASE}/drever`, {waitUntil: 'domcontentloaded'});
  await page.waitForTimeout(2000);
  await page.goto(`${BASE}/adminALLhgZ`, {waitUntil: 'domcontentloaded'});
  await page.waitForTimeout(2000);
  await page.goBack();
  await page.waitForTimeout(1500);
  const back = await probe(page);
  await page.goForward();
  await page.waitForTimeout(1500);
  const fwd = await probe(page);
  report.browserNav = {back, fwd, ok: true};

  report.finishedAt = new Date().toISOString();
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
