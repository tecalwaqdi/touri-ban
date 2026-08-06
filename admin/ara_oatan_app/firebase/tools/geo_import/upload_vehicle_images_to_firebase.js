/**
 * Upload the 9 Toury vehicle images to Firebase Storage and patch
 * Firestore `type_car` docs: replace Unsplash/old `img` URLs, update names.
 *
 * Also deactivates non-canonical duplicate categories so the list stays clean.
 *
 * Usage:
 *   node upload_vehicle_images_to_firebase.js --dry-run
 *   node upload_vehicle_images_to_firebase.js --apply
 *
 * Env (optional overrides):
 *   SEED_EMAIL / SEED_PASSWORD / SEED_FIREBASE_API_KEY / SEED_PROJECT_ID
 */
const fs = require('fs');
const path = require('path');

const APPLY = process.argv.includes('--apply');
const DRY = !APPLY;

const API_KEY =
  process.env.SEED_FIREBASE_API_KEY ||
  'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT_ID =
  process.env.SEED_PROJECT_ID || 'tutorial-multi-language-70gx4j';
const BUCKET =
  process.env.SEED_STORAGE_BUCKET ||
  'tutorial-multi-language-70gx4j.firebasestorage.app';
const EMAIL = process.env.SEED_EMAIL || 'demo.super@arawatan.sa';
const PASSWORD = process.env.SEED_PASSWORD || 'Demo@2026';

const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const ASSETS_DIR = path.resolve(
  __dirname,
  '../../../assets/images/vehicles',
);

/** Canonical 9 categories → local file + Arabic/English labels. */
const CATEGORIES = [
  {
    key: 'economy',
    file: 'economy_car.jpg',
    codes: [
      'economy',
      'sedan_standard',
      'comfort',
      'compact',
      'sedan',
      'electric',
      'hybrid',
      'airport_transfer',
    ],
    keepIds: ['economy'],
    names: {
      ar: 'سيارة اقتصادية',
      en: 'Economy Car',
      ru: 'Эконом',
      ky: 'Эконом',
      uz: 'Ekonom',
    },
    isBus: false,
  },
  {
    key: 'family',
    file: 'family_car.jpg',
    codes: ['suv_family', 'suv', 'suv_standard', 'suv_compact', 'van_family'],
    keepIds: ['suv_family'],
    names: {
      ar: 'سيارة عائلية',
      en: 'Family Car',
      ru: 'Семейный',
      ky: 'Үй-бүлөлүк',
      uz: 'Oilaviy',
    },
    isBus: false,
  },
  {
    key: 'suv',
    file: 'suv_car.jpg',
    codes: ['offroad_4x4', 'pickup_4x4', 'suv_large'],
    keepIds: ['offroad_4x4'],
    names: {
      ar: 'سيارة دفع رباعي',
      en: '4x4 SUV',
      ru: 'Полный привод 4x4',
      ky: '4x4',
      uz: '4x4',
    },
    isBus: false,
  },
  {
    key: 'luxury',
    file: 'luxury_car.jpg',
    codes: [
      'luxury',
      'premium',
      'premium_sedan',
      'business',
      'sedan_business',
      'luxury_suv',
    ],
    keepIds: ['luxury'],
    names: {
      ar: 'سيارة فارهة',
      en: 'Luxury Car',
      ru: 'Люкс',
      ky: 'Люкс',
      uz: 'Lyuks',
    },
    isBus: false,
  },
  {
    key: 'mini_bus',
    file: 'mini_bus.jpg',
    codes: [
      'coach_mini',
      'minivan',
      'tour_van',
      'van',
      'tourist_vehicle',
      'executive_shuttle',
    ],
    keepIds: ['coach_mini'],
    names: {
      ar: 'حافلة صغيرة عادية',
      en: 'Small Bus',
      ru: 'Мини-автобус',
      ky: 'Кичи автобус',
      uz: 'Miniavtobus',
    },
    isBus: true,
  },
  {
    key: 'medium_bus',
    file: 'medium_bus.jpg',
    codes: ['medium_bus', 'coach_medium', 'bus_medium'],
    keepIds: ['medium_bus'],
    names: {
      ar: 'حافلة متوسطة تتسع لـ 25 راكبًا',
      en: 'Medium Bus (25 seats)',
      ru: 'Средний автобус (25)',
      ky: 'Орто автобус (25)',
      uz: 'Ortacha avtobus (25)',
    },
    isBus: true,
    createIfMissing: {
      sr: 120,
      agl_saat: 5,
    },
  },
  {
    key: 'large_bus',
    file: 'large_bus.jpg',
    codes: ['coach_tour', 'bus', 'large_bus', 'coach_large'],
    keepIds: ['coach_tour'],
    names: {
      ar: 'حافلة كبيرة تتسع لـ 49 راكبًا',
      en: 'Large Bus (49 seats)',
      ru: 'Большой автобус (49)',
      ky: 'Чоң автобус (49)',
      uz: 'Katta avtobus (49)',
    },
    isBus: true,
  },
  {
    key: 'accessible_bus',
    file: 'accessible_bus.jpg',
    codes: ['wheelchair', 'accessible', 'accessible_bus'],
    keepIds: ['wheelchair'],
    names: {
      ar: 'حافلة مخصصة لذوي الاحتياجات الخاصة',
      en: 'Accessible Bus',
      ru: 'Для инвалидных колясок',
      ky: 'Майыптар үчүн',
      uz: 'Nogironlar uchun',
    },
    isBus: true,
  },
  {
    key: 'vip_bus',
    file: 'vip_bus.jpg',
    codes: ['van_vip', 'vip', 'vip_bus', 'bus_vip'],
    keepIds: ['van_vip'],
    names: {
      ar: 'حافلة VIP فاخرة',
      en: 'VIP Luxury Bus',
      ru: 'VIP автобус',
      ky: 'VIP автобус',
      uz: 'VIP avtobus',
    },
    isBus: true,
  },
];

function categoryForDoc(doc) {
  const code = (doc.fields.codeCar?.stringValue || doc.id || '')
    .trim()
    .toLowerCase();
  const id = doc.id.toLowerCase();
  for (const cat of CATEGORIES) {
    if (cat.codes.includes(code) || cat.codes.includes(id) || cat.keepIds.includes(id)) {
      return cat;
    }
    // kg_economy → economy
    const stripped = id.replace(/^kg_/, '');
    if (cat.codes.includes(stripped)) return cat;
  }
  return null;
}

function isKeepDoc(doc, cat) {
  const id = doc.id.toLowerCase();
  if (cat.keepIds.includes(id)) return true;
  // Keep country-scoped preferred variants: kg_economy etc.
  for (const keep of cat.keepIds) {
    if (id === `kg_${keep}` || id.endsWith(`_${keep}`)) return true;
  }
  return false;
}

async function authRequest(endpoint, body) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message);
  return json;
}

async function getIdToken() {
  try {
    const json = await authRequest('signInWithPassword', {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return { idToken: json.idToken, uid: json.localId };
  } catch (e) {
    const json = await authRequest('signUp', {
      email: EMAIL,
      password: PASSWORD,
      returnSecureToken: true,
    });
    return { idToken: json.idToken, uid: json.localId };
  }
}

async function listTypeCars(idToken) {
  const out = [];
  let pageToken = '';
  do {
    let url = `${DOCS}/type_car?pageSize=100`;
    if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    const j = await res.json();
    if (j.error) throw new Error(JSON.stringify(j.error));
    for (const d of j.documents || []) {
      out.push({ id: d.name.split('/').pop(), fields: d.fields || {} });
    }
    pageToken = j.nextPageToken || '';
  } while (pageToken);
  return out;
}

function strMap(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = { stringValue: v };
  return { mapValue: { fields } };
}

async function patchDoc(idToken, id, fields) {
  const mask = Object.keys(fields)
    .map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`)
    .join('&');
  const res = await fetch(`${DOCS}/type_car/${id}?${mask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) throw new Error(`${id}: ${await res.text()}`);
}

async function createDoc(idToken, id, fields) {
  const res = await fetch(
    `${DOCS}?documentId=${encodeURIComponent(id)}`.replace(
      '/documents',
      '/documents/type_car',
    ),
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ fields }),
    },
  );
  // Fallback PATCH upsert if POST fails (doc may exist)
  if (!res.ok) {
    await patchDoc(idToken, id, fields);
    return;
  }
}

async function uploadToStorage(idToken, objectPath, filePath) {
  const bytes = fs.readFileSync(filePath);
  const encodedName = encodeURIComponent(objectPath);
  const url =
    `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o` +
    `?name=${encodedName}&uploadType=media`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'image/jpeg',
    },
    body: bytes,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`storage upload ${objectPath}: ${res.status} ${text}`);
  }
  const meta = await res.json();
  const token = meta.downloadTokens;
  if (token) {
    return (
      `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/` +
      `${encodedName}?alt=media&token=${token}`
    );
  }
  return (
    `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/` +
    `${encodedName}?alt=media`
  );
}

function publicStorageUrl(objectPath) {
  const encodedName = encodeURIComponent(objectPath);
  return (
    `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/` +
    `${encodedName}?alt=media`
  );
}

(async () => {
  console.log(DRY ? '=== DRY RUN ===' : '=== APPLY ===');
  for (const cat of CATEGORIES) {
    const p = path.join(ASSETS_DIR, cat.file);
    if (!fs.existsSync(p)) throw new Error(`Missing asset: ${p}`);
  }

  const { idToken, uid } = await getIdToken();
  console.log('auth ok', uid);

  const uploaded = {};
  for (const cat of CATEGORIES) {
    const objectPath = `type_car/${cat.file}`;
    const local = path.join(ASSETS_DIR, cat.file);
    if (DRY) {
      uploaded[cat.key] = publicStorageUrl(objectPath);
      console.log('would-upload', objectPath, fs.statSync(local).size, 'bytes');
      continue;
    }
    try {
      uploaded[cat.key] = await uploadToStorage(idToken, objectPath, local);
      console.log('uploaded', objectPath);
    } catch (e) {
      console.error('upload-failed', objectPath, e.message);
      // Fallback: embed as data URL so Firestore still gets the new image.
      const b64 = fs.readFileSync(local).toString('base64');
      uploaded[cat.key] = `data:image/jpeg;base64,${b64}`;
      console.log('fallback-data-url', cat.key, uploaded[cat.key].length);
    }
  }

  const docs = await listTypeCars(idToken);
  console.log('type_car docs', docs.length);

  let patched = 0;
  let deactivated = 0;
  let created = 0;
  const seenKeep = new Set();

  for (const doc of docs) {
    const cat = categoryForDoc(doc);
    if (!cat) {
      console.log('skip-unmapped', doc.id);
      continue;
    }
    const imgUrl = uploaded[cat.key];
    const keep = isKeepDoc(doc, cat);
    const oldImg = doc.fields.img?.stringValue || '';

    if (keep) {
      seenKeep.add(doc.id);
      const fields = {
        img: { stringValue: imgUrl },
        naim: { stringValue: cat.names.ar },
        names_i18n: strMap(cat.names),
        not: { stringValue: cat.names.en },
        actev: { booleanValue: true },
        ishafelh: { booleanValue: cat.isBus },
        codeCar: {
          stringValue: doc.fields.codeCar?.stringValue || cat.keepIds[0],
        },
      };
      console.log(
        keep ? 'patch-keep' : 'patch',
        doc.id,
        'oldImg=',
        oldImg.slice(0, 60),
      );
      if (!DRY) {
        await patchDoc(idToken, doc.id, fields);
      }
      patched++;
    } else {
      // Duplicate category → deactivate (do not delete pricing history).
      console.log('deactivate-dup', doc.id, '→', cat.key);
      if (!DRY) {
        await patchDoc(idToken, doc.id, {
          actev: { booleanValue: false },
          img: { stringValue: imgUrl },
          naim: { stringValue: cat.names.ar },
          names_i18n: strMap(cat.names),
        });
      }
      deactivated++;
    }
  }

  // Ensure each canonical keep id exists (e.g. medium_bus).
  for (const cat of CATEGORIES) {
    for (const keepId of cat.keepIds) {
      if (seenKeep.has(keepId)) continue;
      const exists = docs.some((d) => d.id === keepId);
      if (exists) continue;
      if (!cat.createIfMissing && keepId !== cat.keepIds[0]) continue;
      const imgUrl = uploaded[cat.key];
      const fields = {
        img: { stringValue: imgUrl },
        naim: { stringValue: cat.names.ar },
        names_i18n: strMap(cat.names),
        not: { stringValue: cat.names.en },
        codeCar: { stringValue: keepId },
        actev: { booleanValue: true },
        ishafelh: { booleanValue: cat.isBus },
        sr: {
          integerValue: String(cat.createIfMissing?.sr ?? 500),
        },
        agl_saat: {
          integerValue: String(cat.createIfMissing?.agl_saat ?? 4),
        },
        country_iso2: { stringValue: 'SA' },
        geo_import_source: { stringValue: 'touri_vehicle_images_upload' },
      };
      console.log('create', keepId);
      if (!DRY) {
        await createDoc(idToken, keepId, fields);
      }
      created++;
    }
  }

  // Write report for staging sync
  const report = {
    at: new Date().toISOString(),
    mode: DRY ? 'dry-run' : 'apply',
    uploaded,
    patched,
    deactivated,
    created,
  };
  const reportPath = path.join(__dirname, 'upload_vehicle_images_report.json');
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log('report', reportPath);
  console.log(report);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
