/// مفاتيح اللغات المدعومة في محتوى Firestore (مطابقة للتطبيق).
const List<String> touryI18nLocaleKeys = [
  'ar',
  'en',
  'zh_Hans',
  'tr',
  'ur',
  'ru',
  'az',
  'ka',
  'ky',
  'fr',
  'id',
];

const Map<String, String> touryI18nLocaleLabels = {
  'ar': 'العربية',
  'en': 'English',
  'zh_Hans': '中文',
  'tr': 'Türkçe',
  'ur': 'اردو',
  'ru': 'Русский',
  'az': 'Azərbaycan',
  'ka': 'ქართული',
  'ky': 'Кыргызча',
  'fr': 'Français',
  'id': 'Indonesia',
};

String touryI18nLabel(String localeKey) =>
    touryI18nLocaleLabels[localeKey] ?? localeKey;
