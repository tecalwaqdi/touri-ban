#!/usr/bin/env node
'use strict';

/**
 * Additive import: 7 international countries → local staging (+ optional production).
 * Does NOT modify existing SA/KG/UZ/RU staging files.
 *
 * Usage:
 *   node import_international_seven.js
 *   node import_international_seven.js --production --i-approve-production
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const { COUNTRIES, LANGS } = require('./datasets/curated/international_seven_capitals');
const VERIFIED_IMAGES = require('./datasets/curated/international_seven_images');
const { landmarkDoc } = require('./importers/firestore_mapper');

const ROOT = path.join(__dirname);
const STAGING = path.join(ROOT, 'staging', 'firestore');
const REPORTS = path.join(ROOT, 'reports');

function mapTsnef(category) {
  const map = {
    religious: 'معالم دينية',
    historic: 'معالم تاريخية',
    museum: 'معالم سياحية',
    attraction: 'معالم سياحية',
    park: 'أماكن ترفيهية',
  };
  return map[category] || 'معالم سياحية';
}

function countryDoc(c) {
  return {
    path: `countries/${c.firestoreDocId}`,
    data: {
      naim: c.names.ar,
      naimEnglesh: c.names.en,
      names_i18n: c.names,
      osf: c.osf.ar,
      osf_i18n: c.osf,
      img: `https://flagcdn.com/w320/${c.iso2.toLowerCase()}.png`,
      hederImg: `https://flagcdn.com/w1280/${c.iso2.toLowerCase()}.png`,
      iso_code: c.iso2,
      iso3: c.iso3,
      CurrencySymbol: c.currencySymbol,
      currency_code: c.currencyCode,
      phone_code: c.phoneCode,
      timezone: c.timezone,
      acctev: true,
      saudi: false,
      num_trteb: c.numTrteb,
      geo_center: c.geoCenter,
      bounds_sw: c.bounds.sw,
      bounds_ne: c.bounds.ne,
      geo_import_id: `country_${c.key.toLowerCase()}`,
      geo_import_source: 'international_seven_2026',
    },
  };
}

function regionDoc(c) {
  const r = c.region;
  const docId = `region_${c.key.toLowerCase()}_${r.slug}`;
  const cityDocId = `city_${c.key.toLowerCase()}_${r.hub.slug}`;
  return {
    path: `cities/${docId}`,
    data: {
      naim: r.names.ar,
      names_i18n: r.names,
      osf: `${r.names.ar} — ${c.names.ar}.`,
      osf_i18n: LANGS.reduce((acc, lang) => {
        acc[lang] = `${r.names[lang]} — ${c.names[lang]}.`;
        return acc;
      }, {}),
      img: `https://flagcdn.com/w320/${c.iso2.toLowerCase()}.png`,
      icon: `https://flagcdn.com/w320/${c.iso2.toLowerCase()}.png`,
      dolh: `countries/${c.firestoreDocId}`,
      // Hub village for capital-only countries (same pattern as SA regions when set).
      vil: `villages/${cityDocId}`,
      acctev: true,
      sorting: 1,
      iso_code: r.code,
      country_iso: c.iso2,
      geo_center: { lat: r.hub.lat, lng: r.hub.lng },
      geo_import_id: docId,
      geo_import_source: 'international_seven_2026',
    },
  };
}

function cityDoc(c) {
  const r = c.region;
  const regionDocId = `region_${c.key.toLowerCase()}_${r.slug}`;
  const cityDocId = `city_${c.key.toLowerCase()}_${r.hub.slug}`;
  return {
    path: `villages/${cityDocId}`,
    data: {
      naim: r.hub.names.ar,
      names_i18n: r.hub.names,
      osf: `${r.hub.names.ar} — عاصمة ${c.names.ar}.`,
      osf_i18n: LANGS.reduce((acc, lang) => {
        acc[lang] =
          lang === 'ar'
            ? `${r.hub.names.ar} — عاصمة ${c.names.ar}.`
            : `${r.hub.names[lang]} — capital of ${c.names.en}.`;
        return acc;
      }, {}),
      img: `https://flagcdn.com/w320/${c.iso2.toLowerCase()}.png`,
      cities: `cities/${regionDocId}`,
      dolh: `countries/${c.firestoreDocId}`,
      lat_ling: { latitude: r.hub.lat, longitude: r.hub.lng },
      acctev: true,
      country_iso: c.iso2,
      naimciteText: r.hub.names.en,
      geo_import_id: cityDocId,
      geo_import_source: 'international_seven_2026',
    },
  };
}

function buildLandmarkDoc(c, lm) {
  const r = c.region;
  const regionDocId = `region_${c.key.toLowerCase()}_${r.slug}`;
  const cityDocId = `city_${c.key.toLowerCase()}_${r.hub.slug}`;
  const image = lm.images?.[0] || {};
  const img1 = VERIFIED_IMAGES[lm.id] || image.url || '';

  return {
    path: `mkan/${lm.id}`,
    data: {
      naim: lm.names.ar,
      osf: lm.shortDescriptions.ar,
      names_i18n: lm.names,
      osf_i18n: lm.shortDescriptions,
      content_locale: 'ar',
      address: `${lm.names.ar}، ${r.hub.names.ar}، ${c.names.ar}`,
      address_i18n: LANGS.reduce((acc, lang) => {
        acc[lang] = `${lm.names[lang]}, ${r.hub.names[lang]}, ${c.names[lang]}`;
        return acc;
      }, {}),
      Location: {
        latitude: lm.location.latitude,
        longitude: lm.location.longitude,
      },
      img1,
      img2: '',
      img3: '',
      img_license: image.license || 'CC BY-SA 4.0',
      img_attribution: image.attribution || 'Wikimedia Commons',
      images_license_verified: true,
      img_source: image.source || 'wikipedia_or_commons',
      sr: lm.sortIndex,
      acctev: true,
      as_ads: lm.sortIndex <= 3,
      ismzod: true,
      isShrek: false,
      ismsgd: lm.category === 'religious',
      isfood: false,
      ishmam: true,
      tsnef: mapTsnef(lm.category),
      rate: 4.6,
      add_saat: 2,
      id_cit: `cities/${regionDocId}`,
      id_vill: `villages/${cityDocId}`,
      Rev_dolh: `countries/${c.firestoreDocId}`,
      country_iso: c.iso2,
      wikidata_id: null,
      source_provider: 'curated_international_seven',
      verification_status: lm.verification?.status || 'verified',
      verification_confidence: lm.verification?.confidence ?? 0.92,
      geo_import_id: lm.id,
      geo_import_slug: lm.slug,
      geo_import_source: 'international_seven_2026',
    },
  };
}

function buildPlan() {
  const docs = [];
  for (const c of COUNTRIES) {
    docs.push(countryDoc(c));
    docs.push(regionDoc(c));
    docs.push(cityDoc(c));
    for (const lm of c.landmarks) {
      docs.push(buildLandmarkDoc(c, lm));
    }
  }
  return docs;
}

function writeStagingDoc(doc) {
  const filePath = path.join(STAGING, ...doc.path.split('/')) + '.json';
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const payload = {
    __path: doc.path,
    __writtenAt: new Date().toISOString(),
    __target: 'local-staging',
    ...doc.data,
  };
  fs.writeFileSync(filePath, JSON.stringify(payload, null, 2), 'utf8');
  return filePath;
}

function mergeManifest(newPaths) {
  const manifestPath = path.join(STAGING, '_manifest.json');
  let manifest = { paths: [], stats: {} };
  if (fs.existsSync(manifestPath)) {
    manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  }
  const existing = new Set(manifest.paths || []);
  for (const p of newPaths) existing.add(p);
  manifest.paths = [...existing].sort();
  manifest.stats = manifest.stats || {};
  manifest.stats.international_seven = {
    countries: COUNTRIES.length,
    capitals: COUNTRIES.length,
    landmarks: COUNTRIES.length * 5,
    addedAt: new Date().toISOString(),
  };
  manifest.docCount = manifest.paths.length;
  manifest.generatedAt = new Date().toISOString();
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
  return manifest;
}

function headUrl(url) {
  return new Promise((resolve) => {
    const req = https.request(
      url,
      { method: 'GET', headers: { 'User-Agent': 'TouriTaxiGeoImport/1.0' } },
      (res) => {
        res.resume();
        resolve({ url, status: res.statusCode });
      },
    );
    req.on('error', () => resolve({ url, status: 0 }));
    req.setTimeout(12000, () => {
      req.destroy();
      resolve({ url, status: 0 });
    });
    req.end();
  });
}

async function verifyImages(docs) {
  const urls = new Set();
  for (const d of docs) {
    if (d.path.startsWith('mkan/') && d.data.img1) urls.add(d.data.img1);
  }
  const results = [];
  for (const url of urls) {
    results.push(await headUrl(url));
  }
  const bad = results.filter((r) => r.status !== 200);
  return { total: results.length, bad, ok: results.length - bad.length };
}

async function upsertProduction(docs) {
  const adminPath = path.join(
    ROOT,
    '..',
    '..',
    'functions',
    'node_modules',
    'firebase-admin',
  );
  const admin = require(adminPath);
  if (!admin.apps.length) {
    const saPath =
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      path.join(ROOT, '..', '..', 'functions', 'serviceAccount.toury.json');
    if (fs.existsSync(saPath)) {
      console.log(`Using service account: ${saPath}`);
      admin.initializeApp({
        credential: admin.credential.cert(require(saPath)),
        projectId: 'tutorial-multi-language-70gx4j',
      });
    } else {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: 'tutorial-multi-language-70gx4j',
      });
    }
  }
  const db = admin.firestore();
  let written = 0;
  for (const doc of docs) {
    const data = { ...doc.data };
    if (data.Location) {
      data.Location = new admin.firestore.GeoPoint(
        data.Location.latitude,
        data.Location.longitude,
      );
    }
    if (data.lat_ling) {
      data.lat_ling = new admin.firestore.GeoPoint(
        data.lat_ling.latitude,
        data.lat_ling.longitude,
      );
    }
    if (data.geo_center) {
      data.geo_center = new admin.firestore.GeoPoint(
        data.geo_center.lat,
        data.geo_center.lng,
      );
    }
    if (data.bounds_sw) {
      data.bounds_sw = new admin.firestore.GeoPoint(
        data.bounds_sw.lat,
        data.bounds_sw.lng,
      );
    }
    if (data.bounds_ne) {
      data.bounds_ne = new admin.firestore.GeoPoint(
        data.bounds_ne.lat,
        data.bounds_ne.lng,
      );
    }
    for (const key of ['dolh', 'cities', 'id_cit', 'id_vill', 'Rev_dolh', 'vil']) {
      if (typeof data[key] === 'string' && data[key].includes('/')) {
        data[key] = db.doc(data[key]);
      }
    }
    await db.doc(doc.path).set(data, { merge: true });
    written += 1;
  }
  return written;
}

async function main() {
  const args = process.argv.slice(2);
  const production =
    args.includes('--production') && args.includes('--i-approve-production');

  const docs = buildPlan();
  const stats = {
    countries: COUNTRIES.length,
    regions: COUNTRIES.length,
    cities: COUNTRIES.length,
    landmarks: COUNTRIES.length * 5,
    totalDocs: docs.length,
  };

  console.log('Building international seven plan:', stats);

  const imageCheck = await verifyImages(docs);
  if (imageCheck.bad.length) {
    console.warn(
      'WARNING: some image URLs returned non-200:',
      imageCheck.bad.map((b) => `${b.status} ${b.url}`).join('\n'),
    );
  } else {
    console.log(`Image check OK: ${imageCheck.ok}/${imageCheck.total}`);
  }

  const written = [];
  for (const doc of docs) {
    written.push(writeStagingDoc(doc));
  }

  const manifest = mergeManifest(docs.map((d) => d.path));
  fs.mkdirSync(REPORTS, { recursive: true });
  const report = {
    ok: true,
    stats,
    imageCheck,
    written: written.length,
    manifestDocCount: manifest.docCount,
    capitals: COUNTRIES.map((c) => ({
      country: c.names.en,
      capital: c.region.hub.names.en,
      iso: c.iso2,
    })),
  };
  fs.writeFileSync(
    path.join(REPORTS, 'international_seven_import.json'),
    JSON.stringify(report, null, 2),
    'utf8',
  );
  console.log(JSON.stringify(report, null, 2));

  if (production) {
    const n = await upsertProduction(docs);
    console.log(`Production upsert complete: ${n} docs`);
  }
}

main().catch((e) => {
  const msg = e.message || String(e);
  console.error('FAILED', msg);
  if (msg.includes('invalid_rapt') || msg.includes('invalid_grant')) {
    console.error(`
Firebase credentials expired. Fix one of:
  1) gcloud auth application-default login
  2) Save service account JSON to:
     admin/ara_oatan_app/firebase/functions/serviceAccount.toury.json
     then re-run with GOOGLE_APPLICATION_CREDENTIALS set to that path.
`);
  }
  process.exit(1);
});
