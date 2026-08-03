
import '/backend/admin_partner_orders.dart';
import '/backend/backend.dart';

/// Backfills `partner_mkans` on existing orders from nested `listAmakn` data.
class AdminPartnerOrderBackfill {
  AdminPartnerOrderBackfill._();

  static const _pageSize = 100;
  static const _maxPages = 50;

  static Future<PartnerOrderBackfillResult> run({
    bool activeOnly = true,
  }) async {
    var scanned = 0;
    var updated = 0;
    var skipped = 0;
    DocumentSnapshot? cursor;

    for (var page = 0; page < _maxPages; page++) {
      Query query = OrderRecord.collection
          .orderBy(FieldPath.documentId)
          .limit(_pageSize);
      if (activeOnly) {
        query = OrderRecord.collection
            .where('ALLNOW', isEqualTo: true)
            .orderBy(FieldPath.documentId)
            .limit(_pageSize);
      }
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get().timeout(const Duration(seconds: 30));
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      var batchOps = 0;

      for (final doc in snap.docs) {
        scanned++;
        final order = OrderRecord.fromSnapshot(doc);
        final extracted = AdminPartnerOrders.extractPartnerMkans(order);
        final existing = order.partnerMkans.map((r) => r.path).toSet();
        final extractedPaths = extracted.map((r) => r.path).toSet();

        if (extracted.isEmpty) {
          if (order.hasPartnerMkans()) {
            batch.update(doc.reference, {'partner_mkans': FieldValue.delete()});
            batchOps++;
            updated++;
          } else {
            skipped++;
          }
          continue;
        }

        if (existing.length == extractedPaths.length &&
            existing.containsAll(extractedPaths)) {
          skipped++;
          continue;
        }

        batch.update(doc.reference, {'partner_mkans': extracted});
        batchOps++;
        updated++;
      }

      if (batchOps > 0) {
        await batch.commit().timeout(const Duration(seconds: 30));
      }

      cursor = snap.docs.last;
      if (snap.docs.length < _pageSize) break;
    }

    return PartnerOrderBackfillResult(
      scanned: scanned,
      updated: updated,
      skipped: skipped,
    );
  }
}

class PartnerOrderBackfillResult {
  const PartnerOrderBackfillResult({
    required this.scanned,
    required this.updated,
    required this.skipped,
  });

  final int scanned;
  final int updated;
  final int skipped;
}
