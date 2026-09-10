import '/core/admin_qa_fixture.dart';

/// Order → settlement status from [financial_settlements] (canonical SoT).
///
/// Does not read order.settlement_status flags.
abstract final class FinanceSotSettlementIndex {
  FinanceSotSettlementIndex._();

  static const _orderIdKeys = ['eligibleOrderIds', 'orderIds', 'lineOrderIds'];

  /// Best ledger status per order id (settled preferred over open drafts).
  static Map<String, String> statusByOrderId(
    Iterable<Map<String, dynamic>> settlements,
  ) {
    final out = <String, String>{};
    final rank = <String, int>{};

    for (final raw in settlements) {
      final id = '${raw['id'] ?? raw['settlementId'] ?? ''}'.trim();
      if (AdminQaFixture.isFinanceQaSettlement(raw, settlementId: id)) {
        continue;
      }
      final st = (raw['status'] ?? '').toString().trim().toLowerCase();
      if (st.isEmpty || st == 'voided') continue;
      final r = _rank(st);

      for (final key in _orderIdKeys) {
        final list = raw[key];
        if (list is! List) continue;
        for (final oidRaw in list) {
          final oid = '$oidRaw'.trim();
          if (oid.isEmpty) continue;
          final prev = rank[oid];
          if (prev == null || r > prev) {
            rank[oid] = r;
            out[oid] = st;
          }
        }
      }
    }
    return out;
  }

  static int _rank(String status) {
    switch (status) {
      case 'settled':
        return 50;
      case 'partially_paid':
        return 40;
      case 'locked':
        return 30;
      case 'open':
      case 'pending':
        return 20;
      case 'draft':
        return 10;
      default:
        return 1;
    }
  }
}
