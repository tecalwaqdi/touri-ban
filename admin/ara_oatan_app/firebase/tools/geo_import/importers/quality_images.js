'use strict';

/**
 * Enrich landmarks with Commons images from:
 * 1) Overpass raw tags (wikimedia_commons / image)
 * 2) Existing image_linker (Wikidata P18 → Commons search)
 * Then optionally PATCH img1 to Production.
 */

const fs = require('fs');
const path = require('path');
const { linkCountry, licenseOk, commonsMeta } = require('./image_linker');

const ROOT = path.join(__dirname, '..');
const COLLECTED = path.join(ROOT, 'datasets', 'collected');
const OVERPASS = path.join(ROOT, 'checkpoints', 'overpass');
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

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function parseCommonsFromTags(tags = {}) {
  const raw = tags.wikimedia_commons || tags.image || '';
  if (!raw || typeof raw !== 'string') return null;
  if (/^https?:\/\//i.test(raw) && !/commons\.wikimedia/i.test(raw)) {
    return null; // skip non-commons URLs (may be unlicensed)
  }
  let name = raw
    .replace(/^File:/i, '')
    .replace(/^category:/i, '')
    .trim();
  // Sometimes "File:Foo.jpg" encoded in path
  const m = name.match(/File:([^?#]+)/i);
  if (m) name = decodeURIComponent(m[1].replace(/_/g, ' '));
  name = name.replace(/_/g, ' ').trim();
  if (!name || name.toLowerCase().startsWith('category:')) return null;
  return name;
}

function enrichFromOverpassCache(countryKey) {
  const file = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  if (!fs.existsSync(file)) return { linked: 0 };
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  let linked = 0;
  let candidates = 0;

  for (const row of data.regions || []) {
    const cachePath = path.join(
      OVERPASS,
      `${countryKey}_${row.regionSlug}.json`,
    );
    if (!fs.existsSync(cachePath)) continue;
    const raw = JSON.parse(fs.readFileSync(cachePath, 'utf8'));
    const byKey = new Map();
    for (const el of raw.elements || []) {
      const key = `${el.type}/${el.id}`;
      byKey.set(key, el.tags || {});
    }

    for (const lm of row.landmarks || []) {
      if (lm.images?.[0]?.url) continue;
      const osmKey = lm.osmId; // type/id
      if (!osmKey || !byKey.has(osmKey)) continue;
      const fileName = parseCommonsFromTags(byKey.get(osmKey));
      if (!fileName) continue;
      candidates += 1;
      lm._pendingCommons = fileName;
    }
  }

  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
  return { candidates, linked };
}

async function resolvePendingCommons(countryKey, { limit = 500 } = {}) {
  const file = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  let linked = 0;
  let skipped = 0;
  let processed = 0;

  for (const row of data.regions || []) {
    for (const lm of row.landmarks || []) {
      if (lm.images?.[0]?.url) continue;
      if (!lm._pendingCommons) continue;
      if (processed >= limit) break;
      processed += 1;
      try {
        const meta = await commonsMeta(lm._pendingCommons);
        await sleep(1100);
        if (!meta || meta.missing || !licenseOk(meta.license)) {
          skipped += 1;
          delete lm._pendingCommons;
          continue;
        }
        lm.images = [
          {
            commonsFile: meta.commonsFile,
            url: meta.url,
            license: meta.license,
            licenseUrl: meta.licenseUrl,
            attribution: meta.artist || meta.credit || 'Wikimedia Commons',
            source: 'osm_wikimedia_commons_tag',
          },
        ];
        lm.verification = {
          ...(lm.verification || {}),
          imagesLicenseVerified: true,
        };
        delete lm._pendingCommons;
        linked += 1;
        console.log(`  ${lm.id} → ${meta.license}`);
      } catch (e) {
        skipped += 1;
        console.log(`  ${lm.id} fail: ${e.message}`);
        await sleep(2000);
      }
    }
  }

  data.imagesLinkedAt = new Date().toISOString();
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
  return { linked, skipped, processed };
}

async function patchImagesToProduction(countryKey) {
  const { getIdToken, patchDoc, sleep: seedSleep } = require(SEED_CLIENT);
  const file = path.join(COLLECTED, `${countryKey.toLowerCase()}_regions.json`);
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  const { idToken } = await getIdToken();
  let patched = 0;
  for (const row of data.regions || []) {
    for (const lm of row.landmarks || []) {
      const url = lm.images?.[0]?.url;
      if (!url) continue;
      await patchDoc(idToken, `mkan/${lm.id}`, {
        img1: url,
        img_license: lm.images[0].license || '',
        img_attribution: lm.images[0].attribution || '',
        images_license_verified: true,
      });
      patched += 1;
      if (patched % 20 === 0) {
        console.log(`  patched img ${patched}`);
        await seedSleep(200);
      } else {
        await seedSleep(70);
      }
    }
  }
  return { patched };
}

async function runQualityImages(args = {}) {
  const countries = String(args.country || 'ALL')
    .toUpperCase()
    .split(',')
    .flatMap((c) => (c === 'ALL' ? ['SA', 'KG', 'UZ', 'RU'] : [c.trim()]));

  const summary = [];
  for (const c of countries) {
    console.log(`\n=== ${c}: overpass commons tags ===`);
    const fromOsm = enrichFromOverpassCache(c);
    console.log(fromOsm);
    console.log(`=== ${c}: resolve pending commons ===`);
    const resolved = await resolvePendingCommons(c, {
      limit: Number(args.limit || 800),
    });
    console.log(resolved);
    console.log(`=== ${c}: wikidata/search linker ===`);
    const linked = await linkCountry(c, {
      maxPerRegion: Number(args['max-per-region'] || 20),
      wikidataOnly: args.wikidataOnly !== false && args['wikidata-only'] !== '0',
    });
    let patched = { patched: 0 };
    if (args.patchProduction || args['patch-production']) {
      console.log(`=== ${c}: patch Production img1 ===`);
      patched = await patchImagesToProduction(c);
      console.log(patched);
    }
    summary.push({
      country: c,
      fromOsm,
      resolved,
      linked: { linked: linked.linked, skipped: linked.skipped },
      patched,
    });
  }

  fs.mkdirSync(REPORTS, { recursive: true });
  const out = path.join(REPORTS, 'quality_images_run.json');
  fs.writeFileSync(out, JSON.stringify({ summary, at: new Date().toISOString() }, null, 2), 'utf8');
  return summary;
}

module.exports = {
  runQualityImages,
  enrichFromOverpassCache,
  resolvePendingCommons,
  patchImagesToProduction,
};
