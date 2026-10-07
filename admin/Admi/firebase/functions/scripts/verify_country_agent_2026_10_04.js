'use strict';
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const fin = require('../../../../shared/country_finance');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FX = {SA:1,KG:23.3648,RU:22.258,TR:13.1258,KZ:119.78,GE:0.696001,EG:13.9473,IN:25.7361,ID:4765.081483,MY:1.0914,MA:2.64865,NG:355.559,PT:0.237292,ES:0.237292,TN:0.794406,TM:0.935126,UZ:3144.36,TD:155.653,NE:155.653};

async function db() {
  const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config/configstore/firebase-tools.json'), 'utf8'));
  const {GoogleAuth} = require('google-auth-library');
  const auth = new GoogleAuth({
    credentials: {
      type: 'authorized_user',
      client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
      client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
      refresh_token: cfg.tokens.refresh_token,
    },
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    projectId: PROJECT_ID,
  });
  const {Firestore} = require('@google-cloud/firestore');
  return new Firestore({projectId: PROJECT_ID, authClient: await auth.getClient()});
}

async function main() {
  const firestore = await db();
  const countries = await firestore.collection('countries').where('acctev', '==', true).get();
  let vatOk = 0;
  let fxOk = 0;
  const bad = [];
  const rows = [];
  for (const doc of countries.docs) {
    const d = doc.data();
    const iso = String(d.iso_code || '').toUpperCase();
    const vat = Number(d.vat_percent);
    const fx = Number(d.local_units_per_sar);
    if (vat === 15 && Number(d.vat) === 15 && d.isvat === true) vatOk += 1;
    else bad.push(iso + ' vat');
    if (Number.isFinite(fx) && Math.abs(fx - FX[iso]) < 1e-6) fxOk += 1;
    else bad.push(iso + ' fx');
    const split = fin.splitGross(100, vat);
    const gw = fin.localToGatewaySar(100, fx);
    rows.push({
      iso,
      currency: d.currency_code,
      symbol: d.CurrencySymbol,
      vat,
      fx,
      cash: d.cash_enabled,
      online: d.online_payment_enabled,
      version: d.finance_config_version,
      status: fin.financeStatus(d),
      commission: split.commission,
      tax: split.tax,
      net: split.driverNet,
      gatewaySar: gw.gatewayAmountSar,
      minWallet: fin.minCashLocal(fx),
    });
  }
  const allCountries = await firestore.collection('countries').get();
  const cmap = new Map();
  allCountries.forEach((c) => cmap.set(c.ref.path, String(c.data().iso_code || '').toUpperCase()));
  const agents = await firestore.collection('user').where('Isagent', '==', true).get();
  let nonSa = 0;
  let phoneOk = 0;
  let sa = 0;
  let saChanged = 0;
  for (const doc of agents.docs) {
    const d = doc.data();
    const ref = d.Rev_dloh_agent;
    const p = ref && ref.path ? ref.path : '';
    const iso = cmap.get(p) || '';
    const digits = String(d.phone_number || '').replace(/\D/g, '');
    if (iso === 'SA') {
      sa += 1;
      if (digits === '966577118808') saChanged += 1;
    } else if (iso) {
      nonSa += 1;
      if (d.phone_number === '+966577118808' && digits === '966577118808') phoneOk += 1;
    }
  }
  const support = [];
  for (const doc of countries.docs) {
    const iso = String(doc.data().iso_code || '').toUpperCase();
    const q = await firestore.collection('user').where('Isagent', '==', true).where('Rev_dloh_agent', '==', doc.ref).where('actev_user', '==', true).limit(1).get();
    const phone = q.empty ? '' : String(q.docs[0].data().phone_number || '');
    const r = fin.resolveSupportPhone({iso2: iso, countryPath: doc.ref.path, agentPhone: phone});
    support.push(iso + ':' + (r.ok ? r.digits + (r.fallback ? '/fallback' : '') : r.code));
  }
  support.sort();
  const sanity = rows.every((r) => r.commission === 15 && r.tax === 15 && r.net === 70);
  const fxSanity = rows.every((r) => Math.abs(r.gatewaySar - (100 / r.fx)) < 0.02);
  console.log(JSON.stringify({vatOk, fxOk, bad, nonSa, phoneOk, sa, saChanged, sanity, fxSanity, support, rows}, null, 2));
}

main().catch((err) => {
  console.error(err && err.message ? err.message : err);
  process.exit(1);
});
