import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Firestore `mkan.tsnef` values are historically Arabic.
/// UI chips show localized labels; filtering maps back to storage values.
///
/// Catalog source of truth: collection `landmark_categories` (admin-managed).
/// When empty / unreachable, [builtInDefinitions] are used.
abstract final class TouryLandmarkCategories {
  static const collectionName = 'landmark_categories';

  static const storageAll = 'الكل';
  static const storageReligious = 'معالم دينية';
  static const storageHistorical = 'معالم تاريخية وأثرية';
  static const storageMuseums = 'متاحف وثقافة';
  static const storageNature = 'طبيعة وجبال';
  static const storageParks = 'حدائق ومنتزهات';
  static const storageBeaches = 'شواطئ وكورنيش ومماشي';
  static const storageEntertainment = 'ترفيه وأنشطة';
  static const storageRestaurants = 'مطاعم';
  static const storageCafe = 'مقاهي';
  static const storageMarkets = 'أسواق ومولات';
  static const storageHotels = 'فنادق ومنتجعات';
  static const storageFarms = 'مزارع وتجارب ريفية';
  static const storageSports = 'رياضة وملاعب';
  static const storageTransport = 'مطارات ومحطات';
  static const storageLandmarks = 'معالم وأيقونات المدينة';
  static const storageCamps = 'مخيمات برية';
  static const storageCinema = 'سينما';
  static const storageReserves = 'محميات طبيعية';
  /// Legacy values still stored on older landmarks.
  static const storageTourism = 'معالم سياحية';
  static const storageTouristPlaces = 'أماكن سياحية';
  static const storageLegacyHistorical = 'معالم تاريخية';
  static const storageLegacyEntertainment = 'أماكن ترفيهية';
  static const storageLegacyCafe = 'مقهى';
  static const storageLegacyMarkets = 'أسواق';
  static const storageLegacyHotels = 'فنادق';
  static const storageDesert = 'جولة برية';
  static const storageSea = 'جولة بحرية';

  /// Built-in chip catalog — no near-duplicate pairs, sensible icons.
  static const List<TouryLandmarkCategoryDef> builtInDefinitions = [
    TouryLandmarkCategoryDef(
      id: 'all',
      storage: storageAll,
      trKey: 'landmark_cat_all',
      labelAr: 'الكل',
      labelEn: 'All',
      icon: IconDataHint.all,
      sort: 0,
    ),
    TouryLandmarkCategoryDef(
      id: 'religious',
      storage: storageReligious,
      trKey: 'landmark_cat_religious',
      labelAr: 'معالم دينية',
      labelEn: 'Religious landmarks',
      icon: IconDataHint.mosque,
      sort: 10,
    ),
    TouryLandmarkCategoryDef(
      id: 'historical',
      storage: storageHistorical,
      trKey: 'landmark_cat_historical',
      labelAr: 'معالم تاريخية وأثرية',
      labelEn: 'Historical and archaeological sites',
      icon: IconDataHint.historical,
      sort: 20,
    ),
    TouryLandmarkCategoryDef(
      id: 'museums',
      storage: storageMuseums,
      trKey: 'landmark_cat_museums',
      labelAr: 'متاحف وثقافة',
      labelEn: 'Museums and culture',
      icon: IconDataHint.museum,
      sort: 30,
    ),
    TouryLandmarkCategoryDef(
      id: 'nature',
      storage: storageNature,
      trKey: 'landmark_cat_nature',
      labelAr: 'طبيعة وجبال',
      labelEn: 'Nature and mountains',
      icon: IconDataHint.nature,
      sort: 40,
    ),
    TouryLandmarkCategoryDef(
      id: 'parks',
      storage: storageParks,
      trKey: 'landmark_cat_parks',
      labelAr: 'حدائق ومنتزهات',
      labelEn: 'Parks and gardens',
      icon: IconDataHint.park,
      sort: 50,
    ),
    TouryLandmarkCategoryDef(
      id: 'beaches',
      storage: storageBeaches,
      trKey: 'landmark_cat_beaches',
      labelAr: 'شواطئ وكورنيش ومماشي',
      labelEn: 'Beaches, corniche and walks',
      icon: IconDataHint.beach,
      sort: 60,
    ),
    TouryLandmarkCategoryDef(
      id: 'entertainment',
      storage: storageEntertainment,
      trKey: 'landmark_cat_entertainment',
      labelAr: 'ترفيه وأنشطة',
      labelEn: 'Entertainment and activities',
      icon: IconDataHint.entertainment,
      sort: 70,
    ),
    TouryLandmarkCategoryDef(
      id: 'restaurants',
      storage: storageRestaurants,
      trKey: 'landmark_cat_restaurants',
      labelAr: 'مطاعم',
      labelEn: 'Restaurants',
      icon: IconDataHint.food,
      sort: 80,
    ),
    TouryLandmarkCategoryDef(
      id: 'cafe',
      storage: storageCafe,
      trKey: 'landmark_cat_cafe',
      labelAr: 'مقاهي',
      labelEn: 'Cafes',
      icon: IconDataHint.cafe,
      sort: 90,
    ),
    TouryLandmarkCategoryDef(
      id: 'markets',
      storage: storageMarkets,
      trKey: 'landmark_cat_markets',
      labelAr: 'أسواق ومولات',
      labelEn: 'Markets and malls',
      icon: IconDataHint.mall,
      sort: 100,
    ),
    TouryLandmarkCategoryDef(
      id: 'hotels',
      storage: storageHotels,
      trKey: 'landmark_cat_hotels',
      labelAr: 'فنادق ومنتجعات',
      labelEn: 'Hotels and resorts',
      icon: IconDataHint.hotel,
      sort: 110,
    ),
    TouryLandmarkCategoryDef(
      id: 'farms',
      storage: storageFarms,
      trKey: 'landmark_cat_farms',
      labelAr: 'مزارع وتجارب ريفية',
      labelEn: 'Farms and rural experiences',
      icon: IconDataHint.farm,
      sort: 120,
    ),
    TouryLandmarkCategoryDef(
      id: 'sports',
      storage: storageSports,
      trKey: 'landmark_cat_sports',
      labelAr: 'رياضة وملاعب',
      labelEn: 'Sports and stadiums',
      icon: IconDataHint.sports,
      sort: 130,
    ),
    TouryLandmarkCategoryDef(
      id: 'transport',
      storage: storageTransport,
      trKey: 'landmark_cat_transport',
      labelAr: 'مطارات ومحطات',
      labelEn: 'Airports and stations',
      icon: IconDataHint.transport,
      sort: 140,
    ),
    TouryLandmarkCategoryDef(
      id: 'landmarks',
      storage: storageLandmarks,
      trKey: 'landmark_cat_landmarks',
      labelAr: 'معالم وأيقونات المدينة',
      labelEn: 'City landmarks and icons',
      icon: IconDataHint.landmark,
      sort: 150,
    ),
    TouryLandmarkCategoryDef(
      id: 'camps',
      storage: storageCamps,
      trKey: 'landmark_cat_camps',
      labelAr: 'مخيمات برية',
      labelEn: 'Desert camps',
      icon: IconDataHint.camp,
      sort: 160,
    ),
    TouryLandmarkCategoryDef(
      id: 'cinema',
      storage: storageCinema,
      trKey: 'landmark_cat_cinema',
      labelAr: 'سينما',
      labelEn: 'Cinema',
      icon: IconDataHint.cinema,
      sort: 170,
    ),
    TouryLandmarkCategoryDef(
      id: 'reserves',
      storage: storageReserves,
      trKey: 'landmark_cat_reserves',
      labelAr: 'محميات طبيعية',
      labelEn: 'Nature reserves',
      icon: IconDataHint.reserve,
      sort: 180,
    ),
  ];

  /// Alias of [builtInDefinitions] for older call sites.
  static List<({String trKey, String storage, IconDataHint icon})>
      get definitions => [
            for (final d in builtInDefinitions)
              (trKey: d.trKey, storage: d.storage, icon: d.icon),
          ];

  static List<TouryLandmarkCategoryDef>? _remoteCache;
  static DateTime? _remoteCacheAt;
  static const _cacheTtl = Duration(minutes: 10);

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection(collectionName);

  static const retiredIds = {'tourism', 'sea', 'desert'};

  /// Canonical categories always stay. Custom admin categories are appended.
  static List<TouryLandmarkCategoryDef> mergeWithBuiltIn(
    List<TouryLandmarkCategoryDef> remote,
  ) {
    final known = {for (final item in builtInDefinitions) item.id};
    final extras = remote.where(
      (item) => !known.contains(item.id) && !retiredIds.contains(item.id),
    );
    final out = [...builtInDefinitions, ...extras];
    out.sort((a, b) => a.sort.compareTo(b.sort));
    return out;
  }

  /// Loads enabled categories from Firestore (sorted). Falls back to built-ins.
  static Future<List<TouryLandmarkCategoryDef>> loadCatalog({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _remoteCache != null &&
        _remoteCacheAt != null &&
        now.difference(_remoteCacheAt!) < _cacheTtl) {
      return _remoteCache!;
    }
    try {
      final snap = await collection.orderBy('sort').limit(80).get();
      final parsed = <TouryLandmarkCategoryDef>[];
      for (final doc in snap.docs) {
        final item = TouryLandmarkCategoryDef.fromMap(doc.id, doc.data());
        if (item != null && item.enabled) parsed.add(item);
      }
      if (parsed.isEmpty) {
        // Fallback: unordered read (no index required).
        final raw = await collection.limit(80).get();
        for (final doc in raw.docs) {
          final item = TouryLandmarkCategoryDef.fromMap(doc.id, doc.data());
          if (item != null && item.enabled) parsed.add(item);
        }
        parsed.sort((a, b) => a.sort.compareTo(b.sort));
      }
      final list = mergeWithBuiltIn(parsed);
      _remoteCache = List.unmodifiable(list);
      _remoteCacheAt = now;
      return _remoteCache!;
    } catch (_) {
      try {
        final raw = await collection.limit(80).get();
        final parsed = <TouryLandmarkCategoryDef>[];
        for (final doc in raw.docs) {
          final item = TouryLandmarkCategoryDef.fromMap(doc.id, doc.data());
          if (item != null && item.enabled) parsed.add(item);
        }
        _remoteCache = List.unmodifiable(mergeWithBuiltIn(parsed));
        _remoteCacheAt = now;
        return _remoteCache!;
      } catch (_) {}
      _remoteCache = List.unmodifiable(builtInDefinitions);
      _remoteCacheAt = now;
      return _remoteCache!;
    }
  }

  /// Sync snapshot of last load (or built-ins).
  static List<TouryLandmarkCategoryDef> get cachedOrBuiltIn =>
      _remoteCache ?? builtInDefinitions;

  /// Seed / reset admin defaults into Firestore (idempotent upsert by id).
  static Future<void> seedBuiltInCatalog({bool overwrite = false}) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final d in builtInDefinitions) {
      final ref = collection.doc(d.id);
      if (!overwrite) {
        final existing = await ref.get();
        if (existing.exists) continue;
      }
      batch.set(ref, d.toFirestoreMap(), SetOptions(merge: !overwrite));
    }
    await batch.commit();
    _remoteCache = null;
  }

  static String labelForStorage(String storage) {
    for (final d in cachedOrBuiltIn) {
      if (d.storage == storage) return d.displayLabel();
    }
    for (final d in builtInDefinitions) {
      if (d.storage == storage) return d.displayLabel();
    }
    return storage;
  }

  /// Maps a chip label (any language) or storage Arabic → Firestore `tsnef`.
  static String toStorage(String? chipOrStorage) {
    final v = (chipOrStorage ?? '').trim();
    if (v.isEmpty) return storageAll;
    for (final d in cachedOrBuiltIn) {
      if (v == d.storage ||
          v == d.trKey.tr() ||
          v == d.trKey ||
          v == d.labelAr ||
          v == d.labelEn) {
        return d.storage;
      }
    }
    for (final d in builtInDefinitions) {
      if (v == d.storage ||
          v == d.trKey.tr() ||
          v == d.trKey ||
          v == d.labelAr ||
          v == d.labelEn) {
        return d.storage;
      }
    }
    // Legacy near-duplicate → canonical tourism storage.
    if (v == storageTouristPlaces ||
        v == storageTourism ||
        v == 'landmark_cat_tourist_places'.tr() ||
        v == 'landmark_cat_tourism'.tr()) {
      return storageLandmarks;
    }
    if (v == storageLegacyHistorical) return storageHistorical;
    if (v == storageLegacyEntertainment) return storageEntertainment;
    if (v == storageLegacyCafe) return storageCafe;
    if (v == storageLegacyMarkets) return storageMarkets;
    if (v == storageLegacyHotels) return storageHotels;
    if (v == storageDesert) return storageCamps;
    if (v == storageSea) return storageBeaches;
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
    'museum': storageMuseums,
    'attraction': storageLandmarks,
    'tourism': storageLandmarks,
    'tourist': storageLandmarks,
    'viewpoint': storageLandmarks,
    'park': storageParks,
    'entertainment': storageEntertainment,
    'leisure': storageEntertainment,
    'cafe': storageCafe,
    'café': storageCafe,
    'restaurant': storageRestaurants,
    'food': storageRestaurants,
    'market': storageMarkets,
    'marketplace': storageMarkets,
    'mall': storageMarkets,
    'hotel': storageHotels,
    'desert': storageCamps,
    'camp': storageCamps,
    'sea': storageBeaches,
    'beach': storageBeaches,
    'cinema': storageCinema,
    'nature': storageNature,
    'farm': storageFarms,
    'sports': storageSports,
    'airport': storageTransport,
    'reserve': storageReserves,
  };

  /// Normalize raw `mkan.tsnef` to a canonical storage value when possible.
  static String normalizeTsnef(String? recordTsnef) {
    final raw = (recordTsnef ?? '').trim();
    if (raw.isEmpty) return storageLandmarks;
    if (raw == storageTouristPlaces || raw == storageTourism) {
      return storageLandmarks;
    }
    if (raw == storageLegacyHistorical) return storageHistorical;
    if (raw == storageLegacyEntertainment) return storageEntertainment;
    if (raw == storageLegacyCafe) return storageCafe;
    if (raw == storageLegacyMarkets) return storageMarkets;
    if (raw == storageLegacyHotels) return storageHotels;
    if (raw == storageDesert) return storageCamps;
    if (raw == storageSea) return storageBeaches;
    final mapped = _osmAliases[raw.toLowerCase()];
    if (mapped != null) return mapped;
    return raw;
  }

  /// هل قيمة `mkan.tsnef` تطابق شريحة الفلتر المحددة؟
  static bool matchesTsnef(String? recordTsnef, String? chipOrStorage) {
    if (isAll(chipOrStorage)) return true;
    final wanted = toStorage(chipOrStorage);
    final normalized = normalizeTsnef(recordTsnef);
    if (normalized == wanted) return true;
    final raw = (recordTsnef ?? '').trim();
    if (raw == wanted || raw == chipOrStorage) return true;
    final mapped = _osmAliases[raw.toLowerCase()];
    return mapped == wanted;
  }

  /// Chips for a city: "All" + categories that actually appear in [tsnefValues].
  static List<TouryLandmarkCategoryDef> chipsForPresentCategories(
    Iterable<String?> tsnefValues, {
    List<TouryLandmarkCategoryDef>? catalog,
  }) {
    final source = catalog ?? cachedOrBuiltIn;
    final present = <String>{};
    for (final raw in tsnefValues) {
      present.add(normalizeTsnef(raw));
    }
    final chips = <TouryLandmarkCategoryDef>[];
    for (final d in source) {
      if (!d.enabled) continue;
      if (d.storage == storageAll) {
        chips.add(d);
        continue;
      }
      if (present.contains(d.storage)) {
        chips.add(d);
      }
    }
    if (chips.isEmpty || (chips.length == 1 && chips.first.storage == storageAll)) {
      // No known categories on landmarks — show tourism as fallback with All.
      return [
        for (final d in source)
          if (d.storage == storageAll || d.storage == storageLandmarks) d,
      ];
    }
    return chips;
  }

  static IconData materialIcon(IconDataHint hint) {
    switch (hint) {
      case IconDataHint.all:
        return Icons.density_small;
      case IconDataHint.mosque:
      case IconDataHint.cloud:
        return Icons.mosque_outlined;
      case IconDataHint.historical:
      case IconDataHint.place:
        return Icons.account_balance_outlined;
      case IconDataHint.museum:
        return Icons.museum_outlined;
      case IconDataHint.nature:
        return Icons.terrain_outlined;
      case IconDataHint.park:
        return Icons.park_outlined;
      case IconDataHint.beach:
      case IconDataHint.sea:
        return Icons.beach_access_outlined;
      case IconDataHint.entertainment:
      case IconDataHint.happy:
        return Icons.celebration_outlined;
      case IconDataHint.mall:
      case IconDataHint.cart:
        return Icons.local_mall_outlined;
      case IconDataHint.food:
      case IconDataHint.restaurant:
        return Icons.restaurant_outlined;
      case IconDataHint.cafe:
        return Icons.coffee_outlined;
      case IconDataHint.hotel:
        return Icons.hotel_outlined;
      case IconDataHint.farm:
        return Icons.agriculture_outlined;
      case IconDataHint.sports:
        return Icons.sports_soccer_outlined;
      case IconDataHint.transport:
        return Icons.connecting_airports_outlined;
      case IconDataHint.landmark:
      case IconDataHint.attraction:
        return Icons.location_city_outlined;
      case IconDataHint.camp:
      case IconDataHint.forest:
        return Icons.cabin_outlined;
      case IconDataHint.cinema:
        return Icons.theaters_outlined;
      case IconDataHint.reserve:
        return Icons.nature_outlined;
    }
  }

  static IconDataHint iconFromName(String? name) {
    switch ((name ?? '').trim().toLowerCase()) {
      case 'all':
        return IconDataHint.all;
      case 'mosque':
      case 'cloud':
        return IconDataHint.mosque;
      case 'historical':
      case 'place':
        return IconDataHint.historical;
      case 'museum':
        return IconDataHint.museum;
      case 'nature':
        return IconDataHint.nature;
      case 'park':
        return IconDataHint.park;
      case 'beach':
      case 'sea':
        return IconDataHint.beach;
      case 'entertainment':
      case 'happy':
        return IconDataHint.entertainment;
      case 'mall':
      case 'cart':
        return IconDataHint.mall;
      case 'food':
      case 'restaurant':
        return IconDataHint.food;
      case 'cafe':
        return IconDataHint.cafe;
      case 'hotel':
        return IconDataHint.hotel;
      case 'farm':
        return IconDataHint.farm;
      case 'sports':
        return IconDataHint.sports;
      case 'transport':
        return IconDataHint.transport;
      case 'landmark':
      case 'attraction':
        return IconDataHint.landmark;
      case 'camp':
      case 'forest':
        return IconDataHint.camp;
      case 'cinema':
        return IconDataHint.cinema;
      case 'reserve':
        return IconDataHint.reserve;
      default:
        return IconDataHint.landmark;
    }
  }
}

class TouryLandmarkCategoryDef {
  const TouryLandmarkCategoryDef({
    required this.id,
    required this.storage,
    required this.trKey,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    this.enabled = true,
    this.sort = 0,
  });

  final String id;
  final String storage;
  final String trKey;
  final String labelAr;
  final String labelEn;
  final IconDataHint icon;
  final bool enabled;
  final int sort;

  /// Localized chip label (tr key when available, else AR/EN fallbacks).
  String displayLabel({String locale = 'ar'}) {
    if (trKey.isNotEmpty) {
      try {
        final translated = trKey.tr();
        if (translated.isNotEmpty && translated != trKey) return translated;
      } catch (_) {}
    }
    if (locale.startsWith('en') && labelEn.isNotEmpty) return labelEn;
    return labelAr.isNotEmpty ? labelAr : labelEn;
  }

  Map<String, dynamic> toFirestoreMap() => {
        'storage': storage,
        'trKey': trKey,
        'labelAr': labelAr,
        'labelEn': labelEn,
        'icon': icon.name,
        'enabled': enabled,
        'sort': sort,
      };

  static TouryLandmarkCategoryDef? fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final storage = (data['storage'] as String?)?.trim() ?? '';
    if (storage.isEmpty) return null;
    final labelAr = (data['labelAr'] as String?)?.trim() ?? storage;
    final labelEn = (data['labelEn'] as String?)?.trim() ?? labelAr;
    final trKey = (data['trKey'] as String?)?.trim() ?? '';
    final sort = (data['sort'] is num) ? (data['sort'] as num).toInt() : 0;
    final enabled = data['enabled'] != false;
    return TouryLandmarkCategoryDef(
      id: id,
      storage: storage,
      trKey: trKey,
      labelAr: labelAr,
      labelEn: labelEn,
      icon: TouryLandmarkCategories.iconFromName(data['icon'] as String?),
      enabled: enabled,
      sort: sort,
    );
  }
}

enum IconDataHint {
  all,
  cloud,
  mosque,
  happy,
  entertainment,
  attraction,
  landmark,
  restaurant,
  cafe,
  place,
  historical,
  museum,
  nature,
  park,
  cart,
  mall,
  forest,
  camp,
  sea,
  beach,
  hotel,
  food,
  farm,
  sports,
  transport,
  cinema,
  reserve,
}
