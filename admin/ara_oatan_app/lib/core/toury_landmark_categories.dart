import 'package:easy_localization/easy_localization.dart';

/// Firestore `mkan.tsnef` values are historically Arabic.
/// UI chips show localized labels; filtering maps back to storage values.
abstract final class TouryLandmarkCategories {
  static const storageAll = 'الكل';
  static const storageReligious = 'معالم دينية';
  static const storageEntertainment = 'أماكن ترفيهية';
  static const storageTourism = 'معالم سياحية';
  static const storageCafe = 'مقهى';
  static const storageHistorical = 'معالم تاريخية';
  static const storageTouristPlaces = 'أماكن سياحية';
  static const storageMarkets = 'أسواق';
  static const storageDesert = 'جولة برية';
  static const storageSea = 'جولة بحرية';
  static const storageHotels = 'فنادق';
  static const storageRestaurants = 'مطاعم';

  static const List<({String trKey, String storage, IconDataHint icon})>
      definitions = [
    (trKey: 'landmark_cat_all', storage: storageAll, icon: IconDataHint.all),
    (
      trKey: 'landmark_cat_religious',
      storage: storageReligious,
      icon: IconDataHint.cloud
    ),
    (
      trKey: 'landmark_cat_entertainment',
      storage: storageEntertainment,
      icon: IconDataHint.happy
    ),
    (
      trKey: 'landmark_cat_tourism',
      storage: storageTourism,
      icon: IconDataHint.restaurant
    ),
    (trKey: 'landmark_cat_cafe', storage: storageCafe, icon: IconDataHint.cafe),
    (
      trKey: 'landmark_cat_historical',
      storage: storageHistorical,
      icon: IconDataHint.place
    ),
    (
      trKey: 'landmark_cat_tourist_places',
      storage: storageTouristPlaces,
      icon: IconDataHint.place
    ),
    (
      trKey: 'landmark_cat_markets',
      storage: storageMarkets,
      icon: IconDataHint.cart
    ),
    (
      trKey: 'landmark_cat_desert',
      storage: storageDesert,
      icon: IconDataHint.forest
    ),
    (trKey: 'landmark_cat_sea', storage: storageSea, icon: IconDataHint.sea),
    (
      trKey: 'landmark_cat_hotels',
      storage: storageHotels,
      icon: IconDataHint.hotel
    ),
    (
      trKey: 'landmark_cat_restaurants',
      storage: storageRestaurants,
      icon: IconDataHint.food
    ),
  ];

  static String labelForStorage(String storage) {
    for (final d in definitions) {
      if (d.storage == storage) return d.trKey.tr();
    }
    return storage;
  }

  /// Maps a chip label (any language) or storage Arabic → Firestore `tsnef`.
  static String toStorage(String? chipOrStorage) {
    final v = (chipOrStorage ?? '').trim();
    if (v.isEmpty) return storageAll;
    for (final d in definitions) {
      if (v == d.storage || v == d.trKey.tr() || v == d.trKey) {
        return d.storage;
      }
    }
    // Legacy "filter_all" key used elsewhere.
    if (v == 'filter_all'.tr()) return storageAll;
    return v;
  }

  static bool isAll(String? chipOrStorage) {
    final storage = toStorage(chipOrStorage);
    return storage == storageAll || storage.isEmpty;
  }

  /// OSM / English category tags that may still exist on older docs.
  static const Map<String, String> _osmAliases = {
    'religious': storageReligious,
    'religion': storageReligious,
    'place_of_worship': storageReligious,
    'mosque': storageReligious,
    'historic': storageHistorical,
    'historical': storageHistorical,
    'heritage': storageHistorical,
    'museum': storageTourism,
    'attraction': storageTourism,
    'tourism': storageTourism,
    'tourist': storageTourism,
    'viewpoint': storageTourism,
    'park': storageEntertainment,
    'entertainment': storageEntertainment,
    'leisure': storageEntertainment,
    'cafe': storageCafe,
    'café': storageCafe,
    'restaurant': storageRestaurants,
    'food': storageRestaurants,
    'market': storageMarkets,
    'marketplace': storageMarkets,
    'hotel': storageHotels,
    'desert': storageDesert,
    'sea': storageSea,
    'beach': storageSea,
  };

  /// هل قيمة `mkan.tsnef` تطابق شريحة الفلتر المحددة؟
  static bool matchesTsnef(String? recordTsnef, String? chipOrStorage) {
    if (isAll(chipOrStorage)) return true;
    final wanted = toStorage(chipOrStorage);
    final raw = (recordTsnef ?? '').trim();
    if (raw.isEmpty) return wanted == storageTourism;
    if (raw == wanted || raw == chipOrStorage) return true;
    final mapped = _osmAliases[raw.toLowerCase()];
    return mapped == wanted;
  }
}

enum IconDataHint {
  all,
  cloud,
  happy,
  restaurant,
  cafe,
  place,
  cart,
  forest,
  sea,
  hotel,
  food,
}
