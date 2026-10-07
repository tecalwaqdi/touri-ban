import 'package:flutter/foundation.dart';

/// Unified payment feature flags — **Render is the production Payment Backend**.
///
/// Customer App → Render (`touri-ban.onrender.com`) → N-Genius.
///
/// ## Production / store default (proven HPP in-app WebView)
/// ```
/// flutter build … \
///   --dart-define=ENABLE_ONLINE_PAYMENT=true \
///   --dart-define=PAYMENT_BACKEND=external_api \
///   --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com \
///   --dart-define=MOBILE_PAYMENT_MODE=hpp \
///   --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false \
///   --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
/// ```
/// HPP stays the production checkout path; open it in the in-app WebView so
/// users do not leave for Safari. Native SDK remains QA-only until promoted.
///
/// ## QA-only native SDK (TestFlight / local device — never store production)
/// Use `admin/scripts/build_customer_*_qa_native_sdk.sh`:
/// ```
///   --dart-define=MOBILE_PAYMENT_MODE=sdk \
///   --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false
/// ```
/// Promote SDK to production defaults only after SAFE_TO_PROMOTE_SDK=YES.
///
/// Native NISdk / Android PaymentClient remain in the app binary; production
/// builds simply force HPP via [forceHostedPaymentPage] until promoted.
///
/// Firebase `paymentApi` / CF callables remain **opt-in rollback only**.
abstract final class TouryPaymentFlags {
  /// Compile-time: `--dart-define=TOURY_CLIENT_CASH_FALLBACK=true`
  /// Default **true** — constrained client cash create when CF IAM is down.
  static const bool allowClientCashFallback = bool.fromEnvironment(
    'TOURY_CLIENT_CASH_FALLBACK',
    defaultValue: true,
  );

  /// Runtime gate used by booking. Debug builds also allow the constrained
  /// client cash create when `createCashBooking` CF IAM is broken.
  static bool get allowClientCashFallbackRuntime =>
      allowClientCashFallback || kDebugMode;

  /// Compile-time flag. Default **true** — card + cash (Render for card).
  static const bool enableOnlinePayment = bool.fromEnvironment(
    'ENABLE_ONLINE_PAYMENT',
    defaultValue: true,
  );

  /// `external_api` (Render) | `vercel_api` (alias) | `firebase_functions`
  /// (legacy/rollback only) | `cash_only`
  static const String paymentBackend = String.fromEnvironment(
    'PAYMENT_BACKEND',
    defaultValue: 'external_api',
  );

  /// Public Payment API base URL — no trailing slash.
  /// Default: Render production Payment Backend.
  static const String paymentApiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: 'https://touri-ban.onrender.com',
  );

  /// When true, open Hosted Payment Page in Safari / system browser.
  /// Production / store default **false** — keep HPP inside the in-app WebView.
  /// Set true only for deliberate external-browser experiments.
  static const bool openPaymentInExternalBrowser = bool.fromEnvironment(
    'OPEN_PAYMENT_IN_EXTERNAL_BROWSER',
    defaultValue: false,
  );

  /// Mobile checkout experience: `sdk` | `hpp`.
  ///
  /// Production / store default is **hpp** until native QA gate passes.
  /// QA builds: `--dart-define=MOBILE_PAYMENT_MODE=sdk`
  static const String mobilePaymentMode = String.fromEnvironment(
    'MOBILE_PAYMENT_MODE',
    defaultValue: 'hpp',
  );

  /// Prefer in-app N-Genius Mobile SDK when available (iOS/Android).
  static bool get preferMobileSdk =>
      enableOnlinePayment &&
      !cashOnlyMode &&
      !kIsWeb &&
      mobilePaymentMode.toLowerCase() != 'hpp';

  /// Force Hosted Payment Page (production default until SDK promotion).
  static bool get forceHostedPaymentPage =>
      !preferMobileSdk || mobilePaymentMode.toLowerCase() == 'hpp';

  static bool get cashOnlyMode =>
      !enableOnlinePayment || paymentBackend == 'cash_only';

  /// HTTP Payment API on Render (production). Never falls back to Firebase.
  static bool get useExternalPaymentApi {
    if (!enableOnlinePayment || paymentApiBaseUrl.isEmpty) return false;
    return paymentBackend == 'external_api' || paymentBackend == 'vercel_api';
  }

  /// Legacy alias — prefer [useExternalPaymentApi].
  static bool get useVercelPaymentApi => useExternalPaymentApi;

  /// Firebase CF payment callables — **opt-in rollback only**.
  /// Requires explicit `PAYMENT_BACKEND=firebase_functions`.
  static bool get useFirebasePaymentFunctions =>
      enableOnlinePayment && paymentBackend == 'firebase_functions';

  /// When online is disabled, cash must remain selectable even if remote
  /// `Settings.OKcash` is unset/false (local cash-only wave).
  static bool cashOptionVisible({required bool remoteOkCash}) {
    if (cashOnlyMode) return true;
    return remoteOkCash;
  }

  static bool onlineOptionVisible() => enableOnlinePayment && !cashOnlyMode;
}
