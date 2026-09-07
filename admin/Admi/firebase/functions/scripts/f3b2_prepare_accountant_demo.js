'use strict';

/**
 * F3-B2 — prepare demo Accountant user (SAFE BY DEFAULT).
 *
 * Planned production email: accountant.demo@touri-taxi.com
 * Password: NEVER commit. Pass via ACCOUNTANT_DEMO_PASSWORD env only.
 *
 * Default: --dry-run (prints intended payload, no Auth/Firestore writes).
 * Production create is BLOCKED unless:
 *   F3B2_ALLOW_PRODUCTION_DEMO=YES
 *   AND --create
 *
 * Emulator:
 *   FIRESTORE_EMULATOR_HOST=... FIREBASE_AUTH_EMULATOR_HOST=... \
 *   ACCOUNTANT_DEMO_PASSWORD='...' node scripts/f3b2_prepare_accountant_demo.js --create --emulator
 *
 * Usage dry-run:
 *   node scripts/f3b2_prepare_accountant_demo.js
 */

const admin = require('firebase-admin');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const PLANNED_EMAIL = 'accountant.demo@touri-taxi.com';
const ACCOUNTANT_RULE = 5;

function parseArgs(argv) {
  return {
    dryRun: !argv.includes('--create'),
    emulator: argv.includes('--emulator'),
    create: argv.includes('--create'),
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const password = process.env.ACCOUNTANT_DEMO_PASSWORD || '';
  const allowProd = process.env.F3B2_ALLOW_PRODUCTION_DEMO === 'YES';

  const payload = {
    email: PLANNED_EMAIL,
    isAdminRule: ACCOUNTANT_RULE,
    actev_user: true,
    display_name: 'Accountant Demo',
    // No Isagent — must not touch country-agent locks.
    Isagent: false,
    isagent: false,
    IsAdmin: false,
    note: 'F3-B2 Global Accountant (finance claim, read-only)',
  };

  console.log(JSON.stringify({
    MODE: args.dryRun ? 'DRY_RUN' : 'CREATE',
    EMULATOR: args.emulator,
    PRODUCTION_USER_CREATED: false,
    PLANNED_EMAIL,
    PASSWORD_COMMITTED: false,
    PASSWORD_PROVIDED: password.length > 0,
    PROFILE: payload,
  }, null, 2));

  if (args.dryRun) {
    console.log('STOP — dry-run only. No Auth/Firestore writes.');
    return;
  }

  if (!args.emulator && !allowProd) {
    console.error(
      'REFUSED: production demo create blocked. Use --emulator or set F3B2_ALLOW_PRODUCTION_DEMO=YES for B2D only.',
    );
    process.exit(2);
  }

  if (password.length < 10) {
    console.error('REFUSED: set ACCOUNTANT_DEMO_PASSWORD (min 10 chars). Never commit it.');
    process.exit(2);
  }

  if (!admin.apps.length) {
    admin.initializeApp({projectId: PROJECT_ID});
  }
  const auth = admin.auth();
  const db = admin.firestore();

  const user = await auth.createUser({
    email: PLANNED_EMAIL,
    password,
    emailVerified: true,
    disabled: false,
  });
  await db.doc(`user/${user.uid}`).set({
    email: PLANNED_EMAIL,
    uid: user.uid,
    display_name: payload.display_name,
    actev_user: true,
    isAdminRule: ACCOUNTANT_RULE,
    IsAdmin: false,
    Isagent: false,
    isagent: false,
    created_time: admin.firestore.FieldValue.serverTimestamp(),
    created_by_qa: false,
    panel_persona: 'accountant',
  }, {merge: true});
  // Claims sync via onWrite trigger / syncClaimsForUid.
  console.log(JSON.stringify({
    CREATED_UID: user.uid,
    PRODUCTION_USER_CREATED: !args.emulator,
    NOTE: 'Force token refresh after login (refreshMyClaims).',
  }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
