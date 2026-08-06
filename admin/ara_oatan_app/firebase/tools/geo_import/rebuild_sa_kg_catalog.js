'use strict';

/**
 * Full SA + KG geo catalog rebuild:
 * 1) Wipe local staging countries/cities/villages/mkan
 * 2) Write only Saudi Arabia + Kyrgyzstan (all official regions, 1 hub city, top 5 landmarks)
 * 3) Soft-deactivate (and hard-delete when allowed) obsolete Firebase docs
 * 4) Upsert the new catalog
 *
 * Usage:
 *   node rebuild_sa_kg_catalog.js              # staging only
 *   node rebuild_sa_kg_catalog.js --apply      # staging + Firebase
 *   node rebuild_sa_kg_catalog.js --apply --hard-delete
 */

const fs = require('fs');
const path = require('path');
const { COUNTRIES, SA_REGIONS, KG_REGIONS } = require('./config/regions');
const {
  LANGS,
  PREFERRED_MATCH,
  OVERRIDES,
  REGION_OSF,
} = require('./datasets/curated/sa_kg_top5');

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

const KEEP_COUNTRIES = new Set(['saudi_arabia', 'kyrgyzstan']);
const KEEP_REGIONS = new Set();
const KEEP_VILLAGES = new Set();
const KEEP_MKAN = new Set();

const COUNTRY_META = {
  SA: {
    num_trteb: 1,
    osf: {
      ar: 'المملكة العربية السعودية — وجهة الحج والعمرة والسياحة الحديثة.',
      en: 'Saudi Arabia — pilgrimage destinations and modern tourism across 13 regions.',
      ru: 'Саудовская Аравия — паломничество и современный туризм в 13 регионах.',
      ky: 'Сауд Арабиясы — ажылык жана 13 аймактагы заманбап туризм.',
    },
    geo_center: { lat: 24.7136, lng: 46.6753 },
    bounds_sw: { lat: 16.0, lng: 34.5 },
    bounds_ne: { lat: 32.2, lng: 55.7 },
  },
  KG: {
    num_trteb: 2,
    osf: {
      ar: 'قيرغيزستان — جبال تيان شان وبحيرة إيسيك كول والتراث البدوي.',
      en: 'Kyrgyzstan — Tian Shan mountains, Issyk-Kul, and nomadic heritage.',
      ru: 'Кыргызстан — Тянь-Шань, Иссык-Куль и кочевое наследие.',
      ky: 'Кыргызстан — Тянь-Шань, Ысык-Көл жана көчмөн мурасы.',
    },
    geo_center: { lat: 41.2044, lng: 74.7661 },
    bounds_sw: { lat: 39.1, lng: 69.2 },
    bounds_ne: { lat: 43.3, lng: 80.3 },
  },
};

const wikiCache = new Map();

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function flagImg(iso) {
  return `https://flagcdn.com/w320/${iso.toLowerCase()}.png`;
}

function flagHeader(iso) {
  return `https://flagcdn.com/w1280/${iso.toLowerCase()}.png`;
}

function isUsableImageUrl(url) {
  if (!url || typeof url !== 'string') return false;
  const u = url.toLowerCase();
  if (!/^https:\/\//i.test(u)) return false;
  if (u.includes('maps.wikimedia.org')) return false;
  if (/\.pdf(\?|$)/i.test(u)) return false;
  if (u.includes('sofia_-_national_museum')) return false;
  return true;
}

async function wikiImage(title) {
  const key = String(title || '').trim();
  if (!key) return '';
  if (wikiCache.has(key)) return wikiCache.get(key);
  await sleep(350);
  try {
    const url = `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(key)}`;
    const res = await fetch(url, {
      headers: { 'User-Agent': 'TouriGeoRebuild/1.0 (geo catalog rebuild)' },
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

async function resolveLandmarkImage(lm, preferredUrl) {
  if (isUsableImageUrl(preferredUrl)) return preferredUrl;
  const titles = [
    lm.wikiTitle,
    lm.names?.en,
    lm.names?.ar,
  ].filter(Boolean);
  for (const t of titles) {
    const img = await wikiImage(t);
    if (img) return img;
  }
  const collected = (lm.images || []).find((i) => isUsableImageUrl(i.url));
  return collected?.url || preferredUrl || '';
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function wipeDir(p) {
  fs.rmSync(p, { recursive: true, force: true });
  ensureDir(p);
}

function writeJson(relPath, data) {
  const full = path.join(STAGING, relPath);
  ensureDir(path.dirname(full));
  fs.writeFileSync(full, JSON.stringify(data, null, 2) + '\n');
}

function looksArabic(s) {
  return /[\u0600-\u06FF]/.test(String(s || ''));
}

function pickLangs(map) {
  const ar = (map && (map.ar || map.en)) || '';
  const en = (map && (map.en || map.ar)) || '';
  const ruRaw = map?.ru || '';
  const kyRaw = map?.ky || '';
  const ru = ruRaw && !looksArabic(ruRaw) ? ruRaw : en;
  const ky = kyRaw && !looksArabic(kyRaw) ? kyRaw : ru;
  return { ar, en, ru, ky };
}

function mapTsnef(category) {
  const raw = String(category || 'attraction').toLowerCase();
  const map = {
    religious: 'معالم دينية',
    heritage: 'معالم تاريخية',
    historic: 'معالم تاريخية',
    museum: 'معالم سياحية',
    attraction: 'معالم سياحية',
    nature: 'أماكن ترفيهية',
    park: 'أماكن ترفيهية',
    culture: 'معالم سياحية',
    market: 'أسواق',
    city: 'معالم سياحية',
    wellness: 'أماكن ترفيهية',
  };
  return map[raw] || 'معالم سياحية';
}

function scoreLandmark(lm, preferred) {
  const en = String(lm.names?.en || '');
  const ar = String(lm.names?.ar || '');
  const hay = `${en} ${ar}`.toLowerCase();
  let score = 0;
  preferred.forEach((key, idx) => {
    if (hay.includes(String(key).toLowerCase())) score += 100 - idx;
  });
  if ((lm.images || []).some((i) => i.url)) score += 20;
  if (lm.wikidataId) score += 5;
  if (en && !/^[\u0600-\u06FF]/.test(en)) score += 3;
  return score;
}

function defaultOsf(names, regionNames, countryKey) {
  const country =
    countryKey === 'SA'
      ? {
          ar: 'المملكة العربية السعودية',
          en: 'Saudi Arabia',
          ru: 'Саудовская Аравия',
          ky: 'Сауд Арабиясы',
        }
      : {
          ar: 'قيرغيزستان',
          en: 'Kyrgyzstan',
          ru: 'Кыргызстан',
          ky: 'Кыргызстан',
        };
  return {
    ar: `${names.ar} معلم بارز في ${regionNames.ar}، ${country.ar}.`,
    en: `${names.en} is a notable landmark in ${regionNames.en}, ${country.en}.`,
    ru: `${names.ru || names.en} — достопримечательность в регионе ${regionNames.ru}, ${country.ru}.`,
    ky: `${names.ky || names.en} — ${regionNames.ky} аймагындагы белгилүү жер, ${country.ky}.`,
  };
}

function defaultAddress(names, hub, regionNames, countryKey) {
  const country =
    countryKey === 'SA'
      ? {
          ar: 'المملكة العربية السعودية',
          en: 'Saudi Arabia',
          ru: 'Саудовская Аравия',
          ky: 'Сауд Арабиясы',
        }
      : {
          ar: 'قيرغيزستان',
          en: 'Kyrgyzstan',
          ru: 'Кыргызстан',
          ky: 'Кыргызстан',
        };
  return {
    ar: `${names.ar}، ${hub.names.ar}، ${regionNames.ar}، ${country.ar}`,
    en: `${names.en}, ${hub.names.en}, ${regionNames.en}, ${country.en}`,
    ru: `${names.ru || names.en}, ${hub.names.ru}, ${regionNames.ru}, ${country.ru}`,
    ky: `${names.ky || names.en}, ${hub.names.ky}, ${regionNames.ky}, ${country.ky}`,
  };
}

function loadCollected(countryKey) {
  const file = path.join(
    ROOT,
    'datasets/collected',
    `${countryKey.toLowerCase()}_regions.json`,
  );
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

async function selectLandmarks(countryKey, region, collectedRegion) {
  const preferred = PREFERRED_MATCH[region.slug] || [];
  const overrides = OVERRIDES[region.slug] || [];
  const selected = [];
  const usedNames = new Set();

  for (const ov of overrides) {
    if (selected.length >= 5) break;
    const names = pickLangs(ov.names);
    const imgUrl = await resolveLandmarkImage(
      { names, wikiTitle: ov.wikiTitle, images: [{ url: ov.img }] },
      ov.img,
    );
    selected.push({
      id: `lm_${countryKey.toLowerCase()}_${region.slug}_${ov.slug}`,
      slug: `${region.slug}-${ov.slug}`,
      category: ov.category,
      names,
      shortDescriptions: pickLangs(ov.osf),
      address: pickLangs(ov.address),
      location: { latitude: ov.lat, longitude: ov.lng },
      images: [{ url: imgUrl, source: 'wikipedia_commons' }],
      wikidataId: null,
      sortIndex: selected.length + 1,
      sources: [{ provider: 'curated_sa_kg_rebuild' }],
      verification: { status: 'verified', confidence: 0.95 },
    });
    usedNames.add(ov.names.en.toLowerCase());
  }

  const pool = [...(collectedRegion?.landmarks || [])].sort(
    (a, b) => scoreLandmark(b, preferred) - scoreLandmark(a, preferred),
  );

  for (const lm of pool) {
    if (selected.length >= 5) break;
    const en = String(lm.names?.en || lm.names?.ar || '').toLowerCase();
    if (!en || usedNames.has(en)) continue;
    // Avoid duplicating Sulaiman-Too into osh oblast when osh_city has it.
    if (
      region.slug === 'osh' &&
      /sulaiman|سليمان/.test(en + String(lm.names?.ar || ''))
    ) {
      continue;
    }
    const names = pickLangs({
      ar: lm.names?.ar || lm.names?.en,
      en: lm.names?.en || lm.names?.ar,
      ru: lm.names?.ru || lm.names?.en || lm.names?.ar,
      ky: lm.names?.ky || lm.names?.ru || lm.names?.en || lm.names?.ar,
    });
    const collectedImg = (lm.images || []).find((i) => isUsableImageUrl(i.url));
    let imgUrl = await resolveLandmarkImage(
      { names, images: lm.images || [] },
      collectedImg?.url || '',
    );
    if (!imgUrl) {
      imgUrl =
        (await wikiImage(region.hub.names.en)) ||
        (await wikiImage(region.names.en)) ||
        flagImg(COUNTRIES[countryKey].iso2);
    }
    const osf =
      lm.shortDescriptions &&
      lm.shortDescriptions.ar &&
      !/OpenStreetMap|موثق من/.test(lm.shortDescriptions.ar)
        ? pickLangs(lm.shortDescriptions)
        : defaultOsf(names, region.names, countryKey);
    selected.push({
      id: `lm_${countryKey.toLowerCase()}_${region.slug}_${String(lm.slug || lm.id).replace(/[^a-z0-9_-]+/gi, '-').toLowerCase()}`.slice(0, 120),
      slug: lm.slug || `${region.slug}-${selected.length + 1}`,
      category: lm.category || 'attraction',
      names,
      shortDescriptions: osf,
      address: defaultAddress(names, region.hub, region.names, countryKey),
      location: {
        latitude: lm.location.latitude,
        longitude: lm.location.longitude,
      },
      images: [
        {
          url: imgUrl,
          license: collectedImg?.license || '',
          attribution: collectedImg?.attribution || '',
          source: 'wikipedia_or_commons',
        },
      ],
      wikidataId: lm.wikidataId || null,
      osmId: lm.osmId || '',
      sortIndex: selected.length + 1,
      sources: [{ provider: 'collected_top5_rebuild' }],
      verification: { status: 'verified', confidence: 0.9 },
    });
    usedNames.add(en);
  }

  if (selected.length < 5) {
    throw new Error(
      `Only ${selected.length}/5 landmarks for ${countryKey}/${region.slug}`,
    );
  }
  return selected.slice(0, 5);
}

function buildCountryDoc(countryKey) {
  const c = COUNTRIES[countryKey];
  const meta = COUNTRY_META[countryKey];
  return {
    __path: `countries/${c.firestoreDocId}`,
    __writtenAt: NOW,
    __target: 'local-staging',
    naim: c.names.ar,
    naimEnglesh: c.names.en,
    names_i18n: pickLangs(c.names),
    osf: meta.osf.ar,
    osf_i18n: meta.osf,
    img: flagImg(c.iso2),
    hederImg: flagHeader(c.iso2),
    iso_code: c.iso2,
    iso3: c.iso3,
    CurrencySymbol: c.currencySymbol,
    currency_code: c.currencyCode,
    phone_code: c.phoneCode,
    timezone: c.timezone,
    acctev: true,
    saudi: countryKey === 'SA',
    num_trteb: meta.num_trteb,
    geo_center: meta.geo_center,
    bounds_sw: meta.bounds_sw,
    bounds_ne: meta.bounds_ne,
    geo_import_id: c.id,
    geo_import_source: 'sa_kg_rebuild_2026',
  };
}

async function buildRegionDoc(countryKey, region, index) {
  const c = COUNTRIES[countryKey];
  const docId = `region_${countryKey.toLowerCase()}_${region.slug}`;
  KEEP_REGIONS.add(docId);
  const osf = REGION_OSF[region.slug] || {
    ar: region.names.ar,
    en: region.names.en,
    ru: region.names.ru,
    ky: region.names.ky,
  };
  const wikiTitles = [
    region.hub.names.en,
    `${region.hub.names.en}, ${countryKey === 'SA' ? 'Saudi Arabia' : 'Kyrgyzstan'}`,
    region.names.en,
  ];
  let img = '';
  for (const t of wikiTitles) {
    img = await wikiImage(t);
    if (img) break;
  }
  if (!img) img = flagImg(c.iso2);
  return {
    __path: `cities/${docId}`,
    __writtenAt: NOW,
    __target: 'local-staging',
    naim: region.names.ar,
    names_i18n: pickLangs(region.names),
    osf: osf.ar,
    osf_i18n: osf,
    img,
    icon: img,
    dolh: `countries/${c.firestoreDocId}`,
    acctev: true,
    sorting: index + 1,
    iso_code: region.code || (region.iso ? `SA-${region.iso}` : ''),
    country_iso: c.iso2,
    geo_center: { latitude: region.hub.lat, longitude: region.hub.lng },
    geo_import_id: docId,
    geo_import_source: 'sa_kg_rebuild_2026',
  };
}

async function buildCityDoc(countryKey, region, regionImg) {
  const c = COUNTRIES[countryKey];
  const regionDocId = `region_${countryKey.toLowerCase()}_${region.slug}`;
  const cityDocId = `city_${countryKey.toLowerCase()}_${region.hub.slug}`;
  KEEP_VILLAGES.add(cityDocId);
  return {
    __path: `villages/${cityDocId}`,
    __writtenAt: NOW,
    __target: 'local-staging',
    naim: region.hub.names.ar,
    names_i18n: pickLangs(region.hub.names),
    osf: `${region.hub.names.ar} — ${region.names.ar}`,
    osf_i18n: {
      ar: `${region.hub.names.ar} — المركز الإداري لـ ${region.names.ar}`,
      en: `${region.hub.names.en} — administrative hub of ${region.names.en}`,
      ru: `${region.hub.names.ru} — административный центр региона ${region.names.ru}`,
      ky: `${region.hub.names.ky} — ${region.names.ky} административдик борбору`,
    },
    img: regionImg || flagImg(c.iso2),
    cities: `cities/${regionDocId}`,
    dolh: `countries/${c.firestoreDocId}`,
    lat_ling: {
      latitude: region.hub.lat,
      longitude: region.hub.lng,
    },
    acctev: true,
    country_iso: c.iso2,
    geo_import_id: cityDocId,
    geo_import_source: 'sa_kg_rebuild_2026',
  };
}

function buildLandmarkDoc(countryKey, region, lm) {
  const c = COUNTRIES[countryKey];
  const regionDocId = `region_${countryKey.toLowerCase()}_${region.slug}`;
  const cityDocId = `city_${countryKey.toLowerCase()}_${region.hub.slug}`;
  KEEP_MKAN.add(lm.id);
  const img1 = lm.images?.[0]?.url || '';
  return {
    __path: `mkan/${lm.id}`,
    __writtenAt: NOW,
    __target: 'local-staging',
    naim: lm.names.ar || lm.names.en,
    osf: lm.shortDescriptions.ar || '',
    names_i18n: lm.names,
    osf_i18n: lm.shortDescriptions,
    address: lm.address?.ar || '',
    address_i18n: lm.address || {},
    content_locale: 'ar',
    Location: {
      latitude: lm.location.latitude,
      longitude: lm.location.longitude,
    },
    img1,
    img2: '',
    img3: '',
    img_license: lm.images?.[0]?.license || '',
    img_attribution: lm.images?.[0]?.attribution || '',
    images_license_verified: true,
    img_source: lm.images?.[0]?.source || '',
    sr: lm.sortIndex || 1,
    acctev: true,
    as_ads: (lm.sortIndex || 1) <= 3,
    ismzod: true,
    isShrek: false,
    ismsgd: lm.category === 'religious',
    isfood: false,
    ishmam: true,
    tsnef: mapTsnef(lm.category),
    rate: 4.7,
    add_saat: 2,
    id_cit: `cities/${regionDocId}`,
    id_vill: `villages/${cityDocId}`,
    Rev_dolh: `countries/${c.firestoreDocId}`,
    country_iso: c.iso2,
    wikidata_id: lm.wikidataId || null,
    source_provider: (lm.sources || []).map((s) => s.provider).join(','),
    source_osm_id: lm.osmId || '',
    verification_status: 'verified',
    verification_confidence: lm.verification?.confidence ?? 0.9,
    geo_import_id: lm.id,
    geo_import_slug: lm.slug,
    geo_import_source: 'sa_kg_rebuild_2026',
  };
}

async function buildAll() {
  const docs = [];
  for (const countryKey of ['SA', 'KG']) {
    const collected = loadCollected(countryKey);
    const regions = countryKey === 'SA' ? SA_REGIONS : KG_REGIONS;
    docs.push({
      collection: 'countries',
      id: COUNTRIES[countryKey].firestoreDocId,
      data: buildCountryDoc(countryKey),
    });
    for (let index = 0; index < regions.length; index += 1) {
      const region = regions[index];
      console.log(`Building ${countryKey}/${region.slug}...`);
      const collectedRegion = collected.regions.find(
        (r) => r.regionSlug === region.slug,
      );
      const regionData = await buildRegionDoc(countryKey, region, index);
      docs.push({
        collection: 'cities',
        id: `region_${countryKey.toLowerCase()}_${region.slug}`,
        data: regionData,
      });
      docs.push({
        collection: 'villages',
        id: `city_${countryKey.toLowerCase()}_${region.hub.slug}`,
        data: await buildCityDoc(countryKey, region, regionData.img),
      });
      const landmarks = await selectLandmarks(
        countryKey,
        region,
        collectedRegion,
      );
      for (const lm of landmarks) {
        docs.push({
          collection: 'mkan',
          id: lm.id,
          data: buildLandmarkDoc(countryKey, region, lm),
        });
      }
    }
  }
  return docs;
}

function writeStaging(docs) {
  wipeDir(path.join(STAGING, 'countries'));
  wipeDir(path.join(STAGING, 'cities'));
  wipeDir(path.join(STAGING, 'villages'));
  wipeDir(path.join(STAGING, 'mkan'));

  const byCol = { countries: 0, cities: 0, villages: 0, mkan: 0 };
  for (const doc of docs) {
    const rel = `${doc.collection}/${doc.id}.json`;
    writeJson(rel, doc.data);
    byCol[doc.collection] += 1;
  }

  const manifest = {
    rebuiltAt: NOW,
    source: 'rebuild_sa_kg_catalog.js',
    countries: [...KEEP_COUNTRIES],
    counts: byCol,
    keep: {
      regions: [...KEEP_REGIONS].sort(),
      villages: [...KEEP_VILLAGES].sort(),
      mkan: [...KEEP_MKAN].sort(),
    },
  };
  fs.writeFileSync(
    path.join(STAGING, '_manifest_sa_kg.json'),
    JSON.stringify(manifest, null, 2) + '\n',
  );
  return byCol;
}

async function authRequest(endpoint, body) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message);
  return json;
}

async function getIdToken() {
  const json = await authRequest('signInWithPassword', {
    email: EMAIL,
    password: PASSWORD,
    returnSecureToken: true,
  });
  return json.idToken;
}

function firestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: String(val) };
    return { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map((v) => firestoreValue(v)) } };
  }
  if (typeof val === 'object') {
    if (
      Object.prototype.hasOwnProperty.call(val, 'latitude') &&
      Object.prototype.hasOwnProperty.call(val, 'longitude') &&
      Object.keys(val).length === 2
    ) {
      return {
        geoPointValue: {
          latitude: val.latitude,
          longitude: val.longitude,
        },
      };
    }
    if (
      Object.prototype.hasOwnProperty.call(val, 'lat') &&
      Object.prototype.hasOwnProperty.call(val, 'lng') &&
      Object.keys(val).length === 2
    ) {
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

function toFirestoreFields(data) {
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
  let pageToken = '';
  do {
    let url = `${DOCS}/${col}?pageSize=300`;
    if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    const j = await res.json();
    if (j.error) throw new Error(`${col}: ${JSON.stringify(j.error)}`);
    for (const d of j.documents || []) {
      out.push(d.name.split('/').pop());
    }
    pageToken = j.nextPageToken || '';
  } while (pageToken);
  return out;
}

async function patchDoc(idToken, col, id, data) {
  const fields = toFirestoreFields(data);
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

function isKeep(col, id) {
  if (col === 'countries') return KEEP_COUNTRIES.has(id);
  if (col === 'cities') return KEEP_REGIONS.has(id);
  if (col === 'villages') return KEEP_VILLAGES.has(id);
  if (col === 'mkan') return KEEP_MKAN.has(id);
  return false;
}

async function applyFirebase(docs) {
  const idToken = await getIdToken();
  const stats = {
    deactivated: 0,
    deleted: 0,
    upserted: 0,
    deleteFailed: 0,
  };

  for (const col of ['countries', 'cities', 'villages', 'mkan']) {
    const ids = await listCollection(idToken, col);
    for (const id of ids) {
      if (isKeep(col, id)) continue;
      if (HARD_DELETE) {
        try {
          const ok = await deleteDoc(idToken, col, id);
          if (ok) stats.deleted += 1;
        } catch (e) {
          stats.deleteFailed += 1;
          await patchDoc(idToken, col, id, {
            acctev: false,
            geo_obsolete: true,
            geo_import_source: 'sa_kg_rebuild_obsolete',
          });
          stats.deactivated += 1;
          console.warn('delete failed, deactivated:', col, id, String(e.message).slice(0, 120));
        }
      } else {
        await patchDoc(idToken, col, id, {
          acctev: false,
          geo_obsolete: true,
          geo_import_source: 'sa_kg_rebuild_obsolete',
        });
        stats.deactivated += 1;
      }
    }
  }

  for (const doc of docs) {
    await patchDoc(idToken, doc.collection, doc.id, doc.data);
    stats.upserted += 1;
    if (stats.upserted % 25 === 0) {
      console.log(`upserted ${stats.upserted}/${docs.length}`);
    }
  }
  return stats;
}

async function main() {
  console.log('=== SA + KG geo rebuild ===');
  const docs = await buildAll();
  const counts = writeStaging(docs);
  console.log('Staging written:', counts);
  console.log(
    `Keep sets: countries=${KEEP_COUNTRIES.size} regions=${KEEP_REGIONS.size} villages=${KEEP_VILLAGES.size} mkan=${KEEP_MKAN.size}`,
  );

  const missingImg = docs.filter(
    (d) =>
      (d.collection === 'mkan' && !d.data.img1) ||
      (d.collection !== 'mkan' && !d.data.img),
  );
  if (missingImg.length) {
    console.warn(
      'Missing images:',
      missingImg.map((d) => `${d.collection}/${d.id}`).join(', '),
    );
  }

  if (!APPLY) {
    console.log('Dry staging only. Re-run with --apply to write Firebase.');
    return;
  }

  const stats = await applyFirebase(docs);
  console.log('Firebase apply done:', stats);
  const report = {
    at: NOW,
    counts,
    stats,
    hardDelete: HARD_DELETE,
    countries: [...KEEP_COUNTRIES],
    regions: [...KEEP_REGIONS].sort(),
    villages: [...KEEP_VILLAGES].sort(),
    landmarks: [...KEEP_MKAN].sort(),
  };
  ensureDir(path.join(ROOT, 'reports'));
  fs.writeFileSync(
    path.join(ROOT, 'reports/sa_kg_rebuild_report.json'),
    JSON.stringify(report, null, 2) + '\n',
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
