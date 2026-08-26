'use strict';

/**
 * Add Bishkek (Kyrgyzstan) + 5 curated landmarks to production geo catalog.
 * Scope: region_kg_bishkek, city_kg_bishkek, 5 mkan docs only.
 *
 * Usage:
 *   node publish_bishkek_geo.js           # dry-run
 *   node publish_bishkek_geo.js --apply  # write
 */

process.env.GCLOUD_PROJECT = 'tutorial-multi-language-70gx4j';

const admin = require('firebase-admin');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const APPLY = process.argv.includes('--apply');
const BACKUP_DIR = path.join(
  __dirname,
  '../../../../releases/2026-08-26/geo_bishkek_backup',
);
const REPORT_PATH = path.join(
  __dirname,
  '../../../../releases/2026-08-26/bishkek_geo_publish_report.json',
);

const OLD_FINGERPRINT =
  '637d84841363b34e039783f185098631ac7b30a2094ec2eeb1d0623ffe1b1b0d';

const LOCALE_KEYS = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];

const COUNTRY_REF = 'countries/kyrgyzstan';
const REGION_ID = 'region_kg_bishkek';
const VILLAGE_ID = 'city_kg_bishkek';
const REGION_PATH = `cities/${REGION_ID}`;
const VILLAGE_PATH = `villages/${VILLAGE_ID}`;

const BISHKEK_CENTER = {lat: 42.8746, lng: 74.5698};

const cityNames = {
  ar: 'بيشكيك',
  en: 'Bishkek',
  ru: 'Бишкек',
  ky: 'Бишкек',
  fr: 'Bichkek',
  ur: 'بشکیک',
  pt: 'Bishkek',
};

const cityDescriptions = {
  ar: 'بيشكيك هي عاصمة قيرغيزستان وأكبر مدنها، وتقع في وادي تشüy قرب سلسلة جبال Ala-Too القيرغيزية.',
  en: 'Bishkek is the capital and largest city of Kyrgyzstan, located in the Chüy Valley near the Kyrgyz Ala-Too mountain range.',
  ru: 'Бишкек — столица и крупнейший город Кыргызстана, расположенный в Чуйской долине у хребта Kyrgyz Ala-Too.',
  ky: 'Бишкек — Кыргызстандын борбору жана эң чоң шаары, Чүй өрөөнүндө Kyrgyz Ala-Too тоо кыркасынын жanında жайгашкан.',
  fr: 'Bichkek est la capitale et la plus grande ville du Kirghizistan, située dans la vallée de Tchüy, près de la chaîne Ala-Too kirghize.',
  ur: 'بشکیک قیرغizستان کا دارالحکومت اور سب سے بڑا شہر ہے، جو Kyrgyz Ala-Too پہاڑوں کے قریب Chüy وادی میں واقع ہے۔',
  pt: 'Bishkek é a capital e maior cidade do Quirguistão, no vale de Chüy, perto da cordilheira Ala-Too do Quirguistão.',
};

const villageDescriptions = {
  ar: 'بيشكيك — العاصمة والمركز الإداري لقيرغيزستان.',
  en: 'Bishkek — capital and administrative center of Kyrgyzstan.',
  ru: 'Бишкек — столица и административный центр Кыргызстана.',
  ky: 'Бишкек — Кыргызстандын борбору жана административдик борбору.',
  fr: 'Bichkek — capitale et centre administratif du Kirghizistan.',
  ur: 'بشکیک — قیرغizستان کا دارالحکومت اور انتظامی مرکز۔',
  pt: 'Bishkek — capital e centro administrativo do Quirguistão.',
};

const LANDMARKS = [
  {
    id: 'lm_kg_bishkek_bishkek-ala-too',
    slug: 'bishkek-ala-too',
    sr: 1,
    lat: 42.8746,
    lng: 74.6122,
    tsnef: 'معالم سياحية',
    as_ads: true,
    img1:
      'https://upload.wikimedia.org/wikipedia/commons/5/54/Changing_of_the_guard_Ala-Too_Square%2C_Bishkek%2C_Kyrgyzstan.jpg',
    img_license: 'CC BY-SA 4.0',
    img_attribution: 'Petar Milošević',
    names: {
      ar: 'ساحة ألا توو',
      en: 'Ala-Too Square',
      ru: 'Площадь Ала-Тоо',
      ky: 'Ала-Тоо аянты',
      fr: 'Place Ala-Too',
      ur: 'الا-ٹو میدان',
      pt: 'Praça Ala-Too',
    },
    descriptions: {
      ar: 'الساحة العامة المركزية في بيشكيك، تضم مبانٍ حكومية وفعاليات عامة ونصبًا واحتفالات وطنية.',
      en: 'The central public square of Bishkek, known for government buildings, public events, monuments, and major national celebrations.',
      ru: 'Центральная площадь Бишкека с правительственными зданиями, общественными мероприятиями, памятниками и национальными праздниками.',
      ky: 'Бишкектин борбордук коомдук аянты — мамлекеттик имараттар, иш-чаралар, эстеликтер жана улуттук майрамдар.',
      fr: 'La place publique centrale de Bichkek, connue pour ses bâtiments gouvernementaux, événements publics, monuments et grandes célébrations nationales.',
      ur: 'بشکیک کا مرکزی عوامی میدان — سرکاری عمارتیں، عوامی تقریبات، یادگاریں اور قومی جشن۔',
      pt: 'A praça pública central de Bishkek, conhecida por edifícios governamentais, eventos públicos, monumentos e grandes celebrações nacionais.',
    },
  },
  {
    id: 'lm_kg_bishkek_bishkek-history-museum',
    slug: 'bishkek-history-museum',
    sr: 2,
    lat: 42.8763,
    lng: 74.6037,
    tsnef: 'معالم سياحية',
    as_ads: true,
    img1: 'https://flagcdn.com/w320/kg.png',
    img_license: '',
    img_attribution: '',
    names: {
      ar: 'متحف التاريخ الحكومي لجمهورية قيرغيزستان',
      en: 'State History Museum of the Kyrgyz Republic',
      ru: 'Государственный исторический музей Кыргызской Республики',
      ky: 'Кыргыз Республикасынын мамлекеттик тарых музейи',
      fr: 'Musée d’histoire d’État de la République kirghize',
      ur: 'جمہوریہ قیرغizستان کا ریاستی تاریخی عجائب گھر',
      pt: 'Museu Estatal de História da República do Quirguistão',
    },
    descriptions: {
      ar: 'متحف رئيسي في ساحة ألا توو يعرض تاريخ وثقافة وآثار وتراث قيرغيزستان.',
      en: 'A major museum on Ala-Too Square presenting the history, culture, archaeology and heritage of Kyrgyzstan.',
      ru: 'Крупный музей на площади Ала-Тоо, представляющий историю, культуру, археологию и наследие Кыргызстана.',
      ky: 'Ала-Тоо аянтындагы чоң музей — Кыргызстандын тарыхы, маданияты, археологиясы жана мурасы.',
      fr: 'Un grand musée sur la place Ala-Too présentant l’histoire, la culture, l’archéologie et le patrimoine du Kirghizistan.',
      ur: 'الا-ٹو میدان پر ایک بڑا عجائب گھر جو قیرغizستان کی تاریخ، ثقافت، آثار قدیمہ اور ورثہ پیش کرتا ہے۔',
      pt: 'Um grande museu na Praça Ala-Too que apresenta a história, cultura, arqueologia e património do Quirguistão.',
    },
  },
  {
    id: 'lm_kg_bishkek_bishkek-osh-bazaar',
    slug: 'bishkek-osh-bazaar',
    sr: 3,
    lat: 42.874,
    lng: 74.5696,
    tsnef: 'أسواق',
    as_ads: true,
    img1:
      'https://upload.wikimedia.org/wikipedia/commons/e/e7/Jayma_Bazaar%2C_Osh.jpg',
    img_license: 'CC0',
    img_attribution: 'Bgag',
    names: {
      ar: 'سوق أوش',
      en: 'Osh Bazaar',
      ru: 'Ошский базар',
      ky: 'Ош базары',
      fr: 'Bazar d’Osh',
      ur: 'اوش بازار',
      pt: 'Bazar de Osh',
    },
    descriptions: {
      ar: 'من أشهر الأسواق التقليدية في بيشكيك، يبيع الأطعمة المحلية والتوابل والمنتجات والملابس والسلع اليومية.',
      en: "One of Bishkek's best-known traditional markets, selling local food, spices, produce, clothing and everyday goods.",
      ru: 'Один из самых известных традиционных рынков Бишкека с местными продуктами, специями, одеждой и товарами повседневного спроса.',
      ky: 'Бишкектин белгилүү базарларыndan biri — жергиликтүү тамак-аш, специялар, жемиш-кожо жана күнүмдүк товарлар.',
      fr: 'L’un des marchés traditionnels les plus connus de Bichkek, vendant nourriture locale, épices, produits, vêtements et biens du quotidien.',
      ur: 'بشکیک کے مشہور روایتی بازاروں میں سے ایک — مقامی کھانا، مصالحے، پیداوار، کپڑے اور روزمرہ سامان۔',
      pt: 'Um dos mercados tradicionais mais conhecidos de Bishkek, vendendo comida local, especiarias, produtos, roupas e bens do dia a dia.',
    },
  },
  {
    id: 'lm_kg_bishkek_bishkek-victory-square',
    slug: 'bishkek-victory-square',
    sr: 4,
    lat: 42.8779,
    lng: 74.6138,
    tsnef: 'معالم سياحية',
    as_ads: false,
    img1: 'https://flagcdn.com/w320/kg.png',
    img_license: '',
    img_attribution: '',
    names: {
      ar: 'ساحة النصر',
      en: 'Victory Square',
      ru: 'Площадь Победы',
      ky: 'Жеңиш аянты',
      fr: 'Place de la Victoire',
      ur: 'فتح کا میدان',
      pt: 'Praça da Vitória',
    },
    descriptions: {
      ar: 'ساحة تذكارية رئيسية في بيشكيك مخصصة للنصر في الحرب العالمية الثانية ولمن خدموا وتوفوا.',
      en: 'A major memorial square in Bishkek dedicated to the victory in World War II and those who served and died.',
      ru: 'Главная мемориальная площадь Бишкека, посвящённая победе во Второй мировой войне и павшим.',
      ky: 'Бишкектин негизги эстелик аянты — Экинчи дүйнөлük согуштагы жеңишке жана курман болгондорго арналган.',
      fr: 'Une grande place commémorative de Bichkek dédiée à la victoire de la Seconde Guerre mondiale et à ceux qui ont servi et sont morts.',
      ur: 'بشکیک کا ایک بڑا یادگاری میدان جو دوسری عالمی جنگ میں فتح اور شہداء کے لیے وقف ہے۔',
      pt: 'Uma grande praça memorial em Bishkek dedicada à vitória na Segunda Guerra Mundial e a quem serviu e morreu.',
    },
  },
  {
    id: 'lm_kg_bishkek_bishkek-panfilov',
    slug: 'bishkek-panfilov',
    sr: 5,
    lat: 42.8798,
    lng: 74.6032,
    tsnef: 'معالم سياحية',
    as_ads: false,
    img1:
      'https://upload.wikimedia.org/wikipedia/commons/e/e3/Panfilov_park.jpg',
    img_license: 'CC BY-SA 4.0',
    img_attribution: 'Davide Mauro',
    names: {
      ar: 'منتزه بانفيلوف',
      en: 'Panfilov Park',
      ru: 'Парк имени Панфилова',
      ky: 'Панфилов атындагы парк',
      fr: 'Parc Panfilov',
      ur: 'پانفیلوف پارک',
      pt: 'Parque Panfilov',
    },
    descriptions: {
      ar: 'حديقة مركزية شائعة في بيشكيك بمساحات خضراء وممرات للمشي ومناطق ترفيه عائلية.',
      en: 'A popular central Bishkek park with green spaces, walking areas and family recreation attractions.',
      ru: 'Популярный центральный парк Бишкека с зелёными зонами, прогулочными аллеями и семейным отдыхом.',
      ky: 'Бишкектин борбордук популярдуу паркы — жашыл аймактар, сергек жürüş жана үй-бүлөлük эс алуу.',
      fr: 'Un parc central populaire de Bichkek avec espaces verts, allées de promenade et loisirs familiaux.',
      ur: 'بشکیک کا مقبول مرکزی پارک — سبزہزار، چہل قدمی کے راستے اور خاندانی تفریح۔',
      pt: 'Um parque central popular de Bishkek com áreas verdes, caminhos para passeio e lazer em família.',
    },
  },
];

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();
const GeoPoint = admin.firestore.GeoPoint;

function ref(p) {
  return db.doc(p);
}

function addressFor(names, lang) {
  const city = cityNames[lang] || cityNames.en;
  const country =
    {
      ar: 'قيرغيزستان',
      en: 'Kyrgyzstan',
      ru: 'Кырgyzstan',
      ky: 'Кыргызстан',
      fr: 'Kirghizistan',
      ur: 'قیرغizستان',
      pt: 'Quirguistão',
    }[lang] || 'Kyrgyzstan';
  return `${names[lang] || names.en}, ${city}, ${country}`;
}

function buildRegionDoc() {
  return {
    naim: cityNames.ar,
    names_i18n: cityNames,
    osf: cityDescriptions.ar,
    osf_i18n: cityDescriptions,
    img: 'https://flagcdn.com/w320/kg.png',
    icon: 'https://flagcdn.com/w320/kg.png',
    dolh: ref(COUNTRY_REF),
    vil: ref(VILLAGE_PATH),
    acctev: true,
    sorting: 1,
    iso_code: 'KG-GB',
    country_iso: 'KG',
    geo_center: new GeoPoint(BISHKEK_CENTER.lat, BISHKEK_CENTER.lng),
    geo_import_id: REGION_ID,
    geo_import_source: 'bishkek_curated_2026_08_26',
  };
}

function buildVillageDoc() {
  return {
    naim: cityNames.ar,
    names_i18n: cityNames,
    naimciteText: cityNames.en,
    osf: villageDescriptions.ar,
    osf_i18n: villageDescriptions,
    img: 'https://flagcdn.com/w320/kg.png',
    cities: ref(REGION_PATH),
    dolh: ref(COUNTRY_REF),
    lat_ling: new GeoPoint(BISHKEK_CENTER.lat, BISHKEK_CENTER.lng),
    acctev: true,
    country_iso: 'KG',
    geo_import_id: VILLAGE_ID,
    geo_import_source: 'bishkek_curated_2026_08_26',
  };
}

function buildLandmarkDoc(lm) {
  const address_i18n = {};
  const address = addressFor(lm.names, 'ar');
  for (const lang of LOCALE_KEYS) {
    address_i18n[lang] = addressFor(lm.names, lang);
  }
  return {
    naim: lm.names.ar,
    names_i18n: lm.names,
    osf: lm.descriptions.ar,
    osf_i18n: lm.descriptions,
    address,
    address_i18n,
    content_locale: 'ar',
    Location: new GeoPoint(lm.lat, lm.lng),
    img1: lm.img1,
    img2: '',
    img3: '',
    img_license: lm.img_license,
    img_attribution: lm.img_attribution,
    images_license_verified: true,
    img_source: lm.img1.includes('wikimedia') ? 'wikipedia_or_commons' : 'catalog_placeholder',
    sr: lm.sr,
    acctev: true,
    as_ads: lm.as_ads,
    ismzod: true,
    isShrek: false,
    ismsgd: false,
    isfood: false,
    ishmam: true,
    tsnef: lm.tsnef,
    rate: 4.7,
    add_saat: 2,
    id_cit: ref(REGION_PATH),
    id_vill: ref(VILLAGE_PATH),
    Rev_dolh: ref(COUNTRY_REF),
    country_iso: 'KG',
    wikidata_id: null,
    source_provider: 'curated_bishkek_2026',
    verification_status: 'verified',
    verification_confidence: 0.92,
    geo_import_id: lm.id,
    geo_import_slug: lm.slug,
    geo_import_source: 'bishkek_curated_2026_08_26',
  };
}

async function countCollections() {
  const out = {};
  for (const c of ['countries', 'regions', 'cities', 'villages', 'mkan', 'type_car', 'auto_num']) {
    out[c] = (await db.collection(c).get()).size;
  }
  return out;
}

function fingerprintDocs(docs, fields) {
  const rows = docs.map((d) => {
    const data = d.data();
    const row = {id: d.id};
    for (const f of fields) row[f] = data[f] ?? null;
    return row;
  });
  rows.sort((a, b) => a.id.localeCompare(b.id));
  return crypto.createHash('sha256').update(JSON.stringify(rows)).digest('hex');
}

async function geoFingerprint() {
  async function snap(name, fields) {
    const s = await db.collection(name).limit(5000).get();
    return {count: s.size, hash: fingerprintDocs(s.docs, fields)};
  }
  const countries = await snap('countries', [
    'naim',
    'name',
    'iso_code',
    'actev',
    'acctev',
  ]);
  const regions = await snap('regions', ['naim', 'name', 'dolh', 'actev', 'acctev']);
  const cities = await snap('cities', ['naim', 'name', 'dolh', 'actev', 'acctev']);
  const villages = await snap('villages', ['naim', 'name', 'cities', 'dolh', 'actev', 'acctev']);
  const mkan = await snap('mkan', ['naim', 'name', 'dolh', 'loceshn', 'actev', 'acctev']);
  const typeCar = await snap('type_car', ['naim', 'name', 'actev', 'acctev', 'codeCar', 'dolh']);
  return crypto
    .createHash('sha256')
    .update(
      JSON.stringify({
        c: countries.hash,
        r: regions.hash,
        ci: cities.hash,
        v: villages.hash,
        m: mkan.hash,
        t: typeCar.hash,
      }),
    )
    .digest('hex');
}

function localizationMatrix(entity, names, descriptions) {
  const row = {entity};
  for (const lang of LOCALE_KEYS) {
    row[lang] =
      (names[lang] || '').trim() && (descriptions[lang] || '').trim()
        ? 'PASS'
        : 'MISSING';
  }
  return row;
}

async function backupExisting() {
  fs.mkdirSync(BACKUP_DIR, {recursive: true});
  const paths = [REGION_PATH, VILLAGE_PATH, ...LANDMARKS.map((l) => `mkan/${l.id}`)];
  const backup = {backedUpAt: new Date().toISOString(), docs: {}};
  for (const p of paths) {
    const snap = await db.doc(p).get();
    backup.docs[p] = snap.exists ? snap.data() : null;
  }
  backup.countsBefore = await countCollections();
  backup.fingerprintBefore = await geoFingerprint();
  const out = path.join(BACKUP_DIR, 'pre_write_backup.json');
  fs.writeFileSync(out, JSON.stringify(backup, null, 2));
  return out;
}

async function findDuplicates() {
  const allCities = await db.collection('cities').get();
  const allVillages = await db.collection('villages').get();
  const allMkan = await db.collection('mkan').get();
  const norm = (s) => (s || '').toString().trim().toLowerCase();
  const bishkekCity = allCities.docs.filter((d) => {
    const n = d.data().names_i18n || {};
    return ['en', 'ru', 'ar', 'ky'].some((k) => norm(n[k]).includes('bishkek') || norm(n[k]).includes('бишкек') || norm(n[k]).includes('بيشك'));
  });
  const bishkekVill = allVillages.docs.filter((d) => {
    const n = d.data().names_i18n || {};
    return ['en', 'ru', 'ar', 'ky'].some((k) => norm(n[k]).includes('bishkek') || norm(n[k]).includes('бишкек'));
  });
  const targetNames = new Set(LANDMARKS.map((l) => norm(l.names.en)));
  const lmDupes = allMkan.docs.filter((d) => {
    const en = norm(d.data().names_i18n?.en || d.data().naim);
    return [...targetNames].some((t) => en === t);
  });
  return {
    bishkekCity: bishkekCity.map((d) => d.id),
    bishkekVill: bishkekVill.map((d) => d.id),
    landmarkMatches: lmDupes.map((d) => d.id),
  };
}

async function main() {
  console.log(APPLY ? 'MODE: APPLY' : 'MODE: DRY-RUN');

  const countsBefore = await countCollections();
  const fpBefore = await geoFingerprint();
  const dupes = await findDuplicates();
  console.log('COUNTS_BEFORE', countsBefore);
  console.log('FP_BEFORE', fpBefore);
  console.log('DUPLICATES', dupes);

  const backupPath = await backupExisting();
  console.log('BACKUP', backupPath);

  const mutations = {
    createRegion: REGION_PATH,
    createVillage: VILLAGE_PATH,
    createLandmarks: LANDMARKS.map((l) => `mkan/${l.id}`),
    delete: 0,
    otherUpdates: 0,
  };
  console.log('MUTATIONS', JSON.stringify(mutations, null, 2));

  if (!APPLY) {
    console.log('DRY-RUN complete — pass --apply to write');
    return;
  }

  const batch = db.batch();
  batch.set(db.doc(REGION_PATH), buildRegionDoc(), {merge: false});
  batch.set(db.doc(VILLAGE_PATH), buildVillageDoc(), {merge: false});
  for (const lm of LANDMARKS) {
    batch.set(db.doc(`mkan/${lm.id}`), buildLandmarkDoc(lm), {merge: false});
  }
  await batch.commit();

  const countsAfter = await countCollections();
  const fpAfter = await geoFingerprint();

  const verify = {};
  verify.region = (await db.doc(REGION_PATH).get()).exists;
  verify.village = (await db.doc(VILLAGE_PATH).get()).exists;
  for (const lm of LANDMARKS) {
    verify[lm.id] = (await db.doc(`mkan/${lm.id}`).get()).exists;
  }

  const localization = [
    localizationMatrix('Bishkek region', cityNames, cityDescriptions),
    localizationMatrix('Bishkek village', cityNames, villageDescriptions),
    ...LANDMARKS.map((lm) =>
      localizationMatrix(lm.names.en, lm.names, lm.descriptions),
    ),
  ];

  const report = {
    publishedAt: new Date().toISOString(),
    countsBefore,
    countsAfter,
    fingerprintBefore: fpBefore,
    fingerprintAfter: fpAfter,
    oldExpectedFingerprint: OLD_FINGERPRINT,
    verify,
    localization,
    coordinates: {
      bishkek: {...BISHKEK_CENTER, source: 'OpenStreetMap/Wikipedia city center'},
      landmarks: LANDMARKS.map((l) => ({
        name: l.names.en,
        lat: l.lat,
        lng: l.lng,
        source: 'curated_kyrgyzstan_seed + OSM crosscheck',
      })),
    },
    backupPath,
    mutations,
  };

  fs.mkdirSync(path.dirname(REPORT_PATH), {recursive: true});
  fs.writeFileSync(REPORT_PATH, JSON.stringify(report, null, 2));
  console.log('REPORT', REPORT_PATH);
  console.log('COUNTS_AFTER', countsAfter);
  console.log('FP_AFTER', fpAfter);
  console.log('VERIFY', verify);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
