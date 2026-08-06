/// Unified payment feature flags for cash-only release wave + Vercel migration.
///
/// Re-enable online later with:
/// ```
/// flutter run --dart-define=ENABLE_ONLINE_PAYMENT=true
/// ```
///
/// Select payment backend:
/// ```
/// --dart-define=PAYMENT_BACKEND=vercel_api
/// --dart-define=PAYMENT_API_BASE_URL=https://your-deployment.vercel.app
/// ```
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

  /// `firebase_functions` | `vercel_api` | `cash_only`
  static const String paymentBackend = String.fromEnvironment(
    'PAYMENT_BACKEND',
    defaultValue: 'firebase_functions',
  );

  /// Public Vercel (or local) payment API base URL — no trailing slash.
  static const String paymentApiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: '',
  );

  static bool get cashOnlyMode =>
      !enableOnlinePayment || paymentBackend == 'cash_only';

  static bool get useVercelPaymentApi =>
      enableOnlinePayment &&
      paymentBackend == 'vercel_api' &&
      paymentApiBaseUrl.isNotEmpty;

  static bool get useFirebasePaymentFunctions =>
      enableOnlinePayment &&
      !useVercelPaymentApi &&
      paymentBackend != 'cash_only';

  /// When online is disabled, cash must remain selectable even if remote
  /// `Settings.OKcash` is unset/false (local cash-only wave).
  static bool cashOptionVisible({required bool remoteOkCash}) {
    if (cashOnlyMode) return true;
    return remoteOkCash;
  }

  static bool onlineOptionVisible() => enableOnlinePayment && !cashOnlyMode;
}
