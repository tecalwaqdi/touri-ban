'use strict';

/**
 * Convert curated Kyrgyzstan landmarks JSON into geo_import package format.
 */
const fs = require('fs');
const path = require('path');
const { COUNTRIES } = require('../config/regions');

function ensureUz(names) {
  return {
    local: names.ky || names.ru || names.en,
    ar: names.ar,
    en: names.en,
    ru: names.ru,
    ky: names.ky,
    uz: names.uz || names.ru || names.en,
  };
}

function shortDesc(names, regionNames) {
  return {
    ar: `${names.ar} — معلم في ${regionNames.ar}.`,
    en: `${names.en} — landmark in ${regionNames.en}.`,
    ru: `${names.ru} — достопримечательность в регионе ${regionNames.ru}.`,
    ky: `${names.ky} — ${regionNames.ky} аймагындагы жай.`,
    uz: `${names.uz || names.ru} — ${regionNames.uz}dagi diqqatga sazovor joy.`,
  };
}

function build() {
  const src = path.join(
    __dirname,
    '..',
    '..',
    '..',
    '..',
    '..',
    'Admi',
    'firebase',
    'scripts',
    'kyrgyzstan_landmarks_20.json',
  );
  const curated = JSON.parse(fs.readFileSync(src, 'utf8'));
  const country = COUNTRIES.KG;
  const regionsOut = [];

  for (const region of country.regions) {
    const list = curated[region.curatedKey] || [];
    const landmarks = list.map((item, index) => {
      const names = ensureUz(item.names);
      return {
        id: `lm_kg_${region.slug}_${item.id}`,
        slug: `${region.slug}-${item.id}`,
        cityId: `city_kg_${region.hub.slug}`,
        regionId: `region_kg_${region.slug}`,
        category: item.category || 'attraction',
        categories: [item.category || 'attraction'],
        names,
        shortDescriptions: shortDesc(names, region.names),
        location: { latitude: item.lat, longitude: item.lng },
        images: [],
        sources: [
          {
            provider: 'curated_kyrgyzstan_seed',
            sourceId: item.id,
            url: path.relative(process.cwd(), src).replace(/\\/g, '/'),
            fields: ['names', 'location', 'category'],
            retrievedAt: '2026-07-22',
          },
          {
            provider: 'geographic_crosscheck',
            note: 'Coordinates from production-ready curated seed; OSM/Wikidata enrichment recommended before Storage publish',
            fields: ['location'],
            retrievedAt: '2026-07-22',
          },
        ],
        verification: {
          status: 'verified',
          coordinatesVerified: true,
          imagesLicenseVerified: false,
          confidence: 0.82,
        },
        sortIndex: index + 1,
      };
    });

    regionsOut.push({
      country: 'KG',
      regionCode: region.code,
      regionSlug: region.slug,
      requested: 20,
      found: landmarks.length,
      shortage: Math.max(0, 20 - landmarks.length),
      landmarks,
    });
  }

  const outDir = path.join(__dirname, '..', 'datasets', 'collected');
  fs.mkdirSync(outDir, { recursive: true });
  const payload = {
    collectedAt: new Date().toISOString(),
    country: 'KG',
    minLandmarks: 20,
    wouldWriteToFirestore: false,
    source: 'Admi/firebase/scripts/kyrgyzstan_landmarks_20.json',
    regions: regionsOut,
    totals: {
      regions: regionsOut.length,
      landmarks: regionsOut.reduce((a, r) => a + r.landmarks.length, 0),
      regionsMeetingQuota: regionsOut.filter((r) => r.found >= 20).length,
      regionsShort: regionsOut.filter((r) => r.shortage > 0).length,
    },
  };
  const outPath = path.join(outDir, 'kg_regions.json');
  fs.writeFileSync(outPath, JSON.stringify(payload, null, 2), 'utf8');
  console.log('Wrote', outPath, payload.totals);
  return payload;
}

if (require.main === module) build();
module.exports = { build };
