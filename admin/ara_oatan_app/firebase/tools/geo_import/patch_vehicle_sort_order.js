'use strict';

/**
 * Patch canonical Toury vehicle display order (small → large).
 *
 * Usage:
 *   node patch_vehicle_sort_order.js           # staging only
 *   node patch_vehicle_sort_order.js --apply   # staging + Firestore
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

/** Canonical doc id → display order (1 = first in list). */
const SORT_MAP = {
  economy: 1,
  suv_family: 2,
  offroad_4x4: 3,
  luxury: 4,
  coach_mini: 5,
  medium_bus: 6,
  coach_tour: 7,
  wheelchair: 8,
  van_vip: 9,
};

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

async function patchTypeCar(idToken, id, sortOrder) {
  const mask = [
    'updateMask.fieldPaths=sort_order',
    'updateMask.fieldPaths=num_trteb',
  ].join('&');
  const res = await fetch(
    `${DOCS}/type_car/${encodeURIComponent(id)}?${mask}`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: {
          sort_order: { integerValue: String(sortOrder) },
          num_trteb: { integerValue: String(sortOrder) },
        },
      }),
    },
  );
  if (!res.ok) throw new Error(`PATCH type_car/${id}: ${await res.text()}`);
}

function updateStaging(id, sortOrder) {
  const file = path.join(STAGING, `${id}.json`);
  if (!fs.existsSync(file)) return { id, status: 'staging-missing' };
  const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
  const prev = { sort_order: doc.sort_order, num_trteb: doc.num_trteb };
  doc.sort_order = sortOrder;
  doc.num_trteb = sortOrder;
  doc.__writtenAt = new Date().toISOString();
  fs.writeFileSync(file, JSON.stringify(doc, null, 2), 'utf8');
  return {
    id,
    prev,
    next: { sort_order: sortOrder, num_trteb: sortOrder },
    status: 'staging-ok',
  };
}

async function main() {
  const report = {
    at: new Date().toISOString(),
    apply: APPLY,
    order: SORT_MAP,
    staging: [],
    firestore: [],
  };

  for (const [id, sortOrder] of Object.entries(SORT_MAP)) {
    report.staging.push(updateStaging(id, sortOrder));
  }

  if (APPLY) {
    const idToken = await getIdToken();
    for (const [id, sortOrder] of Object.entries(SORT_MAP)) {
      await patchTypeCar(idToken, id, sortOrder);
      report.firestore.push({ id, sort_order: sortOrder, status: 'ok' });
      console.log('patched', id, '→', sortOrder);
    }
  } else {
    console.log('staging-only (pass --apply to write Firestore)');
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'vehicle_sort_order_patch.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('report', out);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
