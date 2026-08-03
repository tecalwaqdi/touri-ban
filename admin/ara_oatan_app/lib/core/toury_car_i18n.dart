import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_content_locale.dart';
import '/core/toury_i18n_text.dart';

/// Built-in vehicle labels when Firestore `names_i18n` is incomplete.
const Map<String, Map<String, String>> kTouryVehicleNameCatalog = {
  'economy': {
    'ar': 'اقتصادية',
    'en': 'Economy',
    'ru': 'Эконом',
    'ky': 'Эконом',
    'uz': 'Ekonom',
  },
  'compact': {
    'ar': 'مدمجة',
    'en': 'Compact',
    'ru': 'Компакт',
    'ky': 'Компакт',
    'uz': 'Kompakt',
  },
  'sedan': {
    'ar': 'سيدان',
    'en': 'Sedan',
    'ru': 'Седан',
    'ky': 'Седан',
    'uz': 'Sedan',
  },
  'sedan_standard': {
    'ar': 'سيدان قياسية',
    'en': 'Standard Sedan',
    'ru': 'Стандартный седан',
    'ky': 'Стандарт седан',
    'uz': 'Standart sedan',
  },
  'comfort': {
    'ar': 'مريحة',
    'en': 'Comfort',
    'ru': 'Комфорт',
    'ky': 'Комфорт',
    'uz': 'Komfort',
  },
  'sedan_business': {
    'ar': 'سيدان أعمال',
    'en': 'Business Sedan',
    'ru': 'Бизнес седан',
    'ky': 'Бизнес седан',
    'uz': 'Biznes sedan',
  },
  'business': {
    'ar': 'أعمال',
    'en': 'Business',
    'ru': 'Бизнес',
    'ky': 'Бизнес',
    'uz': 'Biznes',
  },
  'premium': {
    'ar': 'ممتازة',
    'en': 'Premium',
    'ru': 'Премиум',
    'ky': 'Премиум',
    'uz': 'Premium',
  },
  'premium_sedan': {
    'ar': 'سيدان فاخرة',
    'en': 'Premium Sedan',
    'ru': 'Премиум седан',
    'ky': 'Премиум седан',
    'uz': 'Premium sedan',
  },
  'luxury': {
    'ar': 'فاخرة',
    'en': 'Luxury',
    'ru': 'Люкс',
    'ky': 'Люкс',
    'uz': 'Lyuks',
  },
  'suv': {
    'ar': 'SUV عائلية',
    'en': 'Family SUV',
    'ru': 'Семейный SUV',
    'ky': 'Үй-бүлөлүк SUV',
    'uz': 'Oilaviy SUV',
  },
  'suv_compact': {
    'ar': 'SUV مدمجة',
    'en': 'Compact SUV',
    'ru': 'Компактный SUV',
    'ky': 'Ыкчам SUV',
    'uz': 'Kompakt SUV',
  },
  'suv_standard': {
    'ar': 'SUV قياسية',
    'en': 'SUV Standard',
    'ru': 'Стандартный SUV',
    'ky': 'Стандарт SUV',
    'uz': 'Standart SUV',
  },
  'suv_family': {
    'ar': 'SUV عائلية',
    'en': 'Family SUV',
    'ru': 'Семейный SUV',
    'ky': 'Үй-бүлөлүк SUV',
    'uz': 'Oilaviy SUV',
  },
  'suv_large': {
    'ar': 'SUV كبيرة',
    'en': 'SUV Large',
    'ru': 'Большой SUV',
    'ky': 'Чоң SUV',
    'uz': 'Katta SUV',
  },
  'luxury_suv': {
    'ar': 'SUV فاخرة',
    'en': 'Luxury SUV',
    'ru': 'Премиум SUV',
    'ky': 'Люкс SUV',
    'uz': 'Lyuks SUV',
  },
  'offroad_4x4': {
    'ar': 'دفع رباعي',
    'en': '4x4',
    'ru': 'Полный привод 4x4',
    'ky': '4x4',
    'uz': '4x4',
  },
  'pickup_4x4': {
    'ar': 'بيك أب 4x4',
    'en': '4x4 Pickup',
    'ru': 'Пикап 4x4',
    'ky': '4x4 пикап',
    'uz': '4x4 pikap',
  },
  'van': {
    'ar': 'فان سياحي',
    'en': 'Tour Van',
    'ru': 'Туристический минивэн',
    'ky': 'Туристтик минивэн',
    'uz': 'Turistik miniven',
  },
  'tour_van': {
    'ar': 'فان سياحي',
    'en': 'Tour Van',
    'ru': 'Туристический минивэн',
    'ky': 'Туристтик минивэн',
    'uz': 'Turistik miniven',
  },
  'minivan': {
    'ar': 'ميني فان',
    'en': 'Minivan',
    'ru': 'Минивэн',
    'ky': 'Минивэн',
    'uz': 'Miniven',
  },
  'van_family': {
    'ar': 'فان عائلي',
    'en': 'Family Van',
    'ru': 'Семейный минивэн',
    'ky': 'Үй-бүлөлүк минивэн',
    'uz': 'Oilaviy miniven',
  },
  'van_vip': {
    'ar': 'فان VIP',
    'en': 'VIP Van',
    'ru': 'VIP минивэн',
    'ky': 'VIP минивэн',
    'uz': 'VIP miniven',
  },
  'bus': {
    'ar': 'باص سياحي',
    'en': 'Tour Bus',
    'ru': 'Туристический автобус',
    'ky': 'Туристтик автобус',
    'uz': 'Turistik avtobus',
  },
  'coach_mini': {
    'ar': 'ميني باص',
    'en': 'Minibus',
    'ru': 'Мини-автобус',
    'ky': 'Кичи автобус',
    'uz': 'Miniavtobus',
  },
  'coach_tour': {
    'ar': 'باص سياحي',
    'en': 'Tour Coach',
    'ru': 'Туристический автобус',
    'ky': 'Туристтик автобус',
    'uz': 'Turistik avtobus',
  },
  'executive_shuttle': {
    'ar': 'شاتل تنفيذي',
    'en': 'Executive Shuttle',
    'ru': 'Представительский шаттл',
    'ky': 'Аткаруучу шаттл',
    'uz': 'Ijro shattli',
  },
  'electric': {
    'ar': 'كهربائية',
    'en': 'Electric',
    'ru': 'Электромобиль',
    'ky': 'Электромобиль',
    'uz': 'Elektromobil',
  },
  'hybrid': {
    'ar': 'هجينة',
    'en': 'Hybrid',
    'ru': 'Гибрид',
    'ky': 'Гибрид',
    'uz': 'Gibrid',
  },
  'wheelchair': {
    'ar': 'مجهزة لكرسي متحرك',
    'en': 'Wheelchair Accessible',
    'ru': 'Для инвалидных колясок',
    'ky': 'Майыптар үчүн',
    'uz': 'Nogironlar aravachasi uchun',
  },
  'airport_transfer': {
    'ar': 'نقل مطار',
    'en': 'Airport Transfer',
    'ru': 'Трансфер в аэропорт',
    'ky': 'Аэропорт трансфери',
    'uz': 'Aeroport transferi',
  },
  'tourist_vehicle': {
    'ar': 'مركبة سياحية',
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
  final merged = Map<String, String>.from(record.namesI18n);
  final catalogKey = _catalogKeyForCar(record);
  if (catalogKey != null) {
    final catalog = kTouryVehicleNameCatalog[catalogKey]!;
    for (final entry in catalog.entries) {
      merged.putIfAbsent(entry.key, () => entry.value);
    }
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
