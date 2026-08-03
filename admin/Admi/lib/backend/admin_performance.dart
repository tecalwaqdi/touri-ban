
import '/backend/backend.dart';

/// Admin list tuning — smaller first page = faster perceived load (KSA mobile).
const int kAdminPageSize = 20;
const int kAdminPageSizeLarge = 30;
const int kAdminMaxPages = 80;

/// Landmark merge caps — keep mobile memory stable (avoid OOM / force-close).
const int kAdminLandmarkMergePageSize = 80;
const int kAdminLandmarkMergeMaxPerQuery = 280;
const int kAdminLandmarkMergeTotalCap = 720;

/// Picker / dropdown queries — capped, cache-friendly.
const int kAdminPickerLimit = 150;

/// Dashboard aggregate TTL.
const Duration kAdminStatsTtl = Duration(minutes: 3);

/// Per-country landmark count cache (count queries, not full collection scan).
class AdminLandmarkCountCache {
  AdminLandmarkCountCache._();

  static final Map<String, _CountEntry> _counts = {};
  static const _ttl = Duration(minutes: 5);

  static void invalidate() => _counts.clear();

  static int peek(DocumentReference? countryRef) {
    if (countryRef == null) return 0;
    final entry = _counts[countryRef.path];
    if (entry == null) return 0;
    if (DateTime.now().difference(entry.at) > _ttl) return 0;
    return entry.count;
  }

  /// Returns cached count when fresh; `null` if not cached yet.
  static int? peekCached(DocumentReference? countryRef) {
    if (countryRef == null) return 0;
    final entry = _counts[countryRef.path];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > _ttl) return null;
    return entry.count;
  }

  /// Preloads landmark counts for many countries in parallel (agent list).
  static Future<void> preloadCountries(
    Iterable<DocumentReference> countryRefs,
  ) async {
    final unique = <String, DocumentReference>{};
    for (final ref in countryRefs) {
      unique[ref.path] = ref;
    }
    final pending = unique.values
        .where((ref) => peekCached(ref) == null)
        .toList(growable: false);
    const batchSize = 4;
    for (var i = 0; i < pending.length; i += batchSize) {
      final end =
          i + batchSize > pending.length ? pending.length : i + batchSize;
      await Future.wait(
        pending.sublist(i, end).map((ref) => countForCountry(ref)),
      );
    }
  }

  /// Firestore count for landmarks in a country (`Rev_dolh`).
  static Future<int> countForCountry(
    DocumentReference? countryRef, {
    bool force = false,
  }) async {
    if (countryRef == null) return 0;

    final path = countryRef.path;
    final existing = _counts[path];
    if (!force &&
        existing != null &&
        DateTime.now().difference(existing.at) < _ttl) {
      return existing.count;
    }

    final count = await queryMkanRecordCount(
      queryBuilder: (q) => q.where('Rev_dolh', isEqualTo: countryRef),
    );

    _counts[path] = _CountEntry(count, DateTime.now());
    return count;
  }
}

class _CountEntry {
  _CountEntry(this.count, this.at);
  final int count;
  final DateTime at;
}

/// Reads cache first (instant UI), then refreshes from server in background.
Future<QuerySnapshot> getQuerySnapshotFast(Query query) async {
  try {
    final cached = await query.get(const GetOptions(source: Source.cache));
    if (cached.docs.isNotEmpty) {
      // ignore: unawaited_futures
      query.get();
      return cached;
    }
  } catch (_) {}

  return query.get();
}

/// Cache-first list load for pickers and one-shot screens.
Future<List<T>> queryListCacheFirst<T>(
  Query collection,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = kAdminPickerLimit,
}) async {
  final base = (queryBuilder ?? (q) => q)(collection);
  final query = limit > 0 ? base.limit(limit) : base;

  try {
    final cached = await query.get(const GetOptions(source: Source.cache));
    if (cached.docs.isNotEmpty) {
      final items = mapQuerySnapshot(cached, recordBuilder);
      // ignore: unawaited_futures
      query.get();
      return items;
    }
  } catch (_) {}

  final snap = await query.get();
  return mapQuerySnapshot(snap, recordBuilder);
}

List<T> mapQuerySnapshot<T>(
  QuerySnapshot snapshot,
  RecordBuilder<T> recordBuilder,
) {
  return snapshot.docs
      .map(
        (d) => safeGet(
          () => recordBuilder(d),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .map((d) => d!)
      .toList();
}

/// Paginated Firestore scan — merges all pages up to [maxDocs].
Future<void> mergeMkanQueryPaginated(
  Query<Map<String, dynamic>> query, {
  required void Function(MkanRecord record) onRecord,
  int pageSize = kAdminLandmarkMergePageSize,
  int maxDocs = kAdminLandmarkMergeMaxPerQuery,
}) async {
  DocumentSnapshot<Map<String, dynamic>>? last;
  var fetched = 0;

  while (fetched < maxDocs) {
    Query<Map<String, dynamic>> page = query;
    if (last != null) {
      page = page.startAfterDocument(last);
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await page.limit(pageSize).get();
    } catch (_) {
      break;
    }

    if (snap.docs.isEmpty) break;

    for (final doc in snap.docs) {
      onRecord(MkanRecord.fromSnapshot(doc));
      fetched++;
      if (fetched >= maxDocs) return;
    }

    last = snap.docs.last;
    if (snap.docs.length < pageSize) break;

    // Yield so the UI thread can process frames between Firestore pages.
    await Future<void>.delayed(Duration.zero);
  }
}
