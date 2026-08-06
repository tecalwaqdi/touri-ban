'use strict';

/**
 * Patch canonical Toury vehicle hourly rates + minimum hours (9 categories).
 *
 * Usage:
 *   node patch_vehicle_prices.js           # staging only
 *   node patch_vehicle_prices.js --apply   # staging + Firestore
 */

const fs = require('fs');
const path = require('path');

const APPLY = process.argv.includes('--apply');
const ROOT = __dirname;
const STAGING = path.join(ROOT, 'staging/firestore/type_car');
const REPORTS = path.join(ROOT, 'reports');

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

/** Canonical doc id → { sr (SAR/hour), agl_saat (min hours) } */
const PRICE_MAP = {
  economy: { sr: 100, agl_saat: 3, ar: 'سيارة اقتصادية' },
  suv_family: { sr: 150, agl_saat: 3, ar: 'سيارة عائلية' },
  offroad_4x4: { sr: 150, agl_saat: 3, ar: 'سيارة دفع رباعي' },
  luxury: { sr: 250, agl_saat: 3, ar: 'سيارة فارهة' },
  coach_mini: { sr: 100, agl_saat: 5, ar: 'حافلة صغيرة' },
  medium_bus: { sr: 120, agl_saat: 5, ar: 'حافلة متوسطة (25 راكب)' },
  coach_tour: { sr: 180, agl_saat: 5, ar: 'حافلة كبيرة (49 راكب)' },
  wheelchair: { sr: 150, agl_saat: 5, ar: 'حافلة ذوي الاحتياجات الخاصة' },
  van_vip: { sr: 300, agl_saat: 5, ar: 'حافلة VIP' },
};

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function getIdToken() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      }),
    },
  );
  const j = await res.json();
  if (!j.idToken) throw new Error(j.error?.message || 'auth failed');
  return j.idToken;
}

async function patchTypeCar(idToken, id, sr, aglSaat) {
  const mask = [
    'updateMask.fieldPaths=sr',
    'updateMask.fieldPaths=agl_saat',
  ].join('&');
  const res = await fetch(`${DOCS}/type_car/${encodeURIComponent(id)}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fields: {
        sr: { integerValue: String(sr) },
        agl_saat: { integerValue: String(aglSaat) },
      },
    }),
  });
  if (!res.ok) throw new Error(`PATCH type_car/${id}: ${await res.text()}`);
}

function updateStaging(id, sr, aglSaat) {
  const file = path.join(STAGING, `${id}.json`);
  if (!fs.existsSync(file)) return { id, status: 'staging-missing' };
  const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
  const prev = { sr: doc.sr, agl_saat: doc.agl_saat };
  doc.sr = sr;
  doc.agl_saat = aglSaat;
  doc.__writtenAt = new Date().toISOString();
  fs.writeFileSync(file, JSON.stringify(doc, null, 2), 'utf8');
  return { id, prev, next: { sr, agl_saat: aglSaat }, status: 'staging-ok' };
}

async function main() {
  const report = {
    at: new Date().toISOString(),
    apply: APPLY,
    prices: PRICE_MAP,
    results: [],
  };

  for (const [id, row] of Object.entries(PRICE_MAP)) {
    const staging = updateStaging(id, row.sr, row.agl_saat);
    report.results.push({ ...staging, ar: row.ar });
  }

  if (APPLY) {
    const idToken = await getIdToken();
    for (const [id, row] of Object.entries(PRICE_MAP)) {
      await patchTypeCar(idToken, id, row.sr, row.agl_saat);
      const entry = report.results.find((r) => r.id === id);
      entry.firestore = 'patched';
      console.log('patched', id, row.sr, 'SAR/h', row.agl_saat, 'min hrs');
      await sleep(100);
    }
  } else {
    console.log('Dry-run: staging updated. Pass --apply for Firestore.');
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'vehicle_prices_patch.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Report:', out);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
