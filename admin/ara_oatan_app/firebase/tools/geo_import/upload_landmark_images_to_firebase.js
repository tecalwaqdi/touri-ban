'use strict';

/**
 * Upload SA landmark (and optional region) images into Firebase.
 * Tries Firebase Storage first; on 403 falls back to compressed data URLs
 * in Firestore img1 (same approach as vehicle images).
 *
 * Usage:
 *   node upload_landmark_images_to_firebase.js           # dry-run
 *   node upload_landmark_images_to_firebase.js --apply
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const os = require('os');

const APPLY = process.argv.includes('--apply');
const ROOT = __dirname;
const STAGING_MKAN = path.join(ROOT, 'staging/firestore/mkan');
const STAGING_CITIES = path.join(ROOT, 'staging/firestore/cities');
const STAGING_VILLAGES = path.join(ROOT, 'staging/firestore/villages');
const ASSETS = path.resolve(ROOT, '../../../assets/images/landmarks');
const REPORTS = path.join(ROOT, 'reports');
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'toury-lm-img-'));

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const BUCKET =
  process.env.SEED_STORAGE_BUCKET ||
  'tutorial-multi-language-70gx4j.firebasestorage.app';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const MAX_DATA_URL_BYTES = 550 * 1024; // leave room for other Firestore fields

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function mimeFor(file) {
  const ext = path.extname(file).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  if (ext === '.jpeg' || ext === '.jpg') return 'image/jpeg';
  return 'image/jpeg';
}

function compressToJpeg(srcPath, maxBytes) {
  let width = 1400;
  let quality = 70;
  for (let i = 0; i < 10; i++) {
    const out = path.join(TMP, `c_${width}_${quality}_${path.basename(srcPath)}.jpg`);
    try {
      execFileSync(
        'sips',
        ['-s', 'format', 'jpeg', '-s', 'formatOptions', String(quality), '-Z', String(width), srcPath, '--out', out],
        { stdio: 'ignore' },
      );
    } catch (e) {
      throw new Error(`sips failed for ${srcPath}: ${e.message}`);
    }
    const size = fs.statSync(out).size;
    if (size <= maxBytes) return { path: out, size, width, quality };
    if (quality > 40) quality -= 10;
    else width = Math.max(640, Math.floor(width * 0.8));
  }
  const last = path.join(TMP, `c_final_${path.basename(srcPath)}.jpg`);
  execFileSync(
    'sips',
    ['-s', 'format', 'jpeg', '-s', 'formatOptions', '35', '-Z', '640', srcPath, '--out', last],
    { stdio: 'ignore' },
  );
  return { path: last, size: fs.statSync(last).size, width: 640, quality: 35 };
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
  return { idToken: j.idToken, uid: j.localId };
}

async function uploadToStorage(idToken, objectPath, filePath, contentType) {
  const bytes = fs.readFileSync(filePath);
  const encodedName = encodeURIComponent(objectPath);
  const url =
    `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o` +
    `?name=${encodedName}&uploadType=media`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': contentType || 'image/jpeg',
    },
    body: bytes,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`storage ${res.status}: ${text.slice(0, 180)}`);
  }
  const meta = await res.json();
  const token = meta.downloadTokens;
  const base =
    `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/` +
    `${encodedName}?alt=media`;
  return token ? `${base}&token=${token}` : base;
}

async function patchMkan(idToken, id, fields) {
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  const body = { fields: {} };
  for (const [k, v] of Object.entries(fields)) {
    if (typeof v === 'boolean') body.fields[k] = { booleanValue: v };
    else body.fields[k] = { stringValue: String(v) };
  }
  const res = await fetch(`${DOCS}/mkan/${id}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`PATCH mkan/${id}: ${await res.text()}`);
}

async function patchCollection(idToken, collection, id, fields) {
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  const body = { fields: {} };
  for (const [k, v] of Object.entries(fields)) {
    body.fields[k] = { stringValue: String(v) };
  }
  const res = await fetch(`${DOCS}/${collection}/${id}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    throw new Error(`PATCH ${collection}/${id}: ${await res.text()}`);
  }
}

function collectAssetLandmarks() {
  const out = [];
  for (const f of fs.readdirSync(STAGING_MKAN).filter((x) => x.startsWith('lm_sa_'))) {
    const doc = JSON.parse(fs.readFileSync(path.join(STAGING_MKAN, f), 'utf8'));
    const img1 = doc.img1 || '';
    if (!img1.startsWith('assets/images/landmarks/')) continue;
    const fileName = path.basename(img1);
    const local = path.join(ASSETS, fileName);
    if (!fs.existsSync(local)) {
      out.push({ id: doc.geo_import_id, status: 'missing-file', img1 });
      continue;
    }
    out.push({
      id: doc.geo_import_id,
      fileName,
      local,
      bytes: fs.statSync(local).size,
      mime: mimeFor(fileName),
    });
  }
  return out;
}

async function downloadRemote(url, outPath) {
  const res = await fetch(url, {
    headers: { 'User-Agent': 'TouryLandmarkUpload/1.0' },
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`download ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 2000) throw new Error('download too small');
  fs.writeFileSync(outPath, buf);
  return outPath;
}

function collectRemoteSaToMirror() {
  /** Remote http images for SA landmarks/regions we want mirrored into Firebase. */
  const items = [];
  for (const f of fs.readdirSync(STAGING_MKAN).filter((x) => x.startsWith('lm_sa_'))) {
    const doc = JSON.parse(fs.readFileSync(path.join(STAGING_MKAN, f), 'utf8'));
    const img1 = doc.img1 || '';
    if (!/^https?:\/\//i.test(img1)) continue;
    if (img1.includes('firebasestorage.googleapis.com')) continue;
    if (img1.startsWith('data:')) continue;
    items.push({
      collection: 'mkan',
      id: doc.geo_import_id,
      remote: img1,
    });
  }
  for (const [col, dir] of [
    ['cities', STAGING_CITIES],
    ['villages', STAGING_VILLAGES],
  ]) {
    for (const f of fs.readdirSync(dir).filter((x) => x.includes('_sa_'))) {
      const doc = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
      const id = path.basename(f, '.json');
      const img1 = doc.img1 || '';
      if (!/^https?:\/\//i.test(img1)) continue;
      if (img1.includes('firebasestorage.googleapis.com')) continue;
      items.push({ collection: col, id, remote: img1 });
    }
  }
  return items;
}

async function materializeToFirebaseUrl(idToken, objectPath, localPath, mime) {
  try {
    const url = await uploadToStorage(idToken, objectPath, localPath, mime);
    return { url, kind: 'storage' };
  } catch (e) {
    const compressed = compressToJpeg(localPath, MAX_DATA_URL_BYTES);
    if (compressed.size > MAX_DATA_URL_BYTES) {
      throw new Error(
        `too large for data-url after compress: ${compressed.size} (${e.message})`,
      );
    }
    const b64 = fs.readFileSync(compressed.path).toString('base64');
    return {
      url: `data:image/jpeg;base64,${b64}`,
      kind: 'data-url',
      note: e.message,
      compressedBytes: compressed.size,
    };
  }
}

async function main() {
  const assets = collectAssetLandmarks();
  const remotes = collectRemoteSaToMirror();
  console.log(
    APPLY ? '=== APPLY ===' : '=== DRY RUN ===',
    'asset landmarks',
    assets.filter((x) => x.local).length,
    'remote to mirror',
    remotes.length,
  );

  const report = {
    at: new Date().toISOString(),
    apply: APPLY,
    storageBucket: BUCKET,
    assets: [],
    remotes: [],
    errors: [],
  };

  if (!APPLY) {
    for (const a of assets) {
      if (!a.local) {
        report.assets.push(a);
        continue;
      }
      console.log('would-upload', a.id, a.fileName, a.bytes);
      report.assets.push({ id: a.id, file: a.fileName, bytes: a.bytes, status: 'dry' });
    }
    for (const r of remotes) {
      console.log('would-mirror', r.collection, r.id);
      report.remotes.push({ ...r, status: 'dry' });
    }
  } else {
    const { idToken, uid } = await getIdToken();
    console.log('auth ok', uid);

    for (const a of assets) {
      if (!a.local) {
        report.errors.push(a);
        continue;
      }
      try {
        const objectPath = `landmarks/sa/${a.fileName.replace(/\.[^.]+$/, '')}.jpg`;
        const result = await materializeToFirebaseUrl(
          idToken,
          objectPath,
          a.local,
          a.mime,
        );
        await patchMkan(idToken, a.id, {
          img1: result.url,
          img_source: `firebase_${result.kind}`,
          images_license_verified: true,
        });
        // staging
        const stagingFile = path.join(STAGING_MKAN, `${a.id}.json`);
        if (fs.existsSync(stagingFile)) {
          const doc = JSON.parse(fs.readFileSync(stagingFile, 'utf8'));
          doc.img1 = result.url;
          doc.img_source = `firebase_${result.kind}`;
          doc.__writtenAt = new Date().toISOString();
          fs.writeFileSync(stagingFile, JSON.stringify(doc, null, 2));
        }
        console.log('ok', a.id, result.kind, result.compressedBytes || a.bytes);
        report.assets.push({
          id: a.id,
          file: a.fileName,
          kind: result.kind,
          status: 'patched',
        });
        await sleep(120);
      } catch (e) {
        console.error('FAIL', a.id, e.message);
        report.errors.push({ id: a.id, error: e.message });
      }
    }

    for (const r of remotes) {
      try {
        const tmpFile = path.join(TMP, `${r.collection}_${r.id}.img`);
        await downloadRemote(r.remote, tmpFile);
        await sleep(400);
        const objectPath = `landmarks/sa_remote/${r.collection}_${r.id}.jpg`;
        const result = await materializeToFirebaseUrl(
          idToken,
          objectPath,
          tmpFile,
          'image/jpeg',
        );
        if (r.collection === 'mkan') {
          await patchMkan(idToken, r.id, {
            img1: result.url,
            img_source: `firebase_${result.kind}_mirrored`,
            images_license_verified: true,
          });
          const stagingFile = path.join(STAGING_MKAN, `${r.id}.json`);
          if (fs.existsSync(stagingFile)) {
            const doc = JSON.parse(fs.readFileSync(stagingFile, 'utf8'));
            doc.img1 = result.url;
            doc.img_source = `firebase_${result.kind}_mirrored`;
            doc.__writtenAt = new Date().toISOString();
            fs.writeFileSync(stagingFile, JSON.stringify(doc, null, 2));
          }
        } else {
          await patchCollection(idToken, r.collection, r.id, {
            img1: result.url,
            img_source: `firebase_${result.kind}_mirrored`,
          });
          const stagingFile = path.join(
            r.collection === 'cities' ? STAGING_CITIES : STAGING_VILLAGES,
            `${r.id}.json`,
          );
          if (fs.existsSync(stagingFile)) {
            const doc = JSON.parse(fs.readFileSync(stagingFile, 'utf8'));
            doc.img1 = result.url;
            doc.img_source = `firebase_${result.kind}_mirrored`;
            doc.__writtenAt = new Date().toISOString();
            fs.writeFileSync(stagingFile, JSON.stringify(doc, null, 2));
          }
        }
        console.log('mirrored', r.collection, r.id, result.kind);
        report.remotes.push({
          collection: r.collection,
          id: r.id,
          kind: result.kind,
          status: 'patched',
        });
        await sleep(120);
      } catch (e) {
        console.error('MIRROR FAIL', r.collection, r.id, e.message);
        report.errors.push({
          collection: r.collection,
          id: r.id,
          error: e.message,
        });
      }
    }
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'upload_landmark_images_report.json');
  // Strip any accidental huge payloads
  const clean = {
    ...report,
    assets: report.assets.map((a) => ({
      id: a.id,
      file: a.file,
      kind: a.kind,
      status: a.status,
      bytes: a.bytes,
    })),
  };
  fs.writeFileSync(out, JSON.stringify(clean, null, 2));
  console.log('Report:', out);
  console.log(
    'summary assets',
    clean.assets.filter((a) => a.status === 'patched').length,
    'remotes',
    report.remotes.filter((r) => r.status === 'patched').length,
    'errors',
    report.errors.length,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
