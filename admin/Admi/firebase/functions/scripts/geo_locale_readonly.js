'use strict';

/**
 * READ-ONLY geo translation coverage. Does not write.
 * Project: tutorial-multi-language-70gx4j
 */
const admin = require('firebase-admin');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FIREBASE_CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
const LOCALES = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];

async function initDb() {
  try {
    admin.initializeApp({projectId: PROJECT_ID});
    await admin.firestore().collection('countries').limit(1).get();
    return admin.firestore();
  } catch (_) {
    try {
      await admin.app().delete();
    } catch (e2) {
      /* ignore */
    }
  }
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

function missingLocales(data) {
  const map = data.names_i18n || {};
  return LOCALES.filter((l) => !String(map[l] || '').trim());
}

function label(data) {
  return (
    data.iso_code ||
    data.iso ||
    data.naimEnglesh ||
    data.naim ||
    data.id ||
    ''
  );
}

function canonicalName(data) {
  return (
    data.naim ||
    data.naimEnglesh ||
    data.name ||
    data.iso_code ||
    data.iso ||
    ''
  );
}

function namesI18n(data) {
  const raw = data.names_i18n || {};
  const out = {};
  for (const [k, v] of Object.entries(raw)) {
    const text = String(v || '').trim();
    if (text) out[k] = text;
  }
  return out;
}

async function main() {
  const db = await initDb();
  const countries = await db.collection('countries').get();
  const active = countries.docs.filter((d) => d.data().acctev === true);
  const activeIds = new Set(active.map((d) => d.id));
  const countryIsoById = new Map(active.map((d) => [d.id, label(d.data())]));
  const countryMissing = [];
  for (const doc of active) {
    const gaps = missingLocales(doc.data());
    if (gaps.length) {
      const data = doc.data();
      countryMissing.push({
        collection: 'countries',
        document_id: doc.id,
        country_iso: label(data),
        canonical_name: canonicalName(data),
        missing_locales: gaps,
        names_i18n: namesI18n(data),
      });
    }
  }

  async function scan(collection, parentField) {
    const snap = await db.collection(collection).get();
    const rows = [];
    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.acctev === false) continue;
      const parent = data[parentField];
      const parentId = parent && parent.id ? parent.id : '';
      if (parentId && !activeIds.has(parentId) && parentField) continue;
      const gaps = missingLocales(data);
      if (gaps.length) {
        rows.push({
          collection,
          document_id: doc.id,
          country_iso: countryIsoById.get(parentId) || label(data),
          parent_country_id: parentId,
          canonical_name: canonicalName(data),
          missing_locales: gaps,
          names_i18n: namesI18n(data),
        });
      }
    }
    return {total: snap.size, missing: rows};
  }

  const cities = await scan('cities', 'dolh');
  const villages = await scan('villages', 'dolh');
  const landmarks = await scan('mkan', 'rev_dolh');

  const report = {
    activeCountries: active.length,
    COUNTRY_GEO_MISSING: countryMissing.length,
    CITY_GEO_MISSING: cities.missing.length,
    VILLAGE_GEO_MISSING: villages.missing.length,
    LANDMARK_GEO_MISSING: landmarks.missing.length,
    countries: countryMissing,
    cities: cities.missing,
    villages: villages.missing,
    landmarks: landmarks.missing,
    scanned: {
      cities: cities.total,
      villages: villages.total,
      landmarks: landmarks.total,
    },
  };
  const out = path.join(__dirname, 'geo_locale_readonly_report.json');
  fs.writeFileSync(out, JSON.stringify(report, null, 2));
  const manifestDir = path.join(__dirname, '..', '..', '..', '..', 'reports');
  fs.mkdirSync(manifestDir, {recursive: true});
  const items = [
    ...countryMissing,
    ...cities.missing,
    ...villages.missing,
    ...landmarks.missing,
  ];
  const manifestPath = path.join(manifestDir, 'geo_i18n_missing.json');
  fs.writeFileSync(manifestPath, JSON.stringify({
    generated: 'read-only',
    COUNTRY_GEO_MISSING: report.COUNTRY_GEO_MISSING,
    CITY_GEO_MISSING: report.CITY_GEO_MISSING,
    VILLAGE_GEO_MISSING: report.VILLAGE_GEO_MISSING,
    LANDMARK_GEO_MISSING: report.LANDMARK_GEO_MISSING,
    items,
  }, null, 2));
  const md = [
    '# Geo names_i18n gaps (read-only)',
    '',
    `Countries missing a locale: ${report.COUNTRY_GEO_MISSING}`,
    `Cities missing a locale: ${report.CITY_GEO_MISSING}`,
    `Villages missing a locale: ${report.VILLAGE_GEO_MISSING}`,
    `Landmarks missing a locale: ${report.LANDMARK_GEO_MISSING}`,
    '',
    'No live documents were modified. Resolver order remains requested locale, then English, then a non-Arabic canonical name.',
    '',
    '| Collection | Document | ISO | Canonical | Missing |',
    '| --- | --- | --- | --- | --- |',
    ...items.map((row) => `| ${row.collection} | ${row.document_id} | ${row.country_iso} | ${String(row.canonical_name).replace(/\|/g, '/')} | ${(row.missing_locales || []).join(', ')} |`),
    '',
  ].join('\n');
  fs.writeFileSync(path.join(manifestDir, 'geo_i18n_missing.md'), md);
  console.log(JSON.stringify({
    COUNTRY_GEO_MISSING: report.COUNTRY_GEO_MISSING,
    CITY_GEO_MISSING: report.CITY_GEO_MISSING,
    VILLAGE_GEO_MISSING: report.VILLAGE_GEO_MISSING,
    LANDMARK_GEO_MISSING: report.LANDMARK_GEO_MISSING,
    scanned: report.scanned,
  }));
}

main().catch((err) => {
  console.error(err && err.message ? err.message : err);
  process.exit(1);
});
