import '/core/admin_qa_fixture.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_accounting_engine.dart';

/// Unsettled trip exposure for AR/AP (COMPLETE collected/paid, not settled).
///
/// Wallet is never included. QA fixtures excluded.
abstract final class FinanceUnsettledExposure {
  FinanceUnsettledExposure._();

  static List<AccountantTripRow> unsettledFromRows(
    Iterable<AccountantTripRow> rows,
  ) {
    return rows.where((r) {
      if (AdminQaFixture.isFixtureId(r.orderId)) return false;
      if (r.dataQuality != FinancialDataQuality.complete) return false;
      if (!r.operationallyCompleted) return false;
      if (_claimedInLockedOrSettled(r)) return false;
      final cashCollected = r.collectionStatusLabel.contains('محصّل') ||
          r.paymentStatusLabel.contains('محصّل');
      final onlinePaid = r.paymentChannelLabel == 'إلكتروني' &&
          (r.paymentStatusLabel.contains('مدفوع') ||
              r.paymentStatusLabel.toLowerCase().contains('paid'));
      final cashChannel = r.paymentChannelLabel == 'نقدي';
      if (cashChannel) return cashCollected;
      if (r.paymentChannelLabel == 'إلكتروني') return onlinePaid;
      return false;
    }).toList(growable: false);
  }

  static bool _claimedInLockedOrSettled(AccountantTripRow r) {
    final st = r.settlementStatusLabel;
    return st.contains('مسوّى') ||
        st.contains('مقفلة') ||
        st.toLowerCase().contains('locked') ||
        st.toLowerCase().contains('settled');
  }

  /// Company receivable side: cash collected unsettled (driver holds cash).
  static List<AccountantTripRow> companyReceivables(
    Iterable<AccountantTripRow> rows,
  ) =>
      unsettledFromRows(rows)
          .where((r) => r.paymentChannelLabel == 'نقدي')
          .toList(growable: false);

  /// Driver payable side: online paid unsettled.
  static List<AccountantTripRow> driverPayables(
    Iterable<AccountantTripRow> rows,
  ) =>
      unsettledFromRows(rows)
          .where((r) => r.paymentChannelLabel == 'إلكتروني')
          .toList(growable: false);

  static bool isSettlementEligibleLine(FinancialOrderLine line) =>
      line.settlementEligible &&
      !AdminQaFixture.isFixtureId(line.orderId);
}
