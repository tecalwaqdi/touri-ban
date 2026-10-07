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
  static const storageEntertainment = 'أماكن ترفيهية';
  static const storageTourism = 'معالم سياحية';
  static const storageCafe = 'مقهى';
  static const storageHistorical = 'معالم تاريخية';
  /// Legacy duplicate of [storageTourism] — kept for matching old docs only.
  static const storageTouristPlaces = 'أماكن سياحية';
  static const storageMarkets = 'أسواق';
  static const storageDesert = 'جولة برية';
  static const storageSea = 'جولة بحرية';
  static const storageHotels = 'فنادق';
  static const storageRestaurants = 'مطاعم';

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
      icon: IconDataHint.cloud,
      sort: 10,
    ),
    TouryLandmarkCategoryDef(
      id: 'historical',
      storage: storageHistorical,
      trKey: 'landmark_cat_historical',
      labelAr: 'معالم تاريخية',
      labelEn: 'Historical landmarks',
      icon: IconDataHint.place,
      sort: 20,
    ),
    TouryLandmarkCategoryDef(
      id: 'tourism',
      storage: storageTourism,
      trKey: 'landmark_cat_tourism',
      labelAr: 'معالم سياحية',
      labelEn: 'Tourist landmarks',
      icon: IconDataHint.attraction,
      sort: 30,
    ),
    TouryLandmarkCategoryDef(
      id: 'entertainment',
      storage: storageEntertainment,
      trKey: 'landmark_cat_entertainment',
      labelAr: 'أماكن ترفيهية',
      labelEn: 'Entertainment',
      icon: IconDataHint.happy,
      sort: 40,
    ),
    TouryLandmarkCategoryDef(
      id: 'markets',
      storage: storageMarkets,
      trKey: 'landmark_cat_markets',
      labelAr: 'أسواق',
      labelEn: 'Markets',
      icon: IconDataHint.cart,
      sort: 50,
    ),
    TouryLandmarkCategoryDef(
      id: 'restaurants',
      storage: storageRestaurants,
      trKey: 'landmark_cat_restaurants',
      labelAr: 'مطاعم',
      labelEn: 'Restaurants',
      icon: IconDataHint.food,
      sort: 60,
    ),
    TouryLandmarkCategoryDef(
      id: 'cafe',
      storage: storageCafe,
      trKey: 'landmark_cat_cafe',
      labelAr: 'مقهى',
      labelEn: 'Cafe',
      icon: IconDataHint.cafe,
      sort: 70,
    ),
    TouryLandmarkCategoryDef(
      id: 'hotels',
      storage: storageHotels,
      trKey: 'landmark_cat_hotels',
      labelAr: 'فنادق',
      labelEn: 'Hotels',
      icon: IconDataHint.hotel,
      sort: 80,
    ),
    TouryLandmarkCategoryDef(
      id: 'desert',
      storage: storageDesert,
      trKey: 'landmark_cat_desert',
      labelAr: 'جولة برية',
      labelEn: 'Desert tour',
      icon: IconDataHint.forest,
      sort: 90,
    ),
    TouryLandmarkCategoryDef(
      id: 'sea',
      storage: storageSea,
      trKey: 'landmark_cat_sea',
      labelAr: 'جولة بحرية',
      labelEn: 'Sea tour',
      icon: IconDataHint.sea,
      sort: 100,
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
      final snap = await collection.orderBy('sort').limit(40).get();
      final parsed = <TouryLandmarkCategoryDef>[];
      for (final doc in snap.docs) {
        final item = TouryLandmarkCategoryDef.fromMap(doc.id, doc.data());
        if (item != null && item.enabled) parsed.add(item);
      }
      if (parsed.isEmpty) {
        // Fallback: unordered read (no index required).
        final raw = await collection.limit(40).get();
        for (final doc in raw.docs) {
          final item = TouryLandmarkCategoryDef.fromMap(doc.id, doc.data());
          if (item != null && item.enabled) parsed.add(item);
        }
        parsed.sort((a, b) => a.sort.compareTo(b.sort));
      }
      if (parsed.isEmpty) {
        _remoteCache = List.unmodifiable(builtInDefinitions);
        _remoteCacheAt = now;
        return _remoteCache!;
      }
      // Always ensure "All" is first.
      final hasAll = parsed.any((e) => e.storage == storageAll);
      final list = hasAll
          ? parsed
          : [
              builtInDefinitions.first,
              ...parsed,
            ];
      _remoteCache = List.unmodifiable(list);
      _remoteCacheAt = now;
      return _remoteCache!;
    } catch (_) {
      // Missing index / offline / rules — use built-ins.
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
    if (v == storageTouristPlaces || v == 'landmark_cat_tourist_places'.tr()) {
      return storageTourism;
    }
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

  /// Normalize raw `mkan.tsnef` to a canonical storage value when possible.
  static String normalizeTsnef(String? recordTsnef) {
    final raw = (recordTsnef ?? '').trim();
    if (raw.isEmpty) return storageTourism;
    if (raw == storageTouristPlaces) return storageTourism;
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
          if (d.storage == storageAll || d.storage == storageTourism) d,
      ];
    }
    return chips;
  }

  static IconData materialIcon(IconDataHint hint) {
    switch (hint) {
      case IconDataHint.all:
        return Icons.density_small;
      case IconDataHint.cloud:
        return Icons.cloud_outlined;
      case IconDataHint.happy:
        return Icons.sentiment_satisfied_rounded;
      case IconDataHint.attraction:
        return Icons.tour;
      case IconDataHint.restaurant:
        return Icons.restaurant;
      case IconDataHint.cafe:
        return Icons.coffee_outlined;
      case IconDataHint.place:
        return Icons.place_outlined;
      case IconDataHint.cart:
        return Icons.shopping_cart_outlined;
      case IconDataHint.forest:
        return Icons.forest_outlined;
      case IconDataHint.sea:
        return Icons.sailing;
      case IconDataHint.hotel:
        return Icons.hotel_outlined;
      case IconDataHint.food:
        return Icons.fastfood_outlined;
    }
  }

  static IconDataHint iconFromName(String? name) {
    switch ((name ?? '').trim().toLowerCase()) {
      case 'all':
        return IconDataHint.all;
      case 'cloud':
        return IconDataHint.cloud;
      case 'happy':
        return IconDataHint.happy;
      case 'attraction':
        return IconDataHint.attraction;
      case 'restaurant':
        return IconDataHint.restaurant;
      case 'cafe':
        return IconDataHint.cafe;
      case 'place':
        return IconDataHint.place;
      case 'cart':
        return IconDataHint.cart;
      case 'forest':
        return IconDataHint.forest;
      case 'sea':
        return IconDataHint.sea;
      case 'hotel':
        return IconDataHint.hotel;
      case 'food':
        return IconDataHint.food;
      default:
        return IconDataHint.attraction;
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
  happy,
  attraction,
  restaurant,
  cafe,
  place,
  cart,
  forest,
  sea,
  hotel,
  food,
}
