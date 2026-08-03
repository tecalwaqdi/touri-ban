
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Server-side partner booking queries via denormalized `partner_mkans`.
class AdminPartnerOrders {
  AdminPartnerOrders._();

  /// Extracts unique landmark refs from an order's nested structures.
  static List<DocumentReference> extractPartnerMkans(OrderRecord order) {
    final seen = <String>{};
    final refs = <DocumentReference>[];

    void addRef(DocumentReference ref) {
      if (seen.add(ref.path)) {
        refs.add(ref);
      }
    }

    for (final item in order.listAmakn) {
      for (final ref in item.mkanRev) {
        addRef(ref);
      }
    }
    for (final ref in order.listamakn.mkanRev) {
      addRef(ref);
    }
    for (final ref in order.partnerMkans) {
      addRef(ref);
    }
    return refs;
  }

  /// Firestore map patch to keep `partner_mkans` in sync with landmarks.
  static Map<String, dynamic> partnerMkansPatch(OrderRecord order) {
    final refs = extractPartnerMkans(order);
    if (refs.isEmpty) {
      return {'partner_mkans': FieldValue.delete()};
    }
    return {'partner_mkans': refs};
  }

  /// Active bookings for a partner landmark (indexed query).
  static Query applyPartnerOrderQuery(
    Query collection,
    DocumentReference partnerMkan, {
    DocumentReference? countryRef,
  }) {
    var q = (collection as Query<Map<String, dynamic>>)
        .where('ALLNOW', isEqualTo: true)
        .where('partner_mkans', arrayContains: partnerMkan);
    if (countryRef != null) {
      q = q.where('Rev_dolh', isEqualTo: countryRef);
    }
    return q.orderBy('data_order', descending: true);
  }

  /// Fast count for partner dashboard stats.
  static Future<int> countActiveBookings(DocumentReference partnerMkan) {
    return queryOrderRecordCount(
      queryBuilder: (q) => applyPartnerOrderQuery(q, partnerMkan),
    );
  }

  static DocumentReference? get currentPartnerMkan =>
      AdminRoleService.partnerMkanRef;
}
