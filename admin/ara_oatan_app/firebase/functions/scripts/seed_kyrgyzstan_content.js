const admin = require("firebase-admin");
const axios = require("axios");

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "tutorial-multi-language-70gx4j";

admin.initializeApp({projectId});
const db = admin.firestore();
const {FieldValue, GeoPoint} = admin.firestore;
const countryRef = db.collection("countries").doc("kyrgyzstan");

const regions = [
  {
    id: "kg-chuy",
    names: names("إقليم تشوي", "Chuy Region", "Чуйская область", "Чүй облусу", {
      az: "Çuy vilayəti", ka: "ჩუის რეგიონი", tr: "Çüy Bölgesi",
      ur: "چوئی علاقہ", fr: "Région de Tchouï", id: "Wilayah Chuy", "zh-Hans": "楚河州",
    }),
    center: [42.85, 74.60], bounds: [[42.00, 73.20], [43.25, 76.30]],
    imageQuery: "Chuy Kyrgyzstan Burana Ala Archa",
    landmarks: [
      place("ala-archa", "منتزه ألا أرتشا الوطني", "Ala Archa National Park", "Национальный парк Ала-Арча", "Ала-Арча улуттук паркы", 42.6369, 74.4880, "nature"),
      place("burana", "برج بورانا", "Burana Tower", "Башня Бурана", "Бурана мунарасы", 42.7468, 75.2502, "heritage"),
      place("ala-too", "ساحة ألا توو", "Ala-Too Square", "Площадь Ала-Тоо", "Ала-Тоо аянты", 42.8746, 74.6122, "city"),
      place("history-museum", "متحف التاريخ الوطني", "National History Museum", "Национальный исторический музей", "Улуттук тарых музейи", 42.8763, 74.6037, "museum"),
      place("osh-bazaar", "سوق أوش", "Osh Bazaar", "Ошский базар", "Ош базары", 42.8740, 74.5696, "market"),
      place("chunkurchak", "وادي تشونكورشاك", "Chunkurchak Gorge", "Ущелье Чункурчак", "Чуңкурчак капчыгайы", 42.6360, 74.8440, "nature"),
      place("issyk-ata", "وادي إيسيك أتا", "Issyk-Ata Gorge", "Ущелье Иссык-Ата", "Ысык-Ата капчыгайы", 42.6010, 75.1870, "nature"),
      place("konorchek", "أخاديد كونورتشيك", "Konorchek Canyons", "Каньоны Коно́рчек", "Коңорчок каньондору", 42.5410, 75.9540, "nature"),
      place("kegety", "وادي كيغيتي", "Kegety Gorge", "Ущелье Кегеты", "Кегети капчыгайы", 42.5960, 75.1250, "nature"),
      place("panfilov", "منتزه بانفيلوف", "Panfilov Park", "Парк Панфилова", "Панфилов паркы", 42.8798, 74.6032, "city"),
    ],
  },
  {
    id: "kg-issyk-kul",
    names: names("إقليم إيسيك كول", "Issyk-Kul Region", "Иссык-Кульская область", "Ысык-Көл облусу", {
      az: "İssık-Kul vilayəti", ka: "ისიქ-ქულის რეგიონი", tr: "Issık Göl Bölgesi",
      ur: "اسیک کول علاقہ", fr: "Région d'Issyk-Koul", id: "Wilayah Issyk-Kul", "zh-Hans": "伊塞克湖州",
    }),
    center: [42.45, 77.28], bounds: [[41.55, 75.95], [43.35, 80.30]],
    imageQuery: "Issyk Kul Kyrgyzstan Jeti Oguz",
    landmarks: [
      place("issyk-kul-lake", "بحيرة إيسيك كول", "Issyk-Kul Lake", "Озеро Иссык-Куль", "Ысык-Көл", 42.4530, 77.2760, "nature"),
      place("cholpon-petroglyphs", "نقوش تشولبون آتا الصخرية", "Cholpon-Ata Petroglyphs", "Петроглифы Чолпон-Аты", "Чолпон-Ата петроглифтери", 42.6604, 77.0570, "heritage"),
      place("rukh-ordo", "مجمع روح أوردو", "Rukh Ordo Cultural Center", "Культурный центр Рух Ордо", "Рух Ордо маданий борбору", 42.6480, 77.0780, "culture"),
      place("jeti-oguz", "صخور جيتي أوغوز", "Jeti-Oguz Rocks", "Скалы Джеты-Огуз", "Жети-Өгүз аскалары", 42.3340, 78.2450, "nature"),
      place("skazka", "وادي سكازكا", "Skazka Canyon", "Каньон Сказка", "Сказка капчыгайы", 42.1550, 77.3540, "nature"),
      place("barskoon", "شلالات بارسكون", "Barskoon Waterfalls", "Водопады Барскоон", "Барскоон шаркыратмалары", 42.0050, 77.5940, "nature"),
      place("holy-trinity", "كاتدرائية الثالوث في كاراكول", "Holy Trinity Cathedral", "Свято-Троицкий собор", "Ыйык Үч Бирдик собору", 42.4910, 78.3930, "heritage"),
      place("dungan-mosque", "مسجد دونغان", "Dungan Mosque", "Дунганская мечеть", "Дунган мечити", 42.4914, 78.3811, "heritage"),
      place("grigorievka", "وادي غريغوريفكا", "Grigorievka Gorge", "Григорьевское ущелье", "Григорьевка капчыгайы", 42.7700, 77.4470, "nature"),
      place("altyn-arashan", "وادي ألتين أراشان", "Altyn Arashan Valley", "Долина Алтын-Арашан", "Алтын-Арашан өрөөнү", 42.3500, 78.6590, "nature"),
    ],
  },
  {
    id: "kg-naryn",
    names: names("إقليم نارين", "Naryn Region", "Нарынская область", "Нарын облусу", {
      az: "Narın vilayəti", ka: "ნარინის რეგიონი", tr: "Narın Bölgesi",
      ur: "نارین علاقہ", fr: "Région de Naryn", id: "Wilayah Naryn", "zh-Hans": "纳伦州",
    }),
    center: [41.43, 76.00], bounds: [[40.10, 73.75], [42.40, 80.30]],
    imageQuery: "Naryn Kyrgyzstan Tash Rabat Song Kol",
    landmarks: [
      place("song-kol", "بحيرة سونغ كول", "Song-Kol Lake", "Озеро Сон-Куль", "Соң-Көл", 41.8400, 75.1500, "nature"),
      place("tash-rabat", "خان تاش رباط", "Tash Rabat Caravanserai", "Караван-сарай Таш-Рабат", "Таш-Рабат кербен сарайы", 40.8230, 75.2880, "heritage"),
      place("kel-suu", "بحيرة كيل سو", "Kel-Suu Lake", "Озеро Кель-Суу", "Көл-Суу", 40.6400, 76.3970, "nature"),
      place("koshoi-korgon", "حصن كوشوي كورغون", "Koshoi Korgon Fortress", "Крепость Кошой-Коргон", "Кошой-Коргон чеби", 41.1270, 75.6820, "heritage"),
      place("salkyn-tor", "منتزه سالكين تور الوطني", "Salkyn-Tor National Park", "Национальный парк Салкын-Тор", "Салкын-Төр улуттук паркы", 41.3900, 76.0500, "nature"),
      place("eki-naryn", "وادي إيكي نارين", "Eki-Naryn Valley", "Долина Эки-Нарын", "Эки-Нарын өрөөнү", 41.4500, 76.4100, "nature"),
      place("at-bashy", "وادي أت باشي", "At-Bashy Valley", "Ат-Башинская долина", "Ат-Башы өрөөнү", 41.1700, 75.8100, "nature"),
      place("ak-sai", "وادي آك ساي", "Ak-Sai Valley", "Долина Ак-Сай", "Ак-Сай өрөөнү", 40.9000, 76.4000, "nature"),
      place("moldo-ashuu", "ممر مولدو أشوو", "Moldo-Ashuu Pass", "Перевал Молдо-Ашуу", "Молдо-Ашуу ашуусу", 41.6600, 74.7900, "nature"),
      place("naryn-panorama", "مطل مدينة نارين", "Naryn Panorama", "Панорама Нарына", "Нарын панорамасы", 41.4280, 76.0000, "city"),
    ],
  },
  {
    id: "kg-talas",
    names: names("إقليم تالاس", "Talas Region", "Таласская область", "Талас облусу", {
      az: "Talas vilayəti", ka: "ტალასის რეგიონი", tr: "Talas Bölgesi",
      ur: "تالاس علاقہ", fr: "Région de Talas", id: "Wilayah Talas", "zh-Hans": "塔拉斯州",
    }),
    center: [42.52, 72.24], bounds: [[41.95, 70.20], [43.10, 74.10]],
    imageQuery: "Talas Kyrgyzstan Manas Ordo",
    landmarks: [
      place("manas-ordo", "مجمع ماناس أوردو", "Manas Ordo National Complex", "Национальный комплекс Манас Ордо", "Манас Ордо улуттук комплекси", 42.5130, 72.2360, "heritage"),
      place("besh-tash", "منتزه بيش تاش الوطني", "Besh-Tash National Park", "Национальный парк Беш-Таш", "Беш-Таш улуттук паркы", 42.2800, 72.3300, "nature"),
      place("kirov-reservoir", "خزان كيروف", "Kirov Reservoir", "Кировское водохранилище", "Киров суу сактагычы", 42.6500, 71.5700, "nature"),
      place("gumbez-manas", "ضريح ماناس", "Gumbez of Manas", "Гумбез Манаса", "Манастын күмбөзү", 42.5134, 72.2370, "heritage"),
      place("talas-museum", "متحف تالاس الإقليمي", "Talas Regional Museum", "Таласский областной музей", "Талас облустук музейи", 42.5220, 72.2420, "museum"),
      place("kara-buura", "وادي كارا بورا", "Kara-Buura Gorge", "Ущелье Кара-Буура", "Кара-Буура капчыгайы", 42.5000, 71.4000, "nature"),
      place("bakai-ata", "وادي باكاي آتا", "Bakai-Ata Valley", "Долина Бакай-Ата", "Бакай-Ата өрөөнү", 42.4900, 71.9200, "nature"),
      place("kenkol", "وادي كينكول التاريخي", "Kenkol Historical Valley", "Историческая долина Кенкол", "Кең-Кол тарыхый өрөөнү", 42.5700, 72.1900, "heritage"),
      place("talas-park", "منتزه تالاس المركزي", "Talas Central Park", "Центральный парк Таласа", "Талас борбордук паркы", 42.5200, 72.2350, "city"),
      place("ak-dobo", "موقع آك دوبو الأثري", "Ak-Dobo Archaeological Site", "Городище Ак-Добо", "Ак-Дөбө археологиялык жайы", 42.4000, 72.3000, "heritage"),
    ],
  },
  {
    id: "kg-jalal-abad",
    names: names("إقليم جلال آباد", "Jalal-Abad Region", "Джалал-Абадская область", "Жалал-Абад облусу", {
      az: "Cəlal-Abad vilayəti", ka: "ჯალალ-აბადის რეგიონი", tr: "Celal-Abad Bölgesi",
      ur: "جلال آباد علاقہ", fr: "Région de Jalal-Abad", id: "Wilayah Jalal-Abad", "zh-Hans": "贾拉拉巴德州",
    }),
    center: [40.93, 73.00], bounds: [[40.20, 69.20], [42.35, 75.30]],
    imageQuery: "Jalal-Abad Kyrgyzstan Sary Chelek Arslanbob",
    landmarks: [
      place("sary-chelek", "بحيرة ساري تشيليك", "Sary-Chelek Lake", "Озеро Сары-Челек", "Сары-Челек көлү", 41.8800, 71.9500, "nature"),
      place("arslanbob", "غابة أرسلانبوب للجوز", "Arslanbob Walnut Forest", "Ореховый лес Арсланбоб", "Арстанбап жаңгак токою", 41.3400, 72.9300, "nature"),
      place("arslanbob-waterfall", "شلال أرسلانبوب", "Arslanbob Waterfall", "Водопад Арсланбоб", "Арстанбап шаркыратмасы", 41.3330, 72.9490, "nature"),
      place("shah-fazil", "ضريح شاه فاضل", "Shah Fazil Mausoleum", "Мавзолей Шах-Фазиль", "Шах-Фазил күмбөзү", 41.4660, 71.6180, "heritage"),
      place("padysha-ata", "محمية باديشا آتا", "Padysha-Ata Reserve", "Заповедник Падыша-Ата", "Падыша-Ата коругу", 41.6100, 71.7500, "nature"),
      place("toktogul", "خزان توكتوغول", "Toktogul Reservoir", "Токтогульское водохранилище", "Токтогул суу сактагычы", 41.7900, 72.9500, "nature"),
      place("saimaluu-tash", "نقوش سايمالو تاش", "Saimaluu-Tash Petroglyphs", "Петроглифы Саймалы-Таш", "Саймалуу-Таш петроглифтери", 41.1800, 73.8600, "heritage"),
      place("jalal-abad-spa", "ينابيع جلال آباد المعدنية", "Jalal-Abad Mineral Springs", "Минеральные источники Джалал-Абада", "Жалал-Абад минералдык булактары", 40.9300, 73.0000, "wellness"),
      place("kara-alma", "وادي كارا ألما", "Kara-Alma Valley", "Долина Кара-Алма", "Кара-Алма өрөөнү", 41.1800, 73.3300, "nature"),
      place("chychkan", "وادي تشيتشكان", "Chychkan Gorge", "Ущелье Чычкан", "Чычкан капчыгайы", 42.0900, 72.7500, "nature"),
    ],
  },
  {
    id: "kg-osh",
    names: names("إقليم أوش", "Osh Region", "Ошская область", "Ош облусу", {
      az: "Oş vilayəti", ka: "ოშის რეგიონი", tr: "Oş Bölgesi",
      ur: "اوش علاقہ", fr: "Région d'Och", id: "Wilayah Osh", "zh-Hans": "奥什州",
    }),
    center: [40.53, 72.78], bounds: [[39.20, 71.10], [41.35, 75.60]],
    imageQuery: "Osh Kyrgyzstan Sulaiman Too Alay",
    landmarks: [
      place("sulaiman-too", "جبل سليمان توو المقدس", "Sulaiman-Too Sacred Mountain", "Священная гора Сулайман-Тоо", "Сулайман-Тоо ыйык тоосу", 40.5290, 72.7830, "heritage"),
      place("jayma-bazaar", "سوق جايما في أوش", "Jayma Bazaar", "Базар Жайма", "Жайма базары", 40.5310, 72.7890, "market"),
      place("uzgen", "مئذنة أوزغن", "Uzgen Minaret", "Узгенский минарет", "Өзгөн мунарасы", 40.7690, 73.3010, "heritage"),
      place("alay", "وادي ألاي", "Alay Valley", "Алайская долина", "Алай өрөөнү", 39.6500, 72.8800, "nature"),
      place("achik-tash", "مخيم أشيك تاش عند قمة لينين", "Achik-Tash Base Camp", "Базовый лагерь Ачик-Таш", "Ачык-Таш базалык лагери", 39.4800, 72.9000, "nature"),
      place("abshir-ata", "شلال أبشير آتا", "Abshir-Ata Waterfall", "Водопад Абшир-Ата", "Абшыр-Ата шаркыратмасы", 40.0800, 72.1200, "nature"),
      place("kyrgyz-ata", "منتزه قيرغيز آتا الوطني", "Kyrgyz-Ata National Park", "Национальный парк Кыргыз-Ата", "Кыргыз-Ата улуттук паркы", 40.1800, 72.6200, "nature"),
      place("tulpar-kol", "بحيرة تولبار كول", "Tulpar-Kol Lake", "Озеро Тулпар-Куль", "Тулпар-Көл", 39.4900, 72.9300, "nature"),
      place("kozho-kelen", "وادي كوجو كيلين", "Kozho-Kelen Valley", "Долина Кожо-Келен", "Кожо-Келең өрөөнү", 40.1200, 72.7300, "nature"),
      place("osh-museum", "متحف سليمان توو", "Sulaiman-Too Museum", "Музей Сулайман-Тоо", "Сулайман-Тоо музейи", 40.5296, 72.7825, "museum"),
    ],
  },
  {
    id: "kg-batken",
    names: names("إقليم باتكين", "Batken Region", "Баткенская область", "Баткен облусу", {
      az: "Batken vilayəti", ka: "ბათქენის რეგიონი", tr: "Batken Bölgesi",
      ur: "باتکین علاقہ", fr: "Région de Batken", id: "Wilayah Batken", "zh-Hans": "巴特肯州",
    }),
    center: [40.06, 70.82], bounds: [[39.20, 69.20], [40.95, 72.00]],
    imageQuery: "Batken Kyrgyzstan Karavshin Turkestan Range",
    landmarks: [
      place("karavshin", "وادي كارافشين", "Karavshin Valley", "Долина Каравшин", "Каравшин өрөөнү", 39.6400, 70.9900, "nature"),
      place("aigul-tash", "محمية آيغول تاش", "Aigul-Tash Reserve", "Заказник Айгуль-Таш", "Айгүл-Таш коругу", 39.9500, 70.9700, "nature"),
      place("ai-kol", "بحيرة آي كول", "Ai-Kol Lake", "Озеро Ай-Куль", "Ай-Көл", 39.7300, 71.2900, "nature"),
      place("kan-i-gut", "كهف كان إي غوت", "Kan-i-Gut Cave", "Пещера Кан-и-Гут", "Кан-и-Гут үңкүрү", 39.9000, 70.0800, "nature"),
      place("sary-too", "جبال ساري توو", "Sary-Too Mountains", "Горы Сары-Тоо", "Сары-Тоо тоолору", 39.9800, 70.9100, "nature"),
      place("batken-city", "مدينة باتكين", "Batken City Center", "Центр Баткена", "Баткен шаарынын борбору", 40.0600, 70.8200, "city"),
      place("razzakov", "مدينة رزاقوف", "Razzakov City", "Город Раззаков", "Раззаков шаары", 39.8400, 69.5300, "city"),
      place("kadamjay", "وادي كادامجااي", "Kadamjay Valley", "Долина Кадамжай", "Кадамжай өрөөнү", 40.1300, 71.7300, "nature"),
      place("khaidarkan", "مرتفعات خيداركان", "Khaidarkan Highlands", "Нагорье Хайдаркан", "Айдаркен бийиктиктери", 39.9400, 71.3400, "nature"),
      place("turkestan-range", "سلسلة جبال تركستان", "Turkestan Range", "Туркестанский хребет", "Түркстан тоо кыркасы", 39.5700, 70.1000, "nature"),
    ],
  },
];

function names(ar, en, ru, ky, extra = {}) {
  return {ar, en, ru, ky, fr: en, tr: en, ur: ar, id: en, az: en, ka: en, "zh-Hans": en, ...extra};
}

function place(id, ar, en, ru, ky, lat, lng, category) {
  return {id, names: names(ar, en, ru, ky), lat, lng, category};
}

function descriptions(landmarkNames, regionNames) {
  return {
    ar: `${landmarkNames.ar} معلم حقيقي في ${regionNames.ar} ومتاح للإضافة إلى مسار الرحلة.`,
    en: `${landmarkNames.en} is a real attraction in ${regionNames.en} available for trip routes.`,
    ru: `${landmarkNames.ru} — реальная достопримечательность в регионе ${regionNames.ru}.`,
    ky: `${landmarkNames.ky} — ${regionNames.ky} аймагындагы чыныгы туристтик жай.`,
    fr: `${landmarkNames.en} est un site touristique réel de la ${regionNames.fr}.`,
    tr: `${landmarkNames.en}, ${regionNames.tr} içinde gerçek bir turistik noktadır.`,
    ur: `${landmarkNames.ar}، ${regionNames.ur} میں ایک حقیقی سیاحتی مقام ہے۔`,
    id: `${landmarkNames.en} adalah objek wisata nyata di ${regionNames.id}.`,
    az: `${landmarkNames.en}, ${regionNames.az} ərazisində real turizm məkanıdır.`,
    ka: `${landmarkNames.en} არის რეალური ტურისტული ადგილი რეგიონში ${regionNames.ka}.`,
    "zh-Hans": `${landmarkNames.en} 是${regionNames["zh-Hans"]}的真实旅游景点。`,
  };
}

async function commonsImage(query, fallback) {
  try {
    const response = await axios.get("https://commons.wikimedia.org/w/api.php", {
      params: {
        action: "query", generator: "search", gsrsearch: query,
        gsrnamespace: 6, gsrlimit: 5, prop: "imageinfo",
        iiprop: "url", iiurlwidth: 1400, format: "json",
      },
      headers: {"User-Agent": "TouriTaxiContent/1.0"}, timeout: 15000,
    });
    const pages = Object.values(response.data?.query?.pages || {});
    for (const page of pages) {
      const imageInfo = page.imageinfo?.[0];
      const url = imageInfo?.thumburl || imageInfo?.url;
      if (url && !/\.svg(?:\?|$)/i.test(url)) return url;
    }
  } catch (error) {
    console.warn(`Wikimedia image lookup failed for ${query}: ${error.message}`);
  }
  return fallback;
}

async function main() {
  const countrySnapshot = await countryRef.get();
  if (!countrySnapshot.exists) throw new Error("Kyrgyzstan country document is missing.");
  const country = countrySnapshot.data() || {};
  const fallbackImage = country.img || country.hederImg || "";
  const regionImages = new Map();
  for (const region of regions) {
    regionImages.set(region.id, await commonsImage(region.imageQuery, fallbackImage));
  }

  let batch = db.batch();
  let writes = 0;
  async function set(ref, data) {
    batch.set(ref, data, {merge: true});
    writes += 1;
    if (writes >= 400) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }

  const now = FieldValue.serverTimestamp();
  for (let regionIndex = 0; regionIndex < regions.length; regionIndex += 1) {
    const region = regions[regionIndex];
    const image = regionImages.get(region.id);
    const cityRef = db.collection("cities").doc(region.id);
    const villageRef = db.collection("villages").doc(`${region.id}-main`);
    const [lat, lng] = region.center;

    await set(cityRef, {
      naim: region.names.ar, names_i18n: region.names,
      osf: `محافظة سياحية في قيرغيزستان: ${region.names.ar}.`,
      osf_i18n: names(
        `محافظة سياحية في قيرغيزستان: ${region.names.ar}.`,
        `A tourism region in Kyrgyzstan: ${region.names.en}.`,
        `Туристический регион Кыргызстана: ${region.names.ru}.`,
        `Кыргызстандын туристтик аймагы: ${region.names.ky}.`,
      ),
      img: image, dolh: countryRef, acctev: true, sorting: regionIndex + 1,
      geo_center: new GeoPoint(lat, lng),
      bounds_sw: new GeoPoint(region.bounds[0][0], region.bounds[0][1]),
      bounds_ne: new GeoPoint(region.bounds[1][0], region.bounds[1][1]),
      country_iso: "kg", content_source: "official-tourism-and-unesco", updated_at: now,
    });

    await set(villageRef, {
      cities: cityRef, dolh: countryRef,
      naim: `${region.names.ar} - المسار الرئيسي`,
      names_i18n: names(
        `${region.names.ar} - المسار الرئيسي`, `${region.names.en} main route`,
        `${region.names.ru} — основной маршрут`, `${region.names.ky} — негизги маршрут`,
      ),
      naim_viil_map: region.names.en, naimciteText: region.names.en,
      osf: `مسار منظم لأبرز معالم ${region.names.ar}.`,
      osf_i18n: names(
        `مسار منظم لأبرز معالم ${region.names.ar}.`,
        `A curated route through top attractions in ${region.names.en}.`,
        `Маршрут по главным достопримечательностям региона ${region.names.ru}.`,
        `${region.names.ky} аймагындагы негизги жайлар боюнча маршрут.`,
      ),
      img: image, lat_ling: new GeoPoint(lat, lng), acctev: true,
      no_delete_place: true, country_iso: "kg", updated_at: now,
    });

    for (let i = 0; i < region.landmarks.length; i += 1) {
      const landmark = region.landmarks[i];
      const description = descriptions(landmark.names, region.names);
      await set(db.collection("mkan").doc(`${region.id}-${landmark.id}`), {
        naim: landmark.names.ar, names_i18n: landmark.names,
        osf: description.ar, osf_i18n: description,
        img1: image, img2: image, img3: image, img: image,
        sr: 0, acctev: true, id_cit: cityRef, id_vill: villageRef,
        Location: new GeoPoint(landmark.lat, landmark.lng),
        address: `${landmark.names.en}, ${region.names.en}, Kyrgyzstan`,
        mdh: region.names.ar, tsnef: landmark.category,
        rate: 4.5 + (i % 5) * 0.1, add_saat: 1,
        as_ads: i < 2, ismsgd: landmark.category === "mosque",
        isfood: false, ishmam: false, ismzod: false, isShrek: false,
        IsSuggested: i < 4, content_locale: "multi", country_iso: "kg",
        source_url: "https://tourism.gov.kg/about-kyrgyzstan/",
        dataAdd: now, updated_at: now,
      });
    }
  }
  if (writes > 0) await batch.commit();
  console.log(`Seeded Kyrgyzstan regions: ${regions.length}`);
  console.log(`Seeded Kyrgyzstan landmarks: ${regions.reduce((sum, region) => sum + region.landmarks.length, 0)}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
