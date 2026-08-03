import '/backend/admin_dashboard_invalidate.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';

const _batchLimit = 450;
const _pageSize = 200;

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

Future<List<DocumentReference>> _paginatedRefs(Query baseQuery) async {
  final refs = <DocumentReference>[];
  DocumentSnapshot? last;

  while (true) {
    var query = baseQuery.limit(_pageSize);
    if (last != null) query = query.startAfterDocument(last);
    final snap = await query.get();
    if (snap.docs.isEmpty) break;
    refs.addAll(snap.docs.map((d) => d.reference));
    last = snap.docs.last;
    if (snap.size < _pageSize) break;
    if (refs.length >= kAdminMaxPages * _pageSize) break;
  }

  return refs;
}

/// Deletes a city/village and its landmarks.
Future<void> deleteCityCascade(DocumentReference villageRef) async {
  final landmarkRefs = await _paginatedRefs(
    MkanRecord.collection.where('id_vill', isEqualTo: villageRef),
  );
  final toDelete = <DocumentReference>[...landmarkRefs, villageRef];

  await _commitDeleteBatch(toDelete);
  await AdminFirestoreDelete.verifyDeleted(villageRef);
  invalidateAdminDashboardStats();
}

/// Deletes a region and related villages + landmarks.
Future<void> deleteRegionCascade(
  DocumentReference regionRef, {
  bool notifyStats = true,
}) async {
  final toDelete = <DocumentReference>[];

  final villageRefs = await _paginatedRefs(
    VillagesRecord.collection.where('cities', isEqualTo: regionRef),
  );

  toDelete.addAll(
    await _paginatedRefs(
      MkanRecord.collection.where('id_cit', isEqualTo: regionRef),
    ),
  );

  for (final villageRef in villageRefs) {
    toDelete.addAll(
      await _paginatedRefs(
        MkanRecord.collection.where('id_vill', isEqualTo: villageRef),
      ),
    );
    toDelete.add(villageRef);
  }

  toDelete.add(regionRef);

  final unique = {for (final r in toDelete) r.path: r}.values.toList();
  await _commitDeleteBatch(unique);
  await AdminFirestoreDelete.verifyDeleted(regionRef);
  if (notifyStats) {
    invalidateAdminDashboardStats();
  }
}

/// Deletes a country and all nested regions, cities, landmarks.
Future<void> deleteCountryCascade(DocumentReference countryRef) async {
  final regionRefs = await _paginatedRefs(
    CitiesRecord.collection.where('dolh', isEqualTo: countryRef),
  );

  for (final regionRef in regionRefs) {
    await deleteRegionCascade(regionRef, notifyStats: false);
  }

  await countryRef.delete();
  await AdminFirestoreDelete.verifyDeleted(countryRef);
  invalidateAdminDashboardStats();
}

/// Syncs landmark visibility when a region is activated/deactivated.
Future<void> setRegionLandmarksActive(
  DocumentReference regionRef,
  bool active,
) async {
  final updates = <DocumentReference, Map<String, dynamic>>{};

  final byRegion = await _paginatedRefs(
    MkanRecord.collection.where('id_cit', isEqualTo: regionRef),
  );
  for (final ref in byRegion) {
    updates[ref] = createMkanRecordData(acctev: active);
  }

  final villageRefs = await _paginatedRefs(
    VillagesRecord.collection.where('cities', isEqualTo: regionRef),
  );
  for (final villageRef in villageRefs) {
    final byVillage = await _paginatedRefs(
      MkanRecord.collection.where('id_vill', isEqualTo: villageRef),
    );
    for (final ref in byVillage) {
      updates[ref] = createMkanRecordData(acctev: active);
    }
  }

  if (updates.isNotEmpty) {
    await _commitUpdateBatch(updates);
  }
}
