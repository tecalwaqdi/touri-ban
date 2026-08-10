/// Payment API flags for driver wallet top-up (Render → N-Genius).
///
/// ```
/// flutter run \
///   --dart-define=PAYMENT_API_BASE_URL=https://touri-ban.onrender.com \
///   --dart-define=ENABLE_WALLET_TOPUP_API=true
/// ```
abstract final class DriverPaymentFlags {
  /// Public Payment API base URL — no trailing slash.
  static const String paymentApiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: 'https://touri-ban.onrender.com',
  );

  /// When true (default), wallet top-up uses Render Payment API.
  /// Set false only to force legacy Firebase callables during rollback.
  static const bool enableWalletTopUpApi = bool.fromEnvironment(
    'ENABLE_WALLET_TOPUP_API',
    defaultValue: true,
  );

  static bool get useExternalWalletTopUp =>
      enableWalletTopUpApi && paymentApiBaseUrl.trim().isNotEmpty;
}
