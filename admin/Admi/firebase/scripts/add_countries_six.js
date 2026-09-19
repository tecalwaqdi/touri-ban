/**
 * Additive-only: create the 6 requested countries if missing.
 * Countries ONLY — no regions/cities/landmarks.
 *
 * Doc IDs follow TouryCountryRegistry preferred / expand_toury_content:
 *   russia, uzbekistan, turkmenistan, kazakhstan, georgia, egypt
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_countries_six.js
 *   GOOGLE_APPLICATION_CREDENTIALS=... node add_countries_six.js --apply
 */
const path = require("path");
const https = require("https");
const http = require("http");
const { URL } = require("url");
const crypto = require("crypto");

const APPLY = process.argv.includes("--apply");
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const BUCKET = "tutorial-multi-language-70gx4j.firebasestorage.app";

const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));

/** From Admi/lib/core/i18n/toury_i18n_locales.dart */
const LOCALES = [
  "ar",
  "en",
  "zh_Hans",
  "tr",
  "ur",
  "ru",
  "az",
  "ka",
  "ky",
  "fr",
  "id",
  "pt",
];

function names(map) {
  for (const k of LOCALES) {
    if (!map[k] || !String(map[k]).trim()) {
      throw new Error(`Missing locale ${k} in ${JSON.stringify(map)}`);
    }
  }
  return map;
}

const COUNTRIES = [
  {
    id: "russia",
    iso2: "RU",
    iso3: "RUS",
    ar: "روسيا",
    en: "Russia",
    currency_code: "RUB",
    CurrencySymbol: "₽",
    phone_code: "+7",
    timezone: "Europe/Moscow",
    lat: 61.524,
    lng: 105.3188,
    sw: [41.1, 19.6],
    ne: [81.9, 180.0],
    names: names({
      ar: "روسيا",
      en: "Russia",
      zh_Hans: "俄罗斯",
      tr: "Rusya",
      ur: "روس",
      ru: "Россия",
      az: "Rusiya",
      ka: "რუსეთი",
      ky: "Россия",
      fr: "Russie",
      id: "Rusia",
      pt: "Rússia",
    }),
    osf: {
      ar: "روسيا — مدن تاريخية وطبيعة شاسعة من موسكو إلى سيبيريا.",
      en: "Russia — historic cities and vast landscapes from Moscow to Siberia.",
      zh_Hans: "俄罗斯 — 从莫斯科到西伯利亚的历史名城与广阔风光。",
      tr: "Rusya — Moskova'dan Sibirya'ya tarihi şehirler ve geniş coğrafya.",
      ur: "روس — ماسکو سے سائبیریا تک تاریخی شہر اور وسیع مناظر۔",
      ru: "Россия — исторические города и просторы от Москвы до Сибири.",
      az: "Rusiya — Moskvadan Sibire qədər tarixi şəhərlər və geniş mənzərələr.",
      ka: "რუსეთი — ისტორიული ქალაქები და უზარმაზარი პეიზაჟები.",
      ky: "Россия — Москвадан Сибирге чейинки тарыхый шаарлар.",
      fr: "Russie — villes historiques et vastes paysages de Moscou à la Sibérie.",
      id: "Rusia — kota bersejarah dan lanskap luas dari Moskow ke Siberia.",
      pt: "Rússia — cidades históricas e vastas paisagens de Moscovo à Sibéria.",
    },
  },
  {
    id: "uzbekistan",
    iso2: "UZ",
    iso3: "UZB",
    ar: "أوزبكستان",
    en: "Uzbekistan",
    currency_code: "UZS",
    CurrencySymbol: "soʻm",
    phone_code: "+998",
    timezone: "Asia/Tashkent",
    lat: 41.3775,
    lng: 64.5853,
    sw: [37.1, 55.9],
    ne: [45.6, 73.2],
    names: names({
      ar: "أوزبكستان",
      en: "Uzbekistan",
      zh_Hans: "乌兹别克斯坦",
      tr: "Özbekistan",
      ur: "ازبکستان",
      ru: "Узбекистан",
      az: "Özbəkistan",
      ka: "უზბეკეთი",
      ky: "Өзбекстан",
      fr: "Ouzbékistan",
      id: "Uzbekistan",
      pt: "Uzbequistão",
    }),
    osf: {
      ar: "أوزبكستان — طريق الحرير ومدن سمرقند وبخارى وطشقند.",
      en: "Uzbekistan — Silk Road heritage of Samarkand, Bukhara, and Tashkent.",
      zh_Hans: "乌兹别克斯坦 — 撒马尔罕、布哈拉与塔什干的丝绸之路遗产。",
      tr: "Özbekistan — Semerkant, Buhara ve Taşkent İpek Yolu mirası.",
      ur: "ازبکستان — سمرقند، بخارا اور تاشقند کا ریشم راستہ ورثہ۔",
      ru: "Узбекистан — наследие Шёлкового пути: Самарканд, Бухара, Ташкент.",
      az: "Özbəkistan — Səmərqənd, Buxara və Daşkənd İpək Yolu irsi.",
      ka: "უზბეკეთი — სამარყანდის, ბუხარასა და ტაშქენტის აბრეშუმის გზა.",
      ky: "Өзбекстан — Самарканд, Бухара жана Ташкент Жүз жылдык жолу.",
      fr: "Ouzbékistan — héritage de la Route de la soie à Samarcande et Boukhara.",
      id: "Uzbekistan — warisan Jalur Sutra Samarkand, Bukhara, dan Tashkent.",
      pt: "Uzbequistão — herança da Rota da Seda em Samarcanda e Bucara.",
    },
  },
  {
    id: "turkmenistan",
    iso2: "TM",
    iso3: "TKM",
    ar: "تركمانستان",
    en: "Turkmenistan",
    currency_code: "TMT",
    CurrencySymbol: "m",
    phone_code: "+993",
    timezone: "Asia/Ashgabat",
    lat: 38.9697,
    lng: 59.5563,
    sw: [35.1, 52.4],
    ne: [42.8, 66.7],
    names: names({
      ar: "تركمانستان",
      en: "Turkmenistan",
      zh_Hans: "土库曼斯坦",
      tr: "Türkmenistan",
      ur: "ترکمانستان",
      ru: "Туркменистан",
      az: "Türkmənistan",
      ka: "თურქმენეთი",
      ky: "Түркмөнстан",
      fr: "Turkménistan",
      id: "Turkmenistan",
      pt: "Turquemenistão",
    }),
    osf: {
      ar: "تركمانستان — عاصمة عشق آباد وتراث طريق الحرير في مرو.",
      en: "Turkmenistan — Ashgabat and Silk Road heritage at Merv.",
      zh_Hans: "土库曼斯坦 — 阿什哈巴德与梅尔夫的丝绸之路遗产。",
      tr: "Türkmenistan — Aşkabat ve Merv İpek Yolu mirası.",
      ur: "ترکمانستان — عشق آباد اور مرو کا ریشم راستہ ورثہ۔",
      ru: "Туркменистан — Ашхабад и наследие Шёлкового пути в Мерве.",
      az: "Türkmənistan — Aşqabad və Merv İpək Yolu irsi.",
      ka: "თურქმენეთი — აშხაბადი და მერვის აბრეშუმის გზა.",
      ky: "Түркмөнстан — Ашхабад жана Мерв Жүз жылдык жолу.",
      fr: "Turkménistan — Achgabat et l'héritage de Merv sur la Route de la soie.",
      id: "Turkmenistan — Ashgabat dan warisan Jalur Sutra di Merv.",
      pt: "Turquemenistão — Asgabate e a herança da Rota da Seda em Merv.",
    },
  },
  {
    id: "kazakhstan",
    iso2: "KZ",
    iso3: "KAZ",
    ar: "كازاخستان",
    en: "Kazakhstan",
    currency_code: "KZT",
    CurrencySymbol: "₸",
    phone_code: "+7",
    timezone: "Asia/Almaty",
    lat: 48.0196,
    lng: 66.9237,
    sw: [40.9, 46.5],
    ne: [55.5, 87.4],
    names: names({
      ar: "كازاخستان",
      en: "Kazakhstan",
      zh_Hans: "哈萨克斯坦",
      tr: "Kazakistan",
      ur: "قازقستان",
      ru: "Казахстан",
      az: "Qazaxıstan",
      ka: "ყაზახეთი",
      ky: "Казакстан",
      fr: "Kazakhstan",
      id: "Kazakhstan",
      pt: "Cazaquistão",
    }),
    osf: {
      ar: "كازاخستان — سهوب واسعة ومدن آستانا وألماتي.",
      en: "Kazakhstan — vast steppes with Astana and Almaty.",
      zh_Hans: "哈萨克斯坦 — 广袤草原与阿斯塔纳、阿拉木图。",
      tr: "Kazakistan — geniş bozkırlar, Astana ve Almatı.",
      ur: "قازقستان — وسیع میدان اور آستانہ و الماتی۔",
      ru: "Казахстан — бескрайние степи, Астана и Алматы.",
      az: "Qazaxıstan — geniş çöllər, Astana və Almatı.",
      ka: "ყაზახეთი — უზარმაზარი სტეპები, ასტანა და ალმათი.",
      ky: "Казакстан — кең талаалар, Астана жана Алматы.",
      fr: "Kazakhstan — immenses steppes, Astana et Almaty.",
      id: "Kazakhstan — stepa luas dengan Astana dan Almaty.",
      pt: "Cazaquistão — vastas estepes com Astana e Almaty.",
    },
  },
  {
    id: "georgia",
    iso2: "GE",
    iso3: "GEO",
    ar: "جورجيا",
    en: "Georgia",
    currency_code: "GEL",
    CurrencySymbol: "₾",
    phone_code: "+995",
    timezone: "Asia/Tbilisi",
    lat: 41.7151,
    lng: 44.8271,
    sw: [41.0, 39.9],
    ne: [43.6, 46.8],
    names: names({
      ar: "جورجيا",
      en: "Georgia",
      zh_Hans: "格鲁吉亚",
      tr: "Gürcistan",
      ur: "جارجیا",
      ru: "Грузия",
      az: "Gürcüstan",
      ka: "საქართველო",
      ky: "Грузия",
      fr: "Géorgie",
      id: "Georgia",
      pt: "Geórgia",
    }),
    osf: {
      ar: "جورجيا — تبليسي القديمة وجبال القوقاز.",
      en: "Georgia — historic Tbilisi and the Caucasus mountains.",
      zh_Hans: "格鲁吉亚 — 历史名城第比利斯与高加索山脉。",
      tr: "Gürcistan — tarihi Tiflis ve Kafkas Dağları.",
      ur: "جارجیا — تاریخی تبلیسی اور قفقاز پہاڑ۔",
      ru: "Грузия — исторический Тбилиси и Кавказские горы.",
      az: "Gürcüstan — tarixi Tbilisi və Qafqaz dağları.",
      ka: "საქართველო — ისტორიული თბილისი და კავკასიონი.",
      ky: "Грузия — тарыхый Тбилиси жана Кавказ тоолору.",
      fr: "Géorgie — Tbilissi historique et le Caucase.",
      id: "Georgia — Tbilisi bersejarah dan Pegunungan Kaukasus.",
      pt: "Geórgia — Tbilisi histórica e as montanhas do Cáucaso.",
    },
  },
  {
    id: "egypt",
    iso2: "EG",
    iso3: "EGY",
    ar: "مصر",
    en: "Egypt",
    currency_code: "EGP",
    CurrencySymbol: "ج.م",
    phone_code: "+20",
    timezone: "Africa/Cairo",
    lat: 26.8206,
    lng: 30.8025,
    sw: [22.0, 24.7],
    ne: [31.7, 36.9],
    names: names({
      ar: "مصر",
      en: "Egypt",
      zh_Hans: "埃及",
      tr: "Mısır",
      ur: "مصر",
      ru: "Египет",
      az: "Misir",
      ka: "ეგვიპტე",
      ky: "Египет",
      fr: "Égypte",
      id: "Mesir",
      pt: "Egito",
    }),
    osf: {
      ar: "مصر — القاهرة والأهرامات ونيل التاريخ.",
      en: "Egypt — Cairo, the pyramids, and the historic Nile.",
      zh_Hans: "埃及 — 开罗、金字塔与历史悠久的尼罗河。",
      tr: "Mısır — Kahire, piramitler ve tarihi Nil.",
      ur: "مصر — قاہرہ، اہرام اور تاریخی نیل۔",
      ru: "Египет — Каир, пирамиды и исторический Нил.",
      az: "Misir — Qahirə, piramidalar və tarixi Nil.",
      ka: "ეგვიპტე — კაირო, პირამიდები და ისტორიული ნილი.",
      ky: "Египет — Каир, пирамидалар жана тарыхый Нил.",
      fr: "Égypte — Le Caire, les pyramides et le Nil historique.",
      id: "Mesir — Kairo, piramida, dan Sungai Nil bersejarah.",
      pt: "Egito — Cairo, as pirâmides e o histórico Nilo.",
    },
  },
];

function initAdmin() {
  if (admin.apps.length) return;
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
    storageBucket: BUCKET,
  });
}

function download(url, attempt = 1) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith("http:") ? http : https;
    const req = lib.get(
      url,
      {
        headers: {
          "User-Agent": "TouriTaxiCountrySeed/1.0",
          Accept: "image/*,*/*",
        },
      },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          download(res.headers.location, attempt).then(resolve, reject);
          return;
        }
        if ((res.statusCode === 429 || res.statusCode >= 500) && attempt < 5) {
          res.resume();
          setTimeout(
            () => download(url, attempt + 1).then(resolve, reject),
            1000 * attempt,
          );
          return;
        }
        if (res.statusCode !== 200) {
          reject(new Error(`download ${res.statusCode} ${url}`));
          res.resume();
          return;
        }
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => resolve(Buffer.concat(chunks)));
      },
    );
    req.on("error", (err) => {
      if (attempt < 5) {
        setTimeout(
          () => download(url, attempt + 1).then(resolve, reject),
          1000 * attempt,
        );
      } else reject(err);
    });
  });
}

function headOk(url) {
  return new Promise((resolve) => {
    https
      .get(
        url,
        {
          headers: { Range: "bytes=0-32", "User-Agent": "TouriTaxiCountrySeed/1.0" },
        },
        (res) => {
          res.resume();
          resolve(res.statusCode === 200 || res.statusCode === 206);
        },
      )
      .on("error", () => resolve(false));
  });
}

async function uploadFlag(iso2) {
  const lower = iso2.toLowerCase();
  const source = `https://flagcdn.com/w1280/${lower}.png`;
  const bytes = await download(source);
  if (!bytes.length) throw new Error(`empty flag ${source}`);
  const objectPath = `countries/uploads/${lower}_${Date.now()}.png`;
  const file = admin.storage().bucket().file(objectPath);
  const token = crypto.randomUUID();
  await file.save(bytes, {
    resumable: false,
    contentType: "image/png",
    metadata: {
      cacheControl: "public,max-age=31536000",
      metadata: {
        source,
        uploaded_by: "add_countries_six.js",
        firebaseStorageDownloadTokens: token,
      },
    },
  });
  const encoded = encodeURIComponent(objectPath);
  const url =
    `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encoded}` +
    `?alt=media&token=${token}`;
  if (!(await headOk(url))) {
    // Fallback to proven flagcdn country pattern if Storage ACL blocks anonymous HEAD.
    const flagcdn = `https://flagcdn.com/w320/${lower}.png`;
    if (!(await headOk(flagcdn))) {
      throw new Error(`flag URL failed to load: storage=${url} flagcdn=${flagcdn}`);
    }
    return {
      img: flagcdn,
      hederImg: `https://flagcdn.com/w1280/${lower}.png`,
      storageUrl: url,
      usedFallback: true,
    };
  }
  return {
    img: url,
    hederImg: `https://flagcdn.com/w1280/${lower}.png`,
    usedFallback: false,
  };
}

function normalize(s) {
  return String(s || "")
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u064B-\u065F]/g, "")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function fingerprint(data) {
  const pick = {};
  for (const k of Object.keys(data || {}).sort()) {
    if (["created_at", "updated_at", "driver_requirements_initialized_at"].includes(k)) {
      continue;
    }
    const v = data[k];
    if (v && v.constructor && v.constructor.name === "DocumentReference") {
      pick[k] = v.path;
    } else if (v && typeof v.latitude === "number") {
      pick[k] = { lat: v.latitude, lng: v.longitude };
    } else if (v && typeof v.toDate === "function") {
      pick[k] = v.toDate().toISOString();
    } else {
      pick[k] = v;
    }
  }
  return crypto.createHash("sha256").update(JSON.stringify(pick)).digest("hex");
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const snap = await db.collection("countries").get();
  const existing = snap.docs;
  const maxSort = existing.reduce((m, d) => {
    const n = Number(d.data().num_trteb) || 0;
    return Math.max(m, n);
  }, 0);

  const beforeExisting = {};
  for (const d of existing) {
    beforeExisting[d.id] = fingerprint(d.data());
  }

  const report = {
    mode: APPLY ? "APPLY" : "DRY-RUN",
    created: [],
    already: [],
    skippedDup: [],
    images: [],
  };

  let order = maxSort + 1;
  for (const c of COUNTRIES) {
    // Duplicate detection by id / iso / names
    const byId = existing.find((d) => d.id === c.id);
    const byIso = existing.find((d) => {
      const x = d.data();
      return String(x.iso_code || x.iso2 || "").toUpperCase() === c.iso2;
    });
    const byName = existing.find((d) => {
      const x = d.data();
      const candidates = [
        x.naim,
        x.naimEnglesh,
        ...(Object.values(x.names_i18n || {})),
      ].map(normalize);
      return (
        candidates.includes(normalize(c.ar)) ||
        candidates.includes(normalize(c.en))
      );
    });

    if (byId || byIso || byName) {
      const hit = (byId || byIso || byName).id;
      report.already.push({ wanted: c.id, existing: hit, iso: c.iso2 });
      continue;
    }

    let img = `https://flagcdn.com/w320/${c.iso2.toLowerCase()}.png`;
    let hederImg = `https://flagcdn.com/w1280/${c.iso2.toLowerCase()}.png`;
    if (APPLY) {
      const uploaded = await uploadFlag(c.iso2);
      img = uploaded.img;
      hederImg = uploaded.hederImg;
      report.images.push({ id: c.id, img, hederImg });
    }

    const payload = {
      naim: c.ar,
      naimEnglesh: c.en,
      names_i18n: c.names,
      osf: c.osf.ar,
      osf_i18n: c.osf,
      acctev: true,
      saudi: false,
      iso_code: c.iso2,
      iso3: c.iso3,
      CurrencySymbol: c.CurrencySymbol,
      currency_code: c.currency_code,
      phone_code: c.phone_code,
      timezone: c.timezone,
      img,
      hederImg,
      num_trteb: order++,
      geo_center: new admin.firestore.GeoPoint(c.lat, c.lng),
      bounds_sw: new admin.firestore.GeoPoint(c.sw[0], c.sw[1]),
      bounds_ne: new admin.firestore.GeoPoint(c.ne[0], c.ne[1]),
      geo_import_id: `country_${c.iso2.toLowerCase()}`,
      geo_import_source: "add_countries_six_2026",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (APPLY) {
      await db.collection("countries").doc(c.id).create(payload);
    }
    report.created.push(c.id);
  }

  // Validation after apply
  let translations = "PASS";
  let images = "PASS";
  let customerRuntime = "PASS";
  let existingChanged = 0;
  const status = {};

  if (APPLY) {
    for (const d of existing) {
      const now = await db.collection("countries").doc(d.id).get();
      if (!now.exists || fingerprint(now.data()) !== beforeExisting[d.id]) {
        existingChanged += 1;
      }
    }

    const active = await db
      .collection("countries")
      .where("acctev", "==", true)
      .get();
    const activeIds = new Set(active.docs.map((d) => d.id));

    for (const c of COUNTRIES) {
      const s = await db.collection("countries").doc(c.id).get();
      if (!s.exists) {
        status[c.id] = "MISSING";
        customerRuntime = "FAIL";
        continue;
      }
      const x = s.data();
      const miss = LOCALES.filter(
        (l) => !(x.names_i18n && String(x.names_i18n[l] || "").trim()),
      );
      if (miss.length) translations = "FAIL";
      if (x.iso_code !== c.iso2 || x.acctev !== true) customerRuntime = "FAIL";
      if (!activeIds.has(c.id)) customerRuntime = "FAIL";
      const imgOk = await headOk(x.img);
      const headerOk = await headOk(x.hederImg);
      if (!imgOk || !headerOk) images = "FAIL";
      // exactly once by iso among all countries
      const sameIso = (
        await db.collection("countries").get()
      ).docs.filter(
        (d) =>
          String(d.data().iso_code || "").toUpperCase() === c.iso2,
      );
      status[c.id] =
        sameIso.length === 1 && x.acctev === true && miss.length === 0 && imgOk
          ? "PASS"
          : "FAIL";
      if (sameIso.length !== 1) customerRuntime = "FAIL";
    }
  }

  console.log(
    JSON.stringify(
      {
        ...report,
        translations,
        images,
        customerRuntime,
        existingChanged,
        status,
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
