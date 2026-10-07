'use strict';
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const LOCALES = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];
const FILLS = require('./geo_i18n_fills_2026_10_04.json');
const BACKUP = path.resolve(__dirname, '../../../../reports/pre_geo_i18n_update_2026-10-04.json');
const SKIP = new Set([
  'منتزه جيريال لاند الترفيهي',
  'قرية التوت',
  'مزرعة تين',
  'القصر الوطني التاريخي',
  'منتجع جسر اللوزية',
]);

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

function textMap(raw) {
  const out = {};
  if (!raw || typeof raw !== 'object') return out;
  for (const [k, v] of Object.entries(raw)) {
    const t = String(v || '').trim();
    if (t) out[k] = t;
  }
  return out;
}

function missingOf(map) {
  return LOCALES.filter((lang) => !map[lang]);
}

async function plan(firestore) {
  const changes = [];
  const unresolved = [];
  const counts = {countries: 0, cities: 0, villages: 0, mkan: 0};
  for (const collection of ['countries', 'cities', 'villages', 'mkan']) {
    const snap = await firestore.collection(collection).get();
    for (const doc of snap.docs) {
      const data = doc.data();
      const current = textMap(data.names_i18n);
      const missing = missingOf(current);
      if (!missing.length) continue;
      const ar = current.ar || '';
      const en = current.en || '';
      const naim = String(data.naim || '').trim();
      const label = ar || en || naim;
      if (SKIP.has(ar) || SKIP.has(naim) || SKIP.has(en)) {
        unresolved.push({collection, id: doc.id, name: label, missing, reason: 'uncertain_name'});
        counts[collection] += 1;
        continue;
      }
      const fill = FILLS[en] || FILLS[ar] || FILLS[naim];
      if (!fill) {
        unresolved.push({collection, id: doc.id, name: label, missing, reason: 'no_reliable_translation'});
        counts[collection] += 1;
        continue;
      }
      const patch = {};
      for (const lang of missing) {
        const value = String(fill[lang] || '').trim();
        if (value) patch[lang] = value;
      }
      const still = missing.filter((lang) => !patch[lang]);
      if (!Object.keys(patch).length) {
        unresolved.push({collection, id: doc.id, name: label, missing: still, reason: 'no_reliable_translation'});
        counts[collection] += 1;
        continue;
      }
      if (still.length) {
        unresolved.push({collection, id: doc.id, name: label, missing: still, reason: 'partial'});
        counts[collection] += 1;
      }
      changes.push({
        collection,
        id: doc.id,
        ref: doc.ref,
        before: current,
        patch,
      });
    }
  }
  return {changes, unresolved, counts};
}

async function main() {
  const apply = process.argv.includes('--apply');
  const firestore = await db();
  const {changes, unresolved, counts} = await plan(firestore);
  if (!apply) {
    fs.mkdirSync(path.dirname(BACKUP), {recursive: true});
    fs.writeFileSync(BACKUP, JSON.stringify({
      generated_at: new Date().toISOString(),
      note: 'names_i18n only, for documents that will receive missing locales',
      documents: changes.map((row) => ({
        collection: row.collection,
        document_id: row.id,
        names_i18n: row.before,
        patch: row.patch,
      })),
      unresolved,
    }, null, 2));
    console.log(JSON.stringify({
      backup: BACKUP,
      willUpdate: changes.length,
      unresolved: unresolved.length,
      unresolvedByCollection: counts,
    }));
    return;
  }
  if (!fs.existsSync(BACKUP)) {
    throw new Error('backup missing');
  }
  let updated = 0;
  for (const row of changes) {
    const next = {...row.before, ...row.patch};
    await row.ref.set({names_i18n: next}, {merge: true});
    updated += 1;
  }
  const after = await plan(firestore);
  const missingDocs = {};
  for (const collection of ['countries', 'cities', 'villages', 'mkan']) {
    const snap = await firestore.collection(collection).get();
    let n = 0;
    snap.forEach((doc) => {
      if (missingOf(textMap(doc.data().names_i18n)).length) n += 1;
    });
    missingDocs[collection] = n;
  }
  console.log(JSON.stringify({
    updated,
    stillMissingDocs: missingDocs,
    unresolvedAfter: after.unresolved.length,
    unresolved: after.unresolved,
  }, null, 2));
}

main().catch((err) => {
  console.error(err && err.message ? err.message : err);
  process.exit(1);
});
