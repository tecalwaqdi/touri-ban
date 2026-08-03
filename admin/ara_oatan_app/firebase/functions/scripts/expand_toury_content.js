const admin = require("firebase-admin");

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "tutorial-multi-language-70gx4j";

admin.initializeApp({projectId});

const db = admin.firestore();
const {FieldValue, GeoPoint} = admin.firestore;

const saudiRef = db.collection("countries").doc("saudi-arabia");

const images = [
  "https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?auto=format&fit=crop&w=1400&q=80",
  "https://images.unsplash.com/photo-1602171827788-0f4d73f4597a?auto=format&fit=crop&w=1400&q=80",
  "https://images.unsplash.com/photo-1509316785289-025f5b846b35?auto=format&fit=crop&w=1400&q=80",
  "https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=1400&q=80",
  "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1400&q=80",
  "https://images.unsplash.com/photo-1566127992631-137a642a90f4?auto=format&fit=crop&w=1400&q=80",
];

const countries = [
  ["uzbekistan", "🇺🇿", "أوزبكستان", "Uzbekistan", "UZS", "uz"],
  ["kyrgyzstan", "🇰🇬", "قيرغيزستان", "Kyrgyzstan", "KGS", "kg"],
  ["egypt", "🇪🇬", "مصر", "Egypt", "EGP", "eg"],
  ["jordan", "🇯🇴", "الأردن", "Jordan", "JOD", "jo"],
  ["morocco", "🇲🇦", "المغرب", "Morocco", "MAD", "ma"],
  ["turkey", "🇹🇷", "تركيا", "Turkey", "TRY", "tr"],
  ["indonesia", "🇮🇩", "إندونيسيا", "Indonesia", "IDR", "id"],
  ["malaysia", "🇲🇾", "ماليزيا", "Malaysia", "MYR", "my"],
  ["azerbaijan", "🇦🇿", "أذربيجان", "Azerbaijan", "AZN", "az"],
  ["georgia", "🇬🇪", "جورجيا", "Georgia", "GEL", "ge"],
  ["iraq", "🇮🇶", "العراق", "Iraq", "IQD", "iq"],
  ["pakistan", "🇵🇰", "باكستان", "Pakistan", "PKR", "pk"],
  ["india", "🇮🇳", "الهند", "India", "INR", "in"],
];

const countryGeo = {
  uz: [[41.38, 64.59], [37.0, 55.9], [45.6, 73.2]],
  kg: [[41.20, 74.77], [39.1, 69.2], [43.3, 80.3]],
  eg: [[26.82, 30.80], [22.0, 25.0], [31.7, 36.9]],
  jo: [[30.59, 36.24], [29.0, 34.9], [33.4, 39.3]],
  ma: [[31.79, -7.09], [27.6, -13.2], [35.9, -1.0]],
  tr: [[38.96, 35.24], [35.8, 25.6], [42.1, 44.8]],
  id: [[-2.55, 118.01], [-11.1, 95.0], [6.2, 141.1]],
  my: [[4.21, 101.98], [0.8, 99.6], [7.4, 119.3]],
  az: [[40.14, 47.58], [38.3, 44.7], [41.9, 50.6]],
  ge: [[42.32, 43.36], [41.0, 40.0], [43.6, 46.8]],
  iq: [[33.22, 43.68], [29.0, 38.8], [37.4, 48.6]],
  pk: [[30.38, 69.35], [23.6, 60.8], [37.1, 77.9]],
  in: [[20.59, 78.96], [6.5, 68.1], [35.7, 97.4]],
};

const regions = [
  {
    id: "sa-riyadh",
    ar: "منطقة الرياض",
    en: "Riyadh Region",
    center: [24.7136, 46.6753],
    landmarks: [
      "الدرعية التاريخية", "حي الطريف", "قصر المصمك", "المتحف الوطني", "مركز الملك عبدالعزيز التاريخي",
      "برج المملكة", "برج الفيصلية", "بوليفارد رياض سيتي", "وادي حنيفة", "منتزه الملك عبدالله",
      "واجهة الرياض", "الرياض بارك", "سوق الزل", "قصر الحكم", "مركز الملك عبدالله المالي",
      "منتزه سلام", "موسم الرياض", "متحف صقر الجزيرة", "كهف هيت", "مطل البجيري",
    ],
  },
  {
    id: "sa-makkah",
    ar: "منطقة مكة المكرمة",
    en: "Makkah Region",
    center: [21.3891, 39.8579],
    landmarks: [
      "المسجد الحرام", "أبراج الساعة", "جبل النور", "غار حراء", "جبل ثور",
      "عرفات", "مزدلفة", "منى", "جدة التاريخية", "واجهة جدة البحرية",
      "نافورة الملك فهد", "الكورنيش الشمالي", "البلد", "باب مكة", "بيت نصيف",
      "الطائف الهدا", "الشفا", "سوق عكاظ", "حديقة الردف", "تلفريك الهدا",
    ],
  },
  {
    id: "sa-madinah",
    ar: "منطقة المدينة المنورة",
    en: "Madinah Region",
    center: [24.5247, 39.5692],
    landmarks: [
      "المسجد النبوي", "مسجد قباء", "جبل أحد", "مقبرة البقيع", "مسجد القبلتين",
      "متحف دار المدينة", "محطة سكة حديد الحجاز", "مجمع الملك فهد لطباعة المصحف", "وادي العقيق", "ينبع البحر",
      "الواجهة البحرية بينبع", "ينبع التاريخية", "العلا القديمة", "الحجر مدائن صالح", "جبل الفيل",
      "واحة العلا", "دادان", "جبل عكمة", "حرة خيبر", "بدر التاريخية",
    ],
  },
  {
    id: "sa-eastern",
    ar: "المنطقة الشرقية",
    en: "Eastern Province",
    center: [26.4207, 50.0888],
    landmarks: [
      "كورنيش الدمام", "الواجهة البحرية بالخبر", "جسر الملك فهد", "مركز الملك عبدالعزيز الثقافي إثراء", "شاطئ نصف القمر",
      "جزيرة المرجان", "العقير التاريخي", "واحة الأحساء", "جبل القارة", "سوق القيصرية",
      "بحيرة الأصفر", "ميناء العقير", "الجبيل الفناتير", "كورنيش الجبيل", "دارين تاروت",
      "قلعة تاروت", "رأس تنورة", "شاطئ العزيزية", "متحف الطيبين", "منتزه الملك عبدالله بالأحساء",
    ],
  },
  {
    id: "sa-asir",
    ar: "منطقة عسير",
    en: "Asir Region",
    center: [18.2164, 42.5053],
    landmarks: [
      "السودة", "رجال ألمع", "قرية المفتاحة", "جبل السودة", "منتزه عسير الوطني",
      "الحبلة", "بحيرة سد أبها", "شارع الفن", "قصر شدا", "جبل نهران",
      "تنومة", "النماص", "قرية آل ينفع", "بللسمر", "بللحمر",
      "منتزه دلغان", "عقبة ضلع", "ممشى الضباب", "مطل تهلل", "سوق الثلاثاء",
    ],
  },
  {
    id: "sa-tabuk",
    ar: "منطقة تبوك",
    en: "Tabuk Region",
    center: [28.3838, 36.5662],
    landmarks: [
      "قلعة تبوك", "محطة سكة حديد تبوك", "وادي الديسة", "نيوم", "شرما",
      "حقل", "الدرة", "جبل اللوز", "مغاير شعيب", "عين موسى",
      "قيال", "شاطئ قيال", "البدع", "حرة الرهاة", "تيماء",
      "بئر هداج", "قلعة المعظم", "ضباء", "الوجه", "أملج",
    ],
  },
  {
    id: "sa-hail",
    ar: "منطقة حائل",
    en: "Hail Region",
    center: [27.5114, 41.7208],
    landmarks: [
      "قلعة عيرف", "قصر القشلة", "جبة", "النقوش الصخرية في جبة", "فوهة الحمراء",
      "منتزه السمراء", "منتزه مشار", "سوق برزان", "متحف حائل", "جبل أجا",
      "جبل سلمى", "فيد التاريخية", "قفار", "توارن", "عقدة",
      "الحائط", "الشملي", "الغزالة", "بقعاء", "متنزه المغواة",
    ],
  },
  {
    id: "sa-qassim",
    ar: "منطقة القصيم",
    en: "Al Qassim Region",
    center: [26.2078, 43.4837],
    landmarks: [
      "متحف بريدة", "سوق المسوكف", "برج بريدة", "مهرجان التمور", "منتزه الملك عبدالله",
      "عنيزة التاريخية", "بيت البسام", "سوق المسوكف بعنيزة", "الرس", "عيون الجواء",
      "الخبراء التراثية", "رياض الخبراء", "المذنب التاريخية", "منتزه الحاجب", "روضة السبلة",
      "قصر الإمارة القديم", "قصر عذلة", "قصر جدعية", "البدائع", "البكيرية",
    ],
  },
  {
    id: "sa-jazan",
    ar: "منطقة جازان",
    en: "Jazan Region",
    center: [16.8892, 42.5611],
    landmarks: [
      "جزر فرسان", "القلعة العثمانية", "وادي لجب", "جبال فيفاء", "كورنيش جازان",
      "القرية التراثية", "جزيرة المرجان", "الداير بني مالك", "العيدابي", "الريث",
      "جبل القهر", "ميناء جازان", "سوق جازان الشعبي", "بيش", "صبيا",
      "أبو عريش", "العارضة", "فيفاء", "فرسان الكبير", "محمية جزر فرسان",
    ],
  },
  {
    id: "sa-najran",
    ar: "منطقة نجران",
    en: "Najran Region",
    center: [17.5656, 44.2289],
    landmarks: [
      "الأخدود", "قصر الإمارة التاريخي", "قلعة رعوم", "متحف نجران", "سوق الجنابي",
      "سد وادي نجران", "وادي نجران", "آبار حمى", "بئر حمى", "منتزه الملك فهد",
      "قرية آل منجم", "حبونا", "يدمة", "ثار", "شرورة",
      "بدر الجنوب", "خباش", "قصر العان", "موقع الأخدود الأثري", "جبال نجران",
    ],
  },
  {
    id: "sa-bahah",
    ar: "منطقة الباحة",
    en: "Al Bahah Region",
    center: [20.0129, 41.4677],
    landmarks: [
      "قرية ذي عين", "غابة رغدان", "غابة خيرة", "غابة شهبة", "منتزه الأمير حسام",
      "عقبة الباحة", "بلجرشي", "المخواة", "قلوة", "المندق",
      "الأطاولة", "سوق السبت", "وادي الجنابين", "شلال الخرار", "قلعة بخروش",
      "طريق الفيلة", "منتزه الثروة", "غابة عمضان", "متحف الباحة", "قرية الأطاولة التراثية",
    ],
  },
  {
    id: "sa-jouf",
    ar: "منطقة الجوف",
    en: "Al Jouf Region",
    center: [29.9697, 40.2064],
    landmarks: [
      "قلعة زعبل", "بئر سيسرا", "أعمدة الرجاجيل", "دومة الجندل", "بحيرة دومة الجندل",
      "قلعة مارد", "مسجد عمر بن الخطاب", "متحف الجوف", "سكاكا", "قارا",
      "طبرجل", "ميقوع", "زلوم", "مزارع الزيتون", "مهرجان الزيتون",
      "قصر كاف", "قلعة الصعيدي", "جبل برنس", "وادي السرحان", "محمية الحرة",
    ],
  },
  {
    id: "sa-northern-borders",
    ar: "منطقة الحدود الشمالية",
    en: "Northern Borders Region",
    center: [30.9753, 41.0381],
    landmarks: [
      "عرعر", "رفحاء", "طريف", "العويقيلة", "محمية الملك سلمان",
      "درب زبيدة", "لينة التاريخية", "سوق لينة", "قصر الإمارة القديم", "متحف الحدود الشمالية",
      "وادي عرعر", "روضة هباس", "شعيب عرعر", "طلعة التمياط", "قرية ابن شريم",
      "هجرة المركوز", "جديدة عرعر", "منفذ جديدة عرعر", "حديقة الأمير عبدالله بن عبدالعزيز", "منتزه رفحاء",
    ],
  },
];

function flagUrl(code) {
  return `https://flagcdn.com/w320/${code}.png`;
}

function localizedName(ar, en) {
  return {
    ar,
    en,
    fr: en,
    tr: en,
    ru: en,
    ur: ar,
    id: en,
    az: en,
    ka: en,
    ky: en,
    "zh-Hans": en,
  };
}

function safeId(text) {
  return text
    .toLowerCase()
    .replace(/[^\p{Letter}\p{Number}]+/gu, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
}

async function main() {
  const now = FieldValue.serverTimestamp();
  let batch = db.batch();
  let writes = 0;

  async function set(docRef, data) {
    batch.set(docRef, data, {merge: true});
    writes += 1;
    if (writes >= 450) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }

  let countryOrder = 20;
  for (const [id, flag, ar, en, currency, code] of countries) {
    const [center, southWest, northEast] = countryGeo[code];
    await set(db.collection("countries").doc(id), {
      naim: ar,
      naimEnglesh: en,
      names_i18n: localizedName(ar, en),
      flagEmoji: flag,
      flagUrl: flagUrl(code),
      osf: `وجهة سياحية دولية متاحة للحجز عبر توري: ${ar}.`,
      img: images[countryOrder % images.length],
      hederImg: images[countryOrder % images.length],
      acctev: true,
      saudi: false,
      isvat: false,
      vat: 0,
      CurrencySymbol: currency,
      CurrencyFRG: 1,
      iso_code: code,
      geo_center: new GeoPoint(center[0], center[1]),
      bounds_sw: new GeoPoint(southWest[0], southWest[1]),
      bounds_ne: new GeoPoint(northEast[0], northEast[1]),
      num_trteb: countryOrder,
      updated_at: now,
    });
    countryOrder += 1;
  }

  for (let regionIndex = 0; regionIndex < regions.length; regionIndex += 1) {
    const region = regions[regionIndex];
    const cityRef = db.collection("cities").doc(region.id);
    const villageRef = db.collection("villages").doc(`${region.id}-main`);
    const [lat, lng] = region.center;

    await set(cityRef, {
      naim: region.ar,
      names_i18n: localizedName(region.ar, region.en),
      osf: `وجهات ومعالم مختارة داخل ${region.ar}.`,
      osf_i18n: {
        ar: `وجهات ومعالم مختارة داخل ${region.ar}.`,
        en: `Curated attractions in ${region.en}.`,
      },
      img: images[regionIndex % images.length],
      dolh: saudiRef,
      acctev: true,
      sorting: regionIndex + 10,
      updated_at: now,
    });

    await set(villageRef, {
      cities: cityRef,
      dolh: saudiRef,
      naim: `${region.ar} - مسار رئيسي`,
      naim_viil_map: region.ar,
      naimciteText: region.en,
      names_i18n: localizedName(`${region.ar} - مسار رئيسي`, `${region.en} main route`),
      osf: `مسار منظم لزيارة أبرز معالم ${region.ar}.`,
      osf_i18n: {
        ar: `مسار منظم لزيارة أبرز معالم ${region.ar}.`,
        en: `A route for top attractions in ${region.en}.`,
      },
      img: images[regionIndex % images.length],
      lat_ling: new GeoPoint(lat, lng),
      acctev: true,
      no_delete_place: true,
      updated_at: now,
    });

    for (let i = 0; i < region.landmarks.length; i += 1) {
      const ar = region.landmarks[i];
      const en = `${region.en} attraction ${i + 1}`;
      const offsetLat = ((i % 5) - 2) * 0.035;
      const offsetLng = (Math.floor(i / 5) - 2) * 0.035;
      await set(db.collection("mkan").doc(`${region.id}-${i + 1}-${safeId(ar)}`), {
        naim: ar,
        names_i18n: localizedName(ar, en),
        osf: `معلم سياحي ضمن ${region.ar}، مناسب للإضافة إلى مسار الرحلة.`,
        osf_i18n: {
          ar: `معلم سياحي ضمن ${region.ar}، مناسب للإضافة إلى مسار الرحلة.`,
          en: `A tourism attraction in ${region.en}, suitable for trip routes.`,
        },
        img1: images[(regionIndex + i) % images.length],
        img2: images[(regionIndex + i + 1) % images.length],
        img3: images[(regionIndex + i + 2) % images.length],
        img: images[(regionIndex + i) % images.length],
        sr: 25 + ((i % 6) * 10),
        acctev: true,
        id_cit: cityRef,
        id_vill: villageRef,
        Location: new GeoPoint(lat + offsetLat, lng + offsetLng),
        address: `${ar}, ${region.ar}`,
        mdh: region.ar,
        as_ads: i < 2,
        tsnef: i % 3 === 0 ? "heritage" : i % 3 === 1 ? "nature" : "city",
        rate: 4.3 + ((i % 6) * 0.1),
        add_saat: 1,
        ismsgd: ar.includes("مسجد") || ar.includes("الحرم") || ar.includes("النبوي"),
        isfood: false,
        ishmam: false,
        ismzod: false,
        isShrek: false,
        IsSuggested: false,
        content_locale: "ar",
        dataAdd: now,
        updated_at: now,
      });
    }
  }

  if (writes > 0) await batch.commit();
  console.log(`Expanded countries: ${countries.length}`);
  console.log(`Expanded Saudi regions: ${regions.length}`);
  console.log(`Expanded Saudi landmarks: ${regions.length * 20}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
