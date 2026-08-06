'use strict';

/**
 * Patch Taif Tanal Resort: user photo + rename Tilal → Tanal.
 *
 * Usage:
 *   node patch_taif_tanal_resort.js           # dry-run
 *   node patch_taif_tanal_resort.js --apply
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const os = require('os');

const APPLY = process.argv.includes('--apply');
const ROOT = __dirname;
const STAGING = path.join(ROOT, 'staging/firestore/mkan');
const ASSETS = path.resolve(ROOT, '../../../assets/images/landmarks');
const REPORTS = path.join(ROOT, 'reports');
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'toury-taif-tanal-'));

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const MAX_DATA_URL_BYTES = 550 * 1024;

const ID = 'lm_sa_taif_tilal-resort';
const FILE = 'taif_tanal_resort.png';
const NAMES = {
  ar: 'منتجع تنال',
  en: 'Tanal Resort',
  ru: 'Курорт Танал',
  ky: 'Танал курорту',
};

function compressToJpeg(srcPath, maxBytes) {
  let width = 1400;
  let quality = 70;
  for (let i = 0; i < 10; i++) {
    const out = path.join(
      TMP,
      `c_${width}_${quality}_${path.basename(srcPath)}.jpg`,
    );
    execFileSync(
      'sips',
      [
        '-s',
        'format',
        'jpeg',
        '-s',
        'formatOptions',
        String(quality),
        '-Z',
        String(width),
        srcPath,
        '--out',
        out,
      ],
      { stdio: 'ignore' },
    );
    const size = fs.statSync(out).size;
    if (size <= maxBytes) return { path: out, size };
    if (quality > 40) quality -= 10;
    else width = Math.max(640, Math.floor(width * 0.8));
  }
  const last = path.join(TMP, `c_final_${path.basename(srcPath)}.jpg`);
  execFileSync(
    'sips',
    [
      '-s',
      'format',
      'jpeg',
      '-s',
      'formatOptions',
      '35',
      '-Z',
      '640',
      srcPath,
      '--out',
      last,
    ],
    { stdio: 'ignore' },
  );
  return { path: last, size: fs.statSync(last).size };
}

function firestoreValue(val) {
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'object' && val !== null) {
    const fields = {};
    for (const [k, v] of Object.entries(val)) fields[k] = firestoreValue(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
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

async function patchMkan(idToken, fields) {
  const bodyFields = {};
  for (const [k, v] of Object.entries(fields)) {
    bodyFields[k] = firestoreValue(v);
  }
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  const res = await fetch(`${DOCS}/mkan/${ID}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: bodyFields }),
  });
  if (!res.ok) throw new Error(`PATCH mkan/${ID}: ${await res.text()}`);
}

async function main() {
  const local = path.join(ASSETS, FILE);
  if (!fs.existsSync(local)) throw new Error(`missing asset: ${local}`);
  const compressed = compressToJpeg(local, MAX_DATA_URL_BYTES);
  const dataUrl = `data:image/jpeg;base64,${fs
    .readFileSync(compressed.path)
    .toString('base64')}`;

  const patch = {
    img1: dataUrl,
    img_source: 'user_photo_IMG_6979',
    images_license_verified: true,
    naim: NAMES.ar,
    names_i18n: NAMES,
  };

  const stagingFile = path.join(STAGING, `${ID}.json`);
  const doc = JSON.parse(fs.readFileSync(stagingFile, 'utf8'));
  Object.assign(doc, patch);
  doc.__writtenAt = new Date().toISOString();
  fs.writeFileSync(stagingFile, JSON.stringify(doc, null, 2), 'utf8');

  const report = {
    at: new Date().toISOString(),
    apply: APPLY,
    id: ID,
    ar: NAMES.ar,
    names_i18n: NAMES,
    asset: `assets/images/landmarks/${FILE}`,
    compressedBytes: compressed.size,
    status: APPLY ? 'pending' : 'staging-only',
  };

  if (APPLY) {
    const idToken = await getIdToken();
    await patchMkan(idToken, patch);
    report.status = 'patched';
    console.log('patched', ID, NAMES.ar);
  } else {
    console.log('Dry-run: staging updated. Pass --apply for Firestore.');
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'taif_tanal_resort_patch.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Report:', out);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
