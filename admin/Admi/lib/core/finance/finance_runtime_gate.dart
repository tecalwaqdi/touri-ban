/// Runtime gate: finance writes require authoritative Cloud Function data.
///
/// Approximate / client-sample finance views must not look like Pilot is safe.
abstract final class FinanceRuntimeGate {
  FinanceRuntimeGate._();

  static bool _authoritativeBackendData = false;

  /// True when the last successful finance load came from CF (not client fallback).
  static bool get authoritativeBackendData => _authoritativeBackendData;

  static void setAuthoritativeBackendData(bool value) {
    _authoritativeBackendData = value;
  }

  /// Extra safety: even if feature flags are later ON, approximate mode blocks writes.
  static bool get canAttemptFinanceWrites => _authoritativeBackendData;
}
