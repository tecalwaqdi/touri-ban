'use strict';

/**
 * Phased Production importer for Touri geo + vehicles.
 * Reuses Admi seed_production_client auth/PATCH helpers.
 *
 * HARD GATE: requires --target=production AND --i-approve-production
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const REPORTS = path.join(ROOT, 'reports');
const COLLECTED = path.join(ROOT, 'datasets', 'collected');

const SEED_CLIENT = path.join(
  ROOT,
  '..',
  '..',
  '..',
  '..',
  'Admi',
  'firebase',
  'scripts',
  'seed_production_client.js',
);

function loadSeedClient() {
  // eslint-disable-next-line import/no-dynamic-require
  return require(SEED_CLIENT);
}

function assertProductionGate(args) {
  if (args.target !== 'production') {
    throw new Error('Use --target=production for live writes (or local-staging).');
  }
  if (!args['i-approve-production'] && args.iApproveProduction !== true) {
    throw new Error(
      'Refusing Production write. Pass --i-approve-production to continue.',
    );
  }
}

function toClientData(data, { ref, geo }) {
  const out = {};
  for (const [k, v] of Object.entries(data)) {
    if (v == null) continue;
    if (
      typeof v === 'object' &&
      typeof v.latitude === 'number' &&
      typeof v.longitude === 'number' &&
      Object.keys(v).length === 2
    ) {
      out[k] = geo(v.latitude, v.longitude);
      continue;
    }
    if (
      typeof v === 'string' &&
      /^(countries|cities|villages|mkan|type_car)\//.test(v) &&
      ['dolh', 'cities', 'id_cit', 'id_vill', 'Rev_dolh'].includes(k)
    ) {
      out[k] = ref(v);
      continue;
    }
    out[k] = v;
  }
  return out;
}

async function writeDocs(docs, { idToken, patchDoc, ref, geo, sleep }, label) {
  let written = 0;
  for (const doc of docs) {
    const data = toClientData(doc.data, { ref, geo });
    let ok = false;
    let lastErr;
    for (let attempt = 0; attempt < 6; attempt++) {
      try {
        await patchDoc(idToken, doc.path, data);
        ok = true;
        break;
      } catch (e) {
        lastErr = e;
        const msg = String(e.message || e);
        const retryable =
          msg.includes('ECONNRESET') ||
          msg.includes('fetch failed') ||
          msg.includes('429') ||
          msg.includes('UNAVAILABLE') ||
          msg.includes('503');
        if (!retryable || attempt === 5) break;
        const wait = 1500 * (attempt + 1);
        console.log(`  retry ${doc.path} in ${wait}ms (${msg.slice(0, 80)})`);
        await sleep(wait);
      }
    }
    if (!ok) throw lastErr;
    written += 1;
    if (written % 25 === 0) {
      console.log(`  [${label}] ${written}/${docs.length}`);
      await sleep(250);
    } else {
      await sleep(100);
    }
  }
  return written;
}

function loadCollected(countryKey) {
  const p = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

async function runPhase1Vehicles(args) {
  assertProductionGate(args);
  const { getIdToken, patchDoc, ref, geo, sleep } = loadSeedClient();
  const { vehicleDocs } = require('./firestore_mapper');
  const docs = vehicleDocs();
  console.log(`Phase 1 — vehicles: ${docs.length} type_car docs`);
  const { idToken } = await getIdToken();
  const written = await writeDocs(docs, { idToken, patchDoc, ref, geo, sleep }, 'vehicles');
  const report = {
    phase: 1,
    name: 'vehicles',
    target: 'production',
    written,
    paths: docs.map((d) => d.path),
    finishedAt: new Date().toISOString(),
  };
  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'phase_1_vehicles.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Phase 1 done →', out);
  return report;
}

async function runPhase2GeoTree(args) {
  assertProductionGate(args);
  const { getIdToken, patchDoc, ref, geo, sleep } = loadSeedClient();
  const { COUNTRIES } = require('../config/regions');
  const {
    countryDoc,
    regionDoc,
    cityDoc,
  } = require('./firestore_mapper');

  const countries = String(args.country || 'ALL')
    .toUpperCase()
    .split(',')
    .flatMap((c) => (c === 'ALL' ? ['SA', 'KG', 'UZ', 'RU'] : [c.trim()]));

  const docs = [];
  for (const key of countries) {
    const c = COUNTRIES[key];
    if (!c) continue;
    docs.push(countryDoc(key));
    // Enrich country with flag + bounds placeholders used by app matching
    const last = docs[docs.length - 1];
    last.data.img = `https://flagcdn.com/w320/${c.iso2.toLowerCase()}.png`;
    last.data.hederImg = `https://flagcdn.com/w1280/${c.iso2.toLowerCase()}.png`;
    last.data.isvat = ['SA', 'UZ', 'KG', 'RU'].includes(key);
    last.data.CurrencySymbol = c.currencySymbol;
    for (const region of c.regions) {
      docs.push(regionDoc(key, region));
      docs.push(cityDoc(key, region));
    }
  }

  console.log(`Phase 2 — geo tree: ${docs.length} docs (${countries.join(',')})`);
  const { idToken } = await getIdToken();
  const written = await writeDocs(docs, { idToken, patchDoc, ref, geo, sleep }, 'geo-tree');
  const report = {
    phase: 2,
    name: 'countries_regions_cities',
    countries,
    written,
    finishedAt: new Date().toISOString(),
  };
  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'phase_2_geo_tree.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Phase 2 done →', out);
  return report;
}

async function runPhase3Landmarks(args) {
  assertProductionGate(args);
  const { getIdToken, patchDoc, ref, geo, sleep } = loadSeedClient();
  const { COUNTRIES } = require('../config/regions');
  const { landmarkDoc } = require('./firestore_mapper');

  const countries = String(args.country || 'SA')
    .toUpperCase()
    .split(',')
    .map((c) => c.trim())
    .filter(Boolean);

  const docs = [];
  const gaps = [];
  for (const key of countries) {
    const collected = loadCollected(key);
    const country = COUNTRIES[key];
    if (!collected || !country) {
      gaps.push({ country: key, error: 'missing_dataset_or_config' });
      continue;
    }
    const bySlug = new Map(country.regions.map((r) => [r.slug, r]));
    for (const row of collected.regions || []) {
      const region = bySlug.get(row.regionSlug);
      if (!region) {
        gaps.push({ country: key, region: row.regionSlug, error: 'region_not_in_config' });
        continue;
      }
      for (const lm of row.landmarks || []) {
        docs.push(landmarkDoc(key, region, lm));
      }
    }
  }

  console.log(`Phase 3 — landmarks: ${docs.length} mkan docs (${countries.join(',')})`);
  const { idToken } = await getIdToken();
  const written = await writeDocs(docs, { idToken, patchDoc, ref, geo, sleep }, 'landmarks');
  const report = {
    phase: 3,
    name: 'landmarks',
    countries,
    written,
    gaps,
    finishedAt: new Date().toISOString(),
  };
  fs.mkdirSync(REPORTS, { recursive: true });
  const tag = countries.join('_').toLowerCase();
  const out = path.join(REPORTS, `phase_3_landmarks_${tag}.json`);
  fs.writeFileSync(out, JSON.stringify(report, null, 2), 'utf8');
  console.log('Phase 3 done →', out);
  return report;
}

async function runPhase4Verify() {
  // Lightweight local verify of reports + collected totals
  const { COUNTRIES } = require('../config/regions');
  const summary = {
    phase: 4,
    name: 'verify',
    collected: {},
    reportsPresent: {
      phase1: fs.existsSync(path.join(REPORTS, 'phase_1_vehicles.json')),
      phase2: fs.existsSync(path.join(REPORTS, 'phase_2_geo_tree.json')),
    },
    finishedAt: new Date().toISOString(),
  };
  for (const key of Object.keys(COUNTRIES)) {
    const c = loadCollected(key);
    summary.collected[key] = c?.totals || null;
  }
  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'phase_4_verify.json');
  fs.writeFileSync(out, JSON.stringify(summary, null, 2), 'utf8');
  console.log(JSON.stringify(summary, null, 2));
  return summary;
}

async function runPhase(args) {
  const phase = Number(args.phase || args._?.[1] || 1);
  switch (phase) {
    case 1:
      return runPhase1Vehicles(args);
    case 2:
      return runPhase2GeoTree(args);
    case 3:
      return runPhase3Landmarks(args);
    case 4:
      return runPhase4Verify();
    default:
      throw new Error(`Unknown phase ${phase}. Use 1–4.`);
  }
}

module.exports = {
  runPhase,
  runPhase1Vehicles,
  runPhase2GeoTree,
  runPhase3Landmarks,
  runPhase4Verify,
};
