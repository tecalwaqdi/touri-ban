/**
 * Phase 8C — Live browser Visual QA against Admin release build.
 * No financial writes. Screenshots + overflow probes only.
 *
 * Usage:
 *   BASE_URL=http://127.0.0.1:4173 node scripts/phase_8c_visual_qa.mjs
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_8c');
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4173';

const VIEWPORTS = [
  { name: '1920x1080', width: 1920, height: 1080 },
  { name: '1440x900', width: 1440, height: 900 },
  { name: '1366x768', width: 1366, height: 768 },
  { name: '1280x800', width: 1280, height: 800 },
  { name: 'tablet_1024x768', width: 1024, height: 768 },
];

const LOCALES = [
  { code: 'ar', dir: 'rtl', label: 'Arabic' },
  { code: 'en', dir: 'ltr', label: 'English' },
  { code: 'ur', dir: 'rtl', label: 'Urdu' },
];

const ROUTES = [
  { key: 'login', path: '/' },
  { key: 'dashboard', path: '/home22Dashboard' },
  { key: 'orders', path: '/adminALLhgZ' },
  { key: 'drivers', path: '/admindrever' },
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

async function setFlutterLocale(context, code) {
  // Flutter web SharedPreferences stores under flutter.* in localStorage.
  await context.addInitScript((locale) => {
    try {
      localStorage.setItem('flutter.__locale_key__', `"${locale}"`);
      localStorage.setItem('flutter.__locale_user_picked__', 'true');
      localStorage.setItem('__locale_key__', `"${locale}"`);
      localStorage.setItem('__locale_user_picked__', 'true');
    } catch (_) {}
  }, code);
}

async function probeOverflow(page) {
  return page.evaluate(() => {
    const doc = document.documentElement;
    const body = document.body;
    const scrollW = Math.max(doc.scrollWidth, body?.scrollWidth || 0);
    const clientW = doc.clientWidth;
    const horizontalOverflow = scrollW > clientW + 2;

    const offenders = [];
    const all = Array.from(document.querySelectorAll('body *'));
    for (const el of all.slice(0, 2500)) {
      const r = el.getBoundingClientRect();
      if (r.width < 1 || r.height < 1) continue;
      if (r.right > clientW + 4 || r.left < -4) {
        const tag = el.tagName.toLowerCase();
        const cls = (el.className && String(el.className).slice(0, 80)) || '';
        offenders.push({
          tag,
          cls,
          left: Math.round(r.left),
          right: Math.round(r.right),
          text: (el.innerText || '').trim().slice(0, 60),
        });
        if (offenders.length >= 12) break;
      }
    }

    const dir = document.documentElement.getAttribute('dir')
      || getComputedStyle(document.body).direction
      || '';
    const sampleText = (document.body?.innerText || '').replace(/\s+/g, ' ').slice(0, 180);

    return {
      horizontalOverflow,
      scrollW,
      clientW,
      dir,
      sampleText,
      offenders,
      title: document.title,
      url: location.href,
    };
  });
}

async function waitForFlutter(page) {
  await page.waitForTimeout(2500);
  // Flutter canvaskit / html renderer: wait for flutter-view or flt-*
  try {
    await page.waitForSelector('flutter-view, flt-glass-pane, canvas, body', {
      timeout: 15000,
    });
  } catch (_) {}
  await page.waitForTimeout(1500);
}

async function main() {
  ensureDir(OUT);
  const report = {
    startedAt: new Date().toISOString(),
    baseUrl: BASE,
    results: [],
    summary: { pass: 0, warn: 0, fail: 0, blocked_auth: 0 },
  };

  const browser = await chromium.launch({ headless: true });
  try {
    for (const locale of LOCALES) {
      for (const vp of VIEWPORTS) {
        const context = await browser.newContext({
          viewport: { width: vp.width, height: vp.height },
          locale: locale.code === 'ar' ? 'ar-SA' : locale.code === 'ur' ? 'ur-PK' : 'en-US',
        });
        await setFlutterLocale(context, locale.code);
        const page = await context.newPage();

        // Login / shell first
        const shellUrl = `${BASE}/#/`;
        await page.goto(shellUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
        await waitForFlutter(page);

        const shellProbe = await probeOverflow(page);
        const shotDir = path.join(OUT, locale.code, vp.name);
        ensureDir(shotDir);
        const shellShot = path.join(shotDir, '00_login_or_shell.png');
        await page.screenshot({ path: shellShot, fullPage: false });

        const entry = {
          locale: locale.code,
          expectedDir: locale.dir,
          viewport: vp.name,
          shell: {
            ...shellProbe,
            screenshot: path.relative(OUT, shellShot),
          },
          pages: [],
        };

        // Heuristic: if login form visible and no admin chrome, mark auth-gated
        const bodyText = shellProbe.sampleText.toLowerCase();
        const looksLikeLogin =
          bodyText.includes('login') ||
          bodyText.includes('تسجيل') ||
          bodyText.includes('لاگ ان') ||
          bodyText.includes('email') ||
          bodyText.includes('password') ||
          bodyText.includes('كلمة');

        for (const route of ROUTES) {
          if (route.key === 'login') continue;
          const url = `${BASE}/#${route.path}`;
          let pageResult = { key: route.key, path: route.path };
          try {
            await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
            await waitForFlutter(page);
            const probe = await probeOverflow(page);
            const shot = path.join(shotDir, `${route.key}.png`);
            await page.screenshot({ path: shot, fullPage: false });
            pageResult = {
              ...pageResult,
              ...probe,
              screenshot: path.relative(OUT, shot),
              authGated: looksLikeLogin && (probe.sampleText || '').toLowerCase().includes('login')
                || (probe.url || '').includes('homePage')
                || (probe.url || '').endsWith('/#/')
                || (probe.url || '').endsWith('/#')
                || false,
            };
            // If redirected to login, mark
            if (looksLikeLogin && route.key !== 'login') {
              const stillLogin =
                (probe.sampleText || '').toLowerCase().match(/login|تسجيل|لاگ ان|password|كلمة المرور/);
              if (stillLogin) pageResult.authGated = true;
            }
          } catch (e) {
            pageResult.error = String(e.message || e).slice(0, 200);
          }
          entry.pages.push(pageResult);
        }

        // Finance money formatting probe on login/shell via injecting a temporary overlay
        // (does not touch app state — visual only)
        await page.goto(shellUrl, { waitUntil: 'domcontentloaded', timeout: 45000 });
        await waitForFlutter(page);
        await page.evaluate((isRtl) => {
          const box = document.createElement('div');
          box.id = 'qa-money-probe';
          box.setAttribute('dir', isRtl ? 'rtl' : 'ltr');
          box.style.cssText =
            'position:fixed;z-index:99999;left:12px;top:12px;right:12px;padding:12px;' +
            'background:#111;color:#fff;font:16px/1.4 Cairo,Arial,sans-serif;' +
            'display:flex;flex-direction:column;gap:6px;border-radius:8px;';
          const samples = [
            '804 SAR',
            '-804 SAR',
            '0 SAR',
            '1,245,678.50 SAR',
            'Driver Pays Company',
            'Company Pays Driver',
            'Debit / Credit',
          ];
          for (const s of samples) {
            const row = document.createElement('div');
            row.textContent = s;
            row.style.unicodeBidi = 'isolate';
            row.style.direction = 'ltr';
            row.style.textAlign = isRtl ? 'right' : 'left';
            box.appendChild(row);
          }
          document.body.appendChild(box);
        }, locale.dir === 'rtl');
        const moneyShot = path.join(shotDir, 'money_formatting_probe.png');
        await page.screenshot({ path: moneyShot, fullPage: false });
        entry.moneyProbeScreenshot = path.relative(OUT, moneyShot);

        // Gate scoring
        const overflowHits = [entry.shell, ...entry.pages].filter(
          (p) => p && p.horizontalOverflow,
        ).length;
        const authBlocked = entry.pages.filter((p) => p.authGated).length;
        entry.overflowHits = overflowHits;
        entry.authGatedPages = authBlocked;
        if (overflowHits > 0) {
          entry.verdict = 'FAIL_OVERFLOW';
          report.summary.fail++;
        } else if (authBlocked >= ROUTES.length - 2) {
          entry.verdict = 'AUTH_GATED';
          report.summary.blocked_auth++;
        } else {
          entry.verdict = 'PASS_SHELL';
          report.summary.pass++;
        }

        report.results.push(entry);
        await context.close();
      }
    }
  } finally {
    await browser.close();
  }

  report.finishedAt = new Date().toISOString();
  const reportPath = path.join(OUT, 'report.json');
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(JSON.stringify({
    reportPath,
    summary: report.summary,
    sample: report.results.slice(0, 3).map((r) => ({
      locale: r.locale,
      viewport: r.viewport,
      verdict: r.verdict,
      overflowHits: r.overflowHits,
      authGatedPages: r.authGatedPages,
    })),
  }, null, 2));
}

main().catch((e) => {
  console.error(JSON.stringify({ ok: false, error: String(e.message || e) }));
  process.exit(1);
});
