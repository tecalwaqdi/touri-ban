/// Runtime gate: finance writes require authoritative Cloud Function data.
///
/// Approximate / client-sample finance views must not look like Pilot is safe.
///
/// Sticky rule: once a successful CF finance load marks authoritative, secondary
/// approximate loads must NOT clear the gate (Hub wallet fallback used to do that).
abstract final class FinanceRuntimeGate {
  FinanceRuntimeGate._();

  static bool _authoritativeBackendData = false;

  /// True when a successful finance CF load has marked the session authoritative.
  static bool get authoritativeBackendData => _authoritativeBackendData;

  /// Explicit set — use [markAuthoritativeBackendData] from loaders; use `false`
  /// only for tests / session reset.
  static void setAuthoritativeBackendData(bool value) {
    _authoritativeBackendData = value;
  }

  /// Sticky upgrade after a successful Cloud Function finance response.
  static void markAuthoritativeBackendData() {
    _authoritativeBackendData = true;
  }

  /// Extra safety: even if feature flags are later ON, approximate mode blocks writes.
  static bool get canAttemptFinanceWrites => _authoritativeBackendData;

  static const writeBlockedMessageAr =
      'البيانات المالية غير موثوقة بعد — الكتابة المالية غير متاحة حتى يكتمل تحميل السيرفر.';
}
