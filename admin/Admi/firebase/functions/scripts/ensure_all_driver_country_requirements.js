#!/usr/bin/env node
'use strict';

/**
 * Production-safe migration: initialize missing/empty driver_requirements.
 * Usage:
 *   node scripts/ensure_all_driver_country_requirements.js --dry-run
 *   node scripts/ensure_all_driver_country_requirements.js --write
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const countryConfig = require('../driver_country_config.js');

const dryRun = process.argv.includes('--dry-run') || !process.argv.includes('--write');

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

async function main() {
  const snap = await db.collection('countries').get();
  const backupRows = [];
  let configured = 0;
  let empty = 0;
  let missing = 0;
  let malformed = 0;
  let wouldInitialize = 0;
  const toInit = [];

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const status = countryConfig.classifyRequirements(data.driver_requirements);
    if (status === 'configured') configured++;
    else if (status === 'empty') empty++;
    else if (status === 'missing') missing++;
    else if (status === 'malformed') malformed++;

    backupRows.push({
      countryId: doc.id,
      status,
      enabledCount: countryConfig.countEnabledRequirements(data.driver_requirements),
      driver_requirements: countryConfig.sanitizeRequirementsForLog(
        data.driver_requirements,
      ),
    });

    const result = await countryConfig.ensureDriverCountryConfiguration(
      db,
      doc.ref,
      {dryRun, actor: dryRun ? 'migration_dry_run' : 'migration_write'},
    );
    if (result.action === 'would_initialize' || result.action === 'initialized') {
      wouldInitialize++;
      toInit.push(doc.id);
    }
    if (!dryRun && result.action === 'initialized') {
      console.log(
        [
          `COUNTRY=${doc.id}`,
          `BEFORE_ENABLED_COUNT=${result.beforeEnabled}`,
          `ACTION=${result.action}`,
          `AFTER_ENABLED_COUNT=${result.afterEnabled}`,
          `CUSTOM_CONFIG_PRESERVED=${result.customConfigPreserved}`,
        ].join('\n'),
      );
    }
  }

  console.log('COUNTRIES_TOTAL =', snap.size);
  console.log('CONFIGURED =', configured);
  console.log('MISSING =', missing);
  console.log('EMPTY =', empty);
  console.log('MALFORMED =', malformed);
  console.log('WOULD_INITIALIZE =', wouldInitialize);
  if (toInit.length) {
    console.log('WOULD_INITIALIZE_IDS =', toInit.join(', '));
  }

  const reportDir = path.resolve(
    __dirname,
    '../../../../releases/2026-08-27/driver_country_governance',
  );
  fs.mkdirSync(reportDir, {recursive: true});
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = path.join(
    reportDir,
    dryRun ? `migration_dry_run_${stamp}.json` : `migration_write_${stamp}.json`,
  );
  fs.writeFileSync(
    backupPath,
    JSON.stringify({dryRun, backupRows, toInit}, null, 2),
  );
  console.log('REPORT =', backupPath);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
