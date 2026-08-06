'use strict';

/**
 * Patch Taif + Jeddah region/city card images (user photos only).
 *
 * Usage:
 *   node patch_taif_jeddah_region_images.js           # staging only
 *   node patch_taif_jeddah_region_images.js --apply
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const os = require('os');

const APPLY = process.argv.includes('--apply');
const ROOT = __dirname;
const STAGING = path.join(ROOT, 'staging/firestore');
const ASSETS = path.resolve(ROOT, '../../../assets/images/regions');
const REPORTS = path.join(ROOT, 'reports');
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'toury-region-img-'));

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const MAP = [
  {
    file: 'taif_region.png',
    source: 'IMG_6981',
    ar: 'الطائف',
    targets: [
      { col: 'cities', id: 'region_sa_taif' },
      { col: 'villages', id: 'city_sa_taif' },
    ],
  },
  {
    file: 'jeddah_region.png',
    source: 'IMG_6980',
    ar: 'جدة',
    targets: [
      { col: 'cities', id: 'region_sa_jeddah' },
      { col: 'villages', id: 'city_sa_jeddah' },
    ],
  },
];

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function compressToJpeg(srcPath, maxBytes, maxW = 1200) {
  let width = maxW;
  let quality = 65;
  for (let i = 0; i < 12; i++) {
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
    if (quality > 35) quality -= 8;
    else width = Math.max(480, Math.floor(width * 0.8));
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
      '30',
      '-Z',
      '480',
      srcPath,
      '--out',
      last,
    ],
    { stdio: 'ignore' },
  );
  return { path: last, size: fs.statSync(last).size };
}

function toDataUrl(filePath) {
  return `data:image/jpeg;base64,${fs.readFileSync(filePath).toString('base64')}`;
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

async function patchDoc(idToken, col, id, fields) {
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  const body = { fields: {} };
  for (const [k, v] of Object.entries(fields)) {
    if (typeof v === 'boolean') body.fields[k] = { booleanValue: v };
    else body.fields[k] = { stringValue: String(v) };
  }
  const res = await fetch(`${DOCS}/${col}/${encodeURIComponent(id)}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    throw new Error(`PATCH ${col}/${id}: ${await res.text()}`);
  }
}

async function main() {
  const report = { at: new Date().toISOString(), apply: APPLY, items: [] };
  const prepared = [];

  for (const row of MAP) {
    const local = path.join(ASSETS, row.file);
    if (!fs.existsSync(local)) throw new Error(`missing ${local}`);
    const imgC = compressToJpeg(local, 520 * 1024, 1200);
    const iconC = compressToJpeg(local, 80 * 1024, 400);
    const img = toDataUrl(imgC.path);
    const icon = toDataUrl(iconC.path);
    prepared.push({ ...row, img, icon, imgBytes: imgC.size, iconBytes: iconC.size });
  }

  // uniqueness across cities
  if (prepared[0].img === prepared[1].img) {
    throw new Error('Taif and Jeddah images must not be identical');
  }

  for (const row of prepared) {
    for (const t of row.targets) {
      const file = path.join(STAGING, t.col, `${t.id}.json`);
      if (!fs.existsSync(file)) throw new Error(`staging missing ${file}`);
      const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
      doc.img = row.img;
      doc.icon = row.icon;
      doc.img_source = `user_photo_${row.source}`;
      doc.__writtenAt = new Date().toISOString();
      fs.writeFileSync(file, JSON.stringify(doc, null, 2), 'utf8');
      report.items.push({
        col: t.col,
        id: t.id,
        ar: row.ar,
        source: row.source,
        imgBytes: row.imgBytes,
        iconBytes: row.iconBytes,
        status: APPLY ? 'pending' : 'staging-only',
      });
    }
  }

  if (APPLY) {
    const idToken = await getIdToken();
    for (const row of prepared) {
      for (const t of row.targets) {
        await patchDoc(idToken, t.col, t.id, {
          img: row.img,
          icon: row.icon,
          img_source: `user_photo_${row.source}`,
        });
        const entry = report.items.find(
          (x) => x.col === t.col && x.id === t.id,
        );
        entry.status = 'patched';
        console.log('patched', t.col, t.id, row.ar);
        await sleep(120);
      }
    }
  } else {
    console.log('Dry-run: staging updated. Pass --apply for Firestore.');
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'taif_jeddah_region_images.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Report:', out);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
