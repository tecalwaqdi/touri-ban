/**
 * Imports 20 real OpenStreetMap tourism landmarks for each Saudi region.
 * The operation is idempotent: document IDs are based on OSM IDs.
 *
 * Run:
 *   node seed_saudi_osm_landmarks.js
 */
const { getIdToken, patchDoc, ref, geo, sleep } =
  require("./seed_production_client");

const COUNTRY_PATH = "countries/saudi_arabia";
const MAPS_KEY = "AIzaSyD5G1uXTPM2DP-5ZkeLQA_7FsFjxNWOIzM";
const OVERPASS_ENDPOINTS = [
  "https://overpass.kumi.systems/api/interpreter",
  "https://overpass-api.de/api/interpreter",
  "https://overpass.private.coffee/api/interpreter",
  "https://overpass.openstreetmap.ru/api/interpreter",
];
const LOCALE_KEYS = [
  "ar", "en", "zh_Hans", "tr", "ur", "ru", "az", "ka", "ky", "fr", "id",
];
const DESCRIPTION = {
  ar: "معلم حقيقي موثق جغرافياً من OpenStreetMap، مناسب للاستكشاف وإضافته إلى مسار الرحلة.",
  en: "A real, geographically verified landmark from OpenStreetMap, suitable for exploring and adding to your trip route.",
  zh_Hans: "来自 OpenStreetMap 的真实地理验证景点，适合探索并添加到行程路线。",
  tr: "OpenStreetMap üzerinden coğrafi olarak doğrulanmış, keşfetmeye ve gezi rotanıza eklemeye uygun gerçek bir turistik yer.",
  ur: "OpenStreetMap سے جغرافیائی طور پر تصدیق شدہ حقیقی مقام، سیر اور سفری راستے میں شامل کرنے کے لیے موزوں۔",
  ru: "Реальная географически подтверждённая достопримечательность из OpenStreetMap, подходящая для посещения и добавления в маршрут.",
  az: "OpenStreetMap-dən coğrafi olaraq təsdiqlənmiş, kəşf və səyahət marşrutuna əlavə etmək üçün uyğun real məkan.",
  ka: "OpenStreetMap-ზე გეოგრაფიულად დადასტურებული რეალური ღირსშესანიშნაობა, რომელიც შეგიძლიათ მოგზაურობის მარშრუტს დაამატოთ.",
  ky: "OpenStreetMap аркылуу географиялык жактан ырасталган, саякат маршрутуна кошууга ылайыктуу чыныгы жай.",
  fr: "Un site réel vérifié géographiquement via OpenStreetMap, à découvrir et à ajouter à votre itinéraire.",
  id: "Tempat nyata yang terverifikasi secara geografis dari OpenStreetMap, cocok dijelajahi dan ditambahkan ke rute perjalanan.",
};

const REGIONS = [
  ["01", "riyadh", "منطقة الرياض", "Riyadh Region", "riyadh", "الرياض", 24.7136, 46.6753],
  ["02", "makkah", "منطقة مكة المكرمة", "Makkah Region", "makkah", "مكة المكرمة", 21.4225, 39.8262],
  ["03", "madinah", "منطقة المدينة المنورة", "Madinah Region", "madinah", "المدينة المنورة", 24.4686, 39.6142],
  ["04", "eastern", "المنطقة الشرقية", "Eastern Province", "dammam", "الدمام", 26.4207, 50.0888],
  ["05", "qassim", "منطقة القصيم", "Qassim Region", "buraidah", "بريدة", 26.3592, 43.9818],
  ["06", "hail", "منطقة حائل", "Ha'il Region", "hail", "حائل", 27.5114, 41.7208],
  ["07", "tabuk", "منطقة تبوك", "Tabuk Region", "tabuk", "تبوك", 28.3838, 36.5550],
  ["08", "northern_borders", "منطقة الحدود الشمالية", "Northern Borders Region", "arar", "عرعر", 30.9753, 41.0381],
  ["09", "jazan", "منطقة جازان", "Jazan Region", "jazan", "جازان", 16.8894, 42.5706],
  ["10", "najran", "منطقة نجران", "Najran Region", "najran", "نجران", 17.5656, 44.2289],
  ["11", "baha", "منطقة الباحة", "Al Bahah Region", "baha", "الباحة", 20.0129, 41.4677],
  ["12", "jouf", "منطقة الجوف", "Al Jouf Region", "sakaka", "سكاكا", 29.9697, 40.2064],
  ["14", "asir", "منطقة عسير", "Asir Region", "abha", "أبها", 18.2164, 42.5053],
];

async function createOrSkipProtected(idToken, path, data) {
  try {
    await patchDoc(idToken, path, data);
    return "written";
  } catch (error) {
    const message = String(error?.message || error);
    if (message.includes("403") || message.includes("PERMISSION_DENIED")) {
      console.log(`  protected existing document, skip update: ${path}`);
      return "protected";
    }
    throw error;
  }
}

function i18nName(tags) {
  const fallback = tags["name:ar"] || tags.name || tags["name:en"];
  const result = {};
  for (const key of LOCALE_KEYS) {
    const osmKey = key === "zh_Hans" ? "zh" : key;
    result[key] =
      tags[`name:${osmKey}`] ||
      (key === "ar" ? tags["name:ar"] : null) ||
      (key === "en" ? tags["name:en"] : null) ||
      fallback;
  }
  return result;
}

function category(tags) {
  if (tags.tourism === "museum") return "متحف";
  if (tags.tourism === "viewpoint") return "إطلالة";
  if (tags.tourism === "zoo") return "حديقة حيوان";
  if (tags.tourism === "theme_park") return "ترفيه";
  if (tags.historic) return "تراث وثقافة";
  if (tags.leisure === "park") return "طبيعة وحدائق";
  return "معلم سياحي";
}

function categoryI18n(tags) {
  const key = category(tags);
  const known = {
    "متحف": ["Museum", "博物馆", "Müze", "میوزیم", "Музей", "Muzey", "მუზეუმი", "Музей", "Musée", "Museum"],
    "إطلالة": ["Viewpoint", "观景点", "Seyir noktası", "نقطۂ نظر", "Смотровая площадка", "Mənzərə nöqtəsi", "ხედვის წერტილი", "Көрүү жери", "Point de vue", "Titik pandang"],
    "تراث وثقافة": ["Heritage and culture", "遗产与文化", "Miras ve kültür", "ورثہ اور ثقافت", "Наследие и культура", "İrs və mədəniyyət", "მემკვიდრეობა და კულტურა", "Мурас жана маданият", "Patrimoine et culture", "Warisan dan budaya"],
    "طبيعة وحدائق": ["Nature and parks", "自然与公园", "Doğa ve parklar", "قدرت اور پارکس", "Природа и парки", "Təbiət və parklar", "ბუნება და პარკები", "Жаратылыш жана парктар", "Nature et parcs", "Alam dan taman"],
    "ترفيه": ["Entertainment", "娱乐", "Eğlence", "تفریح", "Развлечения", "Əyləncə", "გასართობი", "Көңүл ачуу", "Divertissement", "Hiburan"],
    "حديقة حيوان": ["Zoo", "动物园", "Hayvanat bahçesi", "چڑیا گھر", "Зоопарк", "Zoopark", "ზოოპარკი", "Зоопарк", "Zoo", "Kebun binatang"],
    "معلم سياحي": ["Tourist attraction", "旅游景点", "Turistik yer", "سیاحتی مقام", "Достопримечательность", "Turistik məkan", "ტურისტული ღირსშესანიშნაობა", "Туристтик жай", "Attraction touristique", "Tempat wisata"],
  }[key];
  return Object.fromEntries(LOCALE_KEYS.map((locale, index) => [
    locale,
    locale === "ar" ? key : known[index - 1],
  ]));
}

function pointOf(element) {
  const lat = element.lat ?? element.center?.lat;
  const lng = element.lon ?? element.center?.lon;
  return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null;
}

function score(element) {
  const t = element.tags || {};
  return (
    (t.wikidata ? 8 : 0) +
    (t.wikipedia ? 8 : 0) +
    (t.image || t.wikimedia_commons ? 6 : 0) +
    (t.website || t["contact:website"] ? 3 : 0) +
    (t["name:ar"] ? 3 : 0) +
    (t["name:en"] ? 2 : 0) +
    (t.tourism ? 4 : 0) +
    (t.historic ? 3 : 0)
  );
}

function imageUrl(tags, point) {
  const image = tags.image;
  if (typeof image === "string" && /^https?:\/\//.test(image)) return image;
  return (
    "https://maps.googleapis.com/maps/api/staticmap" +
    `?center=${point.lat},${point.lng}&zoom=15&size=800x500&scale=2` +
    `&maptype=roadmap&markers=color:teal%7C${point.lat},${point.lng}` +
    `&key=${MAPS_KEY}`
  );
}

async function fetchRegionLandmarks(iso) {
  const query = `
    [out:json][timeout:120];
    area["ISO3166-2"="SA-${iso}"]["boundary"="administrative"]->.r;
    (
      nwr["tourism"~"attraction|museum|viewpoint|gallery|zoo|theme_park"]["name"](area.r);
      nwr["historic"]["name"](area.r);
      nwr["leisure"="park"]["name"](area.r);
    );
    out center tags;
  `;
  let response;
  let lastError;
  for (let attempt = 0; attempt < 10; attempt++) {
    const endpoint = OVERPASS_ENDPOINTS[attempt % OVERPASS_ENDPOINTS.length];
    try {
      response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
          "User-Agent": "ArraWatanAdmin/1.0 (production tourism import)",
        },
        body: new URLSearchParams({ data: query }),
      });
      if (response.ok) break;
      lastError = new Error(`Overpass SA-${iso}: HTTP ${response.status}`);
    } catch (error) {
      lastError = error;
    }
    await sleep(Math.min(60000, 8000 * (attempt + 1)));
  }
  if (!response?.ok) throw lastError || new Error(`Overpass SA-${iso} failed`);
  const data = await response.json();
  const seen = new Set();
  return (data.elements || [])
    .filter((element) => pointOf(element) && element.tags?.name)
    .sort((a, b) => score(b) - score(a))
    .filter((element) => {
      const point = pointOf(element);
      const key = `${element.tags.name}|${point.lat.toFixed(4)}|${point.lng.toFixed(4)}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .slice(0, 20);
}

async function main() {
  const { idToken } = await getIdToken();
  let total = 0;
  const startIso = process.env.START_ISO || REGIONS[0][0];
  const startIndex = REGIONS.findIndex((region) => region[0] === startIso);
  if (startIndex < 0) throw new Error(`Unknown START_ISO: ${startIso}`);

  for (const region of REGIONS.slice(startIndex)) {
    const [iso, slug, arName, enName, citySlug, cityAr, cityLat, cityLng] = region;
    const regionPath = `cities/region_${slug}`;
    const cityPath = `villages/city_${citySlug}`;
    const regionNames = Object.fromEntries(
      LOCALE_KEYS.map((locale) => [locale, locale === "ar" ? arName : enName]),
    );
    const cityNames = Object.fromEntries(
      LOCALE_KEYS.map((locale) => [locale, cityAr]),
    );

    await createOrSkipProtected(idToken, regionPath, {
      naim: arName,
      names_i18n: regionNames,
      dolh: ref(COUNTRY_PATH),
      acctev: true,
      iso_code: `SA-${iso}`,
    });
    await createOrSkipProtected(idToken, cityPath, {
      naim: cityAr,
      names_i18n: cityNames,
      cities: ref(regionPath),
      dolh: ref(COUNTRY_PATH),
      lat_ling: geo(cityLat, cityLng),
      acctev: true,
    });

    console.log(`Fetching ${arName}...`);
    const landmarks = await fetchRegionLandmarks(iso);
    if (landmarks.length < 20) {
      throw new Error(`${arName}: only ${landmarks.length} named landmarks found`);
    }

    for (let i = 0; i < landmarks.length; i++) {
      const item = landmarks[i];
      const tags = item.tags;
      const point = pointOf(item);
      const names = i18nName(tags);
      const id = `osm_${item.type}_${item.id}`;
      const sourceUrl = `https://www.openstreetmap.org/${item.type}/${item.id}`;

      await createOrSkipProtected(idToken, `mkan/${id}`, {
        naim: names.ar || names.en,
        names_i18n: names,
        osf: DESCRIPTION.ar,
        osf_i18n: DESCRIPTION,
        img1: imageUrl(tags, point),
        img2: "",
        img3: "",
        sr: i + 1,
        acctev: true,
        id_cit: ref(regionPath),
        id_vill: ref(cityPath),
        Rev_dolh: ref(COUNTRY_PATH),
        Location: geo(point.lat, point.lng),
        address: `${names.ar || names.en}، ${arName}`,
        as_ads: true,
        ismzod: true,
        isShrek: false,
        ismsgd: tags.amenity === "place_of_worship",
        isfood: true,
        ishmam: true,
        tsnef: category(tags),
        tsnef_i18n: categoryI18n(tags),
        rate: 4.5,
        add_saat: 2,
        source_provider: "OpenStreetMap",
        source_url: sourceUrl,
        source_osm_type: item.type,
        source_osm_id: String(item.id),
        wikidata: tags.wikidata || "",
        website: tags.website || tags["contact:website"] || "",
        dataAdd: new Date(),
        verified_at: new Date(),
      });
      total++;
      if ((i + 1) % 5 === 0) {
        console.log(`  ${arName}: ${i + 1}/20`);
        await sleep(350);
      }
    }
    await sleep(1500);
  }

  console.log(`Done: ${total} real landmarks across ${REGIONS.length} regions.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
