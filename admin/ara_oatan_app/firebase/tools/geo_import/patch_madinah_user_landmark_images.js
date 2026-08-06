'use strict';

/**
 * Patch Madinah user photos + rename Qatrah → Atrah café.
 *
 * Usage:
 *   node patch_madinah_user_landmark_images.js           # dry-run
 *   node patch_madinah_user_landmark_images.js --apply
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
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'toury-madinah-lm-'));

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const MAX_DATA_URL_BYTES = 550 * 1024;

const ATRAH_NAMES = {
  ar: 'مقهى عطرة',
  en: 'Atrah Café',
  ru: 'Кафе «Атра»',
  ky: 'Атра кафеси',
};

const MAP = [
  {
    id: 'lm_sa_madinah_uthman-farm',
    file: 'madinah_uthman_farm.png',
    source: 'user_farm_photo',
    ar: 'مزرعة عثمان بن عفان رضي الله عنه',
  },
  {
    id: 'lm_sa_madinah_qatrah-cafe',
    file: 'madinah_atrah_cafe.png',
    source: 'user_atrah_cafe_photo',
    ar: 'مقهى عطرة',
    rename: ATRAH_NAMES,
  },
];

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

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
    if (size <= maxBytes) return { path: out, size, width, quality };
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
  return { path: last, size: fs.statSync(last).size, width: 640, quality: 35 };
}

function toDataUrl(localPath) {
  const compressed = compressToJpeg(localPath, MAX_DATA_URL_BYTES);
  const b64 = fs.readFileSync(compressed.path).toString('base64');
  return {
    dataUrl: `data:image/jpeg;base64,${b64}`,
    compressedBytes: compressed.size,
  };
}

function firestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val)
      ? { integerValue: String(val) }
      : { doubleValue: val };
  }
  if (typeof val === 'object') {
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

async function patchMkan(idToken, id, fields) {
  const bodyFields = {};
  for (const [k, v] of Object.entries(fields)) {
    bodyFields[k] = firestoreValue(v);
  }
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  const res = await fetch(`${DOCS}/mkan/${id}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: bodyFields }),
  });
  if (!res.ok) throw new Error(`PATCH mkan/${id}: ${await res.text()}`);
}

function updateStaging(id, patch) {
  const file = path.join(STAGING, `${id}.json`);
  const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
  Object.assign(doc, patch);
  doc.__writtenAt = new Date().toISOString();
  fs.writeFileSync(file, JSON.stringify(doc, null, 2), 'utf8');
}

async function main() {
  const report = { at: new Date().toISOString(), apply: APPLY, mapped: [] };
  const dataUrls = new Set();

  for (const row of MAP) {
    const local = path.join(ASSETS, row.file);
    if (!fs.existsSync(local)) throw new Error(`missing asset: ${local}`);
    const { dataUrl, compressedBytes } = toDataUrl(local);
    if (dataUrls.has(dataUrl.slice(0, 200))) {
      throw new Error(`duplicate data-url for ${row.id}`);
    }
    dataUrls.add(dataUrl.slice(0, 200));

    const patch = {
      img1: dataUrl,
      img_source: `user_photo_${row.source}`,
      images_license_verified: true,
    };
    if (row.rename) {
      patch.naim = row.rename.ar;
      patch.names_i18n = row.rename;
    }

    updateStaging(row.id, patch);
    report.mapped.push({
      id: row.id,
      ar: row.ar,
      source: row.source,
      asset: `assets/images/landmarks/${row.file}`,
      compressedBytes,
      renamed: Boolean(row.rename),
      status: APPLY ? 'pending' : 'staging-only',
    });
  }

  if (APPLY) {
    const idToken = await getIdToken();
    for (const row of MAP) {
      const stagingFile = path.join(STAGING, `${row.id}.json`);
      const doc = JSON.parse(fs.readFileSync(stagingFile, 'utf8'));
      const fields = {
        img1: doc.img1,
        img_source: doc.img_source,
        images_license_verified: true,
      };
      if (row.rename) {
        fields.naim = doc.naim;
        fields.names_i18n = doc.names_i18n;
      }
      await patchMkan(idToken, row.id, fields);
      const entry = report.mapped.find((x) => x.id === row.id);
      entry.status = 'patched';
      console.log('patched', row.id);
      await sleep(120);
    }
  } else {
    console.log('Dry-run: staging updated. Pass --apply for Firestore.');
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'madinah_user_landmark_images.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Report:', out);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
