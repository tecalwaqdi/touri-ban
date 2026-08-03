'use strict';

/**
 * Collect named tourism/historic/park landmarks from OpenStreetMap Overpass.
 * Caches raw results under checkpoints/overpass/. Never writes Firestore.
 * Does NOT use Google Maps Static API keys.
 */

const fs = require('fs');
const path = require('path');
const { COUNTRIES } = require('../config/regions');

const OVERPASS_ENDPOINTS = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

const CACHE_DIR = path.join(__dirname, '..', 'checkpoints', 'overpass');
const DATASET_DIR = path.join(__dirname, '..', 'datasets', 'collected');

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function pointOf(element) {
  const lat = element.lat ?? element.center?.lat;
  const lng = element.lon ?? element.center?.lon;
  return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null;
}

function score(element) {
  const t = element.tags || {};
  return (
    (t.wikidata ? 8 : 0) +
    (t.wikipedia ? 8 : 0) +
    (t.image || t.wikimedia_commons ? 6 : 0) +
    (t.website || t['contact:website'] ? 3 : 0) +
    (t['name:ar'] ? 3 : 0) +
    (t['name:en'] ? 2 : 0) +
    (t['name:ru'] ? 2 : 0) +
    (t.tourism ? 4 : 0) +
    (t.historic ? 3 : 0)
  );
}

function looksArabic(text) {
  return /[\u0600-\u06FF]/.test(String(text || ''));
}

function buildNames(tags) {
  const local = tags.name || '';
  const arTag = tags['name:ar'] || '';
  // Never copy English into `ar` — client + Arabic UI treat polluted ar as EN.
  const ar =
    (arTag && looksArabic(arTag) ? arTag : '') ||
    (local && looksArabic(local) ? local : '') ||
    '';
  const en = tags['name:en'] || (!looksArabic(local) ? local : '') || '';
  const ru = tags['name:ru'] || '';
  const fallback = ar || en || local || ru || '';
  return {
    local: local || fallback,
    ar,
    en: en || fallback,
    ru: ru || fallback,
    ky: tags['name:ky'] || ru || fallback,
    uz: tags['name:uz'] || ru || fallback,
  };
}

function categoryOf(tags) {
  if (tags.tourism === 'museum') return 'museum';
  if (tags.tourism === 'viewpoint') return 'viewpoint';
  if (tags.tourism === 'zoo') return 'zoo';
  if (tags.tourism === 'theme_park') return 'entertainment';
  if (tags.tourism === 'hotel') return 'skip';
  if (tags.amenity === 'place_of_worship') return 'religious';
  if (tags.historic) return 'historic';
  if (tags.leisure === 'park') return 'nature';
  if (tags.tourism) return 'attraction';
  return 'attraction';
}

function overpassQuery(iso3166_2) {
  return `
    [out:json][timeout:180];
    area["ISO3166-2"="${iso3166_2}"]["boundary"="administrative"]->.r;
    (
      nwr["tourism"~"attraction|museum|viewpoint|gallery|zoo|theme_park|artwork"]["name"](area.r);
      nwr["historic"~"monument|memorial|castle|ruins|archaeological_site|yes"]["name"](area.r);
      nwr["leisure"="park"]["name"](area.r);
      nwr["amenity"="place_of_worship"]["name"]["tourism"](area.r);
    );
    out center tags;
  `;
}

function bboxQuery(lat, lng, radiusDeg = 0.75) {
  const south = lat - radiusDeg;
  const north = lat + radiusDeg;
  const west = lng - radiusDeg;
  const east = lng + radiusDeg;
  return `
    [out:json][timeout:180];
    (
      nwr["tourism"~"attraction|museum|viewpoint|gallery|zoo|theme_park|artwork"]["name"](${south},${west},${north},${east});
      nwr["historic"~"monument|memorial|castle|ruins|archaeological_site|yes"]["name"](${south},${west},${north},${east});
      nwr["leisure"="park"]["name"](${south},${west},${north},${east});
      nwr["amenity"="place_of_worship"]["name"](${south},${west},${north},${east});
    );
    out center tags;
  `;
}

async function fetchOverpassQuery(query, label) {
  let lastError;
  for (let attempt = 0; attempt < 8; attempt++) {
    const endpoint = OVERPASS_ENDPOINTS[attempt % OVERPASS_ENDPOINTS.length];
    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
          'User-Agent': 'TouriTaxiGeoImport/0.2 (dry-run collector; local)',
        },
        body: new URLSearchParams({ data: query }),
      });
      if (res.ok) {
        return res.json();
      }
      lastError = new Error(`Overpass ${label}: HTTP ${res.status}`);
    } catch (e) {
      lastError = e;
    }
    await sleep(Math.min(45000, 5000 * (attempt + 1)));
  }
  throw lastError || new Error(`Overpass failed for ${label}`);
}

async function fetchOverpass(iso3166_2, region) {
  try {
    return await fetchOverpassQuery(overpassQuery(iso3166_2), iso3166_2);
  } catch (areaError) {
    if (!region?.hub?.lat || !region?.hub?.lng) throw areaError;
    const radius =
      region.slug?.includes('city') || region.code?.endsWith('TK') || region.code?.endsWith('MOW')
        ? 0.35
        : 1.1;
    console.warn(`  area query failed for ${iso3166_2}; bbox fallback r=${radius}`);
    return fetchOverpassQuery(
      bboxQuery(region.hub.lat, region.hub.lng, radius),
      `${iso3166_2}-bbox`,
    );
  }
}

function selectTop(elements, minCount = 20) {
  const seen = new Set();
  const ranked = (elements || [])
    .filter((el) => pointOf(el) && el.tags?.name && categoryOf(el.tags) !== 'skip')
    .sort((a, b) => score(b) - score(a))
    .filter((el) => {
      const p = pointOf(el);
      const key = `${(el.tags.name || '').toLowerCase()}|${p.lat.toFixed(4)}|${p.lng.toFixed(4)}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });

  // Diversify categories when possible
  const picked = [];
  const byCat = new Map();
  for (const el of ranked) {
    const cat = categoryOf(el.tags);
    const n = byCat.get(cat) || 0;
    if (n >= 8) continue;
    byCat.set(cat, n + 1);
    picked.push(el);
    if (picked.length >= minCount) break;
  }
  if (picked.length < minCount) {
    for (const el of ranked) {
      if (picked.includes(el)) continue;
      picked.push(el);
      if (picked.length >= minCount) break;
    }
  }
  return picked.slice(0, Math.max(minCount, picked.length));
}

function toLandmarkRecords(countryIso2, region, elements) {
  return elements.map((el, index) => {
    const tags = el.tags || {};
    const point = pointOf(el);
    const names = buildNames(tags);
    const osmType = el.type;
    const osmId = String(el.id);
    return {
      id: `lm_${countryIso2.toLowerCase()}_${region.slug}_osm_${osmType}_${osmId}`,
      slug: `${region.slug}-${osmType}-${osmId}`,
      cityId: `city_${countryIso2.toLowerCase()}_${region.hub.slug}`,
      regionId: `region_${countryIso2.toLowerCase()}_${region.slug}`,
      osmId: `${osmType}/${osmId}`,
      wikidataId: tags.wikidata || null,
      category: categoryOf(tags),
      categories: [categoryOf(tags)],
      names,
      shortDescriptions: {
        ar: `معلم موثق من OpenStreetMap في ${region.names.ar}.`,
        en: `OpenStreetMap-verified place in ${region.names.en}.`,
        ru: `Место из OpenStreetMap в регионе ${region.names.ru}.`,
        ky: `OpenStreetMap аркылуу ырасталган жай (${region.names.ky}).`,
        uz: `OpenStreetMap orqali tasdiqlangan joy (${region.names.uz}).`,
      },
      location: { latitude: point.lat, longitude: point.lng },
      images: [],
      imageNote: tags.wikimedia_commons
        ? `Commons candidate: ${tags.wikimedia_commons}`
        : 'No Commons file on OSM tags; license pipeline pending.',
      sources: [
        {
          provider: 'openstreetmap',
          sourceId: `${osmType}/${osmId}`,
          url: `https://www.openstreetmap.org/${osmType}/${osmId}`,
          fields: ['names', 'location', 'category'],
          retrievedAt: new Date().toISOString().slice(0, 10),
        },
        ...(tags.wikidata
          ? [
              {
                provider: 'wikidata',
                sourceId: tags.wikidata,
                url: `https://www.wikidata.org/wiki/${tags.wikidata}`,
                fields: ['wikidataId'],
                retrievedAt: new Date().toISOString().slice(0, 10),
              },
            ]
          : []),
      ],
      verification: {
        status: tags.wikidata ? 'verified' : 'needs_review',
        coordinatesVerified: true,
        imagesLicenseVerified: false,
        confidence: tags.wikidata ? 0.86 : 0.72,
      },
      sortIndex: index + 1,
    };
  });
}

async function collectRegion(countryKey, region, { minLandmarks = 20, force = false } = {}) {
  const country = COUNTRIES[countryKey];
  const iso =
    country.overpassIsoField === 'iso'
      ? `${country.overpassIsoPrefix}${region.iso}`
      : region.code;
  fs.mkdirSync(CACHE_DIR, { recursive: true });
  const cacheFile = path.join(CACHE_DIR, `${countryKey}_${region.slug}.json`);

  let raw;
  if (!force && fs.existsSync(cacheFile)) {
    raw = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
  } else {
    console.log(`Overpass fetch ${iso} (${region.names.en})...`);
    raw = await fetchOverpass(iso, region);
    fs.writeFileSync(cacheFile, JSON.stringify(raw), 'utf8');
  }

  const selected = selectTop(raw.elements || [], minLandmarks);
  const landmarks = toLandmarkRecords(country.iso2, region, selected);
  return {
    country: countryKey,
    regionCode: region.code || iso,
    regionSlug: region.slug,
    requested: minLandmarks,
    found: landmarks.length,
    shortage: Math.max(0, minLandmarks - landmarks.length),
    landmarks,
  };
}

async function collectCountry(countryKey, opts = {}) {
  const country = COUNTRIES[countryKey];
  if (!country) throw new Error(`Unknown country ${countryKey}`);
  if (!country.regions?.length) throw new Error(`No regions for ${countryKey}`);

  const minLandmarks = Number(opts.minLandmarks || 20);
  const limit = opts.limitRegions ? Number(opts.limitRegions) : country.regions.length;
  const start = Number(opts.startIndex || 0);
  const regions = country.regions.slice(start, start + limit);
  const results = [];

  for (const region of regions) {
    try {
      const row = await collectRegion(countryKey, region, {
        minLandmarks,
        force: !!opts.force,
      });
      results.push(row);
      console.log(
        `  ${region.slug}: ${row.found}/${minLandmarks}` +
          (row.shortage ? ` (shortage ${row.shortage})` : ''),
      );
    } catch (e) {
      results.push({
        country: countryKey,
        regionSlug: region.slug,
        regionCode: region.code,
        error: String(e.message || e),
        found: 0,
        shortage: minLandmarks,
        landmarks: [],
      });
      console.error(`  ${region.slug}: ERROR ${e.message || e}`);
    }
    await sleep(1500);
  }

  fs.mkdirSync(DATASET_DIR, { recursive: true });
  const outPath = path.join(DATASET_DIR, `${countryKey.toLowerCase()}_regions.json`);
  const payload = {
    collectedAt: new Date().toISOString(),
    country: countryKey,
    minLandmarks,
    wouldWriteToFirestore: false,
    regions: results,
    totals: {
      regions: results.length,
      landmarks: results.reduce((a, r) => a + (r.landmarks?.length || 0), 0),
      regionsMeetingQuota: results.filter((r) => (r.found || 0) >= minLandmarks).length,
      regionsShort: results.filter((r) => (r.shortage || 0) > 0 || r.error).length,
    },
  };
  fs.writeFileSync(outPath, JSON.stringify(payload, null, 2), 'utf8');
  console.log('Wrote', outPath);
  return payload;
}

module.exports = {
  collectCountry,
  collectRegion,
  selectTop,
  toLandmarkRecords,
};
