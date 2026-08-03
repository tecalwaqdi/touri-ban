/**
 * Idempotent seed:
 *  1) Set `img` on every existing type_car doc that has none.
 *  2) Create Kyrgyzstan-scoped type_car docs (dolh=countries/kyrgyzstan, country_iso2=KG).
 *
 * Every image URL is validated with a HEAD request before it is written,
 * so a broken link never lands in Firestore.
 *
 * Project: tutorial-multi-language-70gx4j
 * Run: node seed_type_car_images_and_kg.js
 */
const SEED = require('../../../../Admi/firebase/scripts/seed_production_client.js');

const PROJECT = 'tutorial-multi-language-70gx4j';
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

const U = (id) =>
  `https://images.unsplash.com/photo-${id}?auto=format&fit=crop&w=1200&q=80`;

// Verified-by-HEAD candidates. First working URL per category wins.
const GENERIC_SEDAN = U('1552519507-da3b142c6e3d');
const GENERIC_SUV = U('1533473359331-0135ef1b58bf');
const GENERIC_VAN = U('1612825173281-9a193378527e');

const IMAGE_CANDIDATES = {
  economy: [U('1541899481282-d53bffe3c35d'), GENERIC_SEDAN],
  compact: [U('1503376780353-7e6692767b70'), GENERIC_SEDAN],
  sedan_standard: [GENERIC_SEDAN],
  comfort: [U('1550355291-bbee04a92027'), GENERIC_SEDAN],
  premium: [U('1494976388531-d1058494cdd8'), GENERIC_SEDAN],
  business: [U('1503376780353-7e6692767b70'), GENERIC_SEDAN],
  luxury: [U('1555215695-3004980ad54e'), GENERIC_SEDAN],
  suv_compact: [U('1519641471654-76ce0107ad1b'), GENERIC_SUV],
  suv_standard: [GENERIC_SUV],
  suv_large: [U('1519641471654-76ce0107ad1b'), GENERIC_SUV],
  suv_family: [U('1533473359331-0135ef1b58bf'), GENERIC_SUV],
  offroad_4x4: [U('1533473359331-0135ef1b58bf'), GENERIC_SUV],
  pickup_4x4: [U('1558618666-fcd25c85cd64'), GENERIC_SUV],
  minivan: [GENERIC_VAN],
  van_family: [GENERIC_VAN],
  van_vip: [GENERIC_VAN],
  coach_mini: [U('1544620347-c4fd4a3d5957'), GENERIC_VAN],
  coach_tour: [U('1544620347-c4fd4a3d5957'), GENERIC_VAN],
  executive_shuttle: [GENERIC_VAN],
  electric: [U('1560958089-b8a1929cea89'), GENERIC_SEDAN],
  hybrid: [U('1560958089-b8a1929cea89'), GENERIC_SEDAN],
  wheelchair: [GENERIC_VAN],
  airport_transfer: [GENERIC_SEDAN],
  tourist_vehicle: [GENERIC_VAN],
  sedan: [GENERIC_SEDAN],
  suv: [GENERIC_SUV],
  van: [GENERIC_VAN],
};

// Kyrgyzstan catalogue — rates in KGS (сом), realistic for Bishkek/Osh tours.
const KG_CATEGORIES = [
  {
    code: 'economy',
    names: {
      ar: 'اقتصادية',
      en: 'Economy',
      ru: 'Эконом',
      ky: 'Эконом',
      uz: 'Ekonom',
    },
    sr: 900,
    aglSaat: 3,
  },
  {
    code: 'sedan_standard',
    names: {
      ar: 'سيدان قياسية',
      en: 'Standard Sedan',
      ru: 'Стандартный седан',
      ky: 'Стандарт седан',
      uz: 'Standart sedan',
    },
    sr: 1100,
    aglSaat: 3,
  },
  {
    code: 'comfort',
    names: {
      ar: 'مريحة',
      en: 'Comfort',
      ru: 'Комфорт',
      ky: 'Комфорт',
      uz: 'Komfort',
    },
    sr: 1400,
    aglSaat: 3,
  },
  {
    code: 'business',
    names: {
      ar: 'أعمال',
      en: 'Business',
      ru: 'Бизнес',
      ky: 'Бизнес',
      uz: 'Biznes',
    },
    sr: 1900,
    aglSaat: 4,
  },
  {
    code: 'suv_standard',
    names: {
      ar: 'SUV قياسية',
      en: 'SUV Standard',
      ru: 'Стандартный SUV',
      ky: 'Стандарт SUV',
      uz: 'Standart SUV',
    },
    sr: 1800,
    aglSaat: 4,
  },
  {
    code: 'suv_family',
    names: {
      ar: 'SUV عائلية',
      en: 'Family SUV',
      ru: 'Семейный SUV',
      ky: 'Үй-бүлөлүк SUV',
      uz: 'Oilaviy SUV',
    },
    sr: 2100,
    aglSaat: 4,
  },
  {
    code: 'offroad_4x4',
    names: {
      ar: 'دفع رباعي جبلي',
      en: '4x4 Mountain',
      ru: 'Внедорожник 4x4',
      ky: 'Тоолуу 4x4',
      uz: 'Tog\u02bcli 4x4',
    },
    sr: 2400,
    aglSaat: 4,
  },
  {
    code: 'minivan',
    names: {
      ar: 'ميني فان',
      en: 'Minivan',
      ru: 'Минивэн',
      ky: 'Минивэн',
      uz: 'Miniven',
    },
    sr: 2200,
    aglSaat: 4,
  },
  {
    code: 'van_family',
    names: {
      ar: 'فان عائلي',
      en: 'Family Van',
      ru: 'Семейный минивэн',
      ky: 'Үй-бүлөлүк минивэн',
      uz: 'Oilaviy miniven',
    },
    sr: 2600,
    aglSaat: 5,
  },
  {
    code: 'van_vip',
    names: {
      ar: 'فان VIP',
      en: 'VIP Van',
      ru: 'VIP минивэн',
      ky: 'VIP минивэн',
      uz: 'VIP miniven',
    },
    sr: 3200,
    aglSaat: 5,
  },
  {
    code: 'coach_mini',
    names: {
      ar: 'ميني باص',
      en: 'Minibus',
      ru: 'Мини-автобус',
      ky: 'Кичи автобус',
      uz: 'Miniavtobus',
    },
    sr: 3800,
    aglSaat: 5,
    isBusLike: true,
  },
  {
    code: 'coach_tour',
    names: {
      ar: 'باص سياحي',
      en: 'Tour Bus',
      ru: 'Туристический автобус',
      ky: 'Туристтик автобус',
      uz: 'Turistik avtobus',
    },
    sr: 6000,
    aglSaat: 6,
    isBusLike: true,
  },
  {
    code: 'airport_transfer',
    names: {
      ar: 'نقل مطار ماناس',
      en: 'Airport Transfer',
      ru: 'Трансфер в аэропорт',
      ky: 'Аэропорт трансфери',
      uz: 'Aeroport transferi',
    },
    sr: 1300,
    aglSaat: 2,
  },
  {
    code: 'tourist_vehicle',
    names: {
      ar: 'مركبة سياحية',
      en: 'Tourist Vehicle',
      ru: 'Туристический транспорт',
      ky: 'Туристтик унаа',
      uz: 'Turistik transport',
    },
    sr: 2300,
    aglSaat: 4,
  },
];

const urlOk = new Map();

async function checkUrl(url) {
  if (urlOk.has(url)) return urlOk.get(url);
  let ok = false;
  try {
    const res = await fetch(url, { method: 'HEAD', redirect: 'follow' });
    ok = res.ok;
  } catch (_) {
    ok = false;
  }
  urlOk.set(url, ok);
  return ok;
}

async function pickImage(code) {
  const list = IMAGE_CANDIDATES[code] || [GENERIC_SEDAN];
  for (const url of list) {
    if (await checkUrl(url)) return url;
  }
  for (const url of [GENERIC_SEDAN, GENERIC_SUV, GENERIC_VAN]) {
    if (await checkUrl(url)) return url;
  }
  return null;
}

function strMap(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = { stringValue: v };
  return { mapValue: { fields } };
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

(async () => {
  const { idToken } = await SEED.getIdToken();
  const existing = await listTypeCars(idToken);
  const byId = new Map(existing.map((d) => [d.id, d]));

  // ---- 1) Backfill images on all existing docs ----
  let imaged = 0;
  let imgSkipped = 0;
  for (const doc of existing) {
    const current = doc.fields.img?.stringValue || '';
    if (current.trim()) {
      imgSkipped++;
      continue;
    }
    const code = doc.fields.codeCar?.stringValue || doc.id;
    const url = await pickImage(code);
    if (!url) {
      console.log('no-image-candidate', doc.id);
      continue;
    }
    await patchDoc(idToken, doc.id, { img: { stringValue: url } });
    imaged++;
    console.log('img+', doc.id);
  }

  // ---- 2) Kyrgyzstan-scoped vehicle types ----
  let kgCreated = 0;
  let kgUpdated = 0;
  for (const cat of KG_CATEGORIES) {
    const id = `kg_${cat.code}`;
    const url = await pickImage(cat.code);
    const fields = {
      naim: { stringValue: cat.names.ar },
      names_i18n: strMap(cat.names),
      codeCar: { stringValue: cat.code },
      sr: { integerValue: String(cat.sr) },
      agl_saat: { integerValue: String(cat.aglSaat) },
      actev: { booleanValue: true },
      ishafelh: { booleanValue: !!cat.isBusLike },
      not: { stringValue: cat.names.en },
      dolh: {
        referenceValue: `projects/${PROJECT}/databases/(default)/documents/countries/kyrgyzstan`,
      },
      country_iso2: { stringValue: 'KG' },
      geo_import_id: { stringValue: `vehcat_kg_${cat.code}` },
      geo_import_source: { stringValue: 'touri_type_car_kg' },
    };
    if (url) fields.img = { stringValue: url };

    const existed = byId.has(id);
    await patchDoc(idToken, id, fields);
    if (existed) {
      kgUpdated++;
      console.log('kg~', id);
    } else {
      kgCreated++;
      console.log('kg+', id);
    }
  }

  console.log({
    existingDocs: existing.length,
    imagesAdded: imaged,
    imagesAlreadySet: imgSkipped,
    kgCreated,
    kgUpdated,
  });
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
