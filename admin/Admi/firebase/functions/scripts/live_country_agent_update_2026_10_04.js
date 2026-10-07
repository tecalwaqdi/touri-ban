'use strict';

/**
 * Authorized live country VAT/FX and non-SA agent phone update.
 * Does not deploy, does not touch orders, wallets, or Wasl.
 */
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const admin = require('firebase-admin');
const fin = require('../../../../shared/country_finance');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FIREBASE_CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
const EXPECTED = ['SA','KG','RU','TR','KZ','GE','EG','IN','ID','MY','MA','NG','PT','ES','TN','TM','UZ','TD','NE'];
const CURRENCY = {
  SA:'SAR', KG:'KGS', RU:'RUB', TR:'TRY', KZ:'KZT', GE:'GEL', EG:'EGP',
  IN:'INR', ID:'IDR', MY:'MYR', MA:'MAD', NG:'NGN', PT:'EUR', ES:'EUR',
  TN:'TND', TM:'TMT', UZ:'UZS', TD:'XAF', NE:'XAF',
};
const FX = {
  SA:1, KG:23.3648, RU:22.258, TR:13.1258, KZ:119.78, GE:0.696001, EG:13.9473,
  IN:25.7361, ID:4765.081483, MY:1.0914, MA:2.64865, NG:355.559, PT:0.237292,
  ES:0.237292, TN:0.794406, TM:0.935126, UZ:3144.36, TD:155.653, NE:155.653,
};
const NON_SA_PHONE = '+966577118808';
const REPORTS = path.resolve(__dirname, '../../../../reports');

async function initDb() {
  const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  const {GoogleAuth} = require('google-auth-library');
  const auth = new GoogleAuth({
    credentials: {
      type: 'authorized_user',
      client_id: FIREBASE_CLI_CLIENT_ID,
      client_secret: FIREBASE_CLI_CLIENT_SECRET,
      refresh_token: cfg.tokens.refresh_token,
    },
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    projectId: PROJECT_ID,
  });
  const authClient = await auth.getClient();
  const {Firestore, FieldValue} = require('@google-cloud/firestore');
  const db = new Firestore({projectId: PROJECT_ID, authClient});
  return {db, FieldValue};
}

function isoOf(data, id) {
  return String(data.iso_code || data.iso2 || data.isoCode || '').trim().toUpperCase() || '';
}

function currencyOf(data) {
  return String(data.currency_code || data.currencyCode || data.currency || '').trim().toUpperCase();
}

function symbolOf(data) {
  return String(data.CurrencySymbol || data.currency_symbol || data.currencySymbol || '');
}

function countrySnapshot(id, data) {
  return {
    id,
    iso_code: isoOf(data, id),
    acctev: data.acctev === true,
    currency_code: currencyOf(data),
    CurrencySymbol: data.CurrencySymbol == null ? null : String(data.CurrencySymbol),
    currency_symbol: data.currency_symbol == null ? null : String(data.currency_symbol),
    vat_percent: data.vat_percent == null ? null : data.vat_percent,
    vat: data.vat == null ? null : data.vat,
    isvat: data.isvat == null ? null : data.isvat,
    local_units_per_sar: data.local_units_per_sar == null ? null : data.local_units_per_sar,
    finance_config_version: data.finance_config_version == null ? null : data.finance_config_version,
    cash_enabled: data.cash_enabled == null ? null : data.cash_enabled,
    online_payment_enabled: data.online_payment_enabled == null ? null : data.online_payment_enabled,
  };
}

async function main() {
  const apply = process.argv.includes('--apply');
  const {db, FieldValue} = await initDb();
  const countries = await db.collection('countries').get();
  const active = [];
  const inactive = [];
  for (const doc of countries.docs) {
    const row = countrySnapshot(doc.id, doc.data());
    if (doc.data().acctev === true) active.push(row);
    else inactive.push({id: doc.id, iso: row.iso_code, acctev: false});
  }
  active.sort((a, b) => a.iso_code.localeCompare(b.iso_code));
  const activeIsos = active.map((c) => c.iso_code).filter(Boolean);
  const missingExpected = EXPECTED.filter((iso) => !activeIsos.includes(iso));
  const extraActive = activeIsos.filter((iso) => !EXPECTED.includes(iso));

  fs.mkdirSync(REPORTS, {recursive: true});
  const countryBackup = path.join(REPORTS, 'pre_country_config_update_2026-10-04.json');
  if (!apply) {
    fs.writeFileSync(countryBackup, JSON.stringify({
      taken_at: new Date().toISOString(),
      active,
      inactive_ids_only: inactive,
      missingExpected,
      extraActive,
    }, null, 2));
  }

  const agentsSnap = await db.collection('user').where('Isagent', '==', true).get();
  const countryByPath = new Map();
  for (const doc of countries.docs) {
    countryByPath.set(doc.ref.path, {id: doc.id, iso: isoOf(doc.data(), doc.id), acctev: doc.data().acctev === true});
  }
  const agents = [];
  for (const doc of agentsSnap.docs) {
    const data = doc.data();
    const ref = data.Rev_dloh_agent;
    const pathStr = ref && ref.path ? ref.path : (typeof ref === 'string' ? ref : '');
    const country = pathStr ? countryByPath.get(pathStr) : null;
    agents.push({
      id: doc.id,
      country_path: pathStr || null,
      country_iso: country ? country.iso : null,
      actev_user: data.actev_user === true,
      phone_number: data.phone_number == null ? null : String(data.phone_number),
    });
  }
  const agentBackup = path.join(REPORTS, 'pre_agent_phone_update_2026-10-04.json');
  if (!apply) {
    fs.writeFileSync(agentBackup, JSON.stringify({taken_at: new Date().toISOString(), agents}, null, 2));
  }

  const summary = {
    mode: apply ? 'apply' : 'backup',
    activeIsos,
    missingExpected,
    extraActive,
    inactiveCount: inactive.length,
    agentCount: agents.length,
    countryBackup: apply ? 'already_written' : countryBackup,
    agentBackup: apply ? 'already_written' : agentBackup,
  };

  if (!apply) {
    console.log(JSON.stringify(summary, null, 2));
    console.log('ACTIVE_DETAIL');
    for (const c of active) {
      console.log([c.id, c.iso_code, c.currency_code, 'vat=' + c.vat_percent, 'legacyVat=' + c.vat, 'fx=' + c.local_units_per_sar, 'sym=' + JSON.stringify(symbolOf(c)), 'cash=' + c.cash_enabled, 'online=' + c.online_payment_enabled].join(' '));
    }
    console.log('AGENTS');
    for (const a of agents) {
      const digits = String(a.phone_number || '').replace(/\D/g, '');
      console.log([a.id, a.country_iso || 'NO_COUNTRY', a.actev_user ? 'active' : 'inactive', 'digits_len=' + digits.length].join(' '));
    }
    return;
  }

  if (!fs.existsSync(countryBackup) || !fs.existsSync(agentBackup)) {
    throw new Error('BACKUP_MISSING');
  }
  if (missingExpected.length || extraActive.length) {
    throw new Error('ACTIVE_SET_MISMATCH ' + JSON.stringify({missingExpected, extraActive}));
  }

  let vatUpdated = 0;
  let fxUpdated = 0;
  const flagNotes = [];
  for (const doc of countries.docs) {
    const data = doc.data();
    if (data.acctev !== true) continue;
    const iso = isoOf(data, doc.id);
    if (!EXPECTED.includes(iso)) continue;
    const storedCurrency = currencyOf(data);
    if (storedCurrency && storedCurrency !== CURRENCY[iso]) {
      throw new Error('CURRENCY_MISMATCH ' + iso + ' stored=' + storedCurrency);
    }
    const patch = {
      vat_percent: 15,
      vat: 15,
      isvat: true,
      local_units_per_sar: FX[iso],
      finance_config_version: FieldValue.increment(1),
      finance_config_updated_at: FieldValue.serverTimestamp(),
    };
    if (!storedCurrency) patch.currency_code = CURRENCY[iso];
    const symbol = symbolOf(data);
    if (iso === 'KG' && symbol === 'с') {
      patch.CurrencySymbol = 'сом';
      if (data.currency_symbol != null) patch.currency_symbol = 'сом';
    }
    if (data.cash_enabled == null) {
      patch.cash_enabled = true;
      flagNotes.push(iso + ' cash_enabled MISSING->true');
    } else if (data.cash_enabled === false) {
      flagNotes.push(iso + ' cash_enabled PRESERVED false');
    }
    if (data.online_payment_enabled == null) {
      patch.online_payment_enabled = true;
      flagNotes.push(iso + ' online_payment_enabled MISSING->true');
    } else if (data.online_payment_enabled === false) {
      flagNotes.push(iso + ' online_payment_enabled PRESERVED false');
    }
    await doc.ref.set(patch, {merge: true});
    vatUpdated += 1;
    fxUpdated += 1;
  }

  let nonSa = 0;
  let phoneUpdated = 0;
  let saUnchanged = 0;
  let noCountry = 0;
  for (const doc of agentsSnap.docs) {
    const data = doc.data();
    const ref = data.Rev_dloh_agent;
    const pathStr = ref && ref.path ? ref.path : (typeof ref === 'string' ? ref : '');
    const country = pathStr ? countryByPath.get(pathStr) : null;
    if (!country || !country.iso) {
      noCountry += 1;
      continue;
    }
    if (country.iso === 'SA') {
      saUnchanged += 1;
      continue;
    }
    nonSa += 1;
    if (String(data.phone_number || '') !== NON_SA_PHONE) {
      await doc.ref.set({phone_number: NON_SA_PHONE}, {merge: true});
      phoneUpdated += 1;
    }
  }

  console.log(JSON.stringify({
    vatUpdated,
    fxUpdated,
    flagNotes,
    nonSa,
    phoneUpdated,
    saUnchanged,
    noCountry,
  }, null, 2));
}

main().catch((err) => {
  console.error(err && err.message ? err.message : err);
  process.exit(1);
});
