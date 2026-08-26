import 'package:flutter/foundation.dart';

/// Unified payment feature flags — **Render is the production Payment Backend**.
///
/// Customer App → Render (`touri-ban.onrender.com`) → N-Genius.
///
/// Production / store defaults (override only for explicit rollback):
/// ```
/// flutter run \
///   --dart-define=ENABLE_ONLINE_PAYMENT=true \
///   --dart-define=PAYMENT_BACKEND=external_api \
///   --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com \
///   --dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true \
///   --dart-define=TOURY_CLIENT_CASH_FALLBACK=true
/// ```
///
/// Firebase `paymentApi` / CF callables remain in-repo as **Future / Legacy /
/// Rollback only**. They are never selected unless
/// `PAYMENT_BACKEND=firebase_functions` is set explicitly.
///
/// N-Genius **production** is controlled by the backend `NGENIUS_ENV`
/// (Render), not by Flutter. Do not change PURCHASE / HPP / webhook logic here.
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
  /// Only used for **HPP fallback** after native is unavailable — never as
  /// the iOS primary path. Rollback: `--dart-define=OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true`
  static const bool openPaymentInExternalBrowser = bool.fromEnvironment(
    'OPEN_PAYMENT_IN_EXTERNAL_BROWSER',
    defaultValue: true,
  );

  /// Mobile checkout experience: `sdk` (N-Genius native primary) | `hpp` (legacy).
  ///
  /// iOS release default is **sdk**. Safe rollback:
  /// `--dart-define=MOBILE_PAYMENT_MODE=hpp`
  static const String mobilePaymentMode = String.fromEnvironment(
    'MOBILE_PAYMENT_MODE',
    defaultValue: 'sdk',
  );

  /// Prefer in-app N-Genius Mobile SDK when available (iOS/Android).
  static bool get preferMobileSdk =>
      enableOnlinePayment &&
      !cashOnlyMode &&
      !kIsWeb &&
      mobilePaymentMode.toLowerCase() != 'hpp';

  /// Force Hosted Payment Page (safe rollback without native SDK).
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
