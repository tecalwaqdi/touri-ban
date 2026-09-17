import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Current Touri platform commission policy (new calculations only).
///
/// Historical trips always keep persisted `total_app` / [FinancialOrderLine.platformFee].
/// This policy is used only to **flag** mismatches — never to overwrite money.
abstract final class PlatformCommissionPolicy {
  PlatformCommissionPolicy._();

  /// Approved current platform commission rate for new bookings.
  static const double currentRatePercent = 15.0;

  /// Policy effective date (UTC) — matches Admin Next FC-01 approval.
  static final DateTime effectiveFromUtc = DateTime.utc(2026, 9, 13);

  /// Minor-unit tolerance when comparing expected vs persisted fee.
  static const int mismatchToleranceMinor = 1;

  static bool appliesToOrderDate(DateTime? orderedAt) {
    if (orderedAt == null) return false;
    return !orderedAt.toUtc().isBefore(effectiveFromUtc);
  }

  /// Expected platform fee minor from gross base at the current policy rate.
  /// Returns null when gross base is unavailable (missing ≠ 0).
  static int? expectedPlatformFeeMinor(MoneyAmount? grossBase) {
    if (grossBase == null) return null;
    final expected =
        (grossBase.minorUnits * currentRatePercent / 100.0).round();
    return expected;
  }

  /// True when a completed trip under the current policy has a persisted
  /// platform fee that disagrees with 15% of gross base.
  static bool hasCurrentPolicyMismatch(FinancialOrderLine line) {
    if (!appliesToOrderDate(line.orderedAt)) return false;
    if (line.lifecycle != FinancialLifecycle.completed) return false;
    final expected = expectedPlatformFeeMinor(line.grossBase);
    final actual = line.platformFee?.minorUnits;
    if (expected == null || actual == null) return false;
    return (actual - expected).abs() > mismatchToleranceMinor;
  }
}
