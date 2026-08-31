import '/backend/backend.dart';

/// Result of scanning production references before hard-delete.
class AdminGeoReferenceScanResult {
  const AdminGeoReferenceScanResult({
    required this.entityType,
    required this.entityId,
    required this.counts,
  });

  final String entityType;
  final String entityId;
  final Map<String, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);
  bool get hasReferences => total > 0;

  String get arabicSummary {
    if (!hasReferences) return 'لا توجد مراجع معروفة';
    final parts = <String>[];
    counts.forEach((k, v) {
      if (v > 0) parts.add('$k: $v');
    });
    return parts.join(' · ');
  }
}

/// Bounded reference scan for geo entities. Never deletes.
abstract final class AdminGeoReferenceScan {
  AdminGeoReferenceScan._();

  static const _pageLimit = 5;

  static Future<AdminGeoReferenceScanResult> scanCountry(
    DocumentReference countryRef,
  ) async {
    final counts = <String, int>{};
    counts['regions'] = await _countWhere(
      CitiesRecord.collection,
      'dolh',
      countryRef,
    );
    counts['cities'] = await _countWhere(
      VillagesRecord.collection,
      'dolh',
      countryRef,
    );
    counts['landmarks'] = await _countWhere(
      MkanRecord.collection,
      'Rev_dolh',
      countryRef,
    );
    counts['users'] = await _countWhere(
      UserRecord.collection,
      'Rev_dolh',
      countryRef,
    );
    return AdminGeoReferenceScanResult(
      entityType: 'country',
      entityId: countryRef.id,
      counts: counts,
    );
  }

  static Future<AdminGeoReferenceScanResult> scanRegion(
    DocumentReference regionRef,
  ) async {
    final counts = <String, int>{};
    counts['cities'] = await _countWhere(
      VillagesRecord.collection,
      'cities',
      regionRef,
    );
    counts['landmarks'] = await _countWhere(
      MkanRecord.collection,
      'id_cit',
      regionRef,
    );
    return AdminGeoReferenceScanResult(
      entityType: 'region',
      entityId: regionRef.id,
      counts: counts,
    );
  }

  static Future<AdminGeoReferenceScanResult> scanCity(
    DocumentReference cityRef,
  ) async {
    final counts = <String, int>{};
    counts['landmarks'] = await _countWhere(
      MkanRecord.collection,
      'id_vill',
      cityRef,
    );
    // Common user/driver city refs used by mobile.
    counts['drivers_city'] = await _countWhere(
      UserRecord.collection,
      'mndob_vill',
      cityRef,
    );
    counts['orders_city'] = await _countWhere(
      OrderRecord.collection,
      'cities_user_now',
      cityRef,
    );
    return AdminGeoReferenceScanResult(
      entityType: 'city',
      entityId: cityRef.id,
      counts: counts,
    );
  }

  static Future<int> _countWhere(
    CollectionReference collection,
    String field,
    DocumentReference ref,
  ) async {
    try {
      final snap = await collection
          .where(field, isEqualTo: ref)
          .limit(_pageLimit)
          .get();
      // If we hit the limit, report "at least N" as N (UI blocks delete anyway).
      return snap.docs.length;
    } catch (_) {
      // Field may not exist / index missing — treat as unknown-safe (block delete).
      return 1;
    }
  }
}
