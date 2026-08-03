'use strict';

/**
 * Replace Wikimedia Maps previews with licensed Commons photos where possible,
 * then optionally PATCH img1 in Production for upgraded landmarks only.
 *
 *   node importers/upgrade_map_to_commons.js
 *   node importers/upgrade_map_to_commons.js --country=RU --patch-production
 *   node importers/upgrade_map_to_commons.js --wikidata-only --patch-production
 *   node importers/upgrade_map_to_commons.js --limit=120 --patch-production
 */

const fs = require('fs');
const path = require('path');
const {
  enrichLandmark,
  isMapPreviewImage,
  licenseOk,
} = require('./image_linker');

const ROOT = path.join(__dirname, '..');
const COLLECTED = path.join(ROOT, 'datasets', 'collected');
const REPORTS = path.join(ROOT, 'reports');

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

function parseArgs(argv) {
  const args = { _: [] };
  for (const a of argv) {
    if (a.startsWith('--')) {
      const [k, v] = a.slice(2).split('=');
      args[k] = v === undefined ? true : v;
    } else {
      args._.push(a);
    }
  }
  return args;
}

function loadCountry(countryKey) {
  const file = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  return {
    file,
    data: JSON.parse(fs.readFileSync(file, 'utf8')),
  };
}

async function upgradeCountry(countryKey, opts = {}) {
  const { file, data } = loadCountry(countryKey);
  const limit = Number(opts.limit || 9999);
  const wikidataOnly = !!opts.wikidataOnly;
  const preferWikidataFirst = opts.preferWikidataFirst !== false;

  const candidates = [];
  for (const row of data.regions || []) {
    for (const lm of row.landmarks || []) {
      const img = lm.images?.[0];
      if (!isMapPreviewImage(img)) continue;
      if (img?.license && licenseOk(img.license) && !isMapPreviewImage(img)) {
        continue;
      }
      candidates.push({ row, lm });
    }
  }

  candidates.sort((a, b) => {
    if (!preferWikidataFirst) return 0;
    const aw = a.lm.wikidataId ? 0 : 1;
    const bw = b.lm.wikidataId ? 0 : 1;
    return aw - bw;
  });

  let upgraded = 0;
  let skipped = 0;
  let processed = 0;
  const upgradedIds = [];
  const rows = [];

  for (const { lm } of candidates) {
    if (processed >= limit) break;
    if (wikidataOnly && !lm.wikidataId) {
      skipped += 1;
      continue;
    }
    processed += 1;
    const { lm: next, result } = await enrichLandmark(lm, {
      wikidataOnly,
    });
    rows.push(result);
    if (result.linked && next.images?.[0]?.url && !isMapPreviewImage(next.images[0])) {
      Object.assign(lm, next);
      upgraded += 1;
      upgradedIds.push(lm.id);
      console.log(`  ✓ ${lm.id} → ${result.license} (${result.source})`);
    } else {
      skipped += 1;
      console.log(`  · ${lm.id} → ${result.reason || 'skipped'}`);
    }
  }

  data.imagesUpgradedAt = new Date().toISOString();
  data.imageUpgradeStats = {
    candidates: candidates.length,
    processed,
    upgraded,
    skipped,
  };
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');

  return { country: countryKey, upgraded, skipped, processed, upgradedIds, rows };
}

async function patchUpgradedToProduction(upgradedByCountry) {
  const { getIdToken, patchDoc, sleep } = require(SEED_CLIENT);
  const { idToken } = await getIdToken();
  let patched = 0;

  for (const summary of upgradedByCountry) {
    if (!summary.upgradedIds?.length) continue;
    const { data } = loadCountry(summary.country);
    const byId = new Map();
    for (const row of data.regions || []) {
      for (const lm of row.landmarks || []) byId.set(lm.id, lm);
    }
    for (const id of summary.upgradedIds) {
      const lm = byId.get(id);
      const url = lm?.images?.[0]?.url;
      if (!url || isMapPreviewImage(lm.images[0])) continue;
      await patchDoc(idToken, `mkan/${id}`, {
        img1: url,
        img_license: lm.images[0].license || '',
        img_attribution: lm.images[0].attribution || '',
        images_license_verified: true,
        img_source: lm.images[0].source || 'commons',
      });
      patched += 1;
      if (patched % 15 === 0) {
        console.log(`  patched ${patched}`);
        await sleep(250);
      } else {
        await sleep(80);
      }
    }
  }
  return { patched };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const countries = String(args.country || 'ALL')
    .toUpperCase()
    .split(',')
    .flatMap((c) => (c === 'ALL' ? ['SA', 'KG', 'UZ', 'RU'] : [c.trim()]));

  const wikidataOnly =
    args['wikidata-only'] === true ||
    args['wikidata-only'] === '1' ||
    args.wikidataOnly === true;

  const limit = args.limit ? Number(args.limit) : wikidataOnly ? 9999 : 80;
  const patch =
    args['patch-production'] === true || args.patchProduction === true;

  console.log('Upgrade map→Commons', {
    countries,
    wikidataOnly,
    limitPerCountry: limit,
    patchProduction: patch,
  });

  const summaries = [];
  for (const c of countries) {
    console.log(`\n=== ${c} ===`);
    const summary = await upgradeCountry(c, {
      limit,
      wikidataOnly,
    });
    console.log({
      upgraded: summary.upgraded,
      skipped: summary.skipped,
      processed: summary.processed,
    });
    summaries.push(summary);
  }

  let patchResult = { patched: 0 };
  if (patch) {
    console.log('\n=== PATCH Production (upgraded only) ===');
    patchResult = await patchUpgradedToProduction(summaries);
    console.log(patchResult);
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = {
    at: new Date().toISOString(),
    wikidataOnly,
    limitPerCountry: limit,
    patchProduction: patch,
    patchResult,
    summaries: summaries.map((s) => ({
      country: s.country,
      upgraded: s.upgraded,
      skipped: s.skipped,
      processed: s.processed,
      upgradedIds: s.upgradedIds,
    })),
  };
  const outPath = path.join(REPORTS, 'upgrade_map_to_commons.json');
  fs.writeFileSync(outPath, JSON.stringify(out, null, 2), 'utf8');
  console.log('\nWrote', outPath);
  console.log(
    'Total upgraded:',
    summaries.reduce((n, s) => n + s.upgraded, 0),
  );
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}

module.exports = { upgradeCountry, patchUpgradedToProduction };
