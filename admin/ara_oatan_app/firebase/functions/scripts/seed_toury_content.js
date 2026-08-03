const admin = require("firebase-admin");

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "tutorial-multi-language-70gx4j";

admin.initializeApp({projectId});

const db = admin.firestore();
const {FieldValue, GeoPoint} = admin.firestore;

const shouldDelete = process.argv.includes("--confirm-delete");

const collectionsToReplace = [
  "countries",
  "cities",
  "villages",
  "mkan",
  "type_car",
];

const img = {
  saudi:
    "https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?auto=format&fit=crop&w=1400&q=80",
  riyadh:
    "https://images.unsplash.com/photo-1589820296156-2454bb8a6ad1?auto=format&fit=crop&w=1400&q=80",
  alula:
    "https://images.unsplash.com/photo-1602171827788-0f4d73f4597a?auto=format&fit=crop&w=1400&q=80",
  jeddah:
    "https://images.unsplash.com/photo-1578895101408-1a36b834405b?auto=format&fit=crop&w=1400&q=80",
  museum:
    "https://images.unsplash.com/photo-1566127992631-137a642a90f4?auto=format&fit=crop&w=1400&q=80",
  desert:
    "https://images.unsplash.com/photo-1509316785289-025f5b846b35?auto=format&fit=crop&w=1400&q=80",
  heritage:
    "https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=1400&q=80",
  coast:
    "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1400&q=80",
  sedan:
    "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1200&q=80",
  suv:
    "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=1200&q=80",
  van:
    "https://images.unsplash.com/photo-1612825173281-9a193378527e?auto=format&fit=crop&w=1200&q=80",
};

const lang = {
  countrySaudi: {
    ar: "السعودية",
    en: "Saudi Arabia",
    fr: "Arabie saoudite",
    tr: "Suudi Arabistan",
    ru: "Саудовская Аравия",
    ur: "سعودی عرب",
    id: "Arab Saudi",
    az: "Səudiyyə Ərəbistanı",
    ka: "საუდის არაბეთი",
    ky: "Сауд Арабиясы",
    "zh-Hans": "沙特阿拉伯",
  },
  uae: {
    ar: "الإمارات",
    en: "United Arab Emirates",
    fr: "Émirats arabes unis",
    tr: "Birleşik Arap Emirlikleri",
    ru: "ОАЭ",
    ur: "متحدہ عرب امارات",
    id: "Uni Emirat Arab",
    az: "Birləşmiş Ərəb Əmirlikləri",
    ka: "არაბთა გაერთიანებული საამიროები",
    ky: "Бириккен Араб Эмираттары",
    "zh-Hans": "阿拉伯联合酋长国",
  },
  qatar: {
    ar: "قطر",
    en: "Qatar",
    fr: "Qatar",
    tr: "Katar",
    ru: "Катар",
    ur: "قطر",
    id: "Qatar",
    az: "Qətər",
    ka: "კატარი",
    ky: "Катар",
    "zh-Hans": "卡塔尔",
  },
  kuwait: {
    ar: "الكويت",
    en: "Kuwait",
    fr: "Koweït",
    tr: "Kuveyt",
    ru: "Кувейт",
    ur: "کویت",
    id: "Kuwait",
    az: "Küveyt",
    ka: "ქუვეითი",
    ky: "Кувейт",
    "zh-Hans": "科威特",
  },
  bahrain: {
    ar: "البحرين",
    en: "Bahrain",
    fr: "Bahreïn",
    tr: "Bahreyn",
    ru: "Бахрейн",
    ur: "بحرین",
    id: "Bahrain",
    az: "Bəhreyn",
    ka: "ბაჰრეინი",
    ky: "Бахрейн",
    "zh-Hans": "巴林",
  },
  oman: {
    ar: "عُمان",
    en: "Oman",
    fr: "Oman",
    tr: "Umman",
    ru: "Оман",
    ur: "عمان",
    id: "Oman",
    az: "Oman",
    ka: "ომანი",
    ky: "Оман",
    "zh-Hans": "阿曼",
  },
  riyadh: {
    ar: "الرياض",
    en: "Riyadh",
    fr: "Riyad",
    tr: "Riyad",
    ru: "Эр-Рияд",
    ur: "ریاض",
    id: "Riyadh",
    az: "Ər-Riyad",
    ka: "ერ-რიადი",
    ky: "Эр-Рияд",
    "zh-Hans": "利雅得",
  },
  alula: {
    ar: "العلا",
    en: "AlUla",
    fr: "AlUla",
    tr: "AlUla",
    ru: "Аль-Ула",
    ur: "العلا",
    id: "AlUla",
    az: "Əl-Ula",
    ka: "ალულა",
    ky: "Аль-Ула",
    "zh-Hans": "欧拉",
  },
  jeddah: {
    ar: "جدة",
    en: "Jeddah",
    fr: "Djeddah",
    tr: "Cidde",
    ru: "Джидда",
    ur: "جدہ",
    id: "Jeddah",
    az: "Ciddə",
    ka: "ჯიდა",
    ky: "Жидда",
    "zh-Hans": "吉达",
  },
};

function ref(collection, id) {
  return db.collection(collection).doc(id);
}

async function deleteCollection(collectionPath) {
  const collection = db.collection(collectionPath);
  while (true) {
    const snapshot = await collection.limit(400).get();
    if (snapshot.empty) return;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

async function replaceBaseContent() {
  if (!shouldDelete) {
    console.log("Dry run. Add --confirm-delete to replace Firestore content.");
    console.log(`Collections prepared: ${collectionsToReplace.join(", ")}`);
    return;
  }

  for (const collection of collectionsToReplace) {
    console.log(`Deleting ${collection}...`);
    await deleteCollection(collection);
  }

  const country = ref("countries", "saudi-arabia");
  const riyadh = ref("cities", "riyadh");
  const alula = ref("cities", "alula");
  const jeddah = ref("cities", "jeddah");
  const diriyah = ref("villages", "diriyah");
  const oldTown = ref("villages", "jeddah-old-town");
  const alulaOasis = ref("villages", "alula-oasis");

  const batch = db.batch();
  const now = FieldValue.serverTimestamp();
  const countries = [
    {
      id: "saudi-arabia",
      names: lang.countrySaudi,
      flagEmoji: "🇸🇦",
      image: img.saudi,
      osf: "وجهات سياحية متنوعة بين المدن الحديثة، التراث، الصحراء، والسواحل.",
      currencySymbol: "SAR",
      currencyFRG: 1,
      saudi: true,
      sorting: 1,
    },
    {
      id: "united-arab-emirates",
      names: lang.uae,
      flagEmoji: "🇦🇪",
      image:
        "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1400&q=80",
      osf: "مدن عصرية وتجارب تسوق وترفيه وسياحة صحراوية.",
      currencySymbol: "AED",
      currencyFRG: 0.98,
      sorting: 2,
    },
    {
      id: "qatar",
      names: lang.qatar,
      flagEmoji: "🇶🇦",
      image:
        "https://images.unsplash.com/photo-1558959357-685f9c7ace63?auto=format&fit=crop&w=1400&q=80",
      osf: "واجهة خليجية للثقافة والمتاحف والكورنيش والتجارب الراقية.",
      currencySymbol: "QAR",
      currencyFRG: 0.97,
      sorting: 3,
    },
    {
      id: "kuwait",
      names: lang.kuwait,
      flagEmoji: "🇰🇼",
      image:
        "https://images.unsplash.com/photo-1602171827788-0f4d73f4597a?auto=format&fit=crop&w=1400&q=80",
      osf: "تجارب بحرية وثقافية وأسواق تقليدية في قلب الخليج.",
      currencySymbol: "KWD",
      currencyFRG: 12.2,
      sorting: 4,
    },
    {
      id: "bahrain",
      names: lang.bahrain,
      flagEmoji: "🇧🇭",
      image:
        "https://images.unsplash.com/photo-1578895101408-1a36b834405b?auto=format&fit=crop&w=1400&q=80",
      osf: "جزيرة تجمع التاريخ والأسواق والتجارب البحرية.",
      currencySymbol: "BHD",
      currencyFRG: 9.95,
      sorting: 5,
    },
    {
      id: "oman",
      names: lang.oman,
      flagEmoji: "🇴🇲",
      image:
        "https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?auto=format&fit=crop&w=1400&q=80",
      osf: "طبيعة جبلية وسواحل ووديان وتجارب تراثية هادئة.",
      currencySymbol: "OMR",
      currencyFRG: 9.74,
      sorting: 6,
    },
  ];

  const countryGeo = {
    "saudi-arabia": ["sa", [23.89, 45.08], [16.0, 34.0], [33.5, 55.7]],
    "united-arab-emirates": ["ae", [23.42, 53.85], [22.6, 51.5], [26.1, 56.4]],
    qatar: ["qa", [25.35, 51.18], [24.4, 50.7], [26.2, 51.7]],
    kuwait: ["kw", [29.31, 47.48], [28.4, 46.5], [30.2, 48.5]],
    bahrain: ["bh", [26.07, 50.56], [25.5, 50.3], [26.4, 50.9]],
    oman: ["om", [21.47, 55.98], [16.6, 51.8], [26.4, 59.8]],
  };

  countries.forEach((item) => {
    const [isoCode, center, southWest, northEast] = countryGeo[item.id];
    batch.set(ref("countries", item.id), {
      naim: item.names.ar,
      naimEnglesh: item.names.en,
      names_i18n: item.names,
      flagEmoji: item.flagEmoji,
      flagUrl:
        `https://flagcdn.com/w320/${item.id === "saudi-arabia" ? "sa" :
          item.id === "united-arab-emirates" ? "ae" :
          item.id === "qatar" ? "qa" :
          item.id === "kuwait" ? "kw" :
          item.id === "bahrain" ? "bh" : "om"}.png`,
      osf: item.osf,
      img: item.image,
      hederImg: item.image,
      acctev: true,
      saudi: item.saudi === true,
      isvat: true,
      vat: 15,
      CurrencySymbol: item.currencySymbol,
      CurrencyFRG: item.currencyFRG,
      iso_code: isoCode,
      geo_center: new GeoPoint(center[0], center[1]),
      bounds_sw: new GeoPoint(southWest[0], southWest[1]),
      bounds_ne: new GeoPoint(northEast[0], northEast[1]),
      num_trteb: item.sorting,
      updated_at: now,
    });
  });

  [
    [riyadh, lang.riyadh, img.riyadh, "العاصمة ومركز التجارب الحضرية والتراثية.", 1],
    [alula, lang.alula, img.alula, "وجهة أثرية وطبيعية بتجارب صحراوية مميزة.", 2],
    [jeddah, lang.jeddah, img.jeddah, "مدينة ساحلية تاريخية على البحر الأحمر.", 3],
  ].forEach(([doc, names, image, osf, sorting]) => {
    batch.set(doc, {
      naim: names.ar,
      names_i18n: names,
      osf,
      osf_i18n: {ar: osf, en: osf},
      img: image,
      dolh: country,
      acctev: true,
      sorting,
      updated_at: now,
    });
  });

  [
    [diriyah, riyadh, "الدرعية", "Diriyah", img.riyadh, new GeoPoint(24.7347, 46.5756)],
    [oldTown, jeddah, "جدة التاريخية", "Historic Jeddah", img.jeddah, new GeoPoint(21.4858, 39.1925)],
    [alulaOasis, alula, "واحة العلا", "AlUla Oasis", img.alula, new GeoPoint(26.6085, 37.9232)],
  ].forEach(([doc, city, ar, en, image, point]) => {
    batch.set(doc, {
      cities: city,
      dolh: country,
      naim: ar,
      naim_viil_map: ar,
      naimciteText: en,
      names_i18n: {ar, en},
      osf: "منطقة مختارة للتجارب السياحية والحجوزات.",
      osf_i18n: {
        ar: "منطقة مختارة للتجارب السياحية والحجوزات.",
        en: "A curated area for tours and bookings.",
      },
      img: image,
      lat_ling: point,
      acctev: true,
      no_delete_place: true,
      updated_at: now,
    });
  });

  [
    {
      id: "diriyah-heritage-walk",
      city: riyadh,
      village: diriyah,
      ar: "جولة الدرعية التاريخية",
      en: "Diriyah Heritage Walk",
      image: img.heritage,
      location: new GeoPoint(24.7347, 46.5756),
      address: "Diriyah, Riyadh",
      price: 85,
      rating: 4.8,
      type: "heritage",
      osfAr: "جولة تراثية في الدرعية للتعرف على التاريخ والعمارة المحلية.",
      osfEn: "A heritage walk through Diriyah with local history and architecture.",
    },
    {
      id: "riyadh-museum-route",
      city: riyadh,
      village: diriyah,
      ar: "مسار متاحف الرياض",
      en: "Riyadh Museum Route",
      image: img.museum,
      location: new GeoPoint(24.7136, 46.6753),
      address: "Riyadh",
      price: 60,
      rating: 4.6,
      type: "museum",
      osfAr: "مسار ثقافي مناسب للعائلات ومحبي المتاحف والمعارض.",
      osfEn: "A culture-focused route for families, museums, and exhibitions.",
    },
    {
      id: "alula-oasis-experience",
      city: alula,
      village: alulaOasis,
      ar: "تجربة واحة العلا",
      en: "AlUla Oasis Experience",
      image: img.alula,
      location: new GeoPoint(26.6085, 37.9232),
      address: "AlUla Oasis",
      price: 120,
      rating: 4.9,
      type: "nature",
      osfAr: "تجربة بين الواحات والتكوينات الطبيعية في العلا.",
      osfEn: "An oasis and nature experience among AlUla landscapes.",
    },
    {
      id: "alula-desert-sunset",
      city: alula,
      village: alulaOasis,
      ar: "غروب صحراء العلا",
      en: "AlUla Desert Sunset",
      image: img.desert,
      location: new GeoPoint(26.585, 37.967),
      address: "AlUla Desert",
      price: 150,
      rating: 4.9,
      type: "desert",
      osfAr: "رحلة قصيرة لمشاهدة الغروب والتصوير في صحراء العلا.",
      osfEn: "A short sunset and photo route in the AlUla desert.",
    },
    {
      id: "historic-jeddah-walk",
      city: jeddah,
      village: oldTown,
      ar: "جولة جدة التاريخية",
      en: "Historic Jeddah Walk",
      image: img.jeddah,
      location: new GeoPoint(21.4858, 39.1925),
      address: "Historic Jeddah",
      price: 75,
      rating: 4.7,
      type: "heritage",
      osfAr: "جولة في أزقة جدة التاريخية والبيوت القديمة والأسواق.",
      osfEn: "A walk through Historic Jeddah, old houses, and local markets.",
    },
    {
      id: "jeddah-corniche-stop",
      city: jeddah,
      village: oldTown,
      ar: "واجهة جدة البحرية",
      en: "Jeddah Corniche Stop",
      image: img.coast,
      location: new GeoPoint(21.5433, 39.1728),
      address: "Jeddah Corniche",
      price: 45,
      rating: 4.5,
      type: "coast",
      osfAr: "توقف ساحلي مناسب للمشي والتصوير والاستراحة.",
      osfEn: "A coastal stop for walking, photos, and a relaxed break.",
    },
  ].forEach((place) => {
    batch.set(ref("mkan", place.id), {
      naim: place.ar,
      names_i18n: {ar: place.ar, en: place.en},
      osf: place.osfAr,
      osf_i18n: {ar: place.osfAr, en: place.osfEn},
      img1: place.image,
      img2: place.image,
      img3: place.image,
      img: place.image,
      sr: place.price,
      acctev: true,
      id_cit: place.city,
      id_vill: place.village,
      Location: place.location,
      address: place.address,
      mdh: place.address,
      as_ads: false,
      tsnef: place.type,
      rate: place.rating,
      add_saat: 1,
      ismsgd: false,
      isfood: false,
      ishmam: false,
      ismzod: false,
      isShrek: false,
      IsSuggested: false,
      content_locale: "ar",
      dataAdd: now,
      updated_at: now,
    });
  });

  [
    ["sedan", "سيارة سيدان", "Sedan", img.sedan, 220, false, 4],
    ["suv", "سيارة عائلية SUV", "Family SUV", img.suv, 320, false, 4],
    ["van", "فان سياحي", "Tour Van", img.van, 480, true, 6],
  ].forEach(([id, ar, en, image, price, isBus, hours]) => {
    batch.set(ref("type_car", id), {
      naim: ar,
      names_i18n: {ar, en},
      sr: price,
      actev: true,
      img: image,
      ishafelh: isBus,
      not: en,
      agl_saat: hours,
      NesbahkKsm: 0,
      TotalKsmUb: 0,
      codeCar: id.toUpperCase(),
      updated_at: now,
    });
  });

  await batch.commit();
  console.log("Toury base content replaced successfully.");
}

replaceBaseContent().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
