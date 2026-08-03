'use strict';

/**
 * Administrative region catalogs for geo import.
 * Region collection maps to Firestore `cities`; city hubs map to `villages`.
 */

const LANGS = ['ar', 'en', 'ru', 'ky', 'uz'];

const SA_REGIONS = [
  { iso: '01', code: 'SA-01', slug: 'riyadh', names: { ar: 'منطقة الرياض', en: 'Riyadh Region', ru: 'Провинция Эр-Рияд', ky: 'Эр-Рияд аймагы', uz: 'Ar-Riyod viloyati' }, hub: { slug: 'riyadh', names: { ar: 'الرياض', en: 'Riyadh', ru: 'Эр-Рияд', ky: 'Эр-Рияд', uz: 'Ar-Riyod' }, lat: 24.7136, lng: 46.6753 } },
  { iso: '02', code: 'SA-02', slug: 'makkah', names: { ar: 'منطقة مكة المكرمة', en: 'Makkah Region', ru: 'Провинция Мекка', ky: 'Мекке аймагы', uz: 'Makka viloyati' }, hub: { slug: 'makkah', names: { ar: 'مكة المكرمة', en: 'Makkah', ru: 'Мекка', ky: 'Мекке', uz: 'Makka' }, lat: 21.4225, lng: 39.8262 } },
  { iso: '03', code: 'SA-03', slug: 'madinah', names: { ar: 'منطقة المدينة المنورة', en: 'Madinah Region', ru: 'Провинция Медина', ky: 'Мадина аймагы', uz: 'Madina viloyati' }, hub: { slug: 'madinah', names: { ar: 'المدينة المنورة', en: 'Madinah', ru: 'Медина', ky: 'Мадина', uz: 'Madina' }, lat: 24.4686, lng: 39.6142 } },
  { iso: '04', code: 'SA-04', slug: 'eastern', names: { ar: 'المنطقة الشرقية', en: 'Eastern Province', ru: 'Восточная провинция', ky: 'Чыгыш аймак', uz: 'Sharqiy viloyat' }, hub: { slug: 'dammam', names: { ar: 'الدمام', en: 'Dammam', ru: 'Даммам', ky: 'Даммам', uz: 'Dammom' }, lat: 26.4207, lng: 50.0888 } },
  { iso: '05', code: 'SA-05', slug: 'qassim', names: { ar: 'منطقة القصيم', en: 'Qassim Region', ru: 'Провинция Эль-Касим', ky: 'Касим аймагы', uz: 'Qosim viloyati' }, hub: { slug: 'buraidah', names: { ar: 'بريدة', en: 'Buraidah', ru: 'Бурайда', ky: 'Бурайда', uz: 'Burayda' }, lat: 26.3592, lng: 43.9818 } },
  { iso: '06', code: 'SA-06', slug: 'hail', names: { ar: 'منطقة حائل', en: "Ha'il Region", ru: 'Провинция Хаиль', ky: 'Хаил аймагы', uz: 'Hoil viloyati' }, hub: { slug: 'hail', names: { ar: 'حائل', en: "Ha'il", ru: 'Хаиль', ky: 'Хаил', uz: 'Hoil' }, lat: 27.5114, lng: 41.7208 } },
  { iso: '07', code: 'SA-07', slug: 'tabuk', names: { ar: 'منطقة تبوك', en: 'Tabuk Region', ru: 'Провинция Табук', ky: 'Табук аймагы', uz: 'Tabuk viloyati' }, hub: { slug: 'tabuk', names: { ar: 'تبوك', en: 'Tabuk', ru: 'Табук', ky: 'Табук', uz: 'Tabuk' }, lat: 28.3838, lng: 36.555 } },
  { iso: '08', code: 'SA-08', slug: 'northern_borders', names: { ar: 'منطقة الحدود الشمالية', en: 'Northern Borders Region', ru: 'Северная граница', ky: 'Түндүк чек ара', uz: 'Shimoliy chegaralar' }, hub: { slug: 'arar', names: { ar: 'عرعر', en: 'Arar', ru: 'Арар', ky: 'Арар', uz: 'Arar' }, lat: 30.9753, lng: 41.0381 } },
  { iso: '09', code: 'SA-09', slug: 'jazan', names: { ar: 'منطقة جازان', en: 'Jazan Region', ru: 'Провинция Джизан', ky: 'Жазан аймагы', uz: 'Jazon viloyati' }, hub: { slug: 'jazan', names: { ar: 'جازان', en: 'Jazan', ru: 'Джизан', ky: 'Жазан', uz: 'Jazon' }, lat: 16.8894, lng: 42.5706 } },
  { iso: '10', code: 'SA-10', slug: 'najran', names: { ar: 'منطقة نجران', en: 'Najran Region', ru: 'Провинция Наджран', ky: 'Нажран аймагы', uz: 'Najron viloyati' }, hub: { slug: 'najran', names: { ar: 'نجران', en: 'Najran', ru: 'Наджран', ky: 'Нажран', uz: 'Najron' }, lat: 17.5656, lng: 44.2289 } },
  { iso: '11', code: 'SA-11', slug: 'baha', names: { ar: 'منطقة الباحة', en: 'Al Bahah Region', ru: 'Провинция Эль-Баха', ky: 'Баха аймагы', uz: 'Al-Baho viloyati' }, hub: { slug: 'baha', names: { ar: 'الباحة', en: 'Al Bahah', ru: 'Эль-Баха', ky: 'Баха', uz: 'Al-Baho' }, lat: 20.0129, lng: 41.4677 } },
  { iso: '12', code: 'SA-12', slug: 'jouf', names: { ar: 'منطقة الجوف', en: 'Al Jouf Region', ru: 'Провинция Эль-Джауф', ky: 'Жауф аймагы', uz: 'Al-Jauf viloyati' }, hub: { slug: 'sakaka', names: { ar: 'سكاكا', en: 'Sakaka', ru: 'Сакака', ky: 'Сакака', uz: 'Sakaka' }, lat: 29.9697, lng: 40.2064 } },
  { iso: '14', code: 'SA-14', slug: 'asir', names: { ar: 'منطقة عسير', en: 'Asir Region', ru: 'Провинция Асир', ky: 'Асир аймагы', uz: 'Asir viloyati' }, hub: { slug: 'abha', names: { ar: 'أبها', en: 'Abha', ru: 'Абха', ky: 'Абха', uz: 'Abha' }, lat: 18.2164, lng: 42.5053 } },
];

const KG_REGIONS = [
  { code: 'KG-GB', slug: 'bishkek', curatedKey: 'kg-bishkek', names: { ar: 'بيشكيك', en: 'Bishkek', ru: 'Бишкек', ky: 'Бишкек', uz: 'Bishkek' }, hub: { slug: 'bishkek', names: { ar: 'بيشكيك', en: 'Bishkek', ru: 'Бишкек', ky: 'Бишкек', uz: 'Bishkek' }, lat: 42.8746, lng: 74.5698 } },
  { code: 'KG-C', slug: 'chuy', curatedKey: 'kg-chuy', names: { ar: 'إقليم تشوي', en: 'Chuy Region', ru: 'Чуйская область', ky: 'Чүй облусу', uz: 'Chuy viloyati' }, hub: { slug: 'tokmok', names: { ar: 'توكموك', en: 'Tokmok', ru: 'Токмок', ky: 'Токмок', uz: 'Toqmoq' }, lat: 42.841, lng: 75.301 } },
  { code: 'KG-Y', slug: 'issyk_kul', curatedKey: 'kg-issyk-kul', names: { ar: 'إقليم إيسيك كول', en: 'Issyk-Kul Region', ru: 'Иссык-Кульская область', ky: 'Ысык-Көл облусу', uz: 'Issiqkoʻl viloyati' }, hub: { slug: 'karakol', names: { ar: 'كاراكول', en: 'Karakol', ru: 'Каракол', ky: 'Каракол', uz: 'Qoraqol' }, lat: 42.4907, lng: 78.3936 } },
  { code: 'KG-N', slug: 'naryn', curatedKey: 'kg-naryn', names: { ar: 'إقليم نارين', en: 'Naryn Region', ru: 'Нарынская область', ky: 'Нарын облусу', uz: 'Norin viloyati' }, hub: { slug: 'naryn', names: { ar: 'نارين', en: 'Naryn', ru: 'Нарын', ky: 'Нарын', uz: 'Norin' }, lat: 41.4287, lng: 75.9911 } },
  { code: 'KG-T', slug: 'talas', curatedKey: 'kg-talas', names: { ar: 'إقليم تالاس', en: 'Talas Region', ru: 'Таласская область', ky: 'Талас облусу', uz: 'Talas viloyati' }, hub: { slug: 'talas', names: { ar: 'تالاس', en: 'Talas', ru: 'Талас', ky: 'Талас', uz: 'Talas' }, lat: 42.5228, lng: 72.2427 } },
  { code: 'KG-J', slug: 'jalal_abad', curatedKey: 'kg-jalal-abad', names: { ar: 'إقليم جلال آباد', en: 'Jalal-Abad Region', ru: 'Джалал-Абадская область', ky: 'Жалал-Абад облусу', uz: 'Jalolobod viloyati' }, hub: { slug: 'jalal_abad', names: { ar: 'جلال آباد', en: 'Jalal-Abad', ru: 'Джалал-Абад', ky: 'Жалал-Абад', uz: 'Jalolobod' }, lat: 40.9333, lng: 73.0 } },
  { code: 'KG-O', slug: 'osh', curatedKey: 'kg-osh', names: { ar: 'إقليم أوش', en: 'Osh Region', ru: 'Ошская область', ky: 'Ош облусу', uz: 'Oʻsh viloyati' }, hub: { slug: 'uzgen', names: { ar: 'أوزجن', en: 'Uzgen', ru: 'Узген', ky: 'Өзгөн', uz: 'Oʻzgan' }, lat: 40.7667, lng: 73.3 } },
  { code: 'KG-GO', slug: 'osh_city', curatedKey: 'kg-osh-city', names: { ar: 'مدينة أوش', en: 'Osh City', ru: 'город Ош', ky: 'Ош шаары', uz: 'Oʻsh shahri' }, hub: { slug: 'osh', names: { ar: 'أوش', en: 'Osh', ru: 'Ош', ky: 'Ош', uz: 'Oʻsh' }, lat: 40.5283, lng: 72.7985 } },
  { code: 'KG-B', slug: 'batken', curatedKey: 'kg-batken', names: { ar: 'إقليم باتكين', en: 'Batken Region', ru: 'Баткенская область', ky: 'Баткен облусу', uz: 'Botken viloyati' }, hub: { slug: 'batken', names: { ar: 'باتكين', en: 'Batken', ru: 'Баткен', ky: 'Баткен', uz: 'Botken' }, lat: 40.0626, lng: 70.8194 } },
];

const UZ_REGIONS = [
  { code: 'UZ-TK', slug: 'tashkent_city', names: { ar: 'مدينة طشقند', en: 'Tashkent City', ru: 'город Ташкент', ky: 'Ташкент шаары', uz: 'Toshkent shahri' }, hub: { slug: 'tashkent', names: { ar: 'طشقند', en: 'Tashkent', ru: 'Ташкент', ky: 'Ташкент', uz: 'Toshkent' }, lat: 41.2995, lng: 69.2401 } },
  { code: 'UZ-TO', slug: 'tashkent_region', names: { ar: 'ولاية طشقند', en: 'Tashkent Region', ru: 'Ташкентская область', ky: 'Ташкент облусу', uz: 'Toshkent viloyati' }, hub: { slug: 'nurafshon', names: { ar: 'نورافشان', en: 'Nurafshon', ru: 'Нурафшон', ky: 'Нурафшон', uz: 'Nurafshon' }, lat: 41.0, lng: 69.35 } },
  { code: 'UZ-SA', slug: 'samarkand', names: { ar: 'ولاية سمرقند', en: 'Samarkand Region', ru: 'Самаркандская область', ky: 'Самарканд облусу', uz: 'Samarqand viloyati' }, hub: { slug: 'samarkand', names: { ar: 'سمرقند', en: 'Samarkand', ru: 'Самарканд', ky: 'Самарканд', uz: 'Samarqand' }, lat: 39.6542, lng: 66.9597 } },
  { code: 'UZ-BU', slug: 'bukhara', names: { ar: 'ولاية بخارى', en: 'Bukhara Region', ru: 'Бухарская область', ky: 'Бухара облусу', uz: 'Buxoro viloyati' }, hub: { slug: 'bukhara', names: { ar: 'بخارى', en: 'Bukhara', ru: 'Бухара', ky: 'Бухара', uz: 'Buxoro' }, lat: 39.7681, lng: 64.4556 } },
  { code: 'UZ-XO', slug: 'xorazm', names: { ar: 'ولاية خوارزم', en: 'Xorazm Region', ru: 'Хорезмская область', ky: 'Хорезм облусу', uz: 'Xorazm viloyati' }, hub: { slug: 'urganch', names: { ar: 'أورغنج', en: 'Urgench', ru: 'Ургенч', ky: 'Ургенч', uz: 'Urganch' }, lat: 41.55, lng: 60.6333 } },
  { code: 'UZ-FA', slug: 'fergana', names: { ar: 'ولاية فرغانة', en: 'Fergana Region', ru: 'Ферганская область', ky: 'Фергана облусу', uz: 'Fargʻona viloyati' }, hub: { slug: 'fergana', names: { ar: 'فرغانة', en: 'Fergana', ru: 'Фергана', ky: 'Фергана', uz: 'Fargʻona' }, lat: 40.3864, lng: 71.7864 } },
  { code: 'UZ-NG', slug: 'namangan', names: { ar: 'ولاية نمنكان', en: 'Namangan Region', ru: 'Наманганская область', ky: 'Наманган облусу', uz: 'Namangan viloyati' }, hub: { slug: 'namangan', names: { ar: 'نمنكان', en: 'Namangan', ru: 'Наманган', ky: 'Наманган', uz: 'Namangan' }, lat: 40.9983, lng: 71.6726 } },
  { code: 'UZ-AN', slug: 'andijan', names: { ar: 'ولاية أنديجان', en: 'Andijan Region', ru: 'Андижанская область', ky: 'Андижан облусу', uz: 'Andijon viloyati' }, hub: { slug: 'andijan', names: { ar: 'أنديجان', en: 'Andijan', ru: 'Андижан', ky: 'Андижан', uz: 'Andijon' }, lat: 40.7833, lng: 72.3333 } },
  { code: 'UZ-QA', slug: 'qashqadaryo', names: { ar: 'ولاية قشقداريا', en: 'Qashqadaryo Region', ru: 'Кашкадарьинская область', ky: 'Кашкадаря облусу', uz: 'Qashqadaryo viloyati' }, hub: { slug: 'qarshi', names: { ar: 'قرشي', en: 'Qarshi', ru: 'Карши', ky: 'Карши', uz: 'Qarshi' }, lat: 38.8667, lng: 65.8 } },
  { code: 'UZ-SU', slug: 'surxondaryo', names: { ar: 'ولاية سرخانداريا', en: 'Surxondaryo Region', ru: 'Сурхандарьинская область', ky: 'Сурхандаря облусу', uz: 'Surxondaryo viloyati' }, hub: { slug: 'termiz', names: { ar: 'ترمذ', en: 'Termez', ru: 'Термез', ky: 'Термез', uz: 'Termiz' }, lat: 37.2242, lng: 67.2783 } },
  { code: 'UZ-NW', slug: 'navoiy', names: { ar: 'ولاية نواوي', en: 'Navoiy Region', ru: 'Навоийская область', ky: 'Навои облусу', uz: 'Navoiy viloyati' }, hub: { slug: 'navoiy', names: { ar: 'نواوي', en: 'Navoiy', ru: 'Навои', ky: 'Навои', uz: 'Navoiy' }, lat: 40.0844, lng: 65.3792 } },
  { code: 'UZ-JI', slug: 'jizzax', names: { ar: 'ولاية جيزك', en: 'Jizzax Region', ru: 'Джизакская область', ky: 'Жиззах облусу', uz: 'Jizzax viloyati' }, hub: { slug: 'jizzax', names: { ar: 'جيزك', en: 'Jizzax', ru: 'Джизак', ky: 'Жиззах', uz: 'Jizzax' }, lat: 40.1158, lng: 67.8422 } },
  { code: 'UZ-SI', slug: 'sirdaryo', names: { ar: 'ولاية سرداريا', en: 'Sirdaryo Region', ru: 'Сырдарьинская область', ky: 'Сырдария облусу', uz: 'Sirdaryo viloyati' }, hub: { slug: 'guliston', names: { ar: 'غوليستان', en: 'Guliston', ru: 'Гулистан', ky: 'Гулистан', uz: 'Guliston' }, lat: 40.4897, lng: 68.7842 } },
  { code: 'UZ-QR', slug: 'karakalpakstan', names: { ar: 'جمهورية قرقل باغستان', en: 'Republic of Karakalpakstan', ru: 'Республика Каракалпакстан', ky: 'Каракалпакстан', uz: 'Qoraqalpogʻiston Respublikasi' }, hub: { slug: 'nukus', names: { ar: 'نوكوس', en: 'Nukus', ru: 'Нукус', ky: 'Нукус', uz: 'Nukus' }, lat: 42.4531, lng: 59.6103 } },
];

/** Russia: tourist-priority federal subjects (wave 1 expansion). */
const RU_REGIONS = [
  { code: 'RU-MOW', slug: 'moscow', names: { ar: 'موسكو', en: 'Moscow', ru: 'Москва', ky: 'Москва', uz: 'Moskva' }, hub: { slug: 'moscow', names: { ar: 'موسكو', en: 'Moscow', ru: 'Москва', ky: 'Москва', uz: 'Moskva' }, lat: 55.7558, lng: 37.6173 } },
  { code: 'RU-SPE', slug: 'saint_petersburg', names: { ar: 'سانت بطرسبرغ', en: 'Saint Petersburg', ru: 'Санкт-Петербург', ky: 'Санкт-Петербург', uz: 'Sankt-Peterburg' }, hub: { slug: 'saint_petersburg', names: { ar: 'سانت بطرسبرغ', en: 'Saint Petersburg', ru: 'Санкт-Петербург', ky: 'Санкт-Петербург', uz: 'Sankt-Peterburg' }, lat: 59.9343, lng: 30.3351 } },
  { code: 'RU-MOS', slug: 'moscow_oblast', names: { ar: 'محافظة موسكو', en: 'Moscow Oblast', ru: 'Московская область', ky: 'Москва облусу', uz: 'Moskva viloyati' }, hub: { slug: 'krasnogorsk', names: { ar: 'كراسنوغورسك', en: 'Krasnogorsk', ru: 'Красногорск', ky: 'Красногорск', uz: 'Krasnogorsk' }, lat: 55.8225, lng: 37.3181 } },
  { code: 'RU-LEN', slug: 'leningrad', names: { ar: 'محافظة لينينغراد', en: 'Leningrad Oblast', ru: 'Ленинградская область', ky: 'Ленинград облусу', uz: 'Leningrad viloyati' }, hub: { slug: 'gatchina', names: { ar: 'غاتتشينا', en: 'Gatchina', ru: 'Гатчина', ky: 'Гатчина', uz: 'Gatchina' }, lat: 59.5764, lng: 30.1283 } },
  { code: 'RU-TA', slug: 'tatarstan', names: { ar: 'تتارستان', en: 'Tatarstan', ru: 'Татарстан', ky: 'Татарстан', uz: 'Tatariston' }, hub: { slug: 'kazan', names: { ar: 'قازان', en: 'Kazan', ru: 'Казань', ky: 'Казан', uz: 'Qozon' }, lat: 55.7961, lng: 49.1064 } },
  { code: 'RU-BA', slug: 'bashkortostan', names: { ar: 'باشكورتوستان', en: 'Bashkortostan', ru: 'Башкортостан', ky: 'Башкортостан', uz: 'Boshqirdiston' }, hub: { slug: 'ufa', names: { ar: 'أوفا', en: 'Ufa', ru: 'Уфа', ky: 'Уфа', uz: 'Ufa' }, lat: 54.7388, lng: 55.9721 } },
  { code: 'RU-DA', slug: 'dagestan', names: { ar: 'داغستان', en: 'Dagestan', ru: 'Дагестан', ky: 'Дагестан', uz: 'Dogʻiston' }, hub: { slug: 'makhachkala', names: { ar: 'محج قلعة', en: 'Makhachkala', ru: 'Махачкала', ky: 'Махачкала', uz: 'Maxachqala' }, lat: 42.9849, lng: 47.5047 } },
  { code: 'RU-KDA', slug: 'krasnodar', names: { ar: 'كراسنودار كراي', en: 'Krasnodar Krai', ru: 'Краснодарский край', ky: 'Краснодар крайы', uz: 'Krasnodar oʻlkasi' }, hub: { slug: 'krasnodar', names: { ar: 'كراسنودار', en: 'Krasnodar', ru: 'Краснодар', ky: 'Краснодар', uz: 'Krasnodar' }, lat: 45.0355, lng: 38.9753 } },
  { code: 'RU-KC', slug: 'karachay_cherkess', names: { ar: 'قرتشاي شركيسيا', en: 'Karachay-Cherkessia', ru: 'Карачаево-Черкесия', ky: 'Карачай-Черкесия', uz: 'Qorachoy-Cherkesiya' }, hub: { slug: 'cherkessk', names: { ar: 'تشيركيسك', en: 'Cherkessk', ru: 'Черкесск', ky: 'Черкесск', uz: 'Cherkessk' }, lat: 44.2269, lng: 42.0468 } },
  { code: 'RU-KB', slug: 'kabardino_balkaria', names: { ar: 'قبردينو بلقاريا', en: 'Kabardino-Balkaria', ru: 'Кабардино-Балкария', ky: 'Кабардино-Балкария', uz: 'Kabardino-Balkariya' }, hub: { slug: 'nalchik', names: { ar: 'نالتشيك', en: 'Nalchik', ru: 'Нальчик', ky: 'Нальчик', uz: 'Nalchik' }, lat: 43.4853, lng: 43.6071 } },
  { code: 'RU-CE', slug: 'chechnya', names: { ar: 'الشيشان', en: 'Chechnya', ru: 'Чечня', ky: 'Чечня', uz: 'Checheniston' }, hub: { slug: 'grozny', names: { ar: 'غروزني', en: 'Grozny', ru: 'Грозный', ky: 'Грозный', uz: 'Grozniy' }, lat: 43.3186, lng: 45.6989 } },
  { code: 'RU-STA', slug: 'stavropol', names: { ar: 'ستافروبول كراي', en: 'Stavropol Krai', ru: 'Ставропольский край', ky: 'Ставрополь крайы', uz: 'Stavropol oʻlkasi' }, hub: { slug: 'stavropol', names: { ar: 'ستافروبول', en: 'Stavropol', ru: 'Ставрополь', ky: 'Ставрополь', uz: 'Stavropol' }, lat: 45.0428, lng: 41.9734 } },
  { code: 'RU-ROS', slug: 'rostov', names: { ar: 'محافظة روستوف', en: 'Rostov Oblast', ru: 'Ростовская область', ky: 'Ростов облусу', uz: 'Rostov viloyati' }, hub: { slug: 'rostov_on_don', names: { ar: 'روستوف على الدون', en: 'Rostov-on-Don', ru: 'Ростов-на-Дону', ky: 'Ростов-на-Дону', uz: 'Rostov-Don' }, lat: 47.2357, lng: 39.7015 } },
  { code: 'RU-SVE', slug: 'sverdlovsk', names: { ar: 'محافظة سفردلوفسك', en: 'Sverdlovsk Oblast', ru: 'Свердловская область', ky: 'Свердловск облусу', uz: 'Sverdlovsk viloyati' }, hub: { slug: 'yekaterinburg', names: { ar: 'يكاترينبورغ', en: 'Yekaterinburg', ru: 'Екатеринбург', ky: 'Екатеринбург', uz: 'Yekaterinburg' }, lat: 56.8389, lng: 60.6057 } },
  { code: 'RU-NVS', slug: 'novosibirsk', names: { ar: 'محافظة نوفوسيبيرسك', en: 'Novosibirsk Oblast', ru: 'Новосибирская область', ky: 'Новосибирск облусу', uz: 'Novosibirsk viloyati' }, hub: { slug: 'novosibirsk', names: { ar: 'نوفوسيبيرسك', en: 'Novosibirsk', ru: 'Новосибирск', ky: 'Новосибирск', uz: 'Novosibirsk' }, lat: 55.0084, lng: 82.9357 } },
  { code: 'RU-KYA', slug: 'krasnoyarsk', names: { ar: 'كراسنويارسك كراي', en: 'Krasnoyarsk Krai', ru: 'Красноярский край', ky: 'Красноярск крайы', uz: 'Krasnoyarsk oʻlkasi' }, hub: { slug: 'krasnoyarsk', names: { ar: 'كراسنويارسك', en: 'Krasnoyarsk', ru: 'Красноярск', ky: 'Красноярск', uz: 'Krasnoyarsk' }, lat: 56.0153, lng: 92.8932 } },
  { code: 'RU-IRK', slug: 'irkutsk', names: { ar: 'محافظة إيركوتسك', en: 'Irkutsk Oblast', ru: 'Иркутская область', ky: 'Иркутск облусу', uz: 'Irkutsk viloyati' }, hub: { slug: 'irkutsk', names: { ar: 'إيركوتسك', en: 'Irkutsk', ru: 'Иркутск', ky: 'Иркутск', uz: 'Irkutsk' }, lat: 52.287, lng: 104.305 } },
  { code: 'RU-PRI', slug: 'primorsky', names: { ar: 'بريمورسكي كراي', en: 'Primorsky Krai', ru: 'Приморский край', ky: 'Приморье крайы', uz: 'Primorye oʻlkasi' }, hub: { slug: 'vladivostok', names: { ar: 'فلاديفوستوك', en: 'Vladivostok', ru: 'Владивосток', ky: 'Владивосток', uz: 'Vladivostok' }, lat: 43.1155, lng: 131.8855 } },
  { code: 'RU-KAM', slug: 'kamchatka', names: { ar: 'كامتشاتكا كراي', en: 'Kamchatka Krai', ru: 'Камчатский край', ky: 'Камчатка крайы', uz: 'Kamchatka oʻlkasi' }, hub: { slug: 'petropavlovsk', names: { ar: 'بيتروبافلوفسك', en: 'Petropavlovsk-Kamchatsky', ru: 'Петропавловск-Камчатский', ky: 'Петропавловск-Камчатский', uz: 'Petropavlovsk-Kamchatskiy' }, lat: 53.037, lng: 158.6559 } },
  { code: 'RU-SA', slug: 'sakha', names: { ar: 'ياقوتيا (ساخا)', en: 'Sakha (Yakutia)', ru: 'Саха (Якутия)', ky: 'Саха (Якутия)', uz: 'Saxa (Yakutiya)' }, hub: { slug: 'yakutsk', names: { ar: 'ياكوتسك', en: 'Yakutsk', ru: 'Якутск', ky: 'Якутск', uz: 'Yakutsk' }, lat: 62.0355, lng: 129.6755 } },
];

/** @deprecated alias — use RU_REGIONS */
const RU_REGIONS_CHECKPOINT = RU_REGIONS;

const COUNTRIES = {
  SA: {
    id: 'country_sa',
    iso2: 'SA',
    iso3: 'SAU',
    currencyCode: 'SAR',
    currencySymbol: 'ر.س',
    phoneCode: '+966',
    timezone: 'Asia/Riyadh',
    firestoreDocId: 'saudi_arabia',
    names: { ar: 'المملكة العربية السعودية', en: 'Saudi Arabia', ru: 'Саудовская Аравия', ky: 'Сауд Арабиясы', uz: 'Saudiya Arabistoni' },
    regions: SA_REGIONS,
    overpassIsoPrefix: 'SA-',
    overpassIsoField: 'iso',
  },
  KG: {
    id: 'country_kg',
    iso2: 'KG',
    iso3: 'KGZ',
    currencyCode: 'KGS',
    currencySymbol: 'с',
    phoneCode: '+996',
    timezone: 'Asia/Bishkek',
    firestoreDocId: 'kyrgyzstan',
    names: { ar: 'قيرغيزستان', en: 'Kyrgyzstan', ru: 'Кыргызстан', ky: 'Кыргызстан', uz: 'Qirgʻiziston' },
    regions: KG_REGIONS,
    curatedLandmarksFile: 'kyrgyzstan_landmarks_20.json',
  },
  UZ: {
    id: 'country_uz',
    iso2: 'UZ',
    iso3: 'UZB',
    currencyCode: 'UZS',
    currencySymbol: "so'm",
    phoneCode: '+998',
    timezone: 'Asia/Tashkent',
    firestoreDocId: 'uzbekistan',
    names: { ar: 'أوزبكستان', en: 'Uzbekistan', ru: 'Узбекистан', ky: 'Өзбекстан', uz: 'Oʻzbekiston' },
    regions: UZ_REGIONS,
    overpassIsoPrefix: '',
    overpassIsoField: 'code',
  },
  RU: {
    id: 'country_ru',
    iso2: 'RU',
    iso3: 'RUS',
    currencyCode: 'RUB',
    currencySymbol: '₽',
    phoneCode: '+7',
    timezone: 'Europe/Moscow',
    firestoreDocId: 'russia',
    names: { ar: 'روسيا', en: 'Russia', ru: 'Россия', ky: 'Россия', uz: 'Rossiya' },
    regions: RU_REGIONS,
    note: 'Wave-1 tourist priority subjects (20). Full federal list can be added later.',
    overpassIsoPrefix: '',
    overpassIsoField: 'code',
  },
};

module.exports = {
  LANGS,
  COUNTRIES,
  SA_REGIONS,
  KG_REGIONS,
  UZ_REGIONS,
  RU_REGIONS,
  RU_REGIONS_CHECKPOINT,
};
