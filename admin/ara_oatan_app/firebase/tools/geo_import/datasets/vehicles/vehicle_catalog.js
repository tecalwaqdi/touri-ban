'use strict';

/**
 * Vehicle categories + make/model catalog for Touri Taxi markets (SA, KG, UZ, RU).
 * No brand logos. Images optional and must be licensed separately.
 * Dry-run by default — maps to Firestore `type_car` categories.
 */

const CATEGORIES = [
  { code: 'economy', seats: 4, luggage: 2, names: { ar: 'اقتصادية', en: 'Economy', ru: 'Эконом', ky: 'Эконом', uz: 'Ekonom' }, hourlyRate: 160, minHours: 4 },
  { code: 'compact', seats: 4, luggage: 2, names: { ar: 'مدمجة', en: 'Compact', ru: 'Компакт', ky: 'Компакт', uz: 'Kompakt' }, hourlyRate: 170, minHours: 4 },
  { code: 'sedan_standard', seats: 4, luggage: 2, names: { ar: 'سيدان قياسية', en: 'Standard Sedan', ru: 'Стандартный седан', ky: 'Стандарт седан', uz: 'Standart sedan' }, hourlyRate: 180, minHours: 4 },
  { code: 'comfort', seats: 4, luggage: 2, names: { ar: 'مريحة', en: 'Comfort', ru: 'Комфорт', ky: 'Комфорт', uz: 'Komfort' }, hourlyRate: 210, minHours: 4 },
  { code: 'premium', seats: 4, luggage: 2, names: { ar: 'ممتازة', en: 'Premium', ru: 'Премиум', ky: 'Премиум', uz: 'Premium' }, hourlyRate: 320, minHours: 4 },
  { code: 'business', seats: 4, luggage: 2, names: { ar: 'أعمال', en: 'Business', ru: 'Бизнес', ky: 'Бизнес', uz: 'Biznes' }, hourlyRate: 280, minHours: 4 },
  { code: 'luxury', seats: 4, luggage: 2, names: { ar: 'فاخرة', en: 'Luxury', ru: 'Люкс', ky: 'Люкс', uz: 'Lyuks' }, hourlyRate: 480, minHours: 5 },
  { code: 'suv_compact', seats: 5, luggage: 3, names: { ar: 'SUV مدمجة', en: 'SUV Compact', ru: 'Компактный SUV', ky: 'Ыкчам SUV', uz: 'Kompakt SUV' }, hourlyRate: 260, minHours: 4 },
  { code: 'suv_standard', seats: 5, luggage: 4, names: { ar: 'SUV قياسية', en: 'SUV Standard', ru: 'Стандартный SUV', ky: 'Стандарт SUV', uz: 'Standart SUV' }, hourlyRate: 300, minHours: 4 },
  { code: 'suv_large', seats: 7, luggage: 5, names: { ar: 'SUV كبيرة', en: 'SUV Large', ru: 'Большой SUV', ky: 'Чоң SUV', uz: 'Katta SUV' }, hourlyRate: 380, minHours: 5 },
  { code: 'suv_family', seats: 7, luggage: 5, names: { ar: 'SUV عائلية', en: 'Family SUV', ru: 'Семейный SUV', ky: 'Үй-бүлөлүк SUV', uz: 'Oilaviy SUV' }, hourlyRate: 320, minHours: 4 },
  { code: 'offroad_4x4', seats: 5, luggage: 3, names: { ar: 'دفع رباعي', en: '4x4', ru: 'Полный привод 4x4', ky: '4x4', uz: '4x4' }, hourlyRate: 340, minHours: 4 },
  { code: 'pickup_4x4', seats: 5, luggage: 4, names: { ar: 'بيك أب 4x4', en: '4x4 Pickup', ru: 'Пикап 4x4', ky: '4x4 пикап', uz: '4x4 pikap' }, hourlyRate: 300, minHours: 4 },
  { code: 'minivan', seats: 7, luggage: 4, names: { ar: 'ميني فان', en: 'Minivan', ru: 'Минивэн', ky: 'Минивэн', uz: 'Miniven' }, hourlyRate: 340, minHours: 5 },
  { code: 'van_family', seats: 8, luggage: 5, names: { ar: 'فان عائلي', en: 'Family Van', ru: 'Семейный минивэн', ky: 'Үй-бүлөлүк минивэн', uz: 'Oilaviy miniven' }, hourlyRate: 360, minHours: 5 },
  { code: 'van_vip', seats: 7, luggage: 4, names: { ar: 'فان VIP', en: 'VIP Van', ru: 'VIP минивэн', ky: 'VIP минивэн', uz: 'VIP miniven' }, hourlyRate: 450, minHours: 5 },
  { code: 'coach_mini', seats: 14, luggage: 8, names: { ar: 'ميني باص', en: 'Minibus', ru: 'Мини-автобус', ky: 'Кичи автобус', uz: 'Miniavtobus' }, hourlyRate: 600, minHours: 6, isBusLike: true },
  { code: 'coach_tour', seats: 45, luggage: 20, names: { ar: 'باص سياحي', en: 'Tour Bus', ru: 'Туристический автобус', ky: 'Туристтик автобус', uz: 'Turistik avtobus' }, hourlyRate: 900, minHours: 6, isBusLike: true },
  { code: 'executive_shuttle', seats: 12, luggage: 8, names: { ar: 'شاتل تنفيذي', en: 'Executive Shuttle', ru: 'Представительский шаттл', ky: 'Аткаруучу шаттл', uz: 'Ijro shattli' }, hourlyRate: 700, minHours: 6, isBusLike: true },
  { code: 'electric', seats: 5, luggage: 2, names: { ar: 'كهربائية', en: 'Electric', ru: 'Электромобиль', ky: 'Электромобиль', uz: 'Elektromobil' }, hourlyRate: 250, minHours: 4 },
  { code: 'hybrid', seats: 5, luggage: 2, names: { ar: 'هجينة', en: 'Hybrid', ru: 'Гибрид', ky: 'Гибрид', uz: 'Gibrid' }, hourlyRate: 230, minHours: 4 },
  { code: 'wheelchair', seats: 4, luggage: 2, names: { ar: 'مجهزة لكرسي متحرك', en: 'Wheelchair Accessible', ru: 'Для инвалидных колясок', ky: 'Майыптар үчүн', uz: 'Nogironlar aravachasi uchun' }, hourlyRate: 280, minHours: 4 },
  { code: 'airport_transfer', seats: 4, luggage: 3, names: { ar: 'نقل مطار', en: 'Airport Transfer', ru: 'Трансфер в аэропорт', ky: 'Аэропорт трансфери', uz: 'Aeroport transferi' }, hourlyRate: 220, minHours: 3 },
  { code: 'tourist_vehicle', seats: 7, luggage: 4, names: { ar: 'مركبة سياحية', en: 'Tourist Vehicle', ru: 'Туристический транспорт', ky: 'Туристтик унаа', uz: 'Turistik transport' }, hourlyRate: 350, minHours: 5 },
];

/** Makes/models common in target markets — verified as widely sold, not exhaustive exclusivity claims. */
const MODELS = [
  { make: 'Toyota', model: 'Camry', categoryIds: ['sedan_standard', 'comfort', 'business'], seats: 5, luggage: 2, years: [2018, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Toyota', model: 'Corolla', categoryIds: ['economy', 'compact', 'sedan_standard'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Toyota', model: 'Yaris', categoryIds: ['economy', 'compact'], seats: 5, luggage: 1, years: [2016, 2026], countries: ['SA', 'UZ'] },
  { make: 'Toyota', model: 'Land Cruiser', categoryIds: ['suv_large', 'offroad_4x4', 'luxury'], seats: 7, luggage: 5, years: [2010, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Toyota', model: 'Prado', categoryIds: ['suv_standard', 'offroad_4x4', 'suv_family'], seats: 7, luggage: 4, years: [2010, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Toyota', model: 'RAV4', categoryIds: ['suv_compact', 'suv_standard', 'hybrid'], seats: 5, luggage: 3, years: [2015, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Toyota', model: 'Hiace', categoryIds: ['van_family', 'minivan', 'airport_transfer'], seats: 12, luggage: 6, years: [2010, 2026], countries: ['SA', 'KG', 'UZ'] },
  { make: 'Toyota', model: 'Coaster', categoryIds: ['coach_mini', 'tourist_vehicle'], seats: 22, luggage: 10, years: [2010, 2026], countries: ['SA', 'UZ'] },
  { make: 'Hyundai', model: 'Elantra', categoryIds: ['economy', 'sedan_standard', 'comfort'], seats: 5, luggage: 2, years: [2016, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Hyundai', model: 'Sonata', categoryIds: ['comfort', 'business'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Hyundai', model: 'Tucson', categoryIds: ['suv_compact', 'suv_standard'], seats: 5, luggage: 3, years: [2016, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Hyundai', model: 'Santa Fe', categoryIds: ['suv_family', 'suv_standard'], seats: 7, luggage: 4, years: [2015, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Hyundai', model: 'Staria', categoryIds: ['van_family', 'minivan', 'van_vip'], seats: 9, luggage: 5, years: [2021, 2026], countries: ['SA', 'UZ'] },
  { make: 'Hyundai', model: 'H-1 / Starex', categoryIds: ['van_family', 'airport_transfer'], seats: 9, luggage: 5, years: [2010, 2024], countries: ['SA', 'KG', 'UZ'] },
  { make: 'Kia', model: 'K5 / Optima', categoryIds: ['comfort', 'business'], seats: 5, luggage: 2, years: [2016, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Kia', model: 'Sportage', categoryIds: ['suv_compact', 'suv_standard'], seats: 5, luggage: 3, years: [2016, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Kia', model: 'Sorento', categoryIds: ['suv_family', 'suv_large'], seats: 7, luggage: 4, years: [2015, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Kia', model: 'Carnival', categoryIds: ['van_family', 'minivan', 'van_vip'], seats: 8, luggage: 5, years: [2015, 2026], countries: ['SA', 'UZ'] },
  { make: 'Nissan', model: 'Sunny / Almera', categoryIds: ['economy', 'sedan_standard'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'UZ'] },
  { make: 'Nissan', model: 'Patrol', categoryIds: ['suv_large', 'offroad_4x4', 'luxury'], seats: 7, luggage: 5, years: [2010, 2026], countries: ['SA', 'UZ'] },
  { make: 'Nissan', model: 'X-Trail', categoryIds: ['suv_standard', 'suv_family'], seats: 5, luggage: 3, years: [2015, 2026], countries: ['SA', 'KG', 'UZ', 'RU'] },
  { make: 'Lexus', model: 'ES', categoryIds: ['premium', 'business', 'luxury'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'KG', 'RU'] },
  { make: 'Lexus', model: 'LX', categoryIds: ['luxury', 'suv_large'], seats: 7, luggage: 5, years: [2015, 2026], countries: ['SA', 'KG', 'RU'] },
  { make: 'Chevrolet', model: 'Tahoe', categoryIds: ['suv_standard', 'suv_family'], seats: 7, luggage: 4, years: [2015, 2026], countries: ['SA', 'UZ'] },
  { make: 'Chevrolet', model: 'Tahoe Tracker', categoryIds: ['suv_compact'], seats: 5, luggage: 3, years: [2019, 2026], countries: ['UZ'] },
  { make: 'Chevrolet', model: 'Cobalt', categoryIds: ['economy', 'sedan_standard'], seats: 5, luggage: 2, years: [2013, 2026], countries: ['UZ'] },
  { make: 'Chevrolet', model: 'Damas', categoryIds: ['minivan', 'economy'], seats: 7, luggage: 2, years: [2010, 2026], countries: ['UZ'] },
  { make: 'GMC', model: 'Yukon', categoryIds: ['suv_large', 'luxury'], seats: 7, luggage: 5, years: [2015, 2026], countries: ['SA'] },
  { make: 'Ford', model: 'Explorer', categoryIds: ['suv_family', 'suv_large'], seats: 7, luggage: 4, years: [2015, 2026], countries: ['SA', 'RU'] },
  { make: 'Mercedes-Benz', model: 'E-Class', categoryIds: ['business', 'premium', 'luxury'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'KG', 'RU'] },
  { make: 'Mercedes-Benz', model: 'S-Class', categoryIds: ['luxury'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'RU'] },
  { make: 'Mercedes-Benz', model: 'V-Class / Vito', categoryIds: ['van_vip', 'van_family', 'airport_transfer'], seats: 7, luggage: 4, years: [2015, 2026], countries: ['SA', 'KG', 'RU', 'UZ'] },
  { make: 'Mercedes-Benz', model: 'Sprinter', categoryIds: ['coach_mini', 'tourist_vehicle'], seats: 16, luggage: 8, years: [2010, 2026], countries: ['SA', 'KG', 'RU', 'UZ'] },
  { make: 'BMW', model: '5 Series', categoryIds: ['business', 'premium'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'KG', 'RU'] },
  { make: 'BMW', model: 'X5', categoryIds: ['suv_standard', 'premium', 'luxury'], seats: 5, luggage: 4, years: [2015, 2026], countries: ['SA', 'KG', 'RU'] },
  { make: 'Audi', model: 'A6', categoryIds: ['business', 'premium'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['SA', 'RU'] },
  { make: 'Volkswagen', model: 'Polo', categoryIds: ['economy', 'compact'], seats: 5, luggage: 1, years: [2015, 2026], countries: ['RU', 'UZ'] },
  { make: 'Volkswagen', model: 'Tiguan', categoryIds: ['suv_compact', 'suv_standard'], seats: 5, luggage: 3, years: [2016, 2026], countries: ['SA', 'RU'] },
  { make: 'Volkswagen', model: 'Caravelle / Multivan', categoryIds: ['van_family', 'van_vip'], seats: 7, luggage: 4, years: [2015, 2026], countries: ['SA', 'RU'] },
  { make: 'Skoda', model: 'Octavia', categoryIds: ['comfort', 'sedan_standard'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['RU', 'UZ'] },
  { make: 'Renault', model: 'Duster', categoryIds: ['suv_compact', 'offroad_4x4'], seats: 5, luggage: 3, years: [2015, 2026], countries: ['RU', 'UZ'] },
  { make: 'Lada', model: 'Vesta', categoryIds: ['economy', 'sedan_standard'], seats: 5, luggage: 2, years: [2015, 2026], countries: ['RU', 'KG'] },
  { make: 'Lada', model: 'Niva / Niva Travel', categoryIds: ['offroad_4x4', 'economy'], seats: 4, luggage: 2, years: [2010, 2026], countries: ['RU', 'KG'] },
  { make: 'UAZ', model: 'Patriot', categoryIds: ['offroad_4x4', 'suv_standard'], seats: 5, luggage: 3, years: [2010, 2026], countries: ['RU', 'KG'] },
  { make: 'GAZ', model: 'Gazelle Next', categoryIds: ['coach_mini', 'tourist_vehicle'], seats: 14, luggage: 6, years: [2015, 2026], countries: ['RU', 'KG', 'UZ'] },
  { make: 'BYD', model: 'Song / Seal family', categoryIds: ['electric', 'hybrid', 'suv_compact'], seats: 5, luggage: 3, years: [2022, 2026], countries: ['UZ', 'RU'] },
  { make: 'Geely', model: 'Coolray / Monjaro', categoryIds: ['suv_compact', 'suv_standard'], seats: 5, luggage: 3, years: [2020, 2026], countries: ['UZ', 'RU', 'KG'] },
  { make: 'Chery', model: 'Tiggo 7/8', categoryIds: ['suv_compact', 'suv_family'], seats: 5, luggage: 3, years: [2019, 2026], countries: ['UZ', 'RU', 'KG', 'SA'] },
  { make: 'Haval', model: 'Jolion / H6', categoryIds: ['suv_compact', 'suv_standard'], seats: 5, luggage: 3, years: [2020, 2026], countries: ['RU', 'UZ', 'SA'] },
  { make: 'Jetour', model: 'X70 / Dashing', categoryIds: ['suv_family', 'suv_standard'], seats: 7, luggage: 4, years: [2021, 2026], countries: ['SA', 'UZ'] },
];

function toTypeCarPreview(cat) {
  return {
    path: `type_car/${cat.code}`,
    data: {
      naim: cat.names.ar,
      names_i18n: cat.names,
      codeCar: cat.code,
      sr: cat.hourlyRate,
      agl_saat: cat.minHours,
      actev: true,
      ishafelh: !!cat.isBusLike,
      not: cat.names.en,
      geo_import_id: `vehcat_${cat.code}`,
    },
    wouldWrite: false,
  };
}

function catalogReport() {
  return {
    generatedAt: new Date().toISOString(),
    wouldWriteToFirestore: false,
    categories: CATEGORIES.length,
    models: MODELS.length,
    modelsByCountry: {
      SA: MODELS.filter((m) => m.countries.includes('SA')).length,
      KG: MODELS.filter((m) => m.countries.includes('KG')).length,
      UZ: MODELS.filter((m) => m.countries.includes('UZ')).length,
      RU: MODELS.filter((m) => m.countries.includes('RU')).length,
    },
    typeCarPreview: CATEGORIES.map(toTypeCarPreview),
    models: MODELS,
    note: 'Categories map to type_car. Make/model catalog is reference data for Admin linking; no logos included.',
  };
}

module.exports = {
  CATEGORIES,
  MODELS,
  toTypeCarPreview,
  catalogReport,
};
