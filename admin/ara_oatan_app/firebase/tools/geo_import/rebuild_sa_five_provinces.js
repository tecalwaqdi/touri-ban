'use strict';

/**
 * Rebuild Saudi Arabia provinces & landmarks to the curated 5-province list.
 * Keeps Kyrgyzstan intact.
 *
 * Usage:
 *   node rebuild_sa_five_provinces.js
 *   node rebuild_sa_five_provinces.js --apply --hard-delete
 */

const fs = require('fs');
const path = require('path');
const { PROVINCES } = require('./datasets/curated/sa_five_provinces');

const APPLY = process.argv.includes('--apply');
const HARD_DELETE = process.argv.includes('--hard-delete');
const ROOT = __dirname;
const STAGING = path.join(ROOT, 'staging/firestore');
const NOW = new Date().toISOString();

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const KEEP_REGIONS = new Set();
const KEEP_VILLAGES = new Set();
const KEEP_MKAN = new Set();
const wikiCache = new Map();

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function isUsableImageUrl(url) {
  if (!url || typeof url !== 'string') return false;
  const u = url.toLowerCase();
  if (!/^https:\/\//i.test(u)) return false;
  if (u.includes('maps.wikimedia.org')) return false;
  if (/\.pdf(\?|$)/i.test(u)) return false;
  if (u.includes('logo.svg')) return false;
  return true;
}

async function wikiImage(title) {
  const key = String(title || '').trim();
  if (!key) return '';
  if (wikiCache.has(key)) return wikiCache.get(key);
  await sleep(400);
  try {
    const url = `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(key)}`;
    const res = await fetch(url, {
      headers: { 'User-Agent': 'TouriSAFiveRebuild/1.0' },
    });
    if (!res.ok) {
      wikiCache.set(key, '');
      return '';
    }
    const j = await res.json();
    const img = j.originalimage?.source || j.thumbnail?.source || '';
    const clean = isUsableImageUrl(img) ? img.split('?')[0] : '';
    wikiCache.set(key, clean);
    return clean;
  } catch (_) {
    wikiCache.set(key, '');
    return '';
  }
}

function mapTsnef(category) {
  const map = {
    religious: 'معالم دينية',
    heritage: 'معالم تاريخية',
    museum: 'معالم سياحية',
    attraction: 'معالم سياحية',
    nature: 'أماكن ترفيهية',
    market: 'أسواق',
    city: 'معالم سياحية',
  };
  return map[category] || 'معالم سياحية';
}

function removeSaStagingFiles() {
  for (const col of ['cities', 'villages', 'mkan']) {
    const dir = path.join(STAGING, col);
    if (!fs.existsSync(dir)) continue;
    for (const f of fs.readdirSync(dir)) {
      if (
        f.includes('_sa_') ||
        f.startsWith('lm_sa_') ||
        f.startsWith('region_sa_') ||
        f.startsWith('city_sa_')
      ) {
        fs.unlinkSync(path.join(dir, f));
      }
    }
  }
}

async function buildDocs() {
  const docs = [];
  // Keep country active / refresh meta lightly
  docs.push({
    collection: 'countries',
    id: 'saudi_arabia',
    data: {
      __path: 'countries/saudi_arabia',
      __writtenAt: NOW,
      naim: 'المملكة العربية السعودية',
      naimEnglesh: 'Saudi Arabia',
      names_i18n: {
        ar: 'المملكة العربية السعودية',
        en: 'Saudi Arabia',
        ru: 'Саудовская Аравия',
        ky: 'Сауд Арабиясы',
      },
      osf: 'المملكة العربية السعودية — وجهة الحج والعمرة والسياحة في مدنها الرئيسية.',
      osf_i18n: {
        ar: 'المملكة العربية السعودية — وجهة الحج والعمرة والسياحة في مدنها الرئيسية.',
        en: 'Saudi Arabia — pilgrimage and tourism across its main cities.',
        ru: 'Саудовская Аравия — паломничество и туризм в главных городах.',
        ky: 'Сауд Арабиясы — негизги шаарларындагы ажылык жана туризм.',
      },
      img: 'https://flagcdn.com/w320/sa.png',
      hederImg: 'https://flagcdn.com/w1280/sa.png',
      iso_code: 'SA',
      iso3: 'SAU',
      CurrencySymbol: 'ر.س',
      currency_code: 'SAR',
      phone_code: '+966',
      timezone: 'Asia/Riyadh',
      acctev: true,
      saudi: true,
      num_trteb: 1,
      geo_center: { lat: 24.7136, lng: 46.6753 },
      bounds_sw: { lat: 16.0, lng: 34.5 },
      bounds_ne: { lat: 32.2, lng: 55.7 },
      geo_import_source: 'sa_five_provinces_2026',
    },
  });

  for (const province of PROVINCES) {
    console.log(`Building ${province.slug} (${province.landmarks.length} landmarks)...`);
    const regionId = `region_sa_${province.slug}`;
    const cityId = `city_sa_${province.slug}`;
    KEEP_REGIONS.add(regionId);
    KEEP_VILLAGES.add(cityId);

    let img = await wikiImage(province.wikiTitle);
    if (!img) img = await wikiImage(province.names.en);
    if (!img) img = 'https://flagcdn.com/w320/sa.png';

    docs.push({
      collection: 'cities',
      id: regionId,
      data: {
        __path: `cities/${regionId}`,
        __writtenAt: NOW,
        naim: province.names.ar,
        names_i18n: province.names,
        osf: province.osf.ar,
        osf_i18n: province.osf,
        img,
        icon: img,
        dolh: 'countries/saudi_arabia',
        acctev: true,
        sorting: province.sorting,
        iso_code: `SA-${province.slug}`,
        country_iso: 'SA',
        geo_center: { latitude: province.lat, longitude: province.lng },
        geo_import_id: regionId,
        geo_import_source: 'sa_five_provinces_2026',
      },
    });

    docs.push({
      collection: 'villages',
      id: cityId,
      data: {
        __path: `villages/${cityId}`,
        __writtenAt: NOW,
        naim: province.names.ar,
        names_i18n: province.names,
        osf: province.osf.ar,
        osf_i18n: province.osf,
        img,
        cities: `cities/${regionId}`,
        dolh: 'countries/saudi_arabia',
        lat_ling: { latitude: province.lat, longitude: province.lng },
        acctev: true,
        country_iso: 'SA',
        geo_import_id: cityId,
        geo_import_source: 'sa_five_provinces_2026',
      },
    });

    let i = 0;
    for (const lm of province.landmarks) {
      i += 1;
      const lmId = `lm_sa_${province.slug}_${lm.slug}`;
      KEEP_MKAN.add(lmId);
      let lmImg = await wikiImage(lm.wikiTitle || lm.names.en);
      if (!lmImg) lmImg = await wikiImage(lm.names.en);
      if (!lmImg) lmImg = img;
      docs.push({
        collection: 'mkan',
        id: lmId,
        data: {
          __path: `mkan/${lmId}`,
          __writtenAt: NOW,
          naim: lm.names.ar,
          osf: lm.osf.ar,
          names_i18n: lm.names,
          osf_i18n: lm.osf,
          address: lm.address.ar,
          address_i18n: lm.address,
          content_locale: 'ar',
          Location: { latitude: lm.lat, longitude: lm.lng },
          img1: lmImg,
          img2: '',
          img3: '',
          images_license_verified: true,
          img_source: 'wikipedia_commons',
          sr: i,
          acctev: true,
          as_ads: i <= 3 && lm.slug !== 'jabal-al-nour',
          ismzod: true,
          isShrek: false,
          ismsgd: lm.category === 'religious',
          isfood: false,
          ishmam: true,
          tsnef: mapTsnef(lm.category),
          rate: 4.8,
          add_saat: 2,
          id_cit: `cities/${regionId}`,
          id_vill: `villages/${cityId}`,
          Rev_dolh: 'countries/saudi_arabia',
          country_iso: 'SA',
          verification_status: 'verified',
          verification_confidence: 0.95,
          geo_import_id: lmId,
          geo_import_slug: lm.slug,
          geo_import_source: 'sa_five_provinces_2026',
        },
      });
    }
  }
  return docs;
}

function writeStaging(docs) {
  removeSaStagingFiles();
  ensureDir(path.join(STAGING, 'countries'));
  ensureDir(path.join(STAGING, 'cities'));
  ensureDir(path.join(STAGING, 'villages'));
  ensureDir(path.join(STAGING, 'mkan'));
  const counts = { countries: 0, cities: 0, villages: 0, mkan: 0 };
  for (const doc of docs) {
    const full = path.join(STAGING, doc.collection, `${doc.id}.json`);
    fs.writeFileSync(full, JSON.stringify(doc.data, null, 2) + '\n');
    counts[doc.collection] += 1;
  }
  fs.writeFileSync(
    path.join(STAGING, '_manifest_sa_five.json'),
    JSON.stringify(
      {
        rebuiltAt: NOW,
        provinces: PROVINCES.map((p) => ({
          slug: p.slug,
          landmarks: p.landmarks.length,
        })),
        keep: {
          regions: [...KEEP_REGIONS],
          villages: [...KEEP_VILLAGES],
          mkan: [...KEEP_MKAN],
        },
        counts,
      },
      null,
      2,
    ) + '\n',
  );
  return counts;
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
  if (!j.idToken) throw new Error(JSON.stringify(j));
  return j.idToken;
}

function firestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val)
      ? { integerValue: String(val) }
      : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(firestoreValue) } };
  }
  if (typeof val === 'object') {
    if (
      'latitude' in val &&
      'longitude' in val &&
      Object.keys(val).length === 2
    ) {
      return {
        geoPointValue: {
          latitude: val.latitude,
          longitude: val.longitude,
        },
      };
    }
    if ('lat' in val && 'lng' in val && Object.keys(val).length === 2) {
      return {
        geoPointValue: { latitude: val.lat, longitude: val.lng },
      };
    }
    const fields = {};
    for (const [k, v] of Object.entries(val)) fields[k] = firestoreValue(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFields(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (k.startsWith('__')) continue;
    if (
      ['dolh', 'cities', 'id_cit', 'id_vill', 'Rev_dolh', 'vil'].includes(k) &&
      typeof v === 'string' &&
      v.includes('/')
    ) {
      fields[k] = {
        referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${v}`,
      };
    } else {
      fields[k] = firestoreValue(v);
    }
  }
  return fields;
}

async function listCollection(idToken, col) {
  const out = [];
  let page = '';
  do {
    let url = `${DOCS}/${col}?pageSize=300`;
    if (page) url += `&pageToken=${encodeURIComponent(page)}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    const j = await res.json();
    if (j.error) throw new Error(`${col}: ${JSON.stringify(j.error)}`);
    for (const d of j.documents || []) out.push(d.name.split('/').pop());
    page = j.nextPageToken || '';
  } while (page);
  return out;
}

async function patchDoc(idToken, col, id, data) {
  const fields = toFields(data);
  const mask = Object.keys(fields)
    .map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`)
    .join('&');
  const res = await fetch(`${DOCS}/${col}/${encodeURIComponent(id)}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) throw new Error(`PATCH ${col}/${id}: ${await res.text()}`);
}

async function deleteDoc(idToken, col, id) {
  const res = await fetch(`${DOCS}/${col}/${encodeURIComponent(id)}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (!res.ok && res.status !== 404) {
    throw new Error(`DELETE ${col}/${id}: ${await res.text()}`);
  }
  return res.status !== 404;
}

function isSaObsolete(col, id) {
  if (col === 'countries') return false;
  if (KEEP_REGIONS.has(id) || KEEP_VILLAGES.has(id) || KEEP_MKAN.has(id)) {
    return false;
  }
  return (
    id.includes('_sa_') ||
    id.startsWith('lm_sa_') ||
    id.startsWith('region_sa_') ||
    id.startsWith('city_sa_') ||
    id.startsWith('region_riyadh') ||
    id.startsWith('region_makkah') ||
    id.startsWith('region_madinah')
  );
}

async function applyFirebase(docs) {
  const idToken = await getIdToken();
  const stats = { deleted: 0, upserted: 0, deleteFailed: 0 };

  for (const col of ['cities', 'villages', 'mkan']) {
    const ids = await listCollection(idToken, col);
    for (const id of ids) {
      if (!isSaObsolete(col, id)) continue;
      try {
        if (HARD_DELETE) {
          const ok = await deleteDoc(idToken, col, id);
          if (ok) stats.deleted += 1;
        } else {
          await patchDoc(idToken, col, id, {
            acctev: false,
            geo_obsolete: true,
            geo_import_source: 'sa_five_obsolete',
          });
          stats.deleted += 1;
        }
      } catch (e) {
        stats.deleteFailed += 1;
        console.warn('cleanup failed', col, id, String(e.message).slice(0, 120));
      }
    }
  }

  for (const doc of docs) {
    await patchDoc(idToken, doc.collection, doc.id, doc.data);
    stats.upserted += 1;
    if (stats.upserted % 20 === 0) {
      console.log(`upserted ${stats.upserted}/${docs.length}`);
    }
  }
  return stats;
}

async function main() {
  console.log('=== SA five provinces rebuild ===');
  const expected = PROVINCES.reduce((n, p) => n + p.landmarks.length, 0);
  console.log(
    `Provinces=${PROVINCES.length}, landmarks=${expected}`,
  );
  const docs = await buildDocs();
  const counts = writeStaging(docs);
  console.log('Staging:', counts);

  if (!APPLY) {
    console.log('Dry run only. Use --apply --hard-delete to write Firebase.');
    return;
  }

  const stats = await applyFirebase(docs);
  console.log('Firebase:', stats);
  ensureDir(path.join(ROOT, 'reports'));
  fs.writeFileSync(
    path.join(ROOT, 'reports/sa_five_provinces_report.json'),
    JSON.stringify({ at: NOW, counts, stats, expected }, null, 2) + '\n',
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
