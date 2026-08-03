
import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Max results returned from landmark search (small payload = fast).
const int kAdminSearchLimit = 40;

/// How many cached docs to scan locally before hitting the network.
const int kAdminSearchCacheScanLimit = 150;

/// In-memory index of landmarks already loaded in list pages (instant re-search).
class AdminLandmarkIndex {
  AdminLandmarkIndex._();

  static final Map<String, MkanRecord> _byPath = {};
  static const int _maxEntries = 500;

  static void ingest(Iterable<MkanRecord> records) {
    for (final record in records) {
      _byPath[record.reference.path] = record;
    }
    while (_byPath.length > _maxEntries) {
      _byPath.remove(_byPath.keys.first);
    }
  }

  static void clear() => _byPath.clear();

  static void removeRecord(MkanRecord record) {
    _byPath.remove(record.reference.path);
  }

  static void removeById(String documentId) {
    _byPath.removeWhere((_, record) => record.reference.id == documentId);
  }

  static List<MkanRecord> searchLocal(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    return _byPath.values
        .where((record) => landmarkMatchesQuery(record, q))
        .toList(growable: false);
  }
}

bool landmarkMatchesQuery(MkanRecord record, String qLower) {
  return record.naim.toLowerCase().contains(qLower) ||
      record.osf.toLowerCase().contains(qLower) ||
      record.address.toLowerCase().contains(qLower) ||
      record.mdh.toLowerCase().contains(qLower) ||
      record.tsnef.toLowerCase().contains(qLower);
}

Query _prefixQuery(String term, bool partnersOnly) {
  final end = '$term\uf8ff';
  final scopeByCountry = AdminRoleService.isCountryAgent;

  if (partnersOnly) {
    var q = MkanRecord.collection.where('isShrek', isEqualTo: true);
    if (scopeByCountry) {
      q = AdminCountryScope.applyLandmarkCountryFilter(
        q as Query<Map<String, dynamic>>,
      );
    }
    return q
        .where('naim', isGreaterThanOrEqualTo: term)
        .where('naim', isLessThanOrEqualTo: end);
  }

  if (scopeByCountry) {
    var q = AdminCountryScope.applyLandmarkCountryFilter(
      MkanRecord.collection as Query<Map<String, dynamic>>,
    );
    return q.orderBy('naim').startAt([term]).endAt([end]);
  }

  return MkanRecord.collection.orderBy('naim').startAt([term]).endAt([end]);
}

/// Fast landmark search: memory index → Firestore cache → indexed prefix query.
Future<List<MkanRecord>> searchLandmarksFast({
  required String query,
  required bool partnersOnly,
}) async {
  final term = query.trim();
  if (term.isEmpty) return const [];

  final qLower = term.toLowerCase();
  final merged = <String, MkanRecord>{};

  void add(MkanRecord record) {
    if (partnersOnly && !record.isShrek) return;
    if (AdminRoleService.isCountryAgent &&
        !AdminCountryScope.isLandmarkInAgentCountry(record)) {
      return;
    }
    if (landmarkMatchesQuery(record, qLower) ||
        record.naim.toLowerCase().startsWith(qLower)) {
      merged[record.reference.path] = record;
    }
  }

  for (final record in AdminLandmarkIndex.searchLocal(term)) {
    add(record);
    if (merged.length >= kAdminSearchLimit) {
      return merged.values.toList(growable: false);
    }
  }

  final prefix = _prefixQuery(term, partnersOnly).limit(kAdminSearchLimit);

  try {
    final cached = await prefix.get(const GetOptions(source: Source.cache));
    for (final doc in cached.docs) {
      add(MkanRecord.fromSnapshot(doc));
      if (merged.length >= kAdminSearchLimit) {
        return merged.values.toList(growable: false);
      }
    }
  } catch (_) {}

  try {
    final cachedScan = await _landmarksListQuery(partnersOnly)
        .limit(kAdminSearchCacheScanLimit)
        .get(const GetOptions(source: Source.cache));
    for (final doc in cachedScan.docs) {
      add(MkanRecord.fromSnapshot(doc));
      if (merged.length >= kAdminSearchLimit) {
        return merged.values.toList(growable: false);
      }
    }
  } catch (_) {}

  if (merged.length < kAdminSearchLimit) {
    try {
      final server = await prefix.get(const GetOptions(source: Source.server));
      for (final doc in server.docs) {
        add(MkanRecord.fromSnapshot(doc));
        if (merged.length >= kAdminSearchLimit) break;
      }
    } catch (_) {}
  }

  return merged.values.toList(growable: false);
}

Query _landmarksListQuery(bool partnersOnly) {
  if (partnersOnly) {
    var q = MkanRecord.collection.where('isShrek', isEqualTo: true)
        as Query<Map<String, dynamic>>;
    if (AdminRoleService.isCountryAgent) {
      q = AdminCountryScope.applyLandmarkCountryFilter(q);
    }
    return q;
  }
  return AdminCountryScope.applyMkanQuery(MkanRecord.collection);
}
