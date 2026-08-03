#!/usr/bin/env node
'use strict';

/**
 * Touri geo import CLI.
 * Default: dry-run (never writes Firestore / Production).
 *
 *   node src/cli.js audit
 *   node src/cli.js collect --country=SA --min-landmarks=20
 *   node src/cli.js collect --country=KG
 *   node src/cli.js collect --country=UZ --limit-regions=2
 *   node src/cli.js dry-run --country=SA
 *   node src/cli.js dry-run --country=ALL
 *   node src/cli.js vehicles
 *   node src/cli.js coverage
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const REPORTS = path.join(ROOT, 'reports');
const COLLECTED = path.join(ROOT, 'datasets', 'collected');

function parseArgs(argv) {
  const args = { _: [] };
  for (const a of argv) {
    if (a.startsWith('--')) {
      const [k, v] = a.slice(2).split('=');
      args[k] = v === undefined ? true : v;
      // aliases
      if (k === 'min-landmarks') args.minLandmarks = v;
      if (k === 'limit-regions') args.limitRegions = v;
      if (k === 'start-index') args.startIndex = v;
    } else {
      args._.push(a);
    }
  }
  return args;
}

function writeJson(name, data) {
  fs.mkdirSync(REPORTS, { recursive: true });
  const p = path.join(REPORTS, name);
  fs.writeFileSync(p, JSON.stringify(data, null, 2), 'utf8');
  return p;
}

function loadCollected(countryKey) {
  const p = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function cmdAudit() {
  const { COUNTRIES } = require('../config/regions');
  const summary = {
    canonicalFirebaseRoot: 'ara_oatan_app/firebase',
    productionWriteBlocked: true,
    countriesConfigured: Object.keys(COUNTRIES),
    regionCounts: Object.fromEntries(
      Object.entries(COUNTRIES).map(([k, c]) => [k, c.regions.length]),
    ),
    targetLandmarksPerRegion: 20,
  };
  const out = writeJson('geo_audit.json', summary);
  console.log(JSON.stringify(summary, null, 2));
  console.log('Wrote', out);
}

async function cmdCollect(args) {
  const country = String(args.country || 'SA').toUpperCase();
  if (country === 'KG') {
    const { build } = require('../collectors/build_kg_dataset');
    return build();
  }
  if (args.environment === 'production') {
    console.error('Refusing collect-with-write. Collect caches locally only.');
    process.exit(2);
  }
  const { collectCountry } = require('../collectors/overpass_collector');
  return collectCountry(country, {
    minLandmarks: Number(args.minLandmarks || args['min-landmarks'] || 20),
    limitRegions: args.limitRegions || args['limit-regions'],
    startIndex: args.startIndex || args['start-index'] || 0,
    force: !!args['force-refresh'] || !!args.force,
  });
}

function cmdVehicles() {
  const { catalogReport } = require('../datasets/vehicles/vehicle_catalog');
  const report = catalogReport();
  const out = writeJson('vehicle_catalog_dry_run.json', report);
  console.log(
    JSON.stringify(
      {
        wouldWriteToFirestore: false,
        categories: report.categories,
        models: report.models.length,
        modelsByCountry: report.modelsByCountry,
      },
      null,
      2,
    ),
  );
  console.log('Wrote', out);
}

function cmdCoverage() {
  const { COUNTRIES } = require('../config/regions');
  const rows = [];
  for (const [key, country] of Object.entries(COUNTRIES)) {
    const collected = loadCollected(key);
    const regionCount = country.regions.length;
    const meeting = collected?.totals?.regionsMeetingQuota ?? 0;
    const landmarks = collected?.totals?.landmarks ?? 0;
    const shortRegions =
      collected?.regions
        ?.filter((r) => (r.shortage || 0) > 0 || r.error)
        ?.map((r) => ({
          slug: r.regionSlug,
          found: r.found || 0,
          shortage: r.shortage || 20,
          error: r.error || null,
        })) || [];
    rows.push({
      country: key,
      officialRegionsConfigured: regionCount,
      regionsWithDataset: collected?.regions?.length || 0,
      regionsMeeting20: meeting,
      landmarksCollected: landmarks,
      targetLandmarks: regionCount * 20,
      gaps: shortRegions,
      datasetReady: !!collected,
      note: country.note || null,
    });
  }
  const out = writeJson('coverage_matrix.json', {
    generatedAt: new Date().toISOString(),
    wouldWriteToFirestore: false,
    rows,
  });
  console.log(JSON.stringify(rows, null, 2));
  console.log('Wrote', out);
}

function cmdDryRun(args) {
  if (args.environment === 'production') {
    console.error('Refusing production. Dry-run / local JSON only.');
    process.exit(2);
  }
  const countryArg = String(args.country || 'ALL').toUpperCase();
  const countries =
    countryArg === 'ALL' ? ['SA', 'KG', 'UZ', 'RU'] : [countryArg];

  // Ensure KG dataset exists
  if (countries.includes('KG') && !loadCollected('KG')) {
    require('../collectors/build_kg_dataset').build();
  }

  const { catalogReport } = require('../datasets/vehicles/vehicle_catalog');
  const vehicles = catalogReport();
  const geo = [];

  for (const key of countries) {
    const collected = loadCollected(key);
    if (!collected) {
      geo.push({
        country: key,
        status: 'missing_dataset',
        hint:
          key === 'KG'
            ? 'run: npm run geo:collect -- --country=KG'
            : `run: npm run geo:collect -- --country=${key}`,
      });
      continue;
    }
    geo.push({
      country: key,
      status: 'dry-run-ready',
      totals: collected.totals,
      regionsShort: (collected.regions || [])
        .filter((r) => (r.shortage || 0) > 0 || r.error)
        .map((r) => ({
          slug: r.regionSlug,
          found: r.found,
          shortage: r.shortage,
          error: r.error || null,
        })),
      sampleLandmarkIds: (collected.regions || [])
        .flatMap((r) => (r.landmarks || []).slice(0, 2).map((l) => l.id))
        .slice(0, 10),
    });
  }

  const summary = {
    mode: 'dry-run',
    wouldWriteToFirestore: false,
    generatedAt: new Date().toISOString(),
    geo,
    vehicles: {
      categories: vehicles.categories,
      models: vehicles.models,
      modelsByCountry: vehicles.modelsByCountry,
    },
  };
  const out = writeJson(
    `dry_run_multi_${countryArg.toLowerCase()}.json`,
    summary,
  );
  console.log(JSON.stringify(summary, null, 2));
  console.log('Wrote', out);
}

function cmdValidate(args) {
  // Prefer collected datasets; fall back to Makkah pilot
  const country = String(args.country || 'SA').toUpperCase();
  if (country === 'SA' && args.region === 'makkah') {
    const { validatePilotDataset } = require('../validators/validate_pilot');
    const dataset = require('../datasets/pilots/sa_makkah_region');
    const report = validatePilotDataset(dataset);
    writeJson('validation_sa_makkah.json', report);
    console.log(JSON.stringify({
      landmarkTotal: report.landmarkTotal,
      okCount: report.okCount,
      publishableCandidateCount: report.publishableCandidateCount,
      needsReviewCount: report.needsReviewCount,
    }, null, 2));
    return;
  }
  return cmdCoverage();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const cmd = args._[0] || 'dry-run';
  switch (cmd) {
    case 'audit':
      return cmdAudit();
    case 'collect':
      return cmdCollect(args);
    case 'vehicles':
      return cmdVehicles();
    case 'coverage':
      return cmdCoverage();
    case 'validate':
      return cmdValidate(args);
    case 'dry-run':
      return cmdDryRun(args);
    case 'report':
      cmdCoverage();
      cmdVehicles();
      return cmdDryRun({ ...args, country: args.country || 'ALL' });
    case 'quality-audit': {
      const { runFullAudit } = require('../validators/audit_all_landmarks');
      return runFullAudit();
    }
    case 'quality-images':
      return cmdQualityImages(args);
    case 'phase':
      return cmdPhase(args);
    case 'images':
      return cmdImages(args);
    case 'import':
      return cmdImport(args);
    case 'staging-verify': {
      const { verifyLocalStaging } = require('../importers/local_staging_import');
      const v = verifyLocalStaging();
      console.log(JSON.stringify(v, null, 2));
      if (!v.ok) process.exit(2);
      return;
    }
    default:
      console.error('Unknown command', cmd);
      process.exit(1);
  }
}

async function cmdQualityImages(args) {
  const { runQualityImages } = require('../importers/quality_images');
  if (args['patch-production'] === true || args['patch-production'] === '') {
    args.patchProduction = true;
  }
  const summary = await runQualityImages(args);
  console.log(JSON.stringify(summary, null, 2));
}

async function cmdPhase(args) {
  const { runPhase } = require('../importers/phased_production_import');
  // Support --i-approve-production boolean flag
  if (args['i-approve-production'] === true || args['i-approve-production'] === '') {
    args.iApproveProduction = true;
    args['i-approve-production'] = true;
  }
  const report = await runPhase(args);
  console.log(JSON.stringify({
    phase: report.phase,
    name: report.name,
    written: report.written,
    countries: report.countries,
    finishedAt: report.finishedAt,
  }, null, 2));
}

async function cmdImages(args) {
  const { linkCountry } = require('../importers/image_linker');
  const country = String(args.country || 'SA').toUpperCase();
  const countries =
    country === 'ALL' ? ['SA', 'KG', 'UZ', 'RU'] : [country];
  const summaries = [];
  for (const c of countries) {
    console.log(`Linking images for ${c}...`);
    summaries.push(
      await linkCountry(c, {
        maxPerRegion: Number(args['max-per-region'] || 20),
        limitRegions: args['limit-regions'],
      }),
    );
  }
  console.log(
    JSON.stringify(
      summaries.map((s) => ({
        country: s.country,
        linked: s.linked,
        skipped: s.skipped,
      })),
      null,
      2,
    ),
  );
}

async function cmdImport(args) {
  const target = args.target || 'local-staging';
  if (target === 'production') {
    console.error('Production import is blocked.');
    process.exit(2);
  }
  if (target === 'emulator') {
    const { importToEmulator } = require('../importers/emulator_import');
    const report = await importToEmulator({ ...args, target: 'emulator' });
    console.log(JSON.stringify(report, null, 2));
    return;
  }
  if (target === 'local-staging' || target === 'staging') {
    const { importToLocalStaging } = require('../importers/local_staging_import');
    const report = importToLocalStaging(args);
    console.log(JSON.stringify(report, null, 2));
    return;
  }
  console.error('Unknown --target. Use local-staging or emulator.');
  process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
