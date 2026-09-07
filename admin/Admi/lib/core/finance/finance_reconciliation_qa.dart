import '/backend/schema/order_record.dart';
import '/core/admin_qa_fixture.dart';

/// B1 reconciliation QA exclusion — composed, read-only.
///
/// Includes frozen [AdminQaFixture] plus **proven** supplemental markers from
/// F3-B0 live evidence (do not broaden by weak naming guesses):
///
/// | Marker | Evidence |
/// |---|---|
/// | `functional_test == true` | Live golden `CASH-03392F80A1` / `03392f80…` |
/// | `golden_cycle == TOURi_GOLDEN_1` | Same trip; B0 soft gap vs AdminQaFixture |
/// | AdminQaFixture prefixes / `is_test_fixture` | fin7 / fin9 / fin_rt / meta |
abstract final class FinanceReconciliationQa {
  FinanceReconciliationQa._();

  static const goldenCycleToury1 = 'TOURi_GOLDEN_1';

  /// Reconciliation-specific composed predicate.
  static bool isReconciliationQaFixture(
    Map<String, dynamic> data, {
    String? orderId,
  }) {
    if (AdminQaFixture.isFixtureMap(data, orderId: orderId)) return true;

    if (data['functional_test'] == true) return true;

    final cycle = '${data['golden_cycle'] ?? ''}'.trim();
    if (cycle == goldenCycleToury1) return true;

    return false;
  }

  static bool isReconciliationQaOrder(OrderRecord order) =>
      isReconciliationQaFixture(
        Map<String, dynamic>.from(order.snapshotData),
        orderId: order.reference.id,
      );

  static bool isReconciliationQaSettlement(
    Map<String, dynamic> data, {
    String? settlementId,
    Iterable<String>? paymentExternalRefs,
  }) {
    if (AdminQaFixture.isFinanceQaSettlement(
      data,
      settlementId: settlementId,
      paymentExternalRefs: paymentExternalRefs,
    )) {
      return true;
    }
    // Settlement that only references reconciliation QA order ids.
    for (final key in ['eligibleOrderIds', 'orderIds', 'lineOrderIds']) {
      final raw = data[key];
      if (raw is! List) continue;
      for (final id in raw) {
        final oid = '$id'.trim();
        if (oid.isEmpty) continue;
        // Order-id-only golden is not in AdminQaFixture prefixes — skip unless
        // settlement itself carries functional_test / golden_cycle.
      }
    }
    return isReconciliationQaFixture(data, orderId: settlementId);
  }
}
