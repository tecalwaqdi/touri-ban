/**
 * Stage E — Admin Drivers visual QA (drivers surfaces only).
 * Usage: BASE_URL=http://127.0.0.1:4173 node scripts/phase_stage_e_drivers_visual_qa.mjs
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_stage_e_drivers');
const BASE = process.env.BASE_URL || 'http://127.0.0.1:4173';

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
  { key: 'drivers_list', path: '/admindrever' },
  { key: 'driver_activation', path: '/DriverActivation' },
];

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

async function setLocale(context, code) {
  await context.addInitScript((locale) => {
    try {
      localStorage.setItem('flutter.__locale_key__', `"${locale}"`);
      localStorage.setItem('__locale_key__', `"${locale}"`);
    } catch (_) {}
  }, code);
}

async function probeOverflow(page) {
  return page.evaluate(() => {
    const doc = document.documentElement;
    const scrollW = Math.max(doc.scrollWidth, doc.body?.scrollWidth || 0);
    return scrollW > doc.clientWidth + 2;
  });
}

const report = { overflow: [], screenshots: 0, errors: [] };

ensureDir(OUT);

const browser = await chromium.launch({ headless: true });
for (const locale of LOCALES) {
  for (const vp of VIEWPORTS) {
    const context = await browser.newContext({
      viewport: { width: vp.width, height: vp.height },
    });
    await setLocale(context, locale.code);
    const page = await context.newPage();
    for (const route of ROUTES) {
      const url = `${BASE}${route.path}`;
      try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 });
        await page.waitForTimeout(2500);
        const overflow = await probeOverflow(page);
        const file = path.join(OUT, locale.code, vp.name, `${route.key}.png`);
        ensureDir(path.dirname(file));
        await page.screenshot({ path: file, fullPage: true });
        report.screenshots++;
        if (overflow) {
          report.overflow.push(`${locale.code}/${vp.name}/${route.key}`);
        }
      } catch (e) {
        report.errors.push(`${locale.code}/${vp.name}/${route.key}: ${String(e.message).slice(0, 120)}`);
      }
    }
    await context.close();
  }
}
await browser.close();

console.log(JSON.stringify({ ADMIN_VISUAL_QA: report }, null, 2));
