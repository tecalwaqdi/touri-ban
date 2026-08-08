/// Unified payment feature flags for cash-only release + external Payment API.
///
/// Sandbox card test (Render Express — do **not** hardcode URL in source):
/// ```
/// flutter run \
///   --dart-define=ENABLE_ONLINE_PAYMENT=true \
///   --dart-define=PAYMENT_BACKEND=external_api \
///   --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
/// ```
///
/// `vercel_api` remains accepted as a legacy alias of `external_api`.
///
/// N-Genius **production** cannot be enabled from Flutter. Only the Render
/// service `NGENIUS_ENV` controls sandbox vs production.
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

  /// `firebase_functions` | `external_api` | `vercel_api` (alias) | `cash_only`
  static const String paymentBackend = String.fromEnvironment(
    'PAYMENT_BACKEND',
    defaultValue: 'firebase_functions',
  );

  /// Public Render (or local) payment API base URL — no trailing slash.
  /// Set only via `--dart-define=PAYMENT_API_BASE_URL=...` (never commit secrets).
  static const String paymentApiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: '',
  );

  static bool get cashOnlyMode =>
      !enableOnlinePayment || paymentBackend == 'cash_only';

  /// External Express Payment API (Render). Preferred identifier: `external_api`.
  static bool get useExternalPaymentApi {
    if (!enableOnlinePayment || paymentApiBaseUrl.isEmpty) return false;
    return paymentBackend == 'external_api' || paymentBackend == 'vercel_api';
  }

  /// Legacy alias — prefer [useExternalPaymentApi].
  static bool get useVercelPaymentApi => useExternalPaymentApi;

  static bool get useFirebasePaymentFunctions =>
      enableOnlinePayment &&
      !useExternalPaymentApi &&
      paymentBackend != 'cash_only';

  /// When online is disabled, cash must remain selectable even if remote
  /// `Settings.OKcash` is unset/false (local cash-only wave).
  static bool cashOptionVisible({required bool remoteOkCash}) {
    if (cashOnlyMode) return true;
    return remoteOkCash;
  }

  static bool onlineOptionVisible() => enableOnlinePayment && !cashOnlyMode;
}
