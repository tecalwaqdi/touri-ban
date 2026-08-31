'use strict';

/**
 * Seed driver_requirements on operational Driver markets (SA, KG).
 * Read-only backup printed; writes driver_requirements only.
 *
 * Auth: Firebase CLI OAuth (same as phase_8b).
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const {GoogleAuth} = require('google-auth-library');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

const TARGETS = ['saudi_arabia', 'kyrgyzstan'];

const BASELINE_REQUIREMENTS = {
  profilePhoto: {
    enabled: true,
    required: true,
    expiryRequired: false,
    operationalBlockingOnExpiry: false,
    effectiveFrom: '2026-08-26',
    gracePeriodDays: 30,
    displayOrder: 0,
  },
  nationalId: {
    enabled: true,
    required: true,
    expiryRequired: false,
    operationalBlockingOnExpiry: false,
    effectiveFrom: '2026-08-26',
    gracePeriodDays: 30,
    displayOrder: 1,
  },
  vehicleRegistration: {
    enabled: true,
    required: true,
    expiryRequired: true,
    operationalBlockingOnExpiry: true,
    expiryWarningDays: 30,
    effectiveFrom: '2026-08-26',
    gracePeriodDays: 30,
    displayOrder: 2,
  },
  driverLicense: {
    enabled: true,
    required: true,
    expiryRequired: true,
    operationalBlockingOnExpiry: true,
    expiryWarningDays: 30,
    effectiveFrom: '2026-08-26',
    gracePeriodDays: 30,
    displayOrder: 3,
  },
  vehicleInsurance: {
    enabled: true,
    required: false,
    expiryRequired: false,
    operationalBlockingOnExpiry: false,
    effectiveFrom: '2026-08-26',
    gracePeriodDays: 30,
    displayOrder: 4,
  },
};

async function getDb() {
  const cfgPath = path.join(
    os.homedir(),
    '.config/configstore/firebase-tools.json',
  );
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  const auth = new GoogleAuth({
    credentials: {
      type: 'authorized_user',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: cfg.tokens.refresh_token,
    },
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    projectId: PROJECT_ID,
  });
  const {Firestore} = require('@google-cloud/firestore');
  return new Firestore({
    projectId: PROJECT_ID,
    authClient: await auth.getClient(),
  });
}

function enabledCount(reqs) {
  if (!reqs || typeof reqs !== 'object') return 0;
  return Object.values(reqs).filter(
    (v) => v && typeof v === 'object' && v.enabled === true,
  ).length;
}

(async () => {
  const db = await getDb();
  for (const countryId of TARGETS) {
    const ref = db.collection('countries').doc(countryId);
    const snap = await ref.get();
    if (!snap.exists) {
      console.log(`SKIP_MISSING_COUNTRY=${countryId}`);
      continue;
    }
    const before = snap.data() || {};
    const beforeReqs = before.driver_requirements || {};
    console.log(
      `COUNTRY_CONFIG_BEFORE_${countryId}=`,
      JSON.stringify({
        enabled: enabledCount(beforeReqs),
        keys: Object.keys(beforeReqs),
      }),
    );
    if (enabledCount(beforeReqs) > 0) {
      console.log(`SKIP_ALREADY_CONFIGURED=${countryId}`);
      continue;
    }
    await ref.set({driver_requirements: BASELINE_REQUIREMENTS}, {merge: true});
    const after = (await ref.get()).data() || {};
    const afterReqs = after.driver_requirements || {};
    console.log(
      `COUNTRY_CONFIG_AFTER_${countryId}=`,
      JSON.stringify({
        enabled: enabledCount(afterReqs),
        keys: Object.keys(afterReqs),
      }),
    );
    console.log(`SEEDED_${countryId}=PASS`);
  }
})().catch((e) => {
  console.error('SEED_FAIL', e.message || e);
  process.exit(1);
});
