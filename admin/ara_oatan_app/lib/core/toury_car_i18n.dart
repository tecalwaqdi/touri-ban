import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_content_locale.dart';
import '/core/toury_i18n_text.dart';

/// Built-in vehicle labels when Firestore `names_i18n` is incomplete.
const Map<String, Map<String, String>> kTouryVehicleNameCatalog = {
  'economy': {
    'ar': 'سيارة اقتصادية',
    'en': 'Economy',
    'ru': 'Эконом',
    'ky': 'Эконом',
    'uz': 'Ekonom',
  },
  'compact': {
    'ar': 'سيارة اقتصادية',
    'en': 'Compact',
    'ru': 'Компакт',
    'ky': 'Компакт',
    'uz': 'Kompakt',
  },
  'sedan': {
    'ar': 'سيارة اقتصادية',
    'en': 'Sedan',
    'ru': 'Седан',
    'ky': 'Седан',
    'uz': 'Sedan',
  },
  'sedan_standard': {
    'ar': 'سيارة اقتصادية',
    'en': 'Standard Sedan',
    'ru': 'Стандартный седан',
    'ky': 'Стандарт седан',
    'uz': 'Standart sedan',
  },
  'comfort': {
    'ar': 'سيارة اقتصادية',
    'en': 'Comfort',
    'ru': 'Комфорт',
    'ky': 'Комфорт',
    'uz': 'Komfort',
  },
  'sedan_business': {
    'ar': 'سيارة فارهة',
    'en': 'Business Sedan',
    'ru': 'Бизнес седан',
    'ky': 'Бизнес седан',
    'uz': 'Biznes sedan',
  },
  'business': {
    'ar': 'سيارة فارهة',
    'en': 'Business',
    'ru': 'Бизнес',
    'ky': 'Бизнес',
    'uz': 'Biznes',
  },
  'premium': {
    'ar': 'سيارة فارهة',
    'en': 'Premium',
    'ru': 'Премиум',
    'ky': 'Премиум',
    'uz': 'Premium',
  },
  'premium_sedan': {
    'ar': 'سيارة فارهة',
    'en': 'Premium Sedan',
    'ru': 'Премиум седан',
    'ky': 'Премиум седан',
    'uz': 'Premium sedan',
  },
  'luxury': {
    'ar': 'سيارة فارهة',
    'en': 'Luxury',
    'ru': 'Люкс',
    'ky': 'Люкс',
    'uz': 'Lyuks',
  },
  'suv': {
    'ar': 'سيارة عائلية',
    'en': 'Family SUV',
    'ru': 'Семейный SUV',
    'ky': 'Үй-бүлөлүк SUV',
    'uz': 'Oilaviy SUV',
  },
  'suv_compact': {
    'ar': 'سيارة عائلية',
    'en': 'Compact SUV',
    'ru': 'Компактный SUV',
    'ky': 'Ыкчам SUV',
    'uz': 'Kompakt SUV',
  },
  'suv_standard': {
    'ar': 'سيارة عائلية',
    'en': 'SUV Standard',
    'ru': 'Стандартный SUV',
    'ky': 'Стандарт SUV',
    'uz': 'Standart SUV',
  },
  'suv_family': {
    'ar': 'سيارة عائلية',
    'en': 'Family SUV',
    'ru': 'Семейный SUV',
    'ky': 'Үй-бүлөлүк SUV',
    'uz': 'Oilaviy SUV',
  },
  'suv_large': {
    'ar': 'سيارة دفع رباعي',
    'en': 'SUV Large',
    'ru': 'Большой SUV',
    'ky': 'Чоң SUV',
    'uz': 'Katta SUV',
  },
  'luxury_suv': {
    'ar': 'سيارة فارهة',
    'en': 'Luxury SUV',
    'ru': 'Премиум SUV',
    'ky': 'Люкс SUV',
    'uz': 'Lyuks SUV',
  },
  'offroad_4x4': {
    'ar': 'سيارة دفع رباعي',
    'en': '4x4',
    'ru': 'Полный привод 4x4',
    'ky': '4x4',
    'uz': '4x4',
  },
  'pickup_4x4': {
    'ar': 'سيارة دفع رباعي',
    'en': '4x4 Pickup',
    'ru': 'Пикап 4x4',
    'ky': '4x4 пикап',
    'uz': '4x4 pikap',
  },
  'van': {
    'ar': 'حافلة صغيرة عادية',
    'en': 'Tour Van',
    'ru': 'Туристический минивэн',
    'ky': 'Туристтик минивэн',
    'uz': 'Turistik miniven',
  },
  'tour_van': {
    'ar': 'حافلة صغيرة عادية',
    'en': 'Tour Van',
    'ru': 'Туристический минивэн',
    'ky': 'Туристтик минивэн',
    'uz': 'Turistik miniven',
  },
  'minivan': {
    'ar': 'حافلة صغيرة عادية',
    'en': 'Minivan',
    'ru': 'Минивэн',
    'ky': 'Минивэн',
    'uz': 'Miniven',
  },
  'van_family': {
    'ar': 'سيارة عائلية',
    'en': 'Family Van',
    'ru': 'Семейный минивэн',
    'ky': 'Үй-бүлөлүк минивэн',
    'uz': 'Oilaviy miniven',
  },
  'van_vip': {
    'ar': 'حافلة VIP فاخرة',
    'en': 'VIP Van',
    'ru': 'VIP минивэн',
    'ky': 'VIP минивэн',
    'uz': 'VIP miniven',
  },
  'bus': {
    'ar': 'حافلة كبيرة تتسع لـ 49 راكبًا',
    'en': 'Tour Bus',
    'ru': 'Туристический автобус',
    'ky': 'Туристтик автобус',
    'uz': 'Turistik avtobus',
  },
  'coach_mini': {
    'ar': 'حافلة صغيرة عادية',
    'en': 'Minibus',
    'ru': 'Мини-автобус',
    'ky': 'Кичи автобус',
    'uz': 'Miniavtobus',
  },
  'coach_tour': {
    'ar': 'حافلة كبيرة تتسع لـ 49 راكبًا',
    'en': 'Tour Coach',
    'ru': 'Туристический автобус',
    'ky': 'Туристтик автобус',
    'uz': 'Turistik avtobus',
  },
  'coach_medium': {
    'ar': 'حافلة متوسطة تتسع لـ 25 راكبًا',
    'en': 'Medium Bus',
    'ru': 'Средний автобус',
    'ky': 'Орто автобус',
    'uz': 'Ortacha avtobus',
  },
  'medium_bus': {
    'ar': 'حافلة متوسطة تتسع لـ 25 راكبًا',
    'en': 'Medium Bus',
    'ru': 'Средний автобус',
    'ky': 'Орто автобус',
    'uz': 'Ortacha avtobus',
  },
  'executive_shuttle': {
    'ar': 'حافلة صغيرة عادية',
    'en': 'Executive Shuttle',
    'ru': 'Представительский шаттл',
    'ky': 'Аткаруучу шаттл',
    'uz': 'Ijro shattli',
  },
  'electric': {
    'ar': 'سيارة اقتصادية',
    'en': 'Electric',
    'ru': 'Электромобиль',
    'ky': 'Электромобиль',
    'uz': 'Elektromobil',
  },
  'hybrid': {
    'ar': 'سيارة اقتصادية',
    'en': 'Hybrid',
    'ru': 'Гибрид',
    'ky': 'Гибрид',
    'uz': 'Gibrid',
  },
  'wheelchair': {
    'ar': 'حافلة مخصصة لذوي الاحتياجات الخاصة',
    'en': 'Wheelchair Accessible',
    'ru': 'Для инвалидных колясок',
    'ky': 'Майыптар үчүн',
    'uz': 'Nogironlar aravachasi uchun',
  },
  'airport_transfer': {
    'ar': 'سيارة اقتصادية',
    'en': 'Airport Transfer',
    'ru': 'Трансфер в аэропорт',
    'ky': 'Аэропорт трансфери',
    'uz': 'Aeroport transferi',
  },
  'tourist_vehicle': {
    'ar': 'حافلة صغيرة عادية',
    'en': 'Tourist Vehicle',
    'ru': 'Туристический транспорт',
    'ky': 'Туристтик унаа',
    'uz': 'Turistik transport',
  },
};

String? _catalogKeyForCar(TypeCarRecord record) {
  final code = record.codeCar.trim().toLowerCase();
  if (code.isNotEmpty && kTouryVehicleNameCatalog.containsKey(code)) {
    return code;
  }

  final haystack = [
    record.codeCar,
    record.naim,
    ...record.namesI18n.values,
  ].join(' ').toLowerCase();

  if (haystack.contains('wheelchair') || haystack.contains('كرسي')) {
    return 'wheelchair';
  }
  if (haystack.contains('electric') || haystack.contains('كهرب')) {
    return 'electric';
  }
  if (haystack.contains('hybrid') || haystack.contains('هجين')) {
    return 'hybrid';
  }
  if (haystack.contains('airport') || haystack.contains('مطار')) {
    return 'airport_transfer';
  }
  if (haystack.contains('sedan') || haystack.contains('سيدان')) {
    if (haystack.contains('business') || haystack.contains('أعمال')) {
      return 'sedan_business';
    }
    if (haystack.contains('premium') ||
        haystack.contains('luxury') ||
        haystack.contains('فاخر')) {
      return 'premium_sedan';
    }
    if (haystack.contains('economy') ||
        haystack.contains('econom') ||
        haystack.contains('اقتصاد')) {
      return 'economy';
    }
    return 'sedan_standard';
  }
  if (haystack.contains('suv') ||
      haystack.contains('دفع') ||
      haystack.contains('عائلي')) {
    if (haystack.contains('compact') || haystack.contains('مدمج')) {
      return 'suv_compact';
    }
    if (haystack.contains('large') || haystack.contains('كبير')) {
      return 'suv_large';
    }
    if (haystack.contains('luxury') || haystack.contains('فاخر')) {
      return 'luxury_suv';
    }
    return 'suv_family';
  }
  if (haystack.contains('pickup') || haystack.contains('بيك')) {
    return 'pickup_4x4';
  }
  if (haystack.contains('4x4') || haystack.contains('offroad')) {
    return 'offroad_4x4';
  }
  if (haystack.contains('van') ||
      haystack.contains('فان') ||
      haystack.contains('минив')) {
    if (haystack.contains('vip')) return 'van_vip';
    if (haystack.contains('family') || haystack.contains('عائل')) {
      return 'van_family';
    }
    return 'tour_van';
  }
  if (haystack.contains('bus') ||
      haystack.contains('coach') ||
      haystack.contains('باص') ||
      haystack.contains('حافل')) {
    if (haystack.contains('mini')) return 'coach_mini';
    return 'coach_tour';
  }
  return null;
}

Map<String, String> _mergedCarNames(TypeCarRecord record) {
  final merged = <String, String>{};
  final catalogKey = _catalogKeyForCar(record);
  // الكتالوج المحلي له الأولوية لأسماء المركبات المعتمدة في الواجهة.
  if (catalogKey != null) {
    merged.addAll(kTouryVehicleNameCatalog[catalogKey]!);
  }
  for (final entry in record.namesI18n.entries) {
    final value = entry.value.trim();
    if (value.isEmpty) continue;
    merged.putIfAbsent(entry.key, () => value);
  }
  return merged;
}

String touryTypeCarName(BuildContext context, TypeCarRecord record) {
  final locale = touryContentLocaleFromContext(context);
  return touryLocalizedText(
    _mergedCarNames(record),
    record.naim,
    localeKey: locale,
  );
}

String touryTypeCarNote(BuildContext context, TypeCarRecord record) {
  return touryLocalizedText(
    record.namesI18n,
    record.not.isNotEmpty ? record.not : record.naim,
    localeKey: touryContentLocaleFromContext(context),
  );
}

List<String> touryTypeCarSearchTerms(TypeCarRecord record) {
  return touryI18nSearchTerms(_mergedCarNames(record), record.naim);
}
