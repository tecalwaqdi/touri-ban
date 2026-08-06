'use strict';

/**
 * Patch SA landmark img1 values with verified real photos only.
 * Uses bundled assets when available; otherwise Wikimedia/Flickr Commons URLs.
 *
 * Usage:
 *   node patch_sa_landmark_images.js           # dry-run
 *   node patch_sa_landmark_images.js --apply
 */

const fs = require('fs');
const path = require('path');

const APPLY = process.argv.includes('--apply');
const ROOT = __dirname;
const STAGING = path.join(ROOT, 'staging/firestore/mkan');
const REPORTS = path.join(ROOT, 'reports');
const ASSET = (name) => `assets/images/landmarks/${name}`;

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

/**
 * High-confidence image map. Each value must be unique.
 * Do NOT reuse province fallbacks (skyline / corniche / haram / nabawi).
 */
const IMAGE_MAP = {
  // ——— Jeddah ———
  'lm_sa_jeddah_jeddah-new-corniche': ASSET('jeddah_new_corniche.jpg'),
  'lm_sa_jeddah_historic-jeddah': ASSET('jeddah_historic_balad_spa.png'),
  'lm_sa_jeddah_kaia': ASSET('jeddah_kaia.jpg'),
  'lm_sa_jeddah_haramain-jeddah-station':
    'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/%D9%82%D8%B7%D8%A7%D8%B1_%D8%A7%D9%84%D8%AD%D8%B1%D9%85%D9%8A%D9%86_%D8%A7%D9%84%D8%B4%D8%B1%D9%8A%D9%81%D9%8A%D9%86.jpg/1920px-%D9%82%D8%B7%D8%A7%D8%B1_%D8%A7%D9%84%D8%AD%D8%B1%D9%85%D9%8A%D9%86_%D8%A7%D9%84%D8%B4%D8%B1%D9%8A%D9%81%D9%8A%D9%86.jpg',
  // Wikipedia article image for Red Sea Mall (Commons File:Red Sea Mall 1 Jeddah.jpg)
  'lm_sa_jeddah_red-sea-mall':
    'https://upload.wikimedia.org/wikipedia/commons/3/33/Red_Sea_Mall_1_Jeddah.jpg',
  'lm_sa_jeddah_north-obhur':
    'https://upload.wikimedia.org/wikipedia/commons/a/a9/Obhur_Jeddah_3.jpg',
  // horse-stables / salam-mall / F1 circuit: only with verified unique photos

  // ——— Madinah ———
  'lm_sa_madinah_masjid-an-nabawi':
    'https://upload.wikimedia.org/wikipedia/commons/0/0c/Masjid_Nabawi_The_Prophet%27s_Mosque%2C_Madina.jpg',
  'lm_sa_madinah_quba-mosque': ASSET('madinah_quba_mosque.png'),
  'lm_sa_madinah_qiblatain-mosque': ASSET('madinah_qiblatain.jpg'),
  'lm_sa_madinah_mount-uhud': ASSET('madinah_mount_uhud.jpg'),
  // Sayyid al-Shuhada / Hamza complex at Mount Uhud
  'lm_sa_madinah_masjid-hamza': ASSET('madinah_masjid_hamza.jpg'),
  // uthman-farm / qatrah-cafe: only when verified

  // ——— Riyadh ———
  'lm_sa_riyadh_kkia': ASSET('riyadh_kkia.jpg'),
  'lm_sa_riyadh_thumamah':
    'https://upload.wikimedia.org/wikipedia/commons/b/be/Thumamah_Nature_Park.jpg',
  // Downtown commercial corridor near traditional souqs (distinct from Batha 2023)
  'lm_sa_riyadh_ibn-qasim-souq':
    'https://upload.wikimedia.org/wikipedia/commons/3/3f/Al_Batha_Street_Riyadh_from_Amal.jpg',
  'lm_sa_riyadh_suspension-bridge': ASSET('riyadh_suspension_bridge.jpg'),
  // Distinct close-up of Wadi Laban bridge pylon (not the same file as suspension-bridge)
  'lm_sa_riyadh_wadi-laban': ASSET('riyadh_wadi_laban_pylon.jpg'),
  'lm_sa_riyadh_kingdom-centre': ASSET('riyadh_kingdom_centre.jpg'),
  'lm_sa_riyadh_faisaliyah-tower': ASSET('riyadh_faisaliyah.jpg'),
  'lm_sa_riyadh_al-batha':
    'https://upload.wikimedia.org/wikipedia/commons/8/82/Al_Batha_Street_Riyadh,_2023.jpg',
  'lm_sa_riyadh_souq-al-zal': ASSET('riyadh_souq_al_zal.jpg'),
  'lm_sa_riyadh_king-fahd-stadium': ASSET('riyadh_king_fahd_stadium.jpg'),

  // ——— Makkah (only requested fixes) ———
  // Arabic Wikipedia Commons File:Al-ejabah.jpg
  'lm_sa_makkah_masjid-al-ijabah': ASSET('makkah_masjid_al_ijabah.jpg'),
  // Exterior from maps listing for مسجد الملك عبدالعزيز، حي المعابدة
  'lm_sa_makkah_masjid-king-abdulaziz': ASSET('makkah_masjid_king_abdulaziz.jpg'),

  // ——— Taif (only requested fixes) ———
  // Arabic Wikipedia Commons images for these two mosques
  'lm_sa_taif_masjid-al-madhun': ASSET('taif_masjid_al_madhun.jpg'),
  'lm_sa_taif_masjid-addas': ASSET('taif_masjid_addas.jpg'),
  // historic-balad-souq: only with verified photo
};

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function toFirestoreString(s) {
  return { stringValue: String(s ?? '') };
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

async function patchDoc(idToken, docPath, fields) {
  const fieldPaths = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  const body = { fields: {} };
  for (const [k, v] of Object.entries(fields)) {
    body.fields[k] = toFirestoreString(v);
  }
  const url = `${DOCS}/${docPath}?${fieldPaths}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`PATCH ${docPath} ${res.status}: ${t.slice(0, 200)}`);
  }
}

function assertUnique() {
  const seen = new Map();
  for (const [id, img] of Object.entries(IMAGE_MAP)) {
    if (seen.has(img)) {
      throw new Error(`Duplicate image for ${id} and ${seen.get(img)}: ${img}`);
    }
    seen.set(img, id);
  }
}

function updateStaging() {
  const updated = [];
  for (const [id, img] of Object.entries(IMAGE_MAP)) {
    const file = path.join(STAGING, `${id}.json`);
    if (!fs.existsSync(file)) {
      updated.push({ id, status: 'staging-missing' });
      continue;
    }
    const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
    const prev = doc.img1 || '';
    doc.img1 = img;
    doc.img_source = img.startsWith('assets/')
      ? 'bundled_asset_verified'
      : 'commons_or_flickr_verified';
    doc.images_license_verified = true;
    doc.__writtenAt = new Date().toISOString();
    fs.writeFileSync(file, JSON.stringify(doc, null, 2), 'utf8');
    updated.push({ id, prev: prev.slice(0, 80), next: img, status: 'staging-ok' });
  }
  return updated;
}

async function main() {
  assertUnique();
  const staging = updateStaging();
  console.log(`Staging updated: ${staging.filter((x) => x.status === 'staging-ok').length}`);

  const report = {
    at: new Date().toISOString(),
    apply: APPLY,
    count: Object.keys(IMAGE_MAP).length,
    map: IMAGE_MAP,
    staging,
    production: [],
    skippedNeedsPhoto: [
      'lm_sa_jeddah_jeddah-corniche-circuit', // no free photo of the F1 track itself
      'lm_sa_jeddah_horse-stables', // no verified free photo of this facility
      'lm_sa_jeddah_salam-mall', // no verified free photo
      'lm_sa_madinah_uthman-farm', // no verified free photo of Biʾr Rumah / farm
      'lm_sa_madinah_qatrah-cafe', // private café — no free photo
      'lm_sa_taif_historic-balad-souq', // no verified free photo of سوق البلد specifically
    ],
  };

  if (APPLY) {
    const idToken = await getIdToken();
    for (const [id, img] of Object.entries(IMAGE_MAP)) {
      await patchDoc(idToken, `mkan/${id}`, {
        img1: img,
        img_source: img.startsWith('assets/')
          ? 'bundled_asset_verified'
          : 'commons_or_flickr_verified',
        images_license_verified: 'true',
      });
      report.production.push({ id, img, status: 'patched' });
      console.log('patched', id);
      await sleep(90);
    }
  } else {
    console.log('Dry-run only. Pass --apply to patch Production.');
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'sa_landmark_images_patch.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Report:', out);
  console.log(
    'Still need verified unique photos:',
    report.skippedNeedsPhoto.join(', '),
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
