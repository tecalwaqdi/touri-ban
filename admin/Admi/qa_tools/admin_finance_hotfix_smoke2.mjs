/**
 * Focused settlement detail + agent finance semantics smoke.
 */
import {chromium} from 'playwright';
import fs from 'node:fs';

const BASE = process.env.BASE_URL || 'https://tutorial-multi-language-70gx4j.web.app/admin';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const EMAIL = process.env.ADMIN_QA_EMAIL || '';
const PASSWORD = process.env.ADMIN_QA_PASSWORD || '';
const SETTLEMENT_DOC = 'iOYduoa6IXPdkUUdhHLq';
const OUT = '/tmp/admin_hotfix_smoke2';
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

async function enableSemantics(page) {
  await page.evaluate(() => {
    window.__flutter_web_set_semantics_enabled?.(true);
    document.querySelector('[aria-label="Enable accessibility"]')?.click();
  });
  await page.keyboard.press('Alt+A').catch(() => {});
  await page.waitForTimeout(800);
}

async function dumpText(page) {
  return page.evaluate(() => {
    const aria = Array.from(
      document.querySelectorAll('flt-semantics, [aria-label]'),
    )
      .map((e) => e.getAttribute('aria-label') || e.textContent || '')
      .join(' | ');
    return `${document.body?.innerText || ''} ${aria}`.replace(/\s+/g, ' ').trim();
  });
}

async function main() {
  const session = await restSignIn();
  const browser = await chromium.launch({headless: true});
  const page = await (await browser.newContext({viewport: {width: 1440, height: 900}, locale: 'ar'})).newPage();
  await page.addInitScript(
    ({session, apiKey}) => {
      const key = `firebase:authUser:${apiKey}:[DEFAULT]`;
      localStorage.setItem(
        key,
        JSON.stringify({
          uid: session.localId,
          email: session.email,
          emailVerified: true,
          isAnonymous: false,
          stsTokenManager: {
            refreshToken: session.refreshToken,
            accessToken: session.idToken,
            expirationTime: Date.now() + 3600000,
          },
          apiKey,
          appName: '[DEFAULT]',
        }),
      );
    },
    {session, apiKey: API_KEY},
  );

  const report = {};

  // Settlement detail by doc id
  await page.goto(`${BASE}/adminSettlementDetails?settlementId=${SETTLEMENT_DOC}`, {
    waitUntil: 'domcontentloaded',
    timeout: 90000,
  });
  await page.waitForTimeout(7000);
  await enableSemantics(page);
  await page.waitForTimeout(2000);
  await page.screenshot({path: `${OUT}/settlement_detail.png`, fullPage: false});
  let text = await dumpText(page);
  report.settlement = {
    textSample: text.slice(0, 1200),
    hasMusadada: text.includes('مسددة'),
    hasDirectionAr: text.includes('مستحق للشركة على المندوب'),
    rawSettled: /\bsettled\b/i.test(text),
    rawDirection: /DRIVER_PAYS_COMPANY/.test(text),
    notFound: text.includes('التسوية غير موجودة'),
    hasMoney: /ر\.س|7\.50|0\.00/.test(text),
  };

  // Settlements list
  await page.goto(`${BASE}/adminSettlements`, {waitUntil: 'domcontentloaded'});
  await page.waitForTimeout(6000);
  await enableSemantics(page);
  await page.screenshot({path: `${OUT}/settlements_list.png`, fullPage: false});
  text = await dumpText(page);
  report.settlementsList = {
    hasMusadada: text.includes('مسددة'),
    rawSettled: /\bsettled\b/i.test(text),
    rawDirection: /DRIVER_PAYS_COMPANY/.test(text),
    sample: text.slice(0, 800),
  };

  // Agent finance with longer wait + semantics
  await page.goto(`${BASE}/adminFinanceAgents`, {waitUntil: 'domcontentloaded'});
  await page.waitForTimeout(10000);
  await enableSemantics(page);
  await page.screenshot({path: `${OUT}/agent_finance.png`, fullPage: false});
  text = await dumpText(page);
  report.agentFinance = {
    hasZeroMsg: text.includes('لا نشاط مالي مثبت'),
    hasError: text.includes('تعذر تحميل البيانات'),
    hasSpinnerOnly: text.length < 80 && !text.includes('وكيل'),
    hasZeroMoney: /0\.00/.test(text),
    sample: text.slice(0, 900),
  };

  // Bookings completed drill-down
  await page.goto(`${BASE}/adminALLhgZ`, {waitUntil: 'domcontentloaded'});
  await page.waitForTimeout(10000);
  await enableSemantics(page);
  text = await dumpText(page);
  const completed = text.match(/المكتملة\s*(\d+)/);
  report.bookings = {
    completedKpi: completed ? Number(completed[1]) : null,
    sample: text.slice(0, 900),
  };
  // click completed via semantics
  try {
    await page.locator('flt-semantics').filter({hasText: /المكتملة/}).first().click({force: true, timeout: 5000});
    await page.waitForTimeout(7000);
    await enableSemantics(page);
    text = await dumpText(page);
    const results = text.match(/النتائج\s*(\d+)/);
    report.bookings.drillResults = results ? Number(results[1]) : null;
    report.bookings.after = text.slice(0, 700);
    await page.screenshot({path: `${OUT}/bookings_completed.png`, fullPage: false});
  } catch (e) {
    report.bookings.clickError = String(e);
  }

  fs.writeFileSync(`${OUT}/report.json`, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
