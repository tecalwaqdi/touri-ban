/**
 * Read-only Production geo inventory for Admin Geo Management.
 *
 * Hierarchy: countries → cities(regions) → villages(cities) → mkan(landmarks)
 *
 * Usage:
 *   ADMIN_QA_EMAIL=... ADMIN_QA_PASSWORD=... node audit_admin_geo_inventory.js
 *
 * Never writes. Never hard-deletes.
 */
const fs = require('fs');
const path = require('path');

const API_KEY = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const EMAIL = process.env.ADMIN_QA_EMAIL || process.env.SEED_EMAIL || 'info@touri-taxi.com';
const PASSWORD = process.env.ADMIN_QA_PASSWORD || process.env.SEED_PASSWORD || '';
const BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
  '/databases/(default)/documents';

const ALIAS_RE = /^(?:region|city|lm)_sa_(?:es|ma|pt|tn|id|my|in)_/i;

async function getIdToken() {
  if (!PASSWORD) throw new Error('ADMIN_QA_PASSWORD / SEED_PASSWORD required');
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
  const json = await res.json();
  if (json.error) throw new Error(json.error.message);
  return json.idToken;
}

function decode(raw) {
  if (!raw || typeof raw !== 'object') return null;
  if ('nullValue' in raw) return null;
  if ('stringValue' in raw) return raw.stringValue;
  if ('booleanValue' in raw) return raw.booleanValue;
  if ('integerValue' in raw) return Number(raw.integerValue);
  if ('doubleValue' in raw) return Number(raw.doubleValue);
  if ('referenceValue' in raw) return raw.referenceValue;
  if ('geoPointValue' in raw) {
    return {
      lat: Number(raw.geoPointValue.latitude),
      lng: Number(raw.geoPointValue.longitude),
    };
  }
  if ('mapValue' in raw) {
    const out = {};
    for (const [k, v] of Object.entries(raw.mapValue.fields || {})) {
      out[k] = decode(v);
    }
    return out;
  }
  if ('arrayValue' in raw) {
    return (raw.arrayValue.values || []).map(decode);
  }
  return null;
}

function docId(name) {
  return String(name || '').split('/').pop();
}

function refId(ref) {
  if (!ref) return null;
  return String(ref).split('/').pop() || null;
}

function isHttpUrl(s) {
  return typeof s === 'string' && /^https?:\/\//i.test(s.trim());
}

async function listAll(idToken, collection) {
  const documents = [];
  let pageToken = '';
  do {
    const url = new URL(`${BASE}/${collection}`);
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    if (!response.ok) {
      throw new Error(`${collection}: ${response.status} ${await response.text()}`);
    }
    const payload = await response.json();
    documents.push(...(payload.documents || []));
    pageToken = payload.nextPageToken || '';
  } while (pageToken);
  return documents.map((d) => {
    const fields = {};
    for (const [k, v] of Object.entries(d.fields || {})) fields[k] = decode(v);
    return { id: docId(d.name), path: d.name, fields, updateTime: d.updateTime };
  });
}

function classifyIssues(countries, regions, cities, landmarks) {
  const countryIds = new Set(countries.map((d) => d.id));
  const regionIds = new Set(regions.map((d) => d.id));
  const cityIds = new Set(cities.map((d) => d.id));

  const issues = {
    WITHOUT_COUNTRY: [],
    WITHOUT_REGION: [],
    WITHOUT_CITY: [],
    WITHOUT_LOCATION: [],
    WITHOUT_IMAGE: [],
    INVALID_IMAGE_URL: [],
    INVALID_REFERENCE: [],
    BROKEN_PARENT_REFERENCE: [],
    LEGACY_ALIAS: [],
  };

  for (const r of regions) {
    if (ALIAS_RE.test(r.id)) issues.LEGACY_ALIAS.push({ type: 'region', id: r.id });
    const dolh = refId(r.fields.dolh);
    if (!dolh) issues.WITHOUT_COUNTRY.push({ type: 'region', id: r.id });
    else if (!countryIds.has(dolh)) {
      issues.BROKEN_PARENT_REFERENCE.push({
        type: 'region',
        id: r.id,
        field: 'dolh',
        value: dolh,
      });
    }
    const img = r.fields.img || '';
    if (!img) issues.WITHOUT_IMAGE.push({ type: 'region', id: r.id });
    else if (!isHttpUrl(img) && !String(img).startsWith('assets/')) {
      issues.INVALID_IMAGE_URL.push({ type: 'region', id: r.id, img });
    }
  }

  for (const c of cities) {
    if (ALIAS_RE.test(c.id)) issues.LEGACY_ALIAS.push({ type: 'city', id: c.id });
    const region = refId(c.fields.cities);
    const dolh = refId(c.fields.dolh);
    if (!dolh) issues.WITHOUT_COUNTRY.push({ type: 'city', id: c.id });
    else if (!countryIds.has(dolh)) {
      issues.BROKEN_PARENT_REFERENCE.push({
        type: 'city',
        id: c.id,
        field: 'dolh',
        value: dolh,
      });
    }
    if (!region) issues.WITHOUT_REGION.push({ type: 'city', id: c.id });
    else if (!regionIds.has(region)) {
      issues.BROKEN_PARENT_REFERENCE.push({
        type: 'city',
        id: c.id,
        field: 'cities',
        value: region,
      });
    }
    if (!c.fields.lat_ling) issues.WITHOUT_LOCATION.push({ type: 'city', id: c.id });
    const img = c.fields.img || '';
    if (!img) issues.WITHOUT_IMAGE.push({ type: 'city', id: c.id });
    else if (!isHttpUrl(img) && !String(img).startsWith('assets/')) {
      issues.INVALID_IMAGE_URL.push({ type: 'city', id: c.id, img });
    }
  }

  for (const m of landmarks) {
    if (ALIAS_RE.test(m.id)) {
      issues.LEGACY_ALIAS.push({ type: 'landmark', id: m.id });
      continue; // aliases are compatibility docs — still counted separately
    }
    const country = refId(m.fields.Rev_dolh);
    const region = refId(m.fields.id_cit);
    const city = refId(m.fields.id_vill);
    if (!country) issues.WITHOUT_COUNTRY.push({ type: 'landmark', id: m.id });
    else if (!countryIds.has(country)) {
      issues.BROKEN_PARENT_REFERENCE.push({
        type: 'landmark',
        id: m.id,
        field: 'Rev_dolh',
        value: country,
      });
    }
    if (!region) issues.WITHOUT_REGION.push({ type: 'landmark', id: m.id });
    else if (!regionIds.has(region)) {
      issues.BROKEN_PARENT_REFERENCE.push({
        type: 'landmark',
        id: m.id,
        field: 'id_cit',
        value: region,
      });
    }
    if (!city) issues.WITHOUT_CITY.push({ type: 'landmark', id: m.id });
    else if (!cityIds.has(city)) {
      issues.BROKEN_PARENT_REFERENCE.push({
        type: 'landmark',
        id: m.id,
        field: 'id_vill',
        value: city,
      });
    }
    const loc = m.fields.Location;
    if (!loc || loc.lat == null || loc.lng == null) {
      issues.WITHOUT_LOCATION.push({ type: 'landmark', id: m.id });
    }
    const img = m.fields.img1 || m.fields.img || '';
    if (!img) issues.WITHOUT_IMAGE.push({ type: 'landmark', id: m.id });
    else if (!isHttpUrl(img) && !String(img).startsWith('assets/')) {
      issues.INVALID_IMAGE_URL.push({ type: 'landmark', id: m.id, img: String(img).slice(0, 80) });
    }
  }

  return issues;
}

async function main() {
  const idToken = await getIdToken();
  const [countries, regions, cities, landmarks] = await Promise.all([
    listAll(idToken, 'countries'),
    listAll(idToken, 'cities'),
    listAll(idToken, 'villages'),
    listAll(idToken, 'mkan'),
  ]);

  const aliasLandmarks = landmarks.filter((d) => ALIAS_RE.test(d.id));
  const logicalLandmarks = landmarks.filter((d) => !ALIAS_RE.test(d.id));
  const aliasRegions = regions.filter((d) => ALIAS_RE.test(d.id));
  const logicalRegions = regions.filter((d) => !ALIAS_RE.test(d.id));
  const aliasCities = cities.filter((d) => ALIAS_RE.test(d.id));
  const logicalCities = cities.filter((d) => !ALIAS_RE.test(d.id));

  const saudiCountry = countries.find(
    (c) =>
      c.fields.saudi === true ||
      String(c.fields.iso_code || '').toUpperCase() === 'SA' ||
      /سعود|saudi/i.test(String(c.fields.naim || '')),
  );
  const saudiRefSuffix = saudiCountry ? `/countries/${saudiCountry.id}` : null;
  const saudiLogical = saudiRefSuffix
    ? logicalLandmarks.filter((m) =>
        String(m.fields.Rev_dolh || '').endsWith(saudiRefSuffix),
      )
    : [];

  const issues = classifyIssues(countries, regions, cities, landmarks);
  const issueCounts = Object.fromEntries(
    Object.entries(issues).map(([k, v]) => [k, v.length]),
  );

  const report = {
    generatedAt: new Date().toISOString(),
    projectId: PROJECT_ID,
    writeMode: 'READ_ONLY',
    COUNTRY_COLLECTION: 'countries',
    REGION_COLLECTION: 'cities',
    CITY_COLLECTION: 'villages',
    LANDMARK_COLLECTION: 'mkan',
    Countries: { TOTAL: countries.length },
    Regions: {
      TOTAL: regions.length,
      LOGICAL: logicalRegions.length,
      ALIAS: aliasRegions.length,
    },
    CitiesVillages: {
      TOTAL: cities.length,
      LOGICAL: logicalCities.length,
      ALIAS: aliasCities.length,
    },
    Landmarks: {
      RAW_TOTAL: landmarks.length,
      LEGACY_ALIASES: aliasLandmarks.length,
      LOGICAL_TOTAL: logicalLandmarks.length,
      SAUDI_SCOPE_LOGICAL: saudiLogical.length,
      SAUDI_COUNTRY_ID: saudiCountry?.id || null,
    },
    ISSUE_COUNTS: issueCounts,
    SAMPLE_ISSUES: Object.fromEntries(
      Object.entries(issues).map(([k, v]) => [k, v.slice(0, 25)]),
    ),
    REPAIR_CLASSIFICATION: {
      AUTO_SAFE: [],
      MANUAL_REVIEW: Object.entries(issueCounts)
        .filter(([, n]) => n > 0)
        .map(([k, n]) => ({ issue: k, count: n, note: 'Do not auto-fix' })),
    },
  };

  const outDir = path.join(__dirname, '../../../releases/2026-08-28/admin_geo');
  fs.mkdirSync(outDir, { recursive: true });
  const outPath = path.join(outDir, 'GEO_INVENTORY.json');
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  console.log(`\nWrote ${outPath}`);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
