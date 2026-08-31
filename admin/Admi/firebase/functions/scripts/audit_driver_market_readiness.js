#!/usr/bin/env node
'use strict';

/**
 * Read-only market readiness audit for all countries.
 * Usage: node scripts/audit_driver_market_readiness.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const countryConfig = require('../driver_country_config.js');

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

async function main() {
  const rows = await countryConfig.auditAllCountriesMarketReadiness(db);
  let ready = 0;
  let missingReqs = 0;
  let missingCatalog = 0;
  let incomplete = 0;

  console.log('COUNTRY\tISO\tREQUIREMENTS_ENABLED\tVEHICLE_TYPES_ACTIVE\tDRIVER_READY\tISSUE');
  for (const row of rows) {
    const driverReady = row.registrationReady ? 'YES' : 'NO';
    if (row.status === 'READY') ready++;
    else if (row.status === 'MISSING_DRIVER_REQUIREMENTS') missingReqs++;
    else if (row.status === 'MISSING_VEHICLE_CATALOG') missingCatalog++;
    else incomplete++;

    console.log(
      [
        row.countryId,
        row.iso2 || '-',
        row.enabledRequirements,
        row.activeVehicles,
        driverReady,
        row.reasonCode,
      ].join('\t'),
    );
  }

  console.log('');
  console.log('READY =', ready);
  console.log('MISSING_REQUIREMENTS =', missingReqs);
  console.log('MISSING_VEHICLE_CATALOG =', missingCatalog);
  console.log('INCOMPLETE =', incomplete);

  const reportDir = path.resolve(
    __dirname,
    '../../../../releases/2026-08-27/driver_country_governance',
  );
  fs.mkdirSync(reportDir, {recursive: true});
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outPath = path.join(reportDir, `readiness_audit_${stamp}.json`);
  fs.writeFileSync(outPath, JSON.stringify(rows, null, 2));
  console.log('REPORT =', outPath);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
