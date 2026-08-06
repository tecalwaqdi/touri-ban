'use strict';

/**
 * Curated top-5 landmarks per official SA region / KG oblast.
 * Names must match collected datasets when possible so images can be reused.
 * Overrides supply full payloads when OSM/collected quality is weak.
 */

const LANGS = ['ar', 'en', 'ru', 'ky'];

/** Preferred match keys (case-insensitive substring against en/ar names). */
const PREFERRED_MATCH = {
  riyadh: [
    'At-Turaif',
    'Masmak',
    'National Museum',
    'Kingdom Centre',
    'Birthplace of the House of Saud',
  ],
  makkah: ['Jabal ar Rahmah', 'Jamaraat', 'Maqam Ibrahim'],
  madinah: ['Al-Hijr', 'Quba', 'Qiblatayn', 'Miqat', 'Uhud'],
  eastern: ['Tarout', 'Ibrahim', 'Sahud', 'Khuzam', 'Dammam 7'],
  qassim: ['Buraidah Museum', 'Old Market', 'Mashqouq', 'Surayyah', 'النصلة'],
  hail: ['Barzan', 'القشلة', "A'Arif", 'Fadak', 'Kharash'],
  tabuk: ['Tabuk castle', 'Hadaj', 'Muwaylih', 'Mueleh', 'Masyoun'],
  northern_borders: ['Zubalah', 'Theleema', 'Duwayd', 'Zafiri', 'Akhdar'],
  jazan: ['Dosariyah', 'Qaraana', 'Qesar', 'Khawlani', 'Rifai'],
  najran: ['Ukhdud', 'Hima', 'Ra`um', 'Ra\'um', 'Aan Palace', 'الذرواء'],
  baha: ['Thee Ain', 'Hamalida', 'Ranyah', 'القهيب', 'الفيل'],
  jouf: ['Rajajil', 'Marid', 'Zabal', 'Moisin', 'Umm al Abi'],
  asir: ['Shaar', 'Jerash', 'Shaibanah', 'Habala', 'Rijal'],
  bishkek: ['Ala-Too', 'National History', 'Osh Bazaar', 'Panfilov', 'Philharmonic'],
  chuy: ['Ala Archa', 'Burana', 'Chunkurchak', 'Issyk-Ata', 'Konorchek'],
  issyk_kul: ['Issyk-Kul Lake', 'Cholpon-Ata', 'Rukh Ordo', 'Jeti-Oguz', 'Skazka'],
  naryn: ['Song-Kol', 'Tash Rabat', 'Kel-Suu', 'Koshoi', 'Salkyn-Tor'],
  talas: ['Manas Ordo', 'Besh-Tash', 'Gumbez', 'Kirov', 'Talas Regional'],
  jalal_abad: ['Sary-Chelek', 'Arslanbob Walnut', 'Arslanbob Waterfall', 'Shah Fazil', 'Padysha'],
  osh: ['Uzgen', 'Alay', 'Abshir', 'Achik-Tash', 'Jayma'],
  osh_city: ['Sulaiman-Too Sacred', 'Jayma', 'Sulaiman-Too Museum', 'Central Mosque', 'central square'],
  batken: ['Karavshin', 'Aigul-Tash', 'Ai-Kol', 'Kan-i-Gut', 'Batken City'],
};

/**
 * Full overrides used when collected data lacks famous landmarks
 * (especially Makkah / Asir). Images may be Wikimedia Commons HTTPS URLs.
 */
const OVERRIDES = {
  makkah: [
    {
      slug: 'masjid-al-haram',
      category: 'religious',
      names: {
        ar: 'المسجد الحرام',
        en: 'Masjid al-Haram',
        ru: 'Запретная мечеть',
        ky: 'Аль-Харам мечити',
      },
      lat: 21.4225,
      lng: 39.8262,
      address: {
        ar: 'المسجد الحرام، مكة المكرمة، المملكة العربية السعودية',
        en: 'Masjid al-Haram, Makkah, Saudi Arabia',
        ru: 'Запретная мечеть, Мекка, Саудовская Аравия',
        ky: 'Аль-Харам мечити, Мекке, Сауд Арабиясы',
      },
      osf: {
        ar: 'أقدس مسجد في الإسلام ومهوى أفئدة المسلمين، يضم الكعبة المشرفة والمطاف والمسعى.',
        en: 'The holiest mosque in Islam, surrounding the Kaaba, the focal point of Muslim prayer and pilgrimage.',
        ru: 'Священнейшая мечеть ислама вокруг Каабы — центр молитвы и паломничества мусульман.',
        ky: 'Исламдагы эң ыйык мечит; Каабаны курчап, намаз жана ажылык борбору.',
      },
      img: 'https://upload.wikimedia.org/wikipedia/commons/b/b8/Edited_Great_Mosque_of_Mecca1_5-2019-ccsa4.0_%28cropped%29.jpg',
      wikiTitle: 'Masjid al-Haram',
    },
    {
      slug: 'abraj-al-bait',
      category: 'attraction',
      names: {
        ar: 'أبراج البيت',
        en: 'Abraj Al Bait (Clock Towers)',
        ru: 'Башни Абрадж аль-Байт',
        ky: 'Абраж Аль-Байт мунаралары',
      },
      lat: 21.4186,
      lng: 39.8256,
      address: {
        ar: 'أبراج البيت، مكة المكرمة، المملكة العربية السعودية',
        en: 'Abraj Al Bait, Makkah, Saudi Arabia',
        ru: 'Абрадж аль-Байт, Мекка, Саудовская Аравия',
        ky: 'Абраж Аль-Байт, Мекке, Сауд Арабиясы',
      },
      osf: {
        ar: 'مجمع ناطحات سحاب مطل على الحرم، يضم برج الساعة الشهير ومرافق للزوار والحجاج.',
        en: 'Iconic skyscraper complex overlooking the Grand Mosque, crowned by the Makkah Clock Tower.',
        ru: 'Знаменитый комплекс небоскрёбов у Запретной мечети с часовой башней Мекки.',
        ky: 'Аль-Харамга караган асман тиреген комплекс жана Мекке саат мунарасы.',
      },
      img: 'https://upload.wikimedia.org/wikipedia/en/a/a4/Abraj_Al_Bait_Tower_2017.jpg',
      wikiTitle: 'Abraj Al Bait',
    },
    {
      slug: 'jabal-al-nour',
      category: 'heritage',
      names: {
        ar: 'جبل النور',
        en: 'Jabal al-Nour',
        ru: 'Джабаль ан-Нур',
        ky: 'Жабал ан-Нур',
      },
      lat: 21.4581,
      lng: 39.8592,
      address: {
        ar: 'جبل النور، مكة المكرمة، المملكة العربية السعودية',
        en: 'Jabal al-Nour, Makkah, Saudi Arabia',
        ru: 'Джабаль ан-Нур, Мекка, Саудовская Аравия',
        ky: 'Жабал ан-Нур, Мекке, Сауд Арабиясы',
      },
      osf: {
        ar: 'جبل تاريخي يضم غار حراء حيث بدأ الوحي، ويقصده الزوار للصعود والتأمل.',
        en: 'Historic mountain home to the Cave of Hira, where revelation began according to Islamic tradition.',
        ru: 'Историческая гора с пещерой Хира, связанная с началом откровения в исламе.',
        ky: 'Хира үңкүрү жайгашкан тарыхый тоо; аян менен зиярат кылынат.',
      },
      img: 'https://upload.wikimedia.org/wikipedia/commons/5/57/Jabbal_An-Nour_%282024%29.jpg',
      wikiTitle: 'Jabal al-Nour',
    },
    {
      slug: 'historic-jeddah',
      category: 'heritage',
      names: {
        ar: 'جدة التاريخية (البلد)',
        en: 'Historic Jeddah (Al-Balad)',
        ru: 'Историческая Джидда (Аль-Балад)',
        ky: 'Тарыхый Жидда (Аль-Балад)',
      },
      lat: 21.4858,
      lng: 39.187,
      address: {
        ar: 'البلد، جدة، منطقة مكة المكرمة، المملكة العربية السعودية',
        en: 'Al-Balad, Jeddah, Makkah Region, Saudi Arabia',
        ru: 'Аль-Балад, Джидда, провинция Мекка, Саудовская Аравия',
        ky: 'Аль-Балад, Жидда, Мекке аймагы, Сауд Арабиясы',
      },
      osf: {
        ar: 'موقع تراث عالمي يضم البيوت الحجازية والمساجد والأسواق التاريخية على ساحل البحر الأحمر.',
        en: 'UNESCO World Heritage old town of Jeddah with Hijazi houses, mosques, and Red Sea trading streets.',
        ru: 'Объект ЮНЕСКО — старый город Джидды с хиджазской архитектурой и рынками у Красного моря.',
        ky: 'ЮНЕСКО мурасы: Жидданын эски шаары, Хижаз үйлөрү жана Кызыл деңиз жээги.',
      },
      img: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Old_Jeddah_%28Al_Balad%29_architecture_3_Feb_2022.jpg',
      wikiTitle: 'Historic Jeddah',
    },
    {
      slug: 'king-fahd-fountain',
      category: 'attraction',
      names: {
        ar: 'نافورة الملك فهد',
        en: 'King Fahd Fountain',
        ru: 'Фонтан короля Фахда',
        ky: 'Король Фахд фонтаны',
      },
      lat: 21.5169,
      lng: 39.1444,
      address: {
        ar: 'كورنيش جدة، جدة، منطقة مكة المكرمة، المملكة العربية السعودية',
        en: 'Jeddah Corniche, Jeddah, Makkah Region, Saudi Arabia',
        ru: 'Набережная Джидды, Джидда, провинция Мекка, Саудовская Аравия',
        ky: 'Жидда набережнаясы, Жидда, Мекке аймагы, Сауд Арабиясы',
      },
      osf: {
        ar: 'أطول نافورة بحرية في العالم على كورنيش جدة، معلم ليلي بارز للزوار.',
        en: 'One of the world’s tallest seawater fountains on the Jeddah Corniche, especially striking at night.',
        ru: 'Один из самых высоких морских фонтанов мира на набережной Джидды.',
        ky: 'Жидда набережнаясындагы дүйнөдөгү эң бийик деңиз фонтандарынын бири.',
      },
      img: 'https://upload.wikimedia.org/wikipedia/commons/9/91/King_Fahd%E2%80%99s_Fountain.jpg',
      wikiTitle: "King Fahd's Fountain",
    },
  ],
  asir: [
    {
      slug: 'rijal-almaa',
      category: 'heritage',
      names: {
        ar: 'رجال ألمع',
        en: 'Rijal Almaa Heritage Village',
        ru: 'Деревня наследия Риджяль Альмаа',
        ky: 'Рижал Алмаа мура кыштагы',
      },
      lat: 18.212,
      lng: 42.273,
      address: {
        ar: 'رجال ألمع، منطقة عسير، المملكة العربية السعودية',
        en: 'Rijal Almaa, Asir Region, Saudi Arabia',
        ru: 'Риджяль Альмаа, провинция Асир, Саудовская Аравия',
        ky: 'Рижал Алмаа, Асир аймагы, Сауд Арабиясы',
      },
      osf: {
        ar: 'قرية تراثية جبلية شهيرة بعمارة الحجر الملون والمتاحف المحلية في عسير.',
        en: 'Famous mountain heritage village in Asir known for colorful stone towers and local museums.',
        ru: 'Знаменитая горная деревня наследия в Асире с цветными каменными башнями.',
        ky: 'Асирдеги таш мунаралуу белгилүү тоолу мура кыштагы.',
      },
      img: 'https://upload.wikimedia.org/wikipedia/commons/4/45/%D8%B1%D8%AC%D8%A7%D9%84_%D8%A3%D9%84%D9%85%D8%B91.jpg',
      wikiTitle: 'Asir',
    },
  ],
};

/** Short official-style region descriptions (ar/en/ru/ky). */
const REGION_OSF = {
  riyadh: {
    ar: 'عاصمة المملكة ومركزها الإداري والاقتصادي، تضم الرياض التاريخية والوجهات الحديثة.',
    en: 'Capital region of Saudi Arabia — historic Najd heritage alongside modern Riyadh.',
    ru: 'Столичный регион Саудовской Аравии: наследие Неджда и современный Эр-Рияд.',
    ky: 'Сауд Арабиясынын борбордук аймагы — тарыхый Нежд жана заманбап Эр-Рияд.',
  },
  makkah: {
    ar: 'المنطقة الأشهر للحج والعمرة، وتشمل مكة المكرمة وجدة والساحل الغربي.',
    en: 'Home of Makkah and Jeddah — pilgrimage, Red Sea coast, and Hijazi heritage.',
    ru: 'Регион Мекки и Джидды: паломничество, Красное море и хиджазское наследие.',
    ky: 'Мекке менен Жидда аймагы — ажылык, Кызыл деңиз жана Хижаз мурасы.',
  },
  madinah: {
    ar: 'منطقة المدينة المنورة والعلا ومدائن صالح، قلب التاريخ الإسلامي والثمودي.',
    en: 'Madinah Region including AlUla and Hegra — Islamic and Nabataean heritage.',
    ru: 'Провинция Медины, включая Эль-Улу и Хегру — исламское и набатейское наследие.',
    ky: 'Мадина аймагы: Аль-Ула жана Хегра — ислам жана набатей мурасы.',
  },
  eastern: {
    ar: 'المنطقة الشرقية على الخليج العربي، مركز النفط والمدن الساحلية مثل الدمام والخبر.',
    en: 'Eastern Province on the Arabian Gulf — oil heartland and coastal cities.',
    ru: 'Восточная провинция у Персидского залива — нефтяной центр и прибрежные города.',
    ky: 'Араб булуңундагы Чыгыш аймак — мунай жана жээк шаарлары.',
  },
  qassim: {
    ar: 'سلة غذاء نجد، تشتهر بالنخيل والزراعة والمدن التاريخية مثل بريدة وعنيزة.',
    en: 'Agricultural heart of Najd, known for date palms and historic Qassim towns.',
    ru: 'Аграрное сердце Неджда, известное финиковыми пальмами и историческими городами.',
    ky: 'Нежддин айыл чарба жүрөгү — курма жана тарыхый шаарлар.',
  },
  hail: {
    ar: 'بوابة الشمال، معروفة بصحراء النفود والقصور التاريخية مثل برزان والقشلة.',
    en: 'Northern gateway region of the Nefud, with historic palaces and desert landscapes.',
    ru: 'Северный регион у пустыни Нефуд с историческими дворцами и пустынными пейзажами.',
    ky: 'Нефуд чөлүнө жанаша түндүк аймак — тарыхый сарайлар жана чөл.',
  },
  tabuk: {
    ar: 'شمال غرب المملكة قرب البحر الأحمر، تجمع بين القلاع العثمانية والساحل والجبال.',
    en: 'Northwestern region near the Red Sea — Ottoman forts, coast, and mountains.',
    ru: 'Северо-запад у Красного моря: османские крепости, побережье и горы.',
    ky: 'Кызыл деңизге жакын түндүк-батыш — осман чептери, жээк жана тоолор.',
  },
  northern_borders: {
    ar: 'منطقة الحدود الشمالية على أطراف المملكة، مع محطات تاريخية على طرق القوافل.',
    en: 'Northern Borders Region — frontier landscapes and historic caravan stations.',
    ru: 'Северная граница — приграничные ландшафты и исторические караванные стоянки.',
    ky: 'Түндүк чек ара аймагы — чек ара пейзаждары жана кербен бекеттери.',
  },
  jazan: {
    ar: 'أقصى الجنوب الغربي، سواحل البحر الأحمر وجزر فرسان ومزارع البن الخولاني.',
    en: 'Southwestern tip of Saudi Arabia — Red Sea coast, Farasan, and Khawlani coffee.',
    ru: 'Крайний юго-запад: Красное море, Фарасан и кофе Холани.',
    ky: 'Түштүк-батыш чети — Кызыл деңиз, Фарасан жана Холани кофеси.',
  },
  najran: {
    ar: 'جنوب المملكة عند بوابة اليمن، مع مواقع الأخدود وحمى للتراث الصخري.',
    en: 'Southern gateway near Yemen — Al-Ukhdud and Hima rock-art heritage.',
    ru: 'Южный регион у границы с Йеменом: Аль-Ухдуд и наскальное наследие Химы.',
    ky: 'Йеменге жакын түштүк дарбаза — Аль-Ухдуд жана Хима аска сүрөттөрү.',
  },
  baha: {
    ar: 'منطقة جبلية خضراء في السروات، تشتهر بقرية ذي عين والمدرجات الزراعية.',
    en: 'Green highland region of the Sarawat — Thee Ain village and mountain terraces.',
    ru: 'Зелёный горный регион Саравит: деревня Зи-Айн и террасы.',
    ky: 'Сарават тоолорундагы жашыл аймак — Зи-Айн жана айыл тектирлери.',
  },
  jouf: {
    ar: 'شمال المملكة، موطن أعمدة الرجاجيل وواحات النخيل حول سكاكا ودومة الجندل.',
    en: 'Northern oasis region — Rajajil stones and palm groves around Sakaka.',
    ru: 'Северный оазисный регион: камни Раджаджиль и пальмовые рощи у Сакаки.',
    ky: 'Түндүк оазис аймагы — Ражажил таштары жана Сакака курмa бактары.',
  },
  asir: {
    ar: 'جبال عسير الخضراء وعاصمة أبها، مع قرى تراثية مثل رجال ألمع.',
    en: 'Green Asir mountains around Abha, with heritage villages like Rijal Almaa.',
    ru: 'Зелёные горы Асира вокруг Абхи и деревни наследия вроде Риджяль Альмаа.',
    ky: 'Абха айланасындагы жашыл Асир тоолору жана Рижал Алмаа кыштагы.',
  },
  bishkek: {
    ar: 'عاصمة قيرغيزستان ومركزها الثقافي والسياسي في سفوح تيان شان.',
    en: 'Capital of Kyrgyzstan — cultural and political hub at the Tian Shan foothills.',
    ru: 'Столица Кыргызстана — культурный и политический центр у Тянь-Шаня.',
    ky: 'Кыргызстандын борбору — Тянь-Шань этегиндеги маданий жана саясий борбор.',
  },
  chuy: {
    ar: 'إقليم تشوي حول بيشكيك، يضم منتزه ألا أرتشا وبرج بورانا التاريخي.',
    en: 'Chuy Region around Bishkek — Ala-Archa park and the Burana Tower.',
    ru: 'Чуйская область у Бишкека: Ала-Арча и башня Бурана.',
    ky: 'Бишкек айланасындагы Чүй облусу — Ала-Арча жана Бурана мунарасы.',
  },
  issyk_kul: {
    ar: 'إقليم بحيرة إيسيك كول الشهيرة، منتجعات الشواطئ والجبال المحيطة.',
    en: 'Issyk-Kul Region — the great alpine lake, beaches, and surrounding peaks.',
    ru: 'Иссык-Кульская область — великое высокогорное озеро и курорты.',
    ky: 'Ысык-Көл облусу — улуу тоо көлү, пляждар жана курчаган чокулар.',
  },
  naryn: {
    ar: 'إقليم نارين الجبلي على طريق الحرير، مع سونغ كول وتاش رباط.',
    en: 'Mountainous Naryn on the Silk Road — Song-Kol and Tash Rabat.',
    ru: 'Горный Нарын на Шёлковом пути: Сон-Куль и Таш-Рабат.',
    ky: 'Жибек Жолундагы тоолуу Нарын — Соң-Көл жана Таш-Рабат.',
  },
  talas: {
    ar: 'إقليم تالاس، مرتبط بملحمة ماناس ومجمع ماناس أوردو.',
    en: 'Talas Region — linked to the Manas epic and Manas Ordo complex.',
    ru: 'Таласская область, связанная с эпосом Манас и комплексом Манас Ордо.',
    ky: 'Талас облусу — Манас эпосу жана Манас Ордо комплекси.',
  },
  jalal_abad: {
    ar: 'إقليم جلال آباد في الغرب، غابات الجوز في أرسلانبوب وبحيرة ساري تشيليك.',
    en: 'Jalal-Abad Region — Arslanbob walnut forests and Sary-Chelek lake.',
    ru: 'Джалал-Абадская область: ореховые леса Арсланбоба и озеро Сары-Челек.',
    ky: 'Жалал-Абад облусу — Арстанбап жаңгак токойлору жана Сары-Челек.',
  },
  osh: {
    ar: 'إقليم أوش الجبلي جنوب البلاد، وديان ألاي ومعالم طريق الحرير مثل أوزغن.',
    en: 'Osh Region in the south — Alay valleys and Silk Road sites such as Uzgen.',
    ru: 'Ошская область на юге: Алайские долины и памятники Узгена.',
    ky: 'Түштүктөгү Ош облусу — Алай өрөөндөрү жана Өзгөн мурасы.',
  },
  osh_city: {
    ar: 'مدينة أوش التاريخية، من أقدم مدن آسيا الوسطى عند جبل سليمان توو.',
    en: 'Historic Osh City — one of Central Asia’s oldest cities at Sulaiman-Too.',
    ru: 'Исторический город Ош — один из древнейших городов Центральной Азии у Сулайман-Тоо.',
    ky: 'Тарыхый Ош шаары — Борбордук Азиянын эң байыркы шаарларынан, Сулайман-Тоо.',
  },
  batken: {
    ar: 'إقليم باتكين في أقصى الجنوب الغربي، وديان وقمم شاهقة قرب حدود طاجيكستان.',
    en: 'Southwestern Batken Region — high valleys and peaks near the Tajik border.',
    ru: 'Юго-западная Баткенская область — высокие долины у границы с Таджикистаном.',
    ky: 'Түштүк-батыш Баткен — Тажикстан чек арасына жакын бийик өрөөндөр.',
  },
};

module.exports = {
  LANGS,
  PREFERRED_MATCH,
  OVERRIDES,
  REGION_OSF,
};
