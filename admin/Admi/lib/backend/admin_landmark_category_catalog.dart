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
    this.trKey = '',
    this.enabled = true,
    this.sort = 0,
  });

  final String id;
  final String storage;
  final String labelAr;
  final String labelEn;
  final String icon;
  final String trKey;
  final bool enabled;
  final int sort;

  Map<String, dynamic> toMap() => {
        'storage': storage,
        'labelAr': labelAr,
        'labelEn': labelEn,
        'icon': icon,
        'trKey': trKey,
        'enabled': enabled,
        'sort': sort,
      };

  AdminLandmarkCategory copyWith({
    String? storage,
    String? labelAr,
    String? labelEn,
    String? icon,
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
    final storage = (data['storage'] as String?)?.trim() ?? '';
    if (storage.isEmpty) return null;
    return AdminLandmarkCategory(
      id: doc.id,
      storage: storage,
      labelAr: (data['labelAr'] as String?)?.trim() ?? storage,
      labelEn: (data['labelEn'] as String?)?.trim() ?? storage,
      icon: (data['icon'] as String?)?.trim() ?? 'attraction',
      trKey: (data['trKey'] as String?)?.trim() ?? '',
      enabled: data['enabled'] != false,
      sort: (data['sort'] is num) ? (data['sort'] as num).toInt() : 0,
    );
  }
}

abstract final class AdminLandmarkCategoryCatalog {
  static const collectionName = 'landmark_categories';

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection(collectionName);

  /// Clean defaults — no near-duplicate tourism chips.
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
      icon: 'cloud',
      trKey: 'landmark_cat_religious',
      sort: 10,
    ),
    AdminLandmarkCategory(
      id: 'historical',
      storage: 'معالم تاريخية',
      labelAr: 'معالم تاريخية',
      labelEn: 'Historical landmarks',
      icon: 'place',
      trKey: 'landmark_cat_historical',
      sort: 20,
    ),
    AdminLandmarkCategory(
      id: 'tourism',
      storage: 'معالم سياحية',
      labelAr: 'معالم سياحية',
      labelEn: 'Tourist landmarks',
      icon: 'attraction',
      trKey: 'landmark_cat_tourism',
      sort: 30,
    ),
    AdminLandmarkCategory(
      id: 'entertainment',
      storage: 'أماكن ترفيهية',
      labelAr: 'أماكن ترفيهية',
      labelEn: 'Entertainment',
      icon: 'happy',
      trKey: 'landmark_cat_entertainment',
      sort: 40,
    ),
    AdminLandmarkCategory(
      id: 'markets',
      storage: 'أسواق',
      labelAr: 'أسواق',
      labelEn: 'Markets',
      icon: 'cart',
      trKey: 'landmark_cat_markets',
      sort: 50,
    ),
    AdminLandmarkCategory(
      id: 'restaurants',
      storage: 'مطاعم',
      labelAr: 'مطاعم',
      labelEn: 'Restaurants',
      icon: 'food',
      trKey: 'landmark_cat_restaurants',
      sort: 60,
    ),
    AdminLandmarkCategory(
      id: 'cafe',
      storage: 'مقهى',
      labelAr: 'مقهى',
      labelEn: 'Cafe',
      icon: 'cafe',
      trKey: 'landmark_cat_cafe',
      sort: 70,
    ),
    AdminLandmarkCategory(
      id: 'hotels',
      storage: 'فنادق',
      labelAr: 'فنادق',
      labelEn: 'Hotels',
      icon: 'hotel',
      trKey: 'landmark_cat_hotels',
      sort: 80,
    ),
    AdminLandmarkCategory(
      id: 'desert',
      storage: 'جولة برية',
      labelAr: 'جولة برية',
      labelEn: 'Desert tour',
      icon: 'forest',
      trKey: 'landmark_cat_desert',
      sort: 90,
    ),
    AdminLandmarkCategory(
      id: 'sea',
      storage: 'جولة بحرية',
      labelAr: 'جولة بحرية',
      labelEn: 'Sea tour',
      icon: 'sea',
      trKey: 'landmark_cat_sea',
      sort: 100,
    ),
  ];

  static const iconChoices = <String>[
    'all',
    'cloud',
    'place',
    'attraction',
    'happy',
    'cart',
    'food',
    'cafe',
    'hotel',
    'forest',
    'sea',
  ];

  static IconData materialIcon(String name) {
    switch (name) {
      case 'all':
        return Icons.density_small;
      case 'cloud':
        return Icons.cloud_outlined;
      case 'happy':
        return Icons.sentiment_satisfied_rounded;
      case 'place':
        return Icons.place_outlined;
      case 'cart':
        return Icons.shopping_cart_outlined;
      case 'food':
        return Icons.fastfood_outlined;
      case 'cafe':
        return Icons.coffee_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'forest':
        return Icons.forest_outlined;
      case 'sea':
        return Icons.sailing;
      case 'attraction':
      default:
        return Icons.tour;
    }
  }

  static Future<List<AdminLandmarkCategory>> loadAll() async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await collection.orderBy('sort').limit(60).get();
    } catch (_) {
      snap = await collection.limit(60).get();
    }
    final out = <AdminLandmarkCategory>[];
    for (final doc in snap.docs) {
      final item = AdminLandmarkCategory.fromDoc(doc);
      if (item != null) out.add(item);
    }
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
    if (writes > 0) await batch.commit();
  }
}
