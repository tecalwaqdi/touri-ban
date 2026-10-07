'use strict';

/**
 * READ-ONLY. Simulates Driver/Customer geo name resolution and reports
 * documents whose rendered name is Arabic while English or a non-Arabic
 * locale value exists. Urdu script is not a leak unless the Urdu slot is
 * an exact copy of the Arabic name and English exists.
 */
const admin = require('firebase-admin');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const FIREBASE_CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
const CHECK_LOCALES = ['en', 'ru', 'ky', 'fr', 'ur', 'pt'];
const ARABIC = /[\u0600-\u06FF]/;

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

function names(data) {
  const raw = data.names_i18n || {};
  const out = {};
  for (const [k, v] of Object.entries(raw)) {
    const text = String(v || '').trim();
    if (text) out[String(k)] = text;
  }
  return out;
}

function looksArabic(value) {
  return ARABIC.test(String(value || ''));
}

function resolve(i18n, legacy, localeKey) {
  const lang = String(localeKey).split(/[_-]/)[0].toLowerCase();
  const legacyTrim = String(legacy || '').trim();
  function pick(key, requireArabic) {
    const v = String(i18n[key] || '').trim();
    if (!v) return null;
    if (requireArabic && !looksArabic(v)) return null;
    if (lang !== 'ar' && lang !== 'ur' && looksArabic(v)) return null;
    return v;
  }
  if (lang === 'ar') {
    const direct = pick('ar', true);
    if (direct) return direct;
  } else {
    const direct = pick(localeKey) || pick(lang);
    if (direct) return direct;
  }
  const en = pick('en');
  if (en) return en;
  for (const value of Object.values(i18n)) {
    const v = String(value || '').trim();
    if (!v) continue;
    if (lang !== 'ar' && lang !== 'ur' && looksArabic(v)) continue;
    return v;
  }
  if (!legacyTrim) return '';
  if (lang !== 'ar' && lang !== 'ur' && looksArabic(legacyTrim)) return '';
  return legacyTrim;
}

function englishFallback(data, i18n) {
  const fromMap = String(i18n.en || '').trim();
  if (fromMap && !looksArabic(fromMap)) return fromMap;
  const legacy = String(data.naimEnglesh || data.name_en || '').trim();
  if (legacy && !looksArabic(legacy)) return legacy;
  return '';
}

function leaksFor(data) {
  const i18n = names(data);
  const legacy = String(data.naim || data.name || '').trim();
  const en = englishFallback(data, i18n);
  const ar = String(i18n.ar || legacy || '').trim();
  const leaks = [];
  for (const locale of CHECK_LOCALES) {
    const rendered = resolve(i18n, legacy, locale);
    if (!looksArabic(rendered)) continue;
    if (locale === 'ur') {
      if (en && ar && rendered === ar) leaks.push(locale);
      continue;
    }
    const own = String(i18n[locale] || '').trim();
    const ownUsable = own && !looksArabic(own);
    if (en || ownUsable) leaks.push(locale);
  }
  return leaks;
}

function presence(i18n) {
  const out = {};
  for (const key of ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt']) {
    out[key] = Boolean(String(i18n[key] || '').trim());
  }
  return out;
}

async function main() {
  const db = await initDb();
  const countries = await db.collection('countries').get();
  const active = countries.docs.filter((d) => d.data().acctev === true);
  const activeIds = new Set(active.map((d) => d.id));
  const makkahIds = new Set([
    'city_makkah',
    'city_sa_makkah',
    'region_makkah',
    'region_sa_makkah',
  ]);
  const makkah = {};

  function considerMakkah(id, data) {
    if (!makkahIds.has(id) && !/makkah|mecca/i.test(id)) return;
    makkah[id] = presence(names(data));
  }

  function scanDocs(docs, parentField) {
    const rows = [];
    for (const doc of docs) {
      const data = doc.data();
      considerMakkah(doc.id, data);
      if (data.acctev === false) continue;
      if (parentField) {
        const parent = data[parentField];
        const parentId = parent && parent.id ? parent.id : '';
        if (parentId && !activeIds.has(parentId)) continue;
      }
      const leaks = leaksFor(data);
      if (leaks.length) rows.push({id: doc.id, leaks});
    }
    return rows;
  }

  const countryRows = scanDocs(active, '');
  const cities = await db.collection('cities').get();
  const villages = await db.collection('villages').get();
  const mkan = await db.collection('mkan').get();
  const report = {
    countries: countryRows,
    cities: scanDocs(cities.docs, 'dolh'),
    villages: scanDocs(villages.docs, 'dolh'),
    mkan: scanDocs(mkan.docs, 'rev_dolh'),
    makkah_presence: makkah,
  };
  const out = path.join(
    __dirname,
    '..',
    '..',
    '..',
    '..',
    'reports',
    'geo_runtime_arabic_leak_2026-10-04.json',
  );
  fs.mkdirSync(path.dirname(out), {recursive: true});
  fs.writeFileSync(out, JSON.stringify(report, null, 2));
  console.log(JSON.stringify({
    countries: report.countries.length,
    cities: report.cities.length,
    villages: report.villages.length,
    mkan: report.mkan.length,
    makkah_ids: Object.keys(makkah),
    makkah_presence: makkah,
  }));
}

main().catch((err) => {
  console.error(err && err.message ? err.message : err);
  process.exit(1);
});
