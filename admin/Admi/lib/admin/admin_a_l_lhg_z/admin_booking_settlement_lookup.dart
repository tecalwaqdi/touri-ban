import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_role_service.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/finance_sot_settlement_index.dart';

/// Read-only booking → settlement status from `financial_settlements`.
///
/// Does not change V2 formulas, wallets, or settlement write paths.
abstract final class AdminBookingSettlementLookup {
  AdminBookingSettlementLookup._();

  /// Arabic label for list/detail. Missing link → `—` (never infer from trip).
  static String labelAr(String? rawStatus) {
    final s = (rawStatus ?? '').trim().toLowerCase();
    if (s.isEmpty) return '—';
    return AccountantFinanceLabels.settlementStatusAr(s);
  }

  /// Loads a country-scoped (or global for Super Admin) settlement index.
  static Future<Map<String, String>> loadStatusByOrderId({
    DocumentReference? countryRef,
    int cap = 200,
  }) async {
    try {
      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('financial_settlements');
      final scoped = countryRef ??
          (AdminRoleService.isCountryAgent
              ? AdminRoleService.scopedCountryRef
              : null);
      if (scoped != null) {
        q = q.where('countryId', isEqualTo: scoped.path);
      }
      q = q.orderBy('createdAt', descending: true).limit(cap);
      final snap = await q.get();
      final maps = snap.docs
          .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
          .toList(growable: false);
      return FinanceSotSettlementIndex.statusByOrderId(maps);
    } catch (_) {
      return const {};
    }
  }
}
