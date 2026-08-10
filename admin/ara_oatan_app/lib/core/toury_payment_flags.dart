/// Unified payment feature flags for cash-only release + Payment API.
///
/// Firebase paymentApi (preferred — Express on Cloud Functions):
/// ```
/// flutter run \
///   --dart-define=ENABLE_ONLINE_PAYMENT=true \
///   --dart-define=PAYMENT_BACKEND=external_api \
///   --dart-define=PAYMENT_API_BASE_URL=https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi
/// ```
///
/// Browser/Safari HPP test (avoids simulator WebView 3DS issues):
/// ```
///   --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
/// ```
///
/// `vercel_api` remains accepted as a legacy alias of `external_api`.
/// Render (`touri-ban.onrender.com`) remains a rollback URL only.
///
/// N-Genius **production** is controlled by the backend `NGENIUS_ENV`
/// (Firebase Function / Render), not by Flutter.
///
/// Does **not** delete N-Genius code, payment_sessions, webhooks, or CFs.
abstract final class TouryPaymentFlags {
  /// When true, cash bookings may use constrained client Firestore create if
  /// Cloud Function is missing. **Production default is false** — create via CF only.
  /// Opt-in for local/no-billing: `--dart-define=TOURY_CLIENT_CASH_FALLBACK=true`
  static const bool allowClientCashFallback = bool.fromEnvironment(
    'TOURY_CLIENT_CASH_FALLBACK',
    defaultValue: false,
  );

  /// Compile-time flag. Default **false** = cash on delivery only.
  static const bool enableOnlinePayment = bool.fromEnvironment(
    'ENABLE_ONLINE_PAYMENT',
    defaultValue: false,
  );

  /// `firebase_functions` | `external_api` | `vercel_api` (alias) | `cash_only`
  /// Prefer `external_api` + [paymentApiBaseUrl] pointing at Firebase `paymentApi`.
  static const String paymentBackend = String.fromEnvironment(
    'PAYMENT_BACKEND',
    defaultValue: 'external_api',
  );

  /// Public Payment API base URL — no trailing slash.
  /// Default: Firebase `paymentApi` (same Express app previously on Render).
  static const String paymentApiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue:
        'https://us-central1-tutorial-multi-language-70gx4j.cloudfunctions.net/paymentApi',
  );

  /// When true, open Hosted Payment Page in the system browser (Safari)
  /// instead of the in-app WebView. Useful to isolate simulator WebView/3DS issues:
  /// `--dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true`
  static const bool openPaymentInExternalBrowser = bool.fromEnvironment(
    'OPEN_PAYMENT_IN_EXTERNAL_BROWSER',
    defaultValue: false,
  );

  static bool get cashOnlyMode =>
      !enableOnlinePayment || paymentBackend == 'cash_only';

  /// HTTP Payment API (Firebase `paymentApi` or Render rollback).
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
