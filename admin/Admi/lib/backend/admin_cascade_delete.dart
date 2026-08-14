import '/backend/admin_dashboard_invalidate.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_storage_cleanup.dart';
import '/backend/backend.dart';

const _batchLimit = 450;

/// Progress callback for long cascade scans (UI feedback only).
typedef AdminCascadeProgress = void Function(String phase, int fetched);

Future<void> _commitDeleteBatch(List<DocumentReference> refs) async {
  for (var i = 0; i < refs.length; i += _batchLimit) {
    final batch = FirebaseFirestore.instance.batch();
    final chunk = refs.skip(i).take(_batchLimit);
    for (final ref in chunk) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}

Future<void> _commitUpdateBatch(
  Map<DocumentReference, Map<String, dynamic>> updates,
) async {
  final entries = updates.entries.toList();
  for (var i = 0; i < entries.length; i += _batchLimit) {
    final batch = FirebaseFirestore.instance.batch();
    final chunk = entries.skip(i).take(_batchLimit);
    for (final entry in chunk) {
      batch.update(entry.key, entry.value);
    }
    await batch.commit();
  }
}

/// Paginates until the query is exhausted.
///
/// Unlike list UI (`kAdminMaxPages`), cascade must not silently stop early.
/// Hits [kAdminCascadeMaxDocs] → throws so the caller can abort safely.
Future<List<DocumentSnapshot>> _paginatedDocs(
  Query baseQuery, {
  AdminCascadeProgress? onProgress,
  String phase = 'scan',
}) async {
  final docs = <DocumentSnapshot>[];
  DocumentSnapshot? last;

  while (true) {
    var query = baseQuery.limit(kAdminCascadePageSize);
    if (last != null) query = query.startAfterDocument(last);
    final snap = await query.get();
    if (snap.docs.isEmpty) break;
    docs.addAll(snap.docs);
    last = snap.docs.last;
    onProgress?.call(phase, docs.length);
    if (snap.size < kAdminCascadePageSize) break;
    if (docs.length >= kAdminCascadeMaxDocs) {
      throw StateError(
        'Cascade incomplete: safety cap ($kAdminCascadeMaxDocs) reached during $phase. '
        'No further deletes were attempted for this page window — retry or split the operation.',
      );
    }
  }

  return docs;
}

Future<List<DocumentReference>> _paginatedRefs(
  Query baseQuery, {
  AdminCascadeProgress? onProgress,
  String phase = 'scan',
}) async {
  final docs = await _paginatedDocs(
    baseQuery,
    onProgress: onProgress,
    phase: phase,
  );
  return docs.map((d) => d.reference).toList();
}

void _collectImageUrls(List<String?> sink, DocumentSnapshot snap) {
  final raw = snap.data();
  if (raw is Map<String, dynamic>) {
    sink.addAll(adminImageUrlsFromData(raw));
  } else if (raw is Map) {
    sink.addAll(adminImageUrlsFromData(Map<String, dynamic>.from(raw)));
  }
}

/// Deletes a city/village and its landmarks (+ Storage images).
///
/// Only runs when an admin explicitly deletes a city — never auto-invoked.
Future<void> deleteCityCascade(
  DocumentReference villageRef, {
  AdminCascadeProgress? onProgress,
}) async {
  final imageUrls = <String?>[];
  final landmarkDocs = await _paginatedDocs(
    MkanRecord.collection.where('id_vill', isEqualTo: villageRef),
    onProgress: onProgress,
    phase: 'city_landmarks',
  );
  for (final doc in landmarkDocs) {
    _collectImageUrls(imageUrls, doc);
  }

  final villageSnap = await villageRef.get();
  if (villageSnap.exists) {
    _collectImageUrls(imageUrls, villageSnap);
  }

  final toDelete = <DocumentReference>[
    ...landmarkDocs.map((d) => d.reference),
    villageRef,
  ];

  onProgress?.call('city_delete', toDelete.length);
  await _commitDeleteBatch(toDelete);
  await AdminFirestoreDelete.verifyDeleted(villageRef);
  await deleteAdminStorageUrls(imageUrls);
  invalidateAdminDashboardStats();
}

/// Deletes a region and related villages + landmarks (+ Storage images).
Future<void> deleteRegionCascade(
  DocumentReference regionRef, {
  bool notifyStats = true,
  AdminCascadeProgress? onProgress,
}) async {
  final imageUrls = <String?>[];
  final toDelete = <DocumentReference>[];

  final villageDocs = await _paginatedDocs(
    VillagesRecord.collection.where('cities', isEqualTo: regionRef),
    onProgress: onProgress,
    phase: 'region_cities',
  );

  final byRegionDocs = await _paginatedDocs(
    MkanRecord.collection.where('id_cit', isEqualTo: regionRef),
    onProgress: onProgress,
    phase: 'region_landmarks',
  );
  for (final doc in byRegionDocs) {
    _collectImageUrls(imageUrls, doc);
    toDelete.add(doc.reference);
  }

  for (final villageDoc in villageDocs) {
    _collectImageUrls(imageUrls, villageDoc);
    final byVillageDocs = await _paginatedDocs(
      MkanRecord.collection.where('id_vill', isEqualTo: villageDoc.reference),
      onProgress: onProgress,
      phase: 'city_landmarks',
    );
    for (final doc in byVillageDocs) {
      _collectImageUrls(imageUrls, doc);
      toDelete.add(doc.reference);
    }
    toDelete.add(villageDoc.reference);
  }

  final regionSnap = await regionRef.get();
  if (regionSnap.exists) {
    _collectImageUrls(imageUrls, regionSnap);
  }
  toDelete.add(regionRef);

  final unique = {for (final r in toDelete) r.path: r}.values.toList();
  onProgress?.call('region_delete', unique.length);
  await _commitDeleteBatch(unique);
  await AdminFirestoreDelete.verifyDeleted(regionRef);
  await deleteAdminStorageUrls(imageUrls);
  if (notifyStats) {
    invalidateAdminDashboardStats();
  }
}

/// Deletes a country and all nested regions, cities, landmarks (+ Storage).
Future<void> deleteCountryCascade(
  DocumentReference countryRef, {
  AdminCascadeProgress? onProgress,
}) async {
  final imageUrls = <String?>[];
  final regionRefs = await _paginatedRefs(
    CitiesRecord.collection.where('dolh', isEqualTo: countryRef),
    onProgress: onProgress,
    phase: 'country_regions',
  );

  for (final regionRef in regionRefs) {
    await deleteRegionCascade(
      regionRef,
      notifyStats: false,
      onProgress: onProgress,
    );
  }

  // Landmarks linked only by country ref (missing id_cit/id_vill).
  final orphanLandmarks = await _paginatedDocs(
    MkanRecord.collection.where('Rev_dolh', isEqualTo: countryRef),
    onProgress: onProgress,
    phase: 'country_orphan_landmarks',
  );
  final orphanRefs = <DocumentReference>[];
  for (final doc in orphanLandmarks) {
    _collectImageUrls(imageUrls, doc);
    orphanRefs.add(doc.reference);
  }
  if (orphanRefs.isNotEmpty) {
    onProgress?.call('orphan_delete', orphanRefs.length);
    await _commitDeleteBatch(orphanRefs);
  }

  final countrySnap = await countryRef.get();
  if (countrySnap.exists) {
    _collectImageUrls(imageUrls, countrySnap);
  }

  await countryRef.delete();
  await AdminFirestoreDelete.verifyDeleted(countryRef);
  await deleteAdminStorageUrls(imageUrls);
  invalidateAdminDashboardStats();
}

/// Syncs landmark visibility when a region is activated/deactivated.
Future<void> setRegionLandmarksActive(
  DocumentReference regionRef,
  bool active, {
  AdminCascadeProgress? onProgress,
}) async {
  final updates = <DocumentReference, Map<String, dynamic>>{};

  final byRegion = await _paginatedRefs(
    MkanRecord.collection.where('id_cit', isEqualTo: regionRef),
    onProgress: onProgress,
    phase: 'region_landmarks_active',
  );
  for (final ref in byRegion) {
    updates[ref] = createMkanRecordData(acctev: active);
  }

  final villageRefs = await _paginatedRefs(
    VillagesRecord.collection.where('cities', isEqualTo: regionRef),
    onProgress: onProgress,
    phase: 'region_cities_active',
  );
  for (final villageRef in villageRefs) {
    final byVillage = await _paginatedRefs(
      MkanRecord.collection.where('id_vill', isEqualTo: villageRef),
      onProgress: onProgress,
      phase: 'city_landmarks_active',
    );
    for (final ref in byVillage) {
      updates[ref] = createMkanRecordData(acctev: active);
    }
  }

  if (updates.isNotEmpty) {
    onProgress?.call('apply_active', updates.length);
    await _commitUpdateBatch(updates);
  }
}

/// Syncs landmark visibility when a city/village is activated/deactivated.
Future<void> setCityLandmarksActive(
  DocumentReference villageRef,
  bool active, {
  AdminCascadeProgress? onProgress,
}) async {
  final updates = <DocumentReference, Map<String, dynamic>>{};
  final byVillage = await _paginatedRefs(
    MkanRecord.collection.where('id_vill', isEqualTo: villageRef),
    onProgress: onProgress,
    phase: 'city_landmarks_active',
  );
  for (final ref in byVillage) {
    updates[ref] = createMkanRecordData(acctev: active);
  }
  if (updates.isNotEmpty) {
    onProgress?.call('apply_active', updates.length);
    await _commitUpdateBatch(updates);
  }
}
