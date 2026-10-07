'use strict';
const admin = require('firebase-admin');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const fin = require('../../../../shared/country_finance');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FIREBASE_CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

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
  const {Firestore} = require('@google-cloud/firestore');
  return new Firestore({projectId: PROJECT_ID, authClient});
}

async function main() {
  const db = await initDb();
  const countries = await db.collection('countries').where('acctev', '==', true).get();
  const rows = [];
  for (const doc of countries.docs) {
    const data = doc.data();
    const country = fin.readCountry(data);
    const fx = fin.resolvedFx(country);
    const status = fin.financeStatus(data);
    let agentPhone = '';
    const pathStr = `countries/${doc.id}`;
    const ref = db.doc(pathStr);
    const q1 = await db.collection('user').where('Isagent', '==', true).where('Rev_dloh_agent', '==', pathStr).where('actev_user', '==', true).limit(1).get();
    const q2 = q1.empty
      ? await db.collection('user').where('Isagent', '==', true).where('Rev_dloh_agent', '==', ref).where('actev_user', '==', true).limit(1).get()
      : q1;
    if (!q2.empty) {
      agentPhone = String(q2.docs[0].data().phone_number || '').replace(/\D/g, '');
    }
    const support = fin.resolveSupportPhone({
      iso2: country.iso2,
      countryPath: pathStr,
      agentPhone,
    });
    const gaps = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'].filter(
      (l) => !String((data.names_i18n || {})[l] || '').trim(),
    );
    rows.push({
      iso: country.iso2 || doc.id,
      currency: country.currency || '',
      fx: fx == null ? 'MISSING' : fx,
      vat: country.vatPercent == null ? 'MISSING' : country.vatPercent,
      cash: data.cash_enabled !== false,
      online: data.online_payment_enabled !== false,
      agent: !q2.empty,
      agentPhone: support.ok ? support.digits : 'MISSING',
      geoMissing: gaps.join(',') || 'none',
      status,
    });
  }
  rows.sort((a, b) => String(a.iso).localeCompare(String(b.iso)));
  console.log(JSON.stringify(rows, null, 2));
}

main().catch((err) => {
  console.error(err && err.message ? err.message : err);
  process.exit(1);
});
