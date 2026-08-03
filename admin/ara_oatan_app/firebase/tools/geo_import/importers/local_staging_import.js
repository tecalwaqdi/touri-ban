'use strict';

/**
 * Local staging store — mirrors Firestore paths as JSON files.
 * Used when Firestore Emulator cannot run (e.g. no Java JDK).
 * Never contacts Production Firebase.
 */

const fs = require('fs');
const path = require('path');
const { buildPlanFromDisk } = require('./emulator_import');

const ROOT = path.join(__dirname, '..');
const STAGING_DIR = path.join(ROOT, 'staging', 'firestore');
const REPORTS = path.join(ROOT, 'reports');

function writeDoc(doc) {
  const filePath = path.join(STAGING_DIR, ...doc.path.split('/')) + '.json';
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

function importToLocalStaging(args = {}) {
  if (args.environment === 'production' || args.target === 'production') {
    throw new Error('Refusing production write.');
  }

  const countries = String(args.country || 'ALL')
    .toUpperCase()
    .split(',')
    .flatMap((c) => (c === 'ALL' ? ['SA', 'KG', 'UZ', 'RU'] : [c.trim()]));

  const plan = buildPlanFromDisk(countries);
  const writtenFiles = [];

  for (const doc of plan.docs) {
    writtenFiles.push(writeDoc(doc));
  }

  // Index for quick counts
  const index = {
    target: 'local-staging',
    wouldWriteToProduction: false,
    generatedAt: new Date().toISOString(),
    stats: plan.stats,
    docCount: plan.docs.length,
    root: STAGING_DIR.replace(/\\/g, '/'),
    samplePaths: plan.docs.slice(0, 15).map((d) => d.path),
  };

  fs.mkdirSync(REPORTS, { recursive: true });
  const indexPath = path.join(REPORTS, 'local_staging_import_result.json');
  fs.writeFileSync(indexPath, JSON.stringify(index, null, 2), 'utf8');

  // Manifest listing all paths
  const manifestPath = path.join(STAGING_DIR, '_manifest.json');
  fs.writeFileSync(
    manifestPath,
    JSON.stringify(
      {
        ...index,
        paths: plan.docs.map((d) => d.path),
      },
      null,
      2,
    ),
    'utf8',
  );

  return { ...index, indexPath, manifestPath, written: writtenFiles.length };
}

function verifyLocalStaging() {
  const manifestPath = path.join(STAGING_DIR, '_manifest.json');
  if (!fs.existsSync(manifestPath)) {
    return { ok: false, error: 'No staging import found. Run import --target=local-staging first.' };
  }
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  let missing = 0;
  let present = 0;
  for (const p of manifest.paths || []) {
    const filePath = path.join(STAGING_DIR, ...p.split('/')) + '.json';
    if (fs.existsSync(filePath)) present += 1;
    else missing += 1;
  }
  return {
    ok: missing === 0 && present === (manifest.paths || []).length,
    present,
    missing,
    expected: (manifest.paths || []).length,
    stats: manifest.stats,
  };
}

module.exports = {
  importToLocalStaging,
  verifyLocalStaging,
  STAGING_DIR,
};
