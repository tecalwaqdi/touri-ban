import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/core/driver_locale_loader.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => [
        'en',
        'ar',
        'ru',
        'ky',
        'fr',
        'ur',
        'pt',
      ];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) {
    final map = kTranslationsMap[key] ?? {};
    final lang = locale.toString();

    final direct = map[lang];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final en = map['en'] ?? '';
    if (en.isEmpty) {
      return '';
    }

    if (lang == 'en') {
      return en;
    }
    if (lang == 'ar') {
      final ar = map['ar'];
      return (ar != null && ar.isNotEmpty) ? ar : en;
    }

    try {
      final translated = DriverCachedAssetLoader.translate(en, locale);
      if (translated != null && translated.isNotEmpty) {
        return translated;
      }
    } catch (_) {}

    return en;
  }

  String getVariableText({
    String? enText = '',
    String? arText = '',
    String? ruText = '',
    String? kyText = '',
    String? frText = '',
    String? urText = '',
    String? ptText = '',
  }) {
    // Never index [en, ar] by languageIndex — ru/ky are 2/3 and throw RangeError.
    switch (languageCode) {
      case 'ar':
        return (arText != null && arText.isNotEmpty) ? arText : (enText ?? '');
      case 'ru':
        if (ruText != null && ruText.isNotEmpty) return ruText;
        return (enText ?? '');
      case 'ky':
        if (kyText != null && kyText.isNotEmpty) return kyText;
        if (ruText != null && ruText.isNotEmpty) return ruText;
        return (enText ?? '');
      case 'fr':
        return (frText != null && frText.isNotEmpty) ? frText : (enText ?? '');
      case 'ur':
        return (urText != null && urText.isNotEmpty) ? urText : (enText ?? '');
      case 'pt':
        return (ptText != null && ptText.isNotEmpty) ? ptText : (enText ?? '');
      default:
        return enText ?? '';
    }
  }

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // Login1
  {
    'fl8vzh1e': {
      'en': 'Welcome Back',
      'ar': 'مرحبًا بعودتك',
    },
    '5xhefls4': {
      'en': 'Let\'s get started by filling out the form below.',
      'ar': 'لنبدأ بملء النموذج أدناه.',
    },
    '7cawtif0': {
      'en': 'Email',
      'ar': 'بريد إلكتروني',
    },
    'owolsfc8': {
      'en': 'Password',
      'ar': 'كلمة المرور',
    },
    'me4pz27r': {
      'en': 'Sign In',
      'ar': 'تسجيل الدخول',
    },
    'q6t722yp': {
      'en': 'Do you want to register?',
      'ar': 'هل تريد التسجيل؟',
    },
    '7cmkrk70': {
      'en': '  ',
      'ar': '  ',
    },
    'h1ev5ljd': {
      'en': ' Register now ',
      'ar': 'سجل الآن',
    },
    'ix8ofow7': {
      'en': 'Terms of Service and Privacy Policy',
      'ar': 'شروط الخدمة وسياسة الخصوصية',
    },
    '7ip6fv5p': {
      'en': ' ',
      'ar': ' ',
    },
    'm5j0ga8s': {
      'en': 'Click here',
      'ar': 'انقر هنا',
    },
    'd7j05t87': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // hgzCopy
  {
    '149brpxm': {
      'en': 'Accepted requests',
      'ar': 'الطلبات المقبولة',
    },
    'vo93ynka': {
      'en': 'accepted',
      'ar': 'مقبول',
    },
  },
  // Dashboard5
  {
    'lfh3vael': {
      'en': 'your trip summary with Ara Watn',
      'ar': 'ملخص رحلتك مع ارى وطن ',
    },
    'j4r154r2': {
      'en': 'new orders',
      'ar': 'طلبات جديدة',
    },
    'u24lsc83': {
      'en': 'accepted',
      'ar': 'مقبول',
    },
    'yy5saxnw': {
      'en': 'completed',
      'ar': 'مكتمل',
    },
    'dp9ecfbr': {
      'en': 'Earnings',
      'ar': 'الأرباح',
    },
    'r4ydq56s': {
      'en': '0',
      'ar': '0',
    },
    'qhuxrhn3': {
      'en': 'Route progress',
      'ar': 'تقدم المسار',
    },
    '1ounnxi7': {
      'en': 'App Commissions',
      'ar': 'عمولات التطبيق',
    },
    'jppwdodb': {
      'en': 'Route progress',
      'ar': 'تقدم المسار',
    },
    'h71b8v5h': {
      'en': 'Dashboard',
      'ar': 'لوحة القيادة',
    },
    'xojc2b6z': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // Profile07
  {
    '11lqnn52': {
      'en': 'Receiving bookings',
      'ar': 'تلقي الحجوزات',
    },
    'g5iyasoo': {
      'en': 'Have a problem? Contact us directly.',
      'ar': 'هل لديك مشكلة؟ تواصل معنا مباشرةً',
    },
    '4627kcfu': {
      'en': 'Bank account update',
      'ar': 'تحديث الحساب البنكي',
    },
    'jso22q9p': {
      'en': 'Log Out',
      'ar': 'تسجيل الخروج',
    },
    'njmac6gm': {
      'en': 'Delete account',
      'ar': 'حذف الحساب',
    },
    '8w8yyua6': {
      'en': 'My account',
      'ar': 'حسابي',
    },
  },
  // mktmlh
  {
    'h2tehj88': {
      'en': 'completed',
      'ar': 'مكتمل',
    },
    '2alqe9c4': {
      'en': 'Completed',
      'ar': 'مكتمل',
    },
  },
  // tfaselCopy
  {
    '4survi6d': {
      'en': 'تفاصيل',
      'ar': 'تفاصيل',
    },
    'aduyy2vy': {
      'en': 'Trip Status',
      'ar': 'حالة الرحلة',
    },
    'y21gdqqn': {
      'en': 'Completed',
      'ar': 'مكتملة',
    },
    '1fhe8dnl': {
      'en': 'Customer Rating',
      'ar': 'تقييم العميل',
    },
    'q9cmhhoe': {
      'en': 'Trip Actions',
      'ar': 'إجراءات الرحلة',
    },
    '4tuynkyb': {
      'en': 'Accept Order',
      'ar': 'قبول الطلب',
    },
    'qjcxve5z': {
      'en': 'Customer Location',
      'ar': 'موقع العميل',
    },
    'lqmmaqas': {
      'en':
          'The customer is currently waiting for you. Please proceed to their location.',
      'ar': 'العميل بانتظارك حاليًا... يُرجى التوجه إلى موقعه',
    },
    'gudsdr7r': {
      'en': 'Start Trip',
      'ar': 'تم الوصول وبدء الرحلة ',
    },
    'bk9pyb5l': {
      'en': 'End Trip',
      'ar': 'إنهاء الرحلة',
    },
    'w6lgumpj': {
      'en': 'Start Time',
      'ar': 'وقت البدء',
    },
    'ghwqsbah': {
      'en': 'End Time',
      'ar': 'وقت النهاية',
    },
    'c4ysn23b': {
      'en': 'Customer Information',
      'ar': 'معلومات العميل',
    },
    'b9voi72j': {
      'en': 'Chat',
      'ar': 'محادثة',
    },
    'l3jg8fh1': {
      'en': 'Order Information',
      'ar': 'معلومات الطلب',
    },
    '8nz8f9es': {
      'en': 'Order Number:',
      'ar': 'رقم الطلب:',
    },
    'iigr8jxx': {
      'en': 'Order Date:',
      'ar': 'تاريخ الطلب:',
    },
    'omp4ebqj': {
      'en': 'Total Hours:',
      'ar': 'إجمالي الساعات:',
    },
    'wmn0k8fz': {
      'en': 'Total Trip Amount:',
      'ar': 'إجمالي مبلغ الرحلة:',
    },
    'b7t96vqf': {
      'en': 'Earnings:',
      'ar': 'الأرباح (لك):',
    },
    'p3pcrjj4': {
      'en': 'App Commission & Taxes:',
      'ar': 'عمولة التطبيق والضرائب:',
    },
    '4vzrpq02': {
      'en': 'Stops',
      'ar': ' الأماكن',
    },
    'sz4f4ea8': {
      'en': 'Map',
      'ar': 'خريطة',
    },
    'ill8dbmq': {
      'en': 'Restaurant',
      'ar': 'مطعم',
    },
    '73039wfk': {
      'en': 'Second Stop',
      'ar': 'المحطة الثانية',
    },
    'r2h0gjdw': {
      'en': 'View on Map',
      'ar': 'عرض على الخريطة',
    },
    'g4g6g5ye': {
      'en': 'Beach Resort',
      'ar': 'منتجع شاطئي',
    },
    'glltr1os': {
      'en': 'Final Destination',
      'ar': 'الوجهة النهائية',
    },
    'smap08gd': {
      'en': 'View on Map',
      'ar': 'عرض على الخريطة',
    },
    'b9xqeiej': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // hgzmgbol
  {
    'hdaiynu7': {
      'en': '  ',
      'ar': '',
    },
    'bpdu8zit': {
      'en': ' -destinations',
      'ar': '-الوجهات',
    },
    '51s9tp7q': {
      'en': '   -Hours ',
      'ar': '-ساعات',
    },
    '9sco8cez': {
      'en': ' R.S ',
      'ar': 'ر.س',
    },
    'kkx0okx7': {
      'en': 'Your account is inactive.',
      'ar': 'حسابك غير نشط.',
    },
    '0p9o2sn0': {
      'en': 'New requests',
      'ar': 'طلبات جديدة',
    },
    '8n5hn863': {
      'en': 'Accepted',
      'ar': 'مقبول',
    },
  },
  // hgzmktml
  {
    'b8uuolxj': {
      'en': '  ',
      'ar': '',
    },
    'z0fe4fs9': {
      'en': ' -destinations',
      'ar': '-الوجهات',
    },
    'bw7me4da': {
      'en': '   -Hours ',
      'ar': '-ساعات',
    },
    'fo2hdffy': {
      'en': ' R.S ',
      'ar': 'ر.س',
    },
    'd4nr29xa': {
      'en': 'Your account is inactive.',
      'ar': 'حسابك غير نشط.',
    },
    'aoy8mqp6': {
      'en':
          'You cannot accept new bookings as you have an ongoing reservation.',
      'ar': 'لا يمكنك قبول حجوزات جديدة لأن لديك حجزًا مستمرًا.',
    },
    'zp7s0q7u': {
      'en': 'Completed',
      'ar': 'مكتمل',
    },
    'xh3ye9pz': {
      'en': 'Completed',
      'ar': 'مكتمل',
    },
  },
  // reg_compne
  {
    'jbty0rd1': {
      'en': 'تسجيل الشركات في أرى وطن',
      'ar': 'الرئيسية',
    },
    '7y3s4gp6': {
      'en': 'معلومات الشركة',
      'ar': 'معلومات الشركة',
    },
    'eni9yuvm': {
      'en': 'رقم السجل التجاري',
      'ar': 'رقم السجل التجاري',
    },
    'pg9q8k9q': {
      'en': 'رقم هوية الشركة أو الفرد',
      'ar': 'رقم هوية الشركة أو الفرد',
    },
    'kykweopk': {
      'en': ' +966 رقم الهاتف',
      'ar': '+966 رقم الهاتف',
    },
    '6br81xy1': {
      'en': 'تاريخ إصدار السجل (هجري)',
      'ar': 'تاريخ الإصدار سجل (هجري)',
    },
    'l3dtyarc': {
      'en': 'رقم التحويلة (اختياري)',
      'ar': 'رقم المحول (اختياري)',
    },
    '7a9dg36g': {
      'en': 'البريد الإلكتروني للشركة',
      'ar': 'البريد الإلكتروني للشركة',
    },
    'qu2tg2ig': {
      'en': 'رقم السجل التجاري is required',
      'ar': 'مطلوب رقم السجل التجاري',
    },
    'cts7190c': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'km4seyw4': {
      'en': 'رقم هوية الشركة أو الفرد is required',
      'ar': 'مطلوب رقم هوية الشركة أو الفرد',
    },
    '2tqed8qz': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'mpqms96k': {
      'en': ' +966 رقم الهاتف is required',
      'ar': 'مطلوب رقم الهاتف +966',
    },
    'zp2zshf5': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'uihz2efs': {
      'en': 'تاريخ إصدار السجل (هجري) is required',
      'ar': 'مطلوب تاريخ الإصدار (سجل هجري).',
    },
    '0sor5qb5': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    '31nak9tl': {
      'en': 'رقم التحويلة (اختياري) is required',
      'ar': 'مطلوب رقم التحويل (اختياري).',
    },
    'sgcimrhu': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'xeyqfymh': {
      'en': 'البريد الإلكتروني للشركة is required',
      'ar': 'مطلوب البريد الإلكتروني للشركة',
    },
    'a37t3hp8': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'hi539rl7': {
      'en': 'معلومات المدير',
      'ar': 'معلومات المدير',
    },
    '1313wasv': {
      'en': 'اسم مدير الشركة',
      'ar': 'اسم مدير الشركة',
    },
    'khty22qt': {
      'en': ' +966 رقم هاتف المدير',
      'ar': '+966 رقم هاتف المدير',
    },
    '8edb6gp4': {
      'en': ' +966 رقم جوال المدير',
      'ar': '+966 رقم جوال المدير',
    },
    'l57eommt': {
      'en': 'نوع النشاط',
      'ar': 'نوع النشاط',
    },
    'teen9wgy': {
      'en': 'نقل متخصص',
      'ar': 'نقل متخصص',
    },
    'shcgfgch': {
      'en': 'تأجير حافلات',
      'ar': 'تأجير سيارات',
    },
    'rvh9b56m': {
      'en': 'نقل تعليمي',
      'ar': 'نقل تعليمي',
    },
    'hl3hjoo1': {
      'en': 'تقديم الطلب',
      'ar': 'تقديم الطلب',
    },
    '8tgsqw8f': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // demoAI1
  {
    '34rwzh2l': {
      'en': 'Michael Rodriguez',
      'ar': 'مايكل رودريجيز',
    },
    'gu0nbiyn': {
      'en': 'Currently Online',
      'ar': 'متصل حاليا',
    },
    'dhraqw9u': {
      'en': 'Go Offline',
      'ar': 'انتقل إلى وضع عدم الاتصال',
    },
    'g7qygnqz': {
      'en': 'Acceptance Rate',
      'ar': 'معدل القبول',
    },
    '6uv7bfpg': {
      'en': '98%',
      'ar': '98%',
    },
    '1kylkkqo': {
      'en': 'Today\'s Trips',
      'ar': 'رحلات اليوم',
    },
    'ytwickls': {
      'en': '14',
      'ar': '14',
    },
    'va748his': {
      'en': 'Pickup Location',
      'ar': 'مكان الاستلام',
    },
    '5qb1vvux': {
      'en': '185 Berry Street, San Francisco',
      'ar': '185 شارع بيري، سان فرانسيسكو',
    },
    'a7og129g': {
      'en': '2 min away',
      'ar': 'على بعد دقيقتين',
    },
    'wloap99t': {
      'en': 'Destination',
      'ar': 'وجهة',
    },
    'molph7f8': {
      'en': 'Golden Gate Bridge Viewpoint',
      'ar': 'نقطة مراقبة جسر البوابة الذهبية',
    },
    'j2mhrqn3': {
      'en': 'Est. Fare',
      'ar': 'السعر التقديري',
    },
    'hovnb8qg': {
      'en': '\$24.50',
      'ar': '24.50 دولارًا',
    },
    'uaona9mq': {
      'en': 'Passenger Rating',
      'ar': 'تصنيف الركاب',
    },
    'r0fi9guq': {
      'en': '4.8',
      'ar': '4.8',
    },
    'fy91fwbd': {
      'en': 'Duration',
      'ar': 'مدة',
    },
    'hsoxeeur': {
      'en': '18 mins',
      'ar': '18 دقيقة',
    },
    'u45d9cxp': {
      'en': 'Distance',
      'ar': 'مسافة',
    },
    '5x5pv3he': {
      'en': '4.2 miles',
      'ar': '4.2 ميل',
    },
    'lees4nrb': {
      'en': 'Decline',
      'ar': 'انخفاض',
    },
    'gafcddmc': {
      'en': 'Accept',
      'ar': 'يقبل',
    },
    'u6czxb59': {
      'en': 'Current Route',
      'ar': 'المسار الحالي',
    },
    '2hvk0iof': {
      'en': 'Estimated Time: 28 mins',
      'ar': 'الوقت المقدر: 28 دقيقة',
    },
    'tdt53pjy': {
      'en': 'Pickup',
      'ar': 'يلتقط',
    },
    'q1qevdpq': {
      'en': '123 Main Street',
      'ar': '123 شارع ماين',
    },
    'hijjo8wk': {
      'en': 'Dropoff',
      'ar': 'التسليم',
    },
    'maqkciqf': {
      'en': '456 Market Avenue',
      'ar': '456 شارع السوق',
    },
    'dyarr5x2': {
      'en': 'Turn right on Oak Street in 0.2 miles',
      'ar': 'انعطف يمينًا على شارع أوك في 0.2 ميل',
    },
    '7mdywrwc': {
      'en': '0.2 mi',
      'ar': '0.2 ميل',
    },
    '6d25tqdb': {
      'en': 'Trip Details',
      'ar': 'تفاصيل الرحلة',
    },
    '759qj0pj': {
      'en': 'Booking #RT58291',
      'ar': 'رقم الحجز #RT58291',
    },
    '3j5uoxa7': {
      'en': 'Edit',
      'ar': 'يحرر',
    },
    'pydq9fl7': {
      'en': 'Passengers',
      'ar': 'الركاب',
    },
    '3fc8wdi4': {
      'en': '2 Adults, 1 Child',
      'ar': 'شخصين بالغين وطفل واحد',
    },
    '54e7ccga': {
      'en': 'Contact',
      'ar': 'اتصال',
    },
    'an20awk6': {
      'en': 'Special Instructions',
      'ar': 'تعليمات خاصة',
    },
    'k07yb5jq': {
      'en':
          'Early check-in requested. Room preference: High floor with city view. Need extra towels.',
      'ar':
          'يُرجى تسجيل الوصول المُبكر. يُفضّل اختيار الغرفة: طابق علوي بإطلالة على المدينة. يُشترط وجود مناشف إضافية.',
    },
    '92vrud6u': {
      'en': 'Payment Method',
      'ar': 'طريقة الدفع',
    },
    '8ousvl0k': {
      'en': '•••• •••• •••• 4891',
      'ar': '•••• •••• •••• 4891',
    },
    've7z4035': {
      'en': 'Estimated Time of Arrival',
      'ar': 'الوقت المتوقع للوصول',
    },
    '72sq4ilx': {
      'en': '23 minutes',
      'ar': '23 دقيقة',
    },
    'xtzigw5y': {
      'en': 'Start Navigation',
      'ar': 'بدء التنقل',
    },
    '989ebf7c': {
      'en': 'Contact Passenger',
      'ar': 'اتصل بالراكب',
    },
    'g8vfz0fr': {
      'en': 'Cancel Trip',
      'ar': 'إلغاء الرحلة',
    },
    'zzt64kkm': {
      'en': 'Today\'s Earnings',
      'ar': 'أرباح اليوم',
    },
    '590zn3xa': {
      'en': '\$187.50',
      'ar': '187.50 دولارًا',
    },
    'pes4eudh': {
      'en': '12',
      'ar': '12',
    },
    'g6qrviaj': {
      'en': 'Trips Completed',
      'ar': 'الرحلات المكتملة',
    },
    'ituff24r': {
      'en': '6h 23m',
      'ar': '6 ساعات و 23 دقيقة',
    },
    'klie67zo': {
      'en': 'Time Online',
      'ar': 'الوقت على الإنترنت',
    },
  },
  // NewDriverRegistration
  {
    '5r0exn1o': {
      'en': 'New Driver Registration',
      'ar': 'تسجيل السائق الجديد',
    },
    'q6cestrx': {
      'en': 'Driver Information',
      'ar': 'معلومات السائق',
    },
    '32m967gv': {
      'en': '* Required fields',
      'ar': '* الحقول المطلوبة',
    },
    'vip2quy1': {
      'en': 'Identity Number *',
      'ar': 'رقم الهوية *',
    },
    '2w4nxotj': {
      'en': 'National ID or Residence Number',
      'ar': 'رقم الهوية الوطنية أو رقم الإقامة',
    },
    '2svo6gf0': {
      'en': 'Full Name *',
      'ar': 'الاسم الكامل *',
    },
    'my1jxoeh': {
      'en': 'Enter your full name',
      'ar': 'أدخل اسمك الكامل',
    },
    '0kcm7o86': {
      'en': 'Date of Birth (Hijri) *',
      'ar': 'تاريخ الميلاد (هجري) *',
    },
    'ifqivatd': {
      'en': 'Day',
      'ar': 'يوم',
    },
    'r899pe4k': {
      'en': 'DD',
      'ar': 'اليوم',
    },
    'u4v6fxf0': {
      'en': 'Month',
      'ar': 'الشهر',
    },
    '8dp5hnft': {
      'en': 'MM',
      'ar': 'الشهر',
    },
    'b5t2remj': {
      'en': 'Year',
      'ar': 'السنة',
    },
    'pysm644d': {
      'en': 'YYYY',
      'ar': 'السنة',
    },
    'egdkgw2q': {
      'en': 'Email Address *',
      'ar': 'عنوان البريد الإلكتروني *',
    },
    '7mf0exuc': {
      'en': 'example@email.com',
      'ar': 'example@email.com',
    },
    '1au0glz0': {
      'en': 'Mobile Number *',
      'ar': 'رقم الجوال مع علامة + ومفتاح الدولة *',
    },
    '3dlqp555': {
      'en': '+9665XXXXXXXX',
      'ar': '+9665XXXXXXXXX',
    },
    'g6m4bzjz': {
      'en': 'Vehicle Information',
      'ar': 'معلومات السيارة',
    },
    'zm9uqkka': {
      'en': 'Vehicle Serial Number *',
      'ar': 'الرقم التسلسلي للمركبة *',
    },
    'f5ii5hjn': {
      'en': 'أدخل اسم السيارة مثلا: كامري',
      'ar': 'أدخل اسم السيارة مثلا: كامري',
    },
    'b5x2pznn': {
      'en': 'Enter vehicle serial number',
      'ar': 'أدخل الرقم التسلسلي للمركبة',
    },
    '68rz02ub': {
      'en': 'License Plate *',
      'ar': 'حروف لوحة المركبة *',
    },
    'qh08wrzi': {
      'en': 'Right',
      'ar': 'اليمين',
    },
    'x868zepg': {
      'en': 'د',
      'ar': 'د',
    },
    'fzhn2mdr': {
      'en': 'Middle',
      'ar': 'وسط',
    },
    'jih70tdc': {
      'en': 'ص',
      'ar': 'ص',
    },
    '7zcg17wy': {
      'en': 'Left',
      'ar': 'اليسار',
    },
    'u2z6fecu': {
      'en': 'ع',
      'ar': 'ع',
    },
    'ncz8v5jv': {
      'en': 'Plate Number *',
      'ar': 'رقم اللوحة *',
    },
    '3c1bsxaa': {
      'en': 'Enter plate number',
      'ar': 'أدخل رقم اللوحة',
    },
    'op3da15o': {
      'en': 'Register',
      'ar': 'تفعيل الحساب',
    },
  },
  // sfdf
  {
    'z834kcif': {
      'en': 'لوحة السيارة',
      'ar': '',
    },
    '0iuaqnxp': {
      'en': 'ب ي س',
      'ar': '',
    },
    '2sglbb8x': {
      'en': '٤٥٧٨',
      'ar': '',
    },
    'fzfkcvym': {
      'en': 'المملكة العربية السعودية',
      'ar': '',
    },
    '73yjq098': {
      'en': 'ع ط ر',
      'ar': '',
    },
    '7fn1gvg8': {
      'en': '١٢٣٤',
      'ar': '',
    },
    'zhofj9ie': {
      'en': 'المملكة العربية السعودية',
      'ar': '',
    },
    '593eu5p0': {
      'en': 'Page Title',
      'ar': '',
    },
    '6xl7kioi': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // Now
  {
    'w5sqogp4': {
      'en':
          'This account is inactive. For further assistance, please contact customer support.',
      'ar':
          'هذا الحساب غير نشط. لمزيد من المساعدة، يُرجى التواصل مع خدمة العملاء.',
    },
    'blsrkk80': {
      'en': 'You cannot view new orders until the current order is completed.',
      'ar':
          'يوجد لديك طلب قائم حاليآ ، ولا يمكنك عرض الطلبات الجديدة إلا بعد إكمال الطلب الحالي',
    },
    'vzhycrvb': {
      'en': 'View order',
      'ar': 'عرض الطلب',
    },
    'cyk8dp1h': {
      'en': 'Total Earnings',
      'ar': 'إجمالي الأرباح',
    },
    '7om1oakw': {
      'en': 'Accept',
      'ar': 'قبول',
    },
    'sebddarz': {
      'en': 'Michael Chen',
      'ar': '',
    },
    'cdkn3tkp': {
      'en': 'Hours: 6',
      'ar': '',
    },
    'n1x2rhng': {
      'en': 'Destinations: 3',
      'ar': '',
    },
    '9puyb1hm': {
      'en': 'Total Earnings',
      'ar': '',
    },
    'yj78dhsa': {
      'en': '\$225',
      'ar': '',
    },
    'jq5qs73c': {
      'en': 'Accept',
      'ar': '',
    },
    '9qcjphaf': {
      'en': 'April 29, 2025 - 10:15 AM',
      'ar': '',
    },
    'b5p3hjgj': {
      'en': 'Emily Rodriguez',
      'ar': '',
    },
    '9g1djv6k': {
      'en': 'Hours: 3',
      'ar': '',
    },
    'vtxilio2': {
      'en': 'Destinations: 1',
      'ar': '',
    },
    'l3bn7qj3': {
      'en': 'Total Earnings',
      'ar': '',
    },
    'qnwrz8hb': {
      'en': '\$112',
      'ar': '',
    },
    'sjuszckd': {
      'en': 'Accept',
      'ar': '',
    },
    't90zwxu2': {
      'en': 'April 30, 2025 - 4:45 PM',
      'ar': '',
    },
    '604z4t02': {
      'en': 'New requests',
      'ar': 'الطلبات الجديدة',
    },
    'hvigto5g': {
      'en': 'Available',
      'ar': 'المتاحة',
    },
  },
  // Accepted
  {
    'jjqc2d63': {
      'en':
          'This account is inactive. For further assistance, please contact customer support.',
      'ar':
          'هذا الحساب غير نشط. لمزيد من المساعدة، يُرجى التواصل مع خدمة العملاء.',
    },
    'osbf1yq2': {
      'en': 'Total Earnings',
      'ar': 'إجمالي الأرباح',
    },
    'vp3hdudk': {
      'en': 'Chat',
      'ar': 'رسائل ',
    },
    'tiln3xf1': {
      'en': 'Details',
      'ar': 'تفاصيل',
    },
    '834esrfw': {
      'en': 'Michael Chen',
      'ar': '',
    },
    'wsjpje08': {
      'en': 'Hours: 6',
      'ar': '',
    },
    'hz3xdol0': {
      'en': 'Destinations: 3',
      'ar': '',
    },
    'mtuvd3kn': {
      'en': 'Total Earnings',
      'ar': '',
    },
    'qhiexweh': {
      'en': '\$225',
      'ar': '',
    },
    '3uc51o4p': {
      'en': 'Accept',
      'ar': '',
    },
    'eiloy94q': {
      'en': 'April 29, 2025 - 10:15 AM',
      'ar': '',
    },
    'kl4o1zkb': {
      'en': 'Emily Rodriguez',
      'ar': '',
    },
    '4tz9pliv': {
      'en': 'Hours: 3',
      'ar': '',
    },
    '3zmraau8': {
      'en': 'Destinations: 1',
      'ar': '',
    },
    'tsualjkx': {
      'en': 'Total Earnings',
      'ar': '',
    },
    't1fsz2em': {
      'en': '\$112',
      'ar': '',
    },
    'yxt4ivq2': {
      'en': 'Accept',
      'ar': '',
    },
    '6toq4rql': {
      'en': 'April 30, 2025 - 4:45 PM',
      'ar': '',
    },
    'xolnmkh5': {
      'en': 'Accepted requests',
      'ar': 'الطلبات المقبولة',
    },
    '1kqxsp9k': {
      'en': 'Accepted',
      'ar': 'المقبولة',
    },
  },
  // Completed
  {
    't4jivayf': {
      'en':
          'This account is inactive. For further assistance, please contact customer support.',
      'ar':
          'هذا الحساب غير نشط. لمزيد من المساعدة، يُرجى التواصل مع خدمة العملاء.',
    },
    'z3snkf0u': {
      'en': 'Total Earnings',
      'ar': 'إجمالي الأرباح',
    },
    'd1vcn2dg': {
      'en': 'Details',
      'ar': 'تفاصيل',
    },
    '1uc7xmvn': {
      'en': 'Michael Chen',
      'ar': '',
    },
    'rqnuh2qd': {
      'en': 'Hours: 6',
      'ar': '',
    },
    'ct7kuo1l': {
      'en': 'Destinations: 3',
      'ar': '',
    },
    'u2n0v0sz': {
      'en': 'Total Earnings',
      'ar': '',
    },
    'q78nya1a': {
      'en': '\$225',
      'ar': '',
    },
    'ub6lrppn': {
      'en': 'Accept',
      'ar': '',
    },
    'men0gwsx': {
      'en': 'April 29, 2025 - 10:15 AM',
      'ar': '',
    },
    '6f3338gb': {
      'en': 'Emily Rodriguez',
      'ar': '',
    },
    'v8bz0352': {
      'en': 'Hours: 3',
      'ar': '',
    },
    'o1a5jz8z': {
      'en': 'Destinations: 1',
      'ar': '',
    },
    'lmq2qpg5': {
      'en': 'Total Earnings',
      'ar': '',
    },
    'lijkv3m3': {
      'en': '\$112',
      'ar': '',
    },
    'kldm8oy1': {
      'en': 'Accept',
      'ar': '',
    },
    'sxo2eyjt': {
      'en': 'April 30, 2025 - 4:45 PM',
      'ar': '',
    },
    '49igunvq': {
      'en': 'Completed requests',
      'ar': 'الطلبات المكتملة',
    },
    'cfe6acde': {
      'en': 'Completed',
      'ar': 'المكتملة',
    },
  },
  // regdrever
  {
    'h53k6bxw': {
      'en': 'Driver registration',
      'ar': 'تسجيل السائق',
    },
    'y52c6v2v': {
      'en': 'Personal Information',
      'ar': 'معلومات شخصية',
    },
    'b78a6lbr': {
      'en': 'Full Name',
      'ar': 'الاسم الكامل',
    },
    'vbhzqfd0': {
      'en': 'ID number',
      'ar': 'رقم الهوية',
    },
    'h1j9zkua': {
      'en': 'Email Address',
      'ar': 'عنوان البريد الإلكتروني',
    },
    'z0ioxhcd': {
      'en': 'Mobile Number',
      'ar': 'رقم الهاتف المحمول',
    },
    'hpdxkp4f': {
      'en': 'Password',
      'ar': 'كلمة المرور',
    },
    '95ktdf69': {
      'en': 'Password',
      'ar': 'كلمة المرور',
    },
    'z0nvh55f': {
      'en': 'Vehicle Information',
      'ar': 'معلومات السيارة',
    },
    '93w64jby': {
      'en': 'Vehicle Name',
      'ar': 'اسم السيارة',
    },
    '3ih7f78t': {
      'en': 'مثلا كامري',
      'ar': 'مثال: كامري',
    },
    'gv0ursmo': {
      'en': 'Model',
      'ar': 'موديل  السيارة',
    },
    'egn02keu': {
      'en': 'مثال: 2025',
      'ar': 'مثال: 2025',
    },
    'j9s6hot5': {
      'en': 'Plate Number',
      'ar': 'رقم اللوحة',
    },
    'zsqfnz2p': {
      'en': 'نوع السيارة',
      'ar': 'نوع السيارة',
    },
    'r4ah2sc5': {
      'en': 'Upload Documents',
      'ar': 'تحميل المستندات',
    },
    '8xvnglk9': {
      'en': 'Personal Photo',
      'ar': 'صورة شخصية',
    },
    '9oxunifk': {
      'en': 'Driver\'s License',
      'ar': 'رخصة السائق',
    },
    'idnralv1': {
      'en': 'Submit Application',
      'ar': 'إرسال الطلب',
    },
    'qtr90kdw': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // listvill
  {
    '95qjz8fm': {
      'en': 'Page Title',
      'ar': 'الطلبات الجديدة',
    },
    'a887ujbc': {
      'en': 'Home',
      'ar': 'المتاحة',
    },
  },
  // home
  {
    'oqek9ss8': {
      'en':
          'To continue receiving orders, please activate your account through the General Transport Authority.',
      'ar': 'لتفعيل استقبال الطلبات، يرجى تفعيل حسابك عبر الهيئة العامة للنقل.',
    },
    'md9y2x4q': {
      'en': 'Account Activation',
      'ar': 'تفعيل حسابك الآن',
    },
    '9lc03d0o': {
      'en': 'Check your registration',
      'ar': 'تحقق من تسجيلك',
    },
    'xhprzvoj': {
      'en': 'Orders',
      'ar': 'طلبات',
    },
    'j9egayfk': {
      'en': '0',
      'ar': '0',
    },
    'tf28iy1f': {
      'en': 'Available',
      'ar': 'متاح',
    },
    'sblrapru': {
      'en': 'Active',
      'ar': 'نشط',
    },
    '22fe4dkq': {
      'en': 'Completed',
      'ar': 'مكتمل',
    },
    'oadi4ucn': {
      'en': 'Finance / Wallet',
      'ar': 'المالية / المحفظة',
    },
    '5w1bmqit': {
      'en': 'Total Earnings',
      'ar': 'إجمالي الأرباح',
    },
    '3wrjokzf': {
      'en': 'Electronic payment obligations',
      'ar': 'مستحقات الدفع الإلكتروني',
    },
    'hfjkl3wt': {
      'en': 'Request payment now',
      'ar': 'طلب المستحقات الآن',
    },
    'xvmvyd3d': {
      'en': 'Please add a bank account to request your payouts.',
      'ar': 'يرجى إضافة حساب بنكي لطلب مستحقاتك المالية.',
    },
    '7hlqu0xi': {
      'en': 'Bank account update',
      'ar': 'تحديث الحساب البنكي',
    },
    'p9lt26gd': {
      'en': 'Unpaid app commissions',
      'ar': 'عمولات التطبيق غير المدفوعة',
    },
    '7rctg8a4': {
      'en':
          'This amount is due. Please pay the outstanding commissions in the Touri Driver app.',
      'ar':
          'هذا المبلغ مستحق الدفع. يرجى سداد عمولات التطبيق المستحقة عبر تطبيق مندوب توري.',
    },
    '3hqugl0j': {
      'en': 'Pay commissions now',
      'ar': 'ادفع العمولات الآن',
    },
    'jnbn4mww': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
    '1dctcly1': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // suport
  {
    'eq5o43g0': {
      'en': 'Bank Account Information',
      'ar': 'معلومات الحساب المصرفي',
    },
    'w8d3aapz': {
      'en': 'Bank Name:',
      'ar': 'اسم البنك:',
    },
    'xy6ckv0p': {
      'en': 'Account Number:',
      'ar': 'رقم الحساب:',
    },
    '1i29t8jx': {
      'en': 'IBAN:',
      'ar': 'الأيبان:',
    },
    'u33lhr0z': {
      'en': 'Account Holder:',
      'ar': 'صاحب الحساب:',
    },
    'kqjw94gh': {
      'en': 'Transfer Confirmation Form',
      'ar': 'نموذج تأكيد التحويل',
    },
    '3cbykrnk': {
      'en': 'Sender\'s Name',
      'ar': 'اسم المحول',
    },
    '52nc4zix': {
      'en': 'Sending Bank',
      'ar': 'البنك المرسل منة',
    },
    '5h0f3l6a': {
      'en': 'Transferred Amount',
      'ar': 'المبلغ المحول',
    },
    'tan5nik6': {
      'en': 'Additional Notes (optional)',
      'ar': 'ملاحظات إضافية (اختياري)',
    },
    'cojvvj9r': {
      'en': 'Submit Transfer Confirmation',
      'ar': 'إرسال تأكيد التحويل',
    },
    'ic2tltrf': {
      'en': 'Transfer Confirmation',
      'ar': 'تأكيد التحويل',
    },
    'l5pp7mp4': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // TfaselOrser
  {
    '9xb7o9cv': {
      'en': 'Trip Status',
      'ar': 'حالة الرحلة',
    },
    '5o8uxjyd': {
      'en': 'Completed',
      'ar': 'مكتملة',
    },
    '2tfu4awd': {
      'en': 'Customer Rating',
      'ar': 'تقييم العميل',
    },
    '4b30ykg1': {
      'en': 'Customer Location',
      'ar': 'موقع العميل',
    },
    'qyrydpsi': {
      'en':
          'The customer is currently waiting for you. Please proceed to their location.\n',
      'ar': 'العميل بانتظارك حاليًا. يُرجى التوجه إلى موقعه.',
    },
    'go8b77km': {
      'en': 'Chat',
      'ar': 'رسائل ',
    },
    'ar2aaxne': {
      'en': 'Cancel Order',
      'ar': 'إلغاء الطلب',
    },
    't6ycy0wz': {
      'en': 'Cancel Order',
      'ar': 'إلغاء الطلب',
    },
    'hctr02e1': {
      'en': 'Accept Order',
      'ar': 'قبول الطلب',
    },
    '5iq2its3': {
      'en': 'Start Trip',
      'ar': 'الوصول (بدء الرحلة)',
    },
    'nbagog2e': {
      'en': 'End Trip',
      'ar': 'إنهاء الرحلة',
    },
    '3kxnmb46': {
      'en': 'Trip Notes',
      'ar': 'ملاحظات الرحلة',
    },
    '2sxecdzz': {
      'en':
          'If the customer does not arrive within 10 minutes, you may cancel the trip.',
      'ar':
          'ملاحظات الرحلة: \n1-يمكنك إنهاء الرحلة بعد نصف ساعة كحد أدنى.\n2-  يمكنك إلغاء الرحلة بعد الانتظار من 10 دقائق حتى 25 دقيقة كحد أقصى.',
    },
    'vpvtpd0h': {
      'en': 'Time Remaining:',
      'ar': 'الوقت المتبقي للرحلة:',
    },
    '1jlut7ry': {
      'en': 'Update Time',
      'ar': 'تحديث الوقت',
    },
    '7atk16av': {
      'en': 'Start Time',
      'ar': 'تاريخ  البدء',
    },
    'q5anstiz': {
      'en': 'End Time',
      'ar': 'تاريخ الإنتهاء',
    },
    'da1x0lkt': {
      'en': 'Start Time',
      'ar': 'وقت البدء',
    },
    'uo3qzmy7': {
      'en': 'End Time',
      'ar': 'وقت النهاية',
    },
    'vlbi1eee': {
      'en': 'Update Time',
      'ar': 'تحديث الوقت',
    },
    'xafw6vd4': {
      'en': 'Trip ends at:',
      'ar': 'تنتهي الرحلة الساعة :',
    },
    'i7kt4eiw': {
      'en': 'وقت الرحلة',
      'ar': 'مؤقت  الرحلة',
    },
    'lv9mwjf6': {
      'en': 'Stops',
      'ar': 'مخطط الرحلة',
    },
    'cjuivl12': {
      'en': ' to Customer Location',
      'ar': 'الذهاب إلى موقع العميل',
    },
    'xajvgc9v': {
      'en': ' Map',
      'ar': ' خريطة',
    },
    'a7x02i9c': {
      'en': 'Site Visited',
      'ar': 'تم',
    },
    '8pdc6fff': {
      'en': ' Map',
      'ar': ' خريطة',
    },
    'sl09paq5': {
      'en': 'Restaurant',
      'ar': 'مطعم',
    },
    '98tn2zkw': {
      'en': 'Second Stop',
      'ar': 'المحطة الثانية',
    },
    'rx3tftt2': {
      'en': 'View on Map',
      'ar': 'عرض على الخريطة',
    },
    'af6u4mcf': {
      'en': 'Beach Resort',
      'ar': 'منتجع شاطئي',
    },
    'ytqouahh': {
      'en': 'Final Destination',
      'ar': 'الوجهة النهائية',
    },
    '8xek3ojp': {
      'en': 'View on Map',
      'ar': 'عرض على الخريطة',
    },
    '9ufh7ltr': {
      'en': 'Return to Customer Location',
      'ar': 'نهاية الرحلة العودة إلى موقع العميل',
    },
    'zxky4qxq': {
      'en': ' Map',
      'ar': ' خريطة',
    },
    '8pbcsylb': {
      'en': 'Order Information',
      'ar': 'معلومات الفاتورة',
    },
    'zssd5l9x': {
      'en': 'Name:',
      'ar': 'اسم العميل:',
    },
    'yci4wt1i': {
      'en': 'Order Number:',
      'ar': 'رقم الطلب/الرحلة:',
    },
    'ewgx1exv': {
      'en': 'Vehicle Type:',
      'ar': 'نوع السيارة:',
    },
    'may2r116': {
      'en': 'Order Status:',
      'ar': 'حالة الطلب:',
    },
    'flsiz002': {
      'en': 'Order Date:',
      'ar': 'تاريخ الطلب:',
    },
    '4tq5mxgb': {
      'en': 'Total Hours:',
      'ar': 'إجمالي الساعات:',
    },
    'bimoowfd': {
      'en': 'Payment Method:',
      'ar': 'طريقة الدفع:',
    },
    'n44ki8x4': {
      'en': 'Total Trip Amount:',
      'ar': 'إجمالي مبلغ الرحلة:',
    },
    '8xz5r4u1': {
      'en': 'Earnings:',
      'ar': 'الأرباح:',
    },
    '87c453o4': {
      'en': 'App Commission & Taxes:',
      'ar': 'عمولة التطبيق والضرائب:',
    },
    'zci7ub2x': {
      'en': 'Have a problem? Contact us directly.',
      'ar': 'هل لديك مشكلة؟ تواصل معنا مباشرةً',
    },
    '8k5qs422': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // dfddf
  {
    'vpmhafpj': {
      'en': 'Page Title',
      'ar': 'تفاصيل الطلب',
    },
    'rgc4ix0r': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // Chat
  {
    '7h5d8vnk': {
      'en': 'Chat',
      'ar': 'محادثة',
    },
    'y34el3aq': {
      'en': 'Pretty good! Just finished a big project. How about you?',
      'ar': '',
    },
    '50inzmuo': {
      'en': '2:35 PM',
      'ar': '',
    },
    'f4aicj1o': {
      'en': 'That\'s awesome! Congratulations 🎉',
      'ar': '',
    },
    'os03oznj': {
      'en': '2:36 PM',
      'ar': '',
    },
    'y8pym4pw': {
      'en': 'Want to grab coffee later to celebrate?',
      'ar': '',
    },
    'sn5z89zm': {
      'en': '2:37 PM',
      'ar': '',
    },
    '0rskl0ug': {
      'en': 'Absolutely! What time works for you?',
      'ar': '',
    },
    'pyru2q6a': {
      'en': '2:38 PM',
      'ar': '',
    },
    'mejzih35': {
      'en': 'Type a message...',
      'ar': 'اكتب رسالتك...',
    },
  },
  // UpdetBank
  {
    'fwdps3he': {
      'en': 'معلومات الحساب البنكي',
      'ar': 'معلومات الحساب البنكي',
    },
    'zlmd7q5u': {
      'en': 'يرجى تحديث بيانات حسابك البنكي',
      'ar': 'يرجى تحديث بيانات حسابك البنكي',
    },
    't433p4i5': {
      'en': 'اسم البنك',
      'ar': 'اسم البنك',
    },
    '2vda5rrx': {
      'en': 'أدخل اسم البنك',
      'ar': 'أدخل اسم البنك',
    },
    'nsr23nzy': {
      'en': 'رقم الحساب',
      'ar': 'رقم الحساب',
    },
    'igm1tdp7': {
      'en': 'أدخل رقم الحساب',
      'ar': 'أدخل رقم الحساب',
    },
    'fan7nqlm': {
      'en': 'رقم الآيبان (IBAN)',
      'ar': 'رقم الآيبان (IBAN)',
    },
    '4kv32oxg': {
      'en': 'SA0000000000000000000000',
      'ar': 'SA0000000000000000000000',
    },
    'w0603k8o': {
      'en': 'اسم صاحب الحساب',
      'ar': 'اسم صاحب الحساب',
    },
    '0an4b4gk': {
      'en': 'أدخل اسم صاحب الحساب',
      'ar': 'أدخل اسم صاحب الحساب',
    },
    'tm5jmdnl': {
      'en': 'تحديث الحساب البنكي',
      'ar': 'تحديث الحساب البنكي',
    },
    'wfk8nxwe': {
      'en': 'تحديث الحساب البنكي',
      'ar': 'تحديث الحساب البنكي',
    },
    'h5tzz9ui': {
      'en': 'Home',
      'ar': '',
    },
  },
  // taimrDemo
  {
    '71jjm3da': {
      'en': 'Button',
      'ar': '',
    },
    'tq0c4st3': {
      'en': 'Page Title',
      'ar': '',
    },
    'yb0nzmps': {
      'en': 'Home',
      'ar': '',
    },
  },
  // ttb3
  {
    '9vw9ln2p': {
      'en': 'Page Title',
      'ar': '',
    },
    'wj3o6h93': {
      'en': 'Home',
      'ar': '',
    },
  },
  // cansel
  {
    'wrc914v3': {
      'en':
          'This account is inactive. For further assistance, please contact customer support.',
      'ar':
          'هذا الحساب غير نشط. لمزيد من المساعدة، يُرجى التواصل مع خدمة العملاء.',
    },
    'g5a8p5v3': {
      'en': 'Cancelled',
      'ar': 'ملغي',
    },
    'fhoeqp3k': {
      'en': 'Total Earnings',
      'ar': 'إجمالي الأرباح',
    },
    'vo1h1i3v': {
      'en': 'Michael Chen',
      'ar': '',
    },
    'pzqiitvk': {
      'en': 'Hours: 6',
      'ar': '',
    },
    '4vj0zb2g': {
      'en': 'Destinations: 3',
      'ar': '',
    },
    'cohzwovl': {
      'en': 'Total Earnings',
      'ar': '',
    },
    '6xbqy8li': {
      'en': '\$225',
      'ar': '',
    },
    '1v9fk38c': {
      'en': 'Accept',
      'ar': '',
    },
    '691hlony': {
      'en': 'April 29, 2025 - 10:15 AM',
      'ar': '',
    },
    'oy3gxd0h': {
      'en': 'Emily Rodriguez',
      'ar': '',
    },
    'upouf95e': {
      'en': 'Hours: 3',
      'ar': '',
    },
    'rafjaz3u': {
      'en': 'Destinations: 1',
      'ar': '',
    },
    '01t1ctsk': {
      'en': 'Total Earnings',
      'ar': '',
    },
    'kujl0eav': {
      'en': '\$112',
      'ar': '',
    },
    '33t7hh49': {
      'en': 'Accept',
      'ar': '',
    },
    '69ve7pvu': {
      'en': 'April 30, 2025 - 4:45 PM',
      'ar': '',
    },
    'v4qagxew': {
      'en': 'Completed requests',
      'ar': 'الطلبات الملغية',
    },
    '3dyv5lob': {
      'en': 'Cancelled',
      'ar': 'الملغية',
    },
  },
  // ProfileUpdatePage
  {
    '5fieigiq': {
      'en': 'Edit Profile',
      'ar': 'تحديث الملف الشخصي',
    },
    'n9rohd22': {
      'en': 'Tap to change photo',
      'ar': 'اضغط على الصورة لتغييرها',
    },
    'i0k5njfx': {
      'en': 'Full Name',
      'ar': 'الأسم كاملا',
    },
    '5m0aofht': {
      'en': 'Enter your full name',
      'ar': '',
    },
    'knkq6gv5': {
      'en': 'Email Address',
      'ar': 'البريد الإلكتروني',
    },
    'hyjo1hzj': {
      'en': 'Enter your email address',
      'ar': '',
    },
    'tte9qdb6': {
      'en': 'Vehicle Type',
      'ar': 'اسم السيارة',
    },
    '4vas6x8x': {
      'en': 'Enter your full name',
      'ar': 'مثلا: كامري',
    },
    '1vt8pppl': {
      'en': 'Vehicle Model',
      'ar': 'موديل السيارة',
    },
    'jhtehfbm': {
      'en': 'Enter vehicle model',
      'ar': 'مثلا: 2025',
    },
    '84nkjru1': {
      'en': 'Update Profile',
      'ar': 'تحديث',
    },
  },
  // villmndob
  {
    'dozeg95k': {
      'en': 'جدة',
      'ar': 'جدة',
    },
    'lmtnw1b7': {
      'en': 'الدمام',
      'ar': 'الدمام',
    },
    'jxkj8ptz': {
      'en': 'مكة المكرمة',
      'ar': 'مكة المكرمة',
    },
    '0iubxee2': {
      'en': 'المدينة المنورة',
      'ar': 'المدينة المنورة',
    },
    '2xu88esj': {
      'en': 'الطائف',
      'ar': 'الطائف',
    },
    'nsittz3j': {
      'en': 'أبها',
      'ar': 'أبها',
    },
    'v1j1jcum': {
      'en': 'تبوك',
      'ar': 'تبوك',
    },
  },
  // ListTypeCar
  {
    '2zbyuhxg': {
      'en': 'تحديد',
      'ar': 'تحديد',
    },
  },
  // ReviewScreen
  {
    'lo233y80': {
      'en': 'Rate your delivery experience',
      'ar': 'يرجى تقييم تجربتك مع العميل',
    },
    'jrljt3nl': {
      'en': 'Write a review',
      'ar': 'كتابة تعليق',
    },
    'bums683l': {
      'en': 'Share your experience...',
      'ar': 'شارك تجربتك مع هذا العميل...',
    },
    '2o2dmbbp': {
      'en': 'Submit Review',
      'ar': 'إرسال التقييم',
    },
  },
  // taim
  {
    'k2zibe66': {
      'en': 'Remaining Time',
      'ar': 'الوقت المتبقي',
    },
    'vclm4olo': {
      'en': 'Trip Ended',
      'ar': 'الوقت إنتهى',
    },
    'r0d4t29u': {
      'en': 'Start Time',
      'ar': 'تاريخ  الرحلة',
    },
    'n5kxjaax': {
      'en': 'End Time',
      'ar': 'تاريخ الإنتهاء',
    },
    'ipd61kmc': {
      'en': 'Start Time',
      'ar': 'وقت البدء',
    },
    'an8ejy50': {
      'en': 'End Time',
      'ar': 'وقت النهاية',
    },
  },
  // Miscellaneous
  {
    'pr7ihdye': {
      'en': 'Please allow camera access to update your profile picture.\n',
      'ar': '',
    },
    'eogie831': {
      'en':
          'Please allow access to photos to update your profile picture from the photo gallery.',
      'ar': '',
    },
    'mrxosh4o': {
      'en': 'CFVFV',
      'ar': '',
    },
    'uuba2erj': {
      'en':
          'Location access must be enabled to help locate the client and to allow the client to know your current location.',
      'ar': '',
    },
    'k2son40w': {
      'en': 'نحتاج لموقعك لتتبع الرحلة حتى عند إغلاق التطبيق',
      'ar': '',
    },
    '9u3k31mr': {
      'en':
          'نحتاج إلى موقعك لتحديث حالة طلب التوصيل وتتبع السائق حتى عند إغلاق التطبيق. هذا يساعدنا على توفير خدمة دقيقة.',
      'ar': '',
    },
    'faij337r': {
      'en':
          'نحتاج للوصول إلى موقعك لتحديد مكانك على الخريطة أثناء استخدام التطبيق',
      'ar': '',
    },
    '4jya93xu': {
      'en':
          'نستخدم بيانات الحركة لتقليل استهلاك البطارية وتحديد حالة السائق أثناء التتبع',
      'ar': '',
    },
    '235nha3u': {
      'en': 'نستخدم الصلاحيات الأمنية لتأمين حسابك والتأكد من هوية المستخدم.',
      'ar': '',
    },
    '7obecfgi': {
      'en': ' لتتبع حركة الموقع وذلك للتبع الرحلة',
      'ar': '',
    },
    'd9rvj7ee': {
      'en': '',
      'ar': '',
    },
    'ztjcyp1y': {
      'en': '',
      'ar': '',
    },
    'c7dh7w7c': {
      'en': '',
      'ar': '',
    },
    '5k6sgo8w': {
      'en': '',
      'ar': '',
    },
    '6hjcletr': {
      'en': '',
      'ar': '',
    },
    'dgo323ov': {
      'en': '',
      'ar': '',
    },
    'cc3tb8oa': {
      'en': '',
      'ar': '',
    },
    '3isjpdwn': {
      'en': '',
      'ar': '',
    },
    '3q8ngk7m': {
      'en': '',
      'ar': '',
    },
    'axnehtwa': {
      'en': '',
      'ar': '',
    },
    'qtxcg0ys': {
      'en': '',
      'ar': '',
    },
    '7sxoey5l': {
      'en': '',
      'ar': '',
    },
    'izpk86hu': {
      'en': '',
      'ar': '',
    },
    'krcrnnnx': {
      'en': '',
      'ar': '',
    },
    'tyicuzbh': {
      'en': '',
      'ar': '',
    },
    'cd224uw5': {
      'en': '',
      'ar': '',
    },
    'cd2uqvwx': {
      'en': '',
      'ar': '',
    },
    '6y7jk8wl': {
      'en': '',
      'ar': '',
    },
    'nducqo5p': {
      'en': '',
      'ar': '',
    },
    'wcj286sy': {
      'en': '',
      'ar': '',
    },
    '5yha9uxw': {
      'en': '',
      'ar': '',
    },
    'anoontgf': {
      'en': '',
      'ar': '',
    },
    '2bpge0fv': {
      'en': '',
      'ar': '',
    },
    'kbx6ypvr': {
      'en': '',
      'ar': '',
    },
    '3j8insfc': {
      'en': '',
      'ar': '',
    },
  },
].reduce((a, b) => a..addAll(b));
