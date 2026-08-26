import '/backend/backend.dart';
import '/core/toury_vehicle_images.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '/core/toury_car_i18n.dart';

/// الفئات التسع المعتمدة في قائمة السيارات (بدون تكرار).
enum TouryVehicleCategory {
  economy,
  family,
  suv,
  luxury,
  miniBus,
  mediumBus,
  largeBus,
  accessibleBus,
  vipBus,
}

extension TouryVehicleCategoryX on TouryVehicleCategory {
  /// ترتيب العرض الرسمي من الأصغر إلى الأكبر (1…9).
  int get sortOrder {
    switch (this) {
      case TouryVehicleCategory.economy:
        return 1;
      case TouryVehicleCategory.family:
        return 2;
      case TouryVehicleCategory.suv:
        return 3;
      case TouryVehicleCategory.luxury:
        return 4;
      case TouryVehicleCategory.miniBus:
        return 5;
      case TouryVehicleCategory.mediumBus:
        return 6;
      case TouryVehicleCategory.largeBus:
        return 7;
      case TouryVehicleCategory.accessibleBus:
        return 8;
      case TouryVehicleCategory.vipBus:
        return 9;
    }
  }

  /// EasyLocalization key — updates when app language changes.
  String get localizationKey {
    switch (this) {
      case TouryVehicleCategory.economy:
        return 'vehicle_cat_economy';
      case TouryVehicleCategory.family:
        return 'vehicle_cat_family';
      case TouryVehicleCategory.suv:
        return 'vehicle_cat_suv';
      case TouryVehicleCategory.luxury:
        return 'vehicle_cat_luxury';
      case TouryVehicleCategory.miniBus:
        return 'vehicle_cat_mini_bus';
      case TouryVehicleCategory.mediumBus:
        return 'vehicle_cat_medium_bus';
      case TouryVehicleCategory.largeBus:
        return 'vehicle_cat_large_bus';
      case TouryVehicleCategory.accessibleBus:
        return 'vehicle_cat_accessible_bus';
      case TouryVehicleCategory.vipBus:
        return 'vehicle_cat_vip_bus';
    }
  }

  /// Fallback Arabic label (matching / legacy only).
  String get arName {
    switch (this) {
      case TouryVehicleCategory.economy:
        return 'سيارة اقتصادية';
      case TouryVehicleCategory.family:
        return 'سيارة عائلية';
      case TouryVehicleCategory.suv:
        return 'سيارة دفع رباعي';
      case TouryVehicleCategory.luxury:
        return 'سيارة فارهة';
      case TouryVehicleCategory.miniBus:
        return 'حافلة صغيرة';
      case TouryVehicleCategory.mediumBus:
        return 'حافلة متوسطة تتسع لـ 25 راكبًا';
      case TouryVehicleCategory.largeBus:
        return 'حافلة كبيرة تتسع لـ 49 راكبًا';
      case TouryVehicleCategory.accessibleBus:
        return 'حافلة مخصصة لذوي الاحتياجات الخاصة';
      case TouryVehicleCategory.vipBus:
        return 'حافلة VIP';
    }
  }

  String get imageAsset {
    switch (this) {
      case TouryVehicleCategory.economy:
        return TouryVehicleImages.economy;
      case TouryVehicleCategory.family:
        return TouryVehicleImages.family;
      case TouryVehicleCategory.suv:
        return TouryVehicleImages.suv;
      case TouryVehicleCategory.luxury:
        return TouryVehicleImages.luxury;
      case TouryVehicleCategory.miniBus:
        return TouryVehicleImages.miniBus;
      case TouryVehicleCategory.mediumBus:
        return TouryVehicleImages.mediumBus;
      case TouryVehicleCategory.largeBus:
        return TouryVehicleImages.largeBus;
      case TouryVehicleCategory.accessibleBus:
        return TouryVehicleImages.accessibleBus;
      case TouryVehicleCategory.vipBus:
        return TouryVehicleImages.vipBus;
    }
  }

  /// أكواد مفضّلة داخل الفئة (الأول يفوز عند التكرار).
  List<String> get preferredCodes {
    switch (this) {
      case TouryVehicleCategory.economy:
        return const [
          'economy',
          'sedan_standard',
          'comfort',
          'compact',
          'sedan',
          'electric',
          'hybrid',
          'airport_transfer',
        ];
      case TouryVehicleCategory.family:
        return const [
          'suv_family',
          'suv',
          'suv_standard',
          'suv_compact',
          'van_family',
        ];
      case TouryVehicleCategory.suv:
        return const ['offroad_4x4', 'pickup_4x4', 'suv_large'];
      case TouryVehicleCategory.luxury:
        return const [
          'luxury',
          'premium',
          'premium_sedan',
          'business',
          'sedan_business',
          'luxury_suv',
        ];
      case TouryVehicleCategory.miniBus:
        return const [
          'coach_mini',
          'minivan',
          'tour_van',
          'van',
          'tourist_vehicle',
          'executive_shuttle',
        ];
      case TouryVehicleCategory.mediumBus:
        return const ['medium_bus', 'coach_medium', 'bus_medium'];
      case TouryVehicleCategory.largeBus:
        return const ['coach_tour', 'bus', 'large_bus', 'coach_large'];
      case TouryVehicleCategory.accessibleBus:
        return const ['wheelchair', 'accessible', 'accessible_bus'];
      case TouryVehicleCategory.vipBus:
        return const ['van_vip', 'vip', 'vip_bus', 'bus_vip'];
    }
  }
}

const Map<String, TouryVehicleCategory> kTouryVehicleCodeToCategory = {
  'economy': TouryVehicleCategory.economy,
  'compact': TouryVehicleCategory.economy,
  'sedan': TouryVehicleCategory.economy,
  'sedan_standard': TouryVehicleCategory.economy,
  'comfort': TouryVehicleCategory.economy,
  'airport_transfer': TouryVehicleCategory.economy,
  'electric': TouryVehicleCategory.economy,
  'hybrid': TouryVehicleCategory.economy,
  'suv_family': TouryVehicleCategory.family,
  'van_family': TouryVehicleCategory.family,
  'suv': TouryVehicleCategory.family,
  'suv_standard': TouryVehicleCategory.family,
  'suv_compact': TouryVehicleCategory.family,
  'offroad_4x4': TouryVehicleCategory.suv,
  'pickup_4x4': TouryVehicleCategory.suv,
  'suv_large': TouryVehicleCategory.suv,
  'luxury': TouryVehicleCategory.luxury,
  'premium': TouryVehicleCategory.luxury,
  'premium_sedan': TouryVehicleCategory.luxury,
  'business': TouryVehicleCategory.luxury,
  'sedan_business': TouryVehicleCategory.luxury,
  'luxury_suv': TouryVehicleCategory.luxury,
  'coach_mini': TouryVehicleCategory.miniBus,
  'minivan': TouryVehicleCategory.miniBus,
  'tour_van': TouryVehicleCategory.miniBus,
  'van': TouryVehicleCategory.miniBus,
  'tourist_vehicle': TouryVehicleCategory.miniBus,
  'executive_shuttle': TouryVehicleCategory.miniBus,
  'coach_medium': TouryVehicleCategory.mediumBus,
  'bus_medium': TouryVehicleCategory.mediumBus,
  'medium_bus': TouryVehicleCategory.mediumBus,
  'coach_tour': TouryVehicleCategory.largeBus,
  'bus': TouryVehicleCategory.largeBus,
  'large_bus': TouryVehicleCategory.largeBus,
  'coach_large': TouryVehicleCategory.largeBus,
  'wheelchair': TouryVehicleCategory.accessibleBus,
  'accessible': TouryVehicleCategory.accessibleBus,
  'accessible_bus': TouryVehicleCategory.accessibleBus,
  'van_vip': TouryVehicleCategory.vipBus,
  'vip': TouryVehicleCategory.vipBus,
  'vip_bus': TouryVehicleCategory.vipBus,
  'bus_vip': TouryVehicleCategory.vipBus,
};

TouryVehicleCategory? touryVehicleCategoryFor({
  String? codeCar,
  String? documentId,
  String? displayName,
  String? note,
}) {
  final code = (codeCar ?? '').trim().toLowerCase();
  if (code.isNotEmpty && kTouryVehicleCodeToCategory.containsKey(code)) {
    return kTouryVehicleCodeToCategory[code];
  }
  final id = (documentId ?? '').trim().toLowerCase();
  if (id.isNotEmpty && kTouryVehicleCodeToCategory.containsKey(id)) {
    return kTouryVehicleCodeToCategory[id];
  }

  final asset = touryVehicleLocalAsset(
    codeCar: codeCar,
    documentId: documentId,
    displayName: displayName,
    note: note,
  );
  if (asset == null) return null;
  if (asset == TouryVehicleImages.economy) return TouryVehicleCategory.economy;
  if (asset == TouryVehicleImages.family) return TouryVehicleCategory.family;
  if (asset == TouryVehicleImages.suv) return TouryVehicleCategory.suv;
  if (asset == TouryVehicleImages.luxury) return TouryVehicleCategory.luxury;
  if (asset == TouryVehicleImages.miniBus) return TouryVehicleCategory.miniBus;
  if (asset == TouryVehicleImages.mediumBus) {
    return TouryVehicleCategory.mediumBus;
  }
  if (asset == TouryVehicleImages.largeBus) return TouryVehicleCategory.largeBus;
  if (asset == TouryVehicleImages.accessibleBus) {
    return TouryVehicleCategory.accessibleBus;
  }
  if (asset == TouryVehicleImages.vipBus) return TouryVehicleCategory.vipBus;
  return null;
}

int _preferenceScore(TypeCarRecord car, TouryVehicleCategory category) {
  final code = car.codeCar.trim().toLowerCase();
  final id = car.reference.id.trim().toLowerCase();
  final preferred = category.preferredCodes;
  final byCode = preferred.indexOf(code);
  if (byCode >= 0) return byCode;
  final byId = preferred.indexOf(id);
  if (byId >= 0) return byId;
  return preferred.length + 10;
}

/// Admin Firestore order when present; otherwise category fallback.
int touryAdminVehicleSortKey({
  required int sortOrder,
  required int numTrteb,
  required int categorySort,
}) {
  if (sortOrder > 0) return sortOrder;
  if (numTrteb > 0) return numTrteb;
  return categorySort;
}

bool touryShouldPreferRemoteVehicleImage(String? url) {
  final u = (url ?? '').trim();
  return u.startsWith('http://') || u.startsWith('https://');
}

/// مفتاح ترتيب المركبة: Admin `sort_order`/`num_trteb` أولاً، ثم الفئة المحلية.
int touryTypeCarSortKey(TypeCarRecord car) {
  final category = touryVehicleCategoryFor(
    codeCar: car.codeCar,
    documentId: car.reference.id,
    displayName: car.naim,
    note: car.not,
  );
  final categorySort = category?.sortOrder ?? 1000;
  return touryAdminVehicleSortKey(
    sortOrder: car.sortOrder,
    numTrteb: car.numTrteb,
    categorySort: categorySort,
  );
}

int touryCompareTypeCars(TypeCarRecord a, TypeCarRecord b) {
  final bySort = touryTypeCarSortKey(a).compareTo(touryTypeCarSortKey(b));
  if (bySort != 0) return bySort;
  return a.sr.compareTo(b.sr);
}

/// يرتّب قائمة المركبات حسب الفئة والحجم (صغير → كبير).
List<TypeCarRecord> tourySortTypeCars(List<TypeCarRecord> cars) {
  final sorted = List<TypeCarRecord>.from(cars);
  sorted.sort(touryCompareTypeCars);
  return sorted;
}

/// يُبقي سيارة واحدة لكل فئة معتمدة ويرتّبها حسب القائمة الرسمية.
List<TypeCarRecord> touryDeduplicateTypeCars(List<TypeCarRecord> cars) {
  final bestByCategory = <TouryVehicleCategory, TypeCarRecord>{};

  for (final car in cars) {
    final category = touryVehicleCategoryFor(
      codeCar: car.codeCar,
      documentId: car.reference.id,
      displayName: car.naim,
      note: car.not,
    );
    if (category == null) continue;

    final current = bestByCategory[category];
    if (current == null) {
      bestByCategory[category] = car;
      continue;
    }
    final nextScore = _preferenceScore(car, category);
    final currentScore = _preferenceScore(current, category);
    if (nextScore < currentScore) {
      bestByCategory[category] = car;
    } else if (nextScore == currentScore && car.sr < current.sr) {
      bestByCategory[category] = car;
    }
  }

  // ترتيب صريح حسب الحجم/الفئة — لا يعتمد فقط على ترتيب تعريف الـ enum.
  final orderedCategories = TouryVehicleCategory.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final ordered = <TypeCarRecord>[];
  for (final category in orderedCategories) {
    final car = bestByCategory[category];
    if (car != null) ordered.add(car);
  }
  return ordered;
}

/// Localized display name — prefers Admin Firestore names over category keys.
String touryVehicleCategoryDisplayName(
  TypeCarRecord car, [
  BuildContext? context,
]) {
  if (context != null) {
    return touryTypeCarName(context, car);
  }
  final fromI18n = car.namesI18n['en']?.trim();
  if (fromI18n != null && fromI18n.isNotEmpty) return fromI18n;
  if (car.naim.trim().isNotEmpty) return car.naim;
  final category = touryVehicleCategoryFor(
    codeCar: car.codeCar,
    documentId: car.reference.id,
    displayName: car.naim,
    note: car.not,
  );
  if (category != null) {
    return category.localizationKey.tr();
  }
  return car.naim;
}

/// Prefer remote Admin image when usable; otherwise category asset fallback.
String? touryVehiclePreferredLocalAsset(TypeCarRecord car) {
  if (touryShouldPreferRemoteVehicleImage(car.img)) {
    return null;
  }
  return touryVehicleCategoryImage(car);
}

String? touryVehicleCategoryImage(TypeCarRecord car) {
  final category = touryVehicleCategoryFor(
    codeCar: car.codeCar,
    documentId: car.reference.id,
    displayName: car.naim,
    note: car.not,
  );
  return category?.imageAsset;
}
