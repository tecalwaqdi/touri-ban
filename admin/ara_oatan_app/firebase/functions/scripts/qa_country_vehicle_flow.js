'use strict';

/**
 * QA: country-scoped type_car writes + booking vehicle/country match.
 *
 * Against Firestore emulator (rules-unit-testing):
 *   1) Agent A (countries/sa) can create type_car with dolh=countries/sa
 *   2) Agent A cannot create/update type_car for countries/kg
 *   3) Agent A cannot change dolh from sa → kg
 *   4) Super admin can write any
 *
 * Always (no emulator needed):
 *   5) matchesCountryTypeCar rejects car SA + country KG
 *      (same gate used by verifiedBookingAmount in ngenius_payments.js)
 *
 * Does NOT deploy. Does NOT modify firestore.rules.
 *
 * Usage (from firebase/functions):
 *   node scripts/qa_country_vehicle_flow.js
 *
 * With emulator:
 *   firebase emulators:exec --project demo-touri-taxi \
 *     --config ../firebase.json --only firestore \
 *     "node scripts/qa_country_vehicle_flow.js"
 *   # or set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 with emulator already up
 */

const fs = require('fs');
const path = require('path');
const net = require('net');

const {matchesCountryTypeCar} = require('../driver_country_config.js');

const PROJECT_ID = 'demo-touri-taxi';
const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');
const DEFAULT_HOST = '127.0.0.1';
const DEFAULT_PORT = 8080;

const results = [];
let failed = 0;

function pass(name) {
  results.push({name, ok: true});
  console.log(`PASS  ${name}`);
}

function fail(name, err) {
  failed += 1;
  const msg = err && err.message ? err.message : String(err);
  results.push({name, ok: false, error: msg});
  console.error(`FAIL  ${name}: ${msg}`);
}

function skip(name, reason) {
  results.push({name, ok: 'skip', reason});
  console.log(`SKIP  ${name}: ${reason}`);
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg || 'assertion failed');
}

/** Pure unit: matchesCountryTypeCar (verifiedBookingAmount gate). */
function runPureMatchesCountryTypeCar() {
  console.log('\n=== Pure: matchesCountryTypeCar (verifiedBookingAmount gate) ===');

  const saCar = {
    country_iso2: 'SA',
    dolh: {path: 'countries/sa'},
    actev: true,
    sr: 100,
  };
  const kgCar = {
    country_iso2: 'KG',
    dolh: {path: 'countries/kg'},
    actev: true,
    sr: 80,
  };

  try {
    assert(
      matchesCountryTypeCar(saCar, 'countries/sa', 'SA') === true,
      'SA car should match countries/sa',
    );
    pass('matchesCountryTypeCar: SA car + SA country');
  } catch (e) {
    fail('matchesCountryTypeCar: SA car + SA country', e);
  }

  try {
    assert(
      matchesCountryTypeCar(saCar, 'countries/kg', 'KG') === false,
      'SA car must NOT match countries/kg (verifiedBookingAmount rejects)',
    );
    pass('matchesCountryTypeCar: reject SA car + KG country');
  } catch (e) {
    fail('matchesCountryTypeCar: reject SA car + KG country', e);
  }

  try {
    assert(
      matchesCountryTypeCar(kgCar, 'countries/sa', 'SA') === false,
      'KG car must NOT match countries/sa',
    );
    pass('matchesCountryTypeCar: reject KG car + SA country');
  } catch (e) {
    fail('matchesCountryTypeCar: reject KG car + SA country', e);
  }

  try {
    assert(
      matchesCountryTypeCar(kgCar, 'countries/kg', 'KG') === true,
      'KG car should match countries/kg',
    );
    pass('matchesCountryTypeCar: KG car + KG country');
  } catch (e) {
    fail('matchesCountryTypeCar: KG car + KG country', e);
  }

  // Path-only match (no country_iso2 on car)
  try {
    const pathOnly = {dolh: {path: 'countries/sa'}};
    assert(
      matchesCountryTypeCar(pathOnly, 'countries/sa', 'SA') === true,
      'dolh.path alone should match country path',
    );
    assert(
      matchesCountryTypeCar(pathOnly, 'countries/kg', 'KG') === false,
      'dolh.path SA must not match KG',
    );
    pass('matchesCountryTypeCar: dolh.path-only gate');
  } catch (e) {
    fail('matchesCountryTypeCar: dolh.path-only gate', e);
  }
}

function resolveEmulatorEndpoint() {
  const hostEnv = process.env.FIRESTORE_EMULATOR_HOST || '';
  if (hostEnv) {
    const [host, portStr] = hostEnv.split(':');
    const port = Number(portStr);
    if (host && Number.isFinite(port) && port > 0) {
      return {host, port, fromEnv: true};
    }
  }
  return {host: DEFAULT_HOST, port: DEFAULT_PORT, fromEnv: false};
}

function probeTcp(host, port, timeoutMs = 800) {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    let settled = false;
    const done = (ok) => {
      if (settled) return;
      settled = true;
      try {
        socket.destroy();
      } catch (_) {
        /* ignore */
      }
      resolve(ok);
    };
    socket.setTimeout(timeoutMs);
    socket.once('connect', () => done(true));
    socket.once('timeout', () => done(false));
    socket.once('error', () => done(false));
    socket.connect(port, host);
  });
}

async function runEmulatorRulesFlow() {
  console.log('\n=== Emulator: type_car country-scope rules ===');

  const endpoint = resolveEmulatorEndpoint();
  const reachable = await probeTcp(endpoint.host, endpoint.port);
  if (!reachable) {
    const hint = endpoint.fromEnv
      ? `FIRESTORE_EMULATOR_HOST=${endpoint.host}:${endpoint.port} not reachable`
      : `Firestore emulator not listening on ${endpoint.host}:${endpoint.port}`;
    console.log(
      `\nSKIP  emulator rules suite: ${hint}. ` +
        'Start with: firebase emulators:start --only firestore ' +
        '(or firebase emulators:exec …). Pure matchesCountryTypeCar checks still ran.\n',
    );
    skip('rules: agent create SA', hint);
    skip('rules: agent deny create/update KG', hint);
    skip('rules: agent deny dolh sa→kg', hint);
    skip('rules: super admin write any', hint);
    return {skipped: true, reason: hint};
  }

  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST || `${endpoint.host}:${endpoint.port}`;

  let initializeTestEnvironment;
  let assertFails;
  let assertSucceeds;
  let doc;
  let setDoc;
  let updateDoc;

  try {
    ({
      initializeTestEnvironment,
      assertFails,
      assertSucceeds,
    } = require('@firebase/rules-unit-testing'));
    ({doc, setDoc, updateDoc} = require('firebase/firestore'));
  } catch (e) {
    const reason =
      `missing @firebase/rules-unit-testing or firebase/firestore (${e.message}). ` +
      'Run npm install in firebase/functions.';
    console.log(`\nSKIP  emulator rules suite: ${reason}\n`);
    skip('rules: agent create SA', reason);
    skip('rules: agent deny create/update KG', reason);
    skip('rules: agent deny dolh sa→kg', reason);
    skip('rules: super admin write any', reason);
    return {skipped: true, reason};
  }

  if (!fs.existsSync(RULES_PATH)) {
    throw new Error(`firestore.rules not found at ${RULES_PATH}`);
  }

  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: endpoint.host,
      port: endpoint.port,
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
    },
  });

  const countryRef = (db, id) => doc(db, 'countries', id);

  try {
    await testEnv.clearFirestore();

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const sa = countryRef(db, 'sa');
      const kg = countryRef(db, 'kg');
      await setDoc(doc(db, 'countries', 'sa'), {naim: 'Saudi', iso_code: 'SA'});
      await setDoc(doc(db, 'countries', 'kg'), {
        naim: 'Kyrgyzstan',
        iso_code: 'KG',
      });
      await setDoc(doc(db, 'type_car', 'economy_qa'), {
        naim: 'Economy QA',
        sr: 100,
        actev: true,
        codeCar: 'economy_qa',
        dolh: sa,
        country_iso2: 'SA',
      });
      await setDoc(doc(db, 'type_car', 'economy_kg'), {
        naim: 'Economy KG',
        sr: 80,
        actev: true,
        codeCar: 'economy_kg',
        dolh: kg,
        country_iso2: 'KG',
      });
      await setDoc(doc(db, 'user', 'super-1'), {
        IsAdmin: true,
        isAdminRule: 1,
      });
      await setDoc(doc(db, 'user', 'admin-sa'), {
        isAdminRule: 2,
        Isagent: true,
        Rev_dloh_agent: sa,
      });
    });

    const agentClaims = {
      country_admin: true,
      country_id: 'countries/sa',
    };

    // 1) Agent A can create type_car with dolh=countries/sa
    try {
      const db = testEnv
        .authenticatedContext('admin-sa', agentClaims)
        .firestore();
      const sa = countryRef(db, 'sa');
      await assertSucceeds(
        setDoc(doc(db, 'type_car', 'qa_new_sa'), {
          naim: 'QA New SA',
          sr: 90,
          actev: true,
          dolh: sa,
          country_iso2: 'SA',
        }),
      );
      pass('rules: agent create type_car dolh=countries/sa');
    } catch (e) {
      fail('rules: agent create type_car dolh=countries/sa', e);
    }

    // 2) Agent A cannot create/update type_car for countries/kg
    try {
      const db = testEnv
        .authenticatedContext('admin-sa', agentClaims)
        .firestore();
      const kg = countryRef(db, 'kg');
      await assertFails(
        setDoc(doc(db, 'type_car', 'qa_hack_kg'), {
          naim: 'Hack KG',
          sr: 1,
          actev: true,
          dolh: kg,
          country_iso2: 'KG',
        }),
      );
      await assertFails(
        updateDoc(doc(db, 'type_car', 'economy_kg'), {sr: 999}),
      );
      pass('rules: agent deny create/update type_car for kg');
    } catch (e) {
      fail('rules: agent deny create/update type_car for kg', e);
    }

    // 3) Agent A cannot change dolh from sa to kg
    try {
      const db = testEnv
        .authenticatedContext('admin-sa', agentClaims)
        .firestore();
      const kg = countryRef(db, 'kg');
      await assertFails(
        updateDoc(doc(db, 'type_car', 'economy_qa'), {
          dolh: kg,
          country_iso2: 'KG',
        }),
      );
      pass('rules: agent deny dolh sa→kg');
    } catch (e) {
      fail('rules: agent deny dolh sa→kg', e);
    }

    // 4) Super admin can write any
    try {
      const db = testEnv
        .authenticatedContext('super-1', {super_admin: true})
        .firestore();
      await assertSucceeds(
        updateDoc(doc(db, 'type_car', 'economy_qa'), {sr: 120, actev: true}),
      );
      await assertSucceeds(
        updateDoc(doc(db, 'type_car', 'economy_kg'), {sr: 85}),
      );
      const kg = countryRef(db, 'kg');
      await assertSucceeds(
        setDoc(doc(db, 'type_car', 'qa_super_any'), {
          naim: 'Super Any',
          sr: 50,
          actev: true,
          dolh: kg,
          country_iso2: 'KG',
        }),
      );
      pass('rules: super admin write any');
    } catch (e) {
      fail('rules: super admin write any', e);
    }

    return {skipped: false};
  } finally {
    await testEnv.cleanup();
  }
}

async function main() {
  console.log('qa_country_vehicle_flow.js');
  console.log(`cwd=${process.cwd()}`);
  console.log(`rules=${RULES_PATH}`);

  runPureMatchesCountryTypeCar();

  let emulatorMeta = {skipped: true};
  try {
    emulatorMeta = await runEmulatorRulesFlow();
  } catch (e) {
    fail('rules: emulator suite (unexpected)', e);
  }

  console.log('\n=== Summary ===');
  const passed = results.filter((r) => r.ok === true).length;
  const skipped = results.filter((r) => r.ok === 'skip').length;
  console.log(`passed=${passed} failed=${failed} skipped=${skipped}`);

  if (emulatorMeta.skipped) {
    console.log(
      'SKIP: Firestore emulator rules suite was not executed ' +
        `(${emulatorMeta.reason || 'unavailable'}). ` +
        'Pure matchesCountryTypeCar assertions still ran.',
    );
  }

  if (failed > 0) {
    process.exitCode = 1;
    console.error('RESULT=FAIL');
  } else {
    console.log(
      emulatorMeta.skipped ? 'RESULT=OK_WITH_SKIP' : 'RESULT=OK',
    );
  }
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});
