import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Admin + Customer share the same `landmark_categories` collection shape.
class AdminLandmarkCategory {
  const AdminLandmarkCategory({
    required this.id,
    required this.storage,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    this.iconUrl = '',
    this.trKey = '',
    this.enabled = true,
    this.sort = 0,
  });

  final String id;
  final String storage;
  final String labelAr;
  final String labelEn;
  final String icon;
  final String iconUrl;
  final String trKey;
  final bool enabled;
  final int sort;

  Map<String, dynamic> toMap() => {
        'storage': storage,
        'labelAr': labelAr,
        'labelEn': labelEn,
        'icon': icon,
        'iconUrl': iconUrl.trim(),
        'trKey': trKey,
        'enabled': enabled,
        'sort': sort,
      };

  AdminLandmarkCategory copyWith({
    String? storage,
    String? labelAr,
    String? labelEn,
    String? icon,
    String? iconUrl,
    String? trKey,
    bool? enabled,
    int? sort,
  }) {
    return AdminLandmarkCategory(
      id: id,
      storage: storage ?? this.storage,
      labelAr: labelAr ?? this.labelAr,
      labelEn: labelEn ?? this.labelEn,
      icon: icon ?? this.icon,
      iconUrl: iconUrl ?? this.iconUrl,
      trKey: trKey ?? this.trKey,
      enabled: enabled ?? this.enabled,
      sort: sort ?? this.sort,
    );
  }

  static AdminLandmarkCategory? fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;
    final storage = _text(data['storage']);
    if (storage.isEmpty) return null;
    return AdminLandmarkCategory(
      id: doc.id,
      storage: storage,
      labelAr: _text(data['labelAr']).isEmpty ? storage : _text(data['labelAr']),
      labelEn: _text(data['labelEn']).isEmpty ? storage : _text(data['labelEn']),
      icon: _text(data['icon']).isEmpty ? 'attraction' : _text(data['icon']),
      iconUrl: _text(data['iconUrl']).isEmpty
          ? _text(data['icon_url'])
          : _text(data['iconUrl']),
      trKey: _text(data['trKey']),
      enabled: data['enabled'] != false,
      sort: (data['sort'] is num) ? (data['sort'] as num).toInt() : 0,
    );
  }

  static String _text(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}

abstract final class AdminLandmarkCategoryCatalog {
  static const collectionName = 'landmark_categories';

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection(collectionName);

  /// Assignment + customer chips. "الكل" is a filter only, not a landmark type.
  static const List<AdminLandmarkCategory> builtIn = [
    AdminLandmarkCategory(
      id: 'all',
      storage: 'الكل',
      labelAr: 'الكل',
      labelEn: 'All',
      icon: 'all',
      trKey: 'landmark_cat_all',
      sort: 0,
    ),
    AdminLandmarkCategory(
      id: 'religious',
      storage: 'معالم دينية',
      labelAr: 'معالم دينية',
      labelEn: 'Religious landmarks',
      icon: 'mosque',
      trKey: 'landmark_cat_religious',
      sort: 10,
    ),
    AdminLandmarkCategory(
      id: 'historical',
      storage: 'معالم تاريخية وأثرية',
      labelAr: 'معالم تاريخية وأثرية',
      labelEn: 'Historical and archaeological sites',
      icon: 'historical',
      trKey: 'landmark_cat_historical',
      sort: 20,
    ),
    AdminLandmarkCategory(
      id: 'museums',
      storage: 'متاحف وثقافة',
      labelAr: 'متاحف وثقافة',
      labelEn: 'Museums and culture',
      icon: 'museum',
      trKey: 'landmark_cat_museums',
      sort: 30,
    ),
    AdminLandmarkCategory(
      id: 'nature',
      storage: 'طبيعة وجبال',
      labelAr: 'طبيعة وجبال',
      labelEn: 'Nature and mountains',
      icon: 'nature',
      trKey: 'landmark_cat_nature',
      sort: 40,
    ),
    AdminLandmarkCategory(
      id: 'parks',
      storage: 'حدائق ومنتزهات',
      labelAr: 'حدائق ومنتزهات',
      labelEn: 'Parks and gardens',
      icon: 'park',
      trKey: 'landmark_cat_parks',
      sort: 50,
    ),
    AdminLandmarkCategory(
      id: 'beaches',
      storage: 'شواطئ وكورنيش ومماشي',
      labelAr: 'شواطئ وكورنيش ومماشي',
      labelEn: 'Beaches, corniche and walks',
      icon: 'beach',
      trKey: 'landmark_cat_beaches',
      sort: 60,
    ),
    AdminLandmarkCategory(
      id: 'entertainment',
      storage: 'ترفيه وأنشطة',
      labelAr: 'ترفيه وأنشطة',
      labelEn: 'Entertainment and activities',
      icon: 'entertainment',
      trKey: 'landmark_cat_entertainment',
      sort: 70,
    ),
    AdminLandmarkCategory(
      id: 'restaurants',
      storage: 'مطاعم',
      labelAr: 'مطاعم',
      labelEn: 'Restaurants',
      icon: 'food',
      trKey: 'landmark_cat_restaurants',
      sort: 80,
    ),
    AdminLandmarkCategory(
      id: 'cafe',
      storage: 'مقاهي',
      labelAr: 'مقاهي',
      labelEn: 'Cafes',
      icon: 'cafe',
      trKey: 'landmark_cat_cafe',
      sort: 90,
    ),
    AdminLandmarkCategory(
      id: 'markets',
      storage: 'أسواق ومولات',
      labelAr: 'أسواق ومولات',
      labelEn: 'Markets and malls',
      icon: 'mall',
      trKey: 'landmark_cat_markets',
      sort: 100,
    ),
    AdminLandmarkCategory(
      id: 'hotels',
      storage: 'فنادق ومنتجعات',
      labelAr: 'فنادق ومنتجعات',
      labelEn: 'Hotels and resorts',
      icon: 'hotel',
      trKey: 'landmark_cat_hotels',
      sort: 110,
    ),
    AdminLandmarkCategory(
      id: 'farms',
      storage: 'مزارع وتجارب ريفية',
      labelAr: 'مزارع وتجارب ريفية',
      labelEn: 'Farms and rural experiences',
      icon: 'farm',
      trKey: 'landmark_cat_farms',
      sort: 120,
    ),
    AdminLandmarkCategory(
      id: 'sports',
      storage: 'رياضة وملاعب',
      labelAr: 'رياضة وملاعب',
      labelEn: 'Sports and stadiums',
      icon: 'sports',
      trKey: 'landmark_cat_sports',
      sort: 130,
    ),
    AdminLandmarkCategory(
      id: 'transport',
      storage: 'مطارات ومحطات',
      labelAr: 'مطارات ومحطات',
      labelEn: 'Airports and stations',
      icon: 'transport',
      trKey: 'landmark_cat_transport',
      sort: 140,
    ),
    AdminLandmarkCategory(
      id: 'landmarks',
      storage: 'معالم وأيقونات المدينة',
      labelAr: 'معالم وأيقونات المدينة',
      labelEn: 'City landmarks and icons',
      icon: 'landmark',
      trKey: 'landmark_cat_landmarks',
      sort: 150,
    ),
    AdminLandmarkCategory(
      id: 'camps',
      storage: 'مخيمات برية',
      labelAr: 'مخيمات برية',
      labelEn: 'Desert camps',
      icon: 'camp',
      trKey: 'landmark_cat_camps',
      sort: 160,
    ),
    AdminLandmarkCategory(
      id: 'cinema',
      storage: 'سينما',
      labelAr: 'سينما',
      labelEn: 'Cinema',
      icon: 'cinema',
      trKey: 'landmark_cat_cinema',
      sort: 170,
    ),
    AdminLandmarkCategory(
      id: 'reserves',
      storage: 'محميات طبيعية',
      labelAr: 'محميات طبيعية',
      labelEn: 'Nature reserves',
      icon: 'reserve',
      trKey: 'landmark_cat_reserves',
      sort: 180,
    ),
  ];

  /// Older catalog ids replaced by the list above.
  static const retiredIds = {'tourism', 'sea', 'desert'};

  static const iconChoices = <String>[
    'all',
    'mosque',
    'historical',
    'museum',
    'nature',
    'park',
    'beach',
    'entertainment',
    'food',
    'cafe',
    'mall',
    'hotel',
    'farm',
    'sports',
    'transport',
    'landmark',
    'camp',
    'cinema',
    'reserve',
    'attraction',
  ];

  static IconData materialIcon(String name) {
    switch (name) {
      case 'all':
        return Icons.density_small;
      case 'mosque':
      case 'cloud':
        return Icons.mosque_outlined;
      case 'historical':
      case 'place':
        return Icons.account_balance_outlined;
      case 'museum':
        return Icons.museum_outlined;
      case 'nature':
        return Icons.terrain_outlined;
      case 'park':
        return Icons.park_outlined;
      case 'beach':
      case 'sea':
        return Icons.beach_access_outlined;
      case 'entertainment':
      case 'happy':
        return Icons.celebration_outlined;
      case 'mall':
      case 'cart':
        return Icons.local_mall_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'cafe':
        return Icons.coffee_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'farm':
        return Icons.agriculture_outlined;
      case 'sports':
        return Icons.sports_soccer_outlined;
      case 'transport':
        return Icons.connecting_airports_outlined;
      case 'landmark':
      case 'attraction':
        return Icons.location_city_outlined;
      case 'camp':
      case 'forest':
        return Icons.cabin_outlined;
      case 'cinema':
        return Icons.theaters_outlined;
      case 'reserve':
        return Icons.nature_outlined;
      default:
        return Icons.tour_outlined;
    }
  }

  static Future<List<AdminLandmarkCategory>> loadAll() async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await collection.orderBy('sort').limit(60).get();
    } catch (_) {
      snap = await collection.limit(60).get();
    }
    final remote = <AdminLandmarkCategory>[];
    for (final doc in snap.docs) {
      final item = AdminLandmarkCategory.fromDoc(doc);
      if (item != null && !retiredIds.contains(item.id)) remote.add(item);
    }
    return mergeWithBuiltIn(remote);
  }

  /// Canonical 18 types always appear. Extra admin-created categories stay.
  static List<AdminLandmarkCategory> mergeWithBuiltIn(
    List<AdminLandmarkCategory> remote,
  ) {
    final known = {for (final item in builtIn) item.id};
    final extras = remote.where((item) => !known.contains(item.id) && item.enabled);
    final out = [...builtIn, ...extras];
    out.sort((a, b) => a.sort.compareTo(b.sort));
    return out;
  }

  static Future<void> upsert(AdminLandmarkCategory item) async {
    await collection.doc(item.id).set(item.toMap(), SetOptions(merge: true));
  }

  static Future<void> delete(String id) async {
    if (id == 'all') return;
    await collection.doc(id).delete();
  }

  static Future<void> seedDefaults({bool overwrite = false}) async {
    final existing = overwrite
        ? <String>{}
        : {
            for (final d in (await collection.limit(60).get()).docs) d.id,
          };
    final batch = FirebaseFirestore.instance.batch();
    var writes = 0;
    for (final d in builtIn) {
      if (!overwrite && existing.contains(d.id)) continue;
      batch.set(
        collection.doc(d.id),
        d.toMap(),
        SetOptions(merge: !overwrite),
      );
      writes++;
    }
    for (final id in retiredIds) {
      batch.set(
        collection.doc(id),
        {'enabled': false},
        SetOptions(merge: true),
      );
      writes++;
    }
    if (writes > 0) await batch.commit();
  }
}
