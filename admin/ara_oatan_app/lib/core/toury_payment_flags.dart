/// Unified payment feature flags for cash-only release wave.
///
/// Re-enable online later with:
/// ```
/// flutter run --dart-define=ENABLE_ONLINE_PAYMENT=true
/// ```
/// or flip [enableOnlinePayment] default after Billing + Secrets + Sandbox E2E.
///
/// Does **not** delete N-Genius code, payment_sessions, webhooks, or CFs.
abstract final class TouryPaymentFlags {
  /// When true (default), cash bookings may use constrained client Firestore
  /// create if Cloud Function is missing/unavailable (no Blaze billing yet).
  static const bool allowClientCashFallback = bool.fromEnvironment(
    'TOURY_CLIENT_CASH_FALLBACK',
    defaultValue: true,
  );

  /// Compile-time flag. Default **false** = cash on delivery only.
  static const bool enableOnlinePayment = bool.fromEnvironment(
    'ENABLE_ONLINE_PAYMENT',
    defaultValue: false,
  );

  static bool get cashOnlyMode => !enableOnlinePayment;

  /// When online is disabled, cash must remain selectable even if remote
  /// `Settings.OKcash` is unset/false (local cash-only wave).
  static bool cashOptionVisible({required bool remoteOkCash}) {
    if (cashOnlyMode) return true;
    return remoteOkCash;
  }

  static bool onlineOptionVisible() => enableOnlinePayment;
}
