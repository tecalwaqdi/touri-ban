'use strict';

/**
 * Detect and deactivate legacy Saudi region docs that duplicate region_sa_*.
 *
 * Legacy seed IDs: region_riyadh, region_makkah, ...
 * Canonical import: region_sa_riyadh, region_sa_makkah, ...
 *
 * Default: dry-run report only.
 * Apply: --apply  (sets acctev:false on legacy cities + dependent villages + mkans)
 *
 *   node importers/cleanup_sa_duplicate_regions.js
 *   node importers/cleanup_sa_duplicate_regions.js --apply
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
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

const PROJECT_ID = 'tutorial-multi-language-70gx4j';

/** Known legacy Saudi region document IDs from older seed. */
const LEGACY_REGION_IDS = [
  'region_riyadh',
  'region_makkah',
  'region_madinah',
  'region_eastern',
  'region_asir',
  'region_alula',
  'region_tabuk',
  'region_hail',
  'region_jazan',
  'region_najran',
  'region_qassim',
  'region_ahsa',
  'region_baha',
  'region_jouf',
  'region_northern_borders',
];

const CANONICAL_PREFIX = 'region_sa_';

function parseArgs(argv) {
  const args = {};
  for (const a of argv) {
    if (a.startsWith('--')) {
      const [k, v] = a.slice(2).split('=');
      args[k] = v === undefined ? true : v;
    }
  }
  return args;
}

function docIdFromName(name) {
  const parts = String(name || '').split('/');
  return parts[parts.length - 1];
}

function decodeFields(fields = {}) {
  const out = {};
  for (const [k, v] of Object.entries(fields)) {
    if (v.stringValue !== undefined) out[k] = v.stringValue;
    else if (v.booleanValue !== undefined) out[k] = v.booleanValue;
    else if (v.integerValue !== undefined) out[k] = Number(v.integerValue);
    else if (v.doubleValue !== undefined) out[k] = v.doubleValue;
    else if (v.referenceValue !== undefined) {
      const ref = v.referenceValue;
      out[k] = ref.includes('/documents/')
        ? ref.split('/documents/')[1]
        : ref;
    } else if (v.nullValue !== undefined) out[k] = null;
  }
  return out;
}

async function listCollection(idToken, collectionId, pageSize = 300) {
  const docs = [];
  let pageToken = '';
  do {
    const url = new URL(
      `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collectionId}`,
    );
    url.searchParams.set('pageSize', String(pageSize));
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    if (!res.ok) {
      throw new Error(`LIST ${collectionId}: ${res.status} ${await res.text()}`);
    }
    const json = await res.json();
    for (const doc of json.documents || []) {
      docs.push({
        id: docIdFromName(doc.name),
        path: doc.name.split('/documents/')[1],
        fields: decodeFields(doc.fields || {}),
      });
    }
    pageToken = json.nextPageToken || '';
  } while (pageToken);
  return docs;
}

async function runQuery(idToken, structuredQuery) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ structuredQuery }),
  });
  if (!res.ok) {
    throw new Error(`runQuery failed: ${res.status} ${await res.text()}`);
  }
  const rows = await res.json();
  return (rows || [])
    .filter((r) => r.document)
    .map((r) => ({
      id: docIdFromName(r.document.name),
      path: r.document.name.split('/documents/')[1],
      fields: decodeFields(r.document.fields || {}),
    }));
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const apply = args.apply === true;
  const { getIdToken, patchDoc, sleep } = require(SEED_CLIENT);
  const { idToken } = await getIdToken();

  console.log('Listing cities / villages / scanning legacy SA regions...');
  const cities = await listCollection(idToken, 'cities');
  const villages = await listCollection(idToken, 'villages');

  const canonical = cities.filter((c) => c.id.startsWith(CANONICAL_PREFIX));
  const legacy = cities.filter((c) => LEGACY_REGION_IDS.includes(c.id));
  const otherSaLooking = cities.filter(
    (c) =>
      !c.id.startsWith(CANONICAL_PREFIX) &&
      !LEGACY_REGION_IDS.includes(c.id) &&
      /^region_/.test(c.id) &&
      !/^region_(kg|uz|ru)_/.test(c.id),
  );

  const legacyPaths = new Set(legacy.map((c) => c.path));
  const dependentVillages = villages.filter((v) => {
    const citiesRef = v.fields.cities || '';
    return legacyPaths.has(citiesRef) || LEGACY_REGION_IDS.includes(docIdFromName(citiesRef));
  });

  const dependentMkans = [];
  for (const region of legacy) {
    const regionPath = `cities/${region.id}`;
    try {
      const mkans = await runQuery(idToken, {
        from: [{ collectionId: 'mkan' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'id_cit' },
            op: 'EQUAL',
            value: {
              referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${regionPath}`,
            },
          },
        },
        limit: 500,
      });
      dependentMkans.push(...mkans);
      await sleep(150);
    } catch (e) {
      console.warn(`  query mkan for ${region.id}: ${e.message}`);
    }
  }

  const report = {
    at: new Date().toISOString(),
    apply,
    counts: {
      citiesTotal: cities.length,
      canonicalSaRegions: canonical.length,
      legacySaRegions: legacy.length,
      otherRegionLooking: otherSaLooking.length,
      dependentVillages: dependentVillages.length,
      dependentMkans: dependentMkans.length,
    },
    canonicalIds: canonical.map((c) => c.id).sort(),
    legacyIds: legacy.map((c) => c.id).sort(),
    otherRegionLookingIds: otherSaLooking.map((c) => c.id).sort(),
    dependentVillageIds: dependentVillages.map((v) => v.id),
    dependentMkanIds: dependentMkans.map((m) => m.id),
    action: apply
      ? 'deactivate acctev=false on legacy cities + villages + mkans'
      : 'dry-run only',
  };

  fs.mkdirSync(REPORTS, { recursive: true });
  const outPath = path.join(REPORTS, 'cleanup_sa_duplicate_regions.json');
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2), 'utf8');
  console.log(JSON.stringify(report.counts, null, 2));
  console.log('Legacy regions:', report.legacyIds);
  console.log('Wrote', outPath);

  if (!apply) {
    console.log('\nDry-run only. Re-run with --apply to deactivate duplicates.');
    return;
  }

  let deactivated = 0;
  const targets = [
    ...legacy.map((d) => d.path),
    ...dependentVillages.map((d) => d.path),
    ...dependentMkans.map((d) => d.path),
  ];
  console.log(`\nDeactivating ${targets.length} docs...`);
  for (const docPath of targets) {
    await patchDoc(idToken, docPath, {
      acctev: false,
      geo_duplicate_legacy: true,
      geo_deactivated_at: new Date().toISOString(),
    });
    deactivated += 1;
    if (deactivated % 20 === 0) {
      console.log(`  deactivated ${deactivated}/${targets.length}`);
      await sleep(200);
    } else {
      await sleep(60);
    }
  }

  report.deactivated = deactivated;
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2), 'utf8');
  console.log(`Done. Deactivated ${deactivated} docs.`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}

module.exports = { LEGACY_REGION_IDS };
