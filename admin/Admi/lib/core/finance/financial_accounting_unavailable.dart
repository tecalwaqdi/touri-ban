/// Thrown when canonical V2 Cloud Function totals are required but unavailable.
///
/// Authoritative finance surfaces (Hub, Profits, Reports) must fail closed —
/// never present [client_full] scan totals as accounting truth.
class FinancialAccountingUnavailableException implements Exception {
  FinancialAccountingUnavailableException([this.cause]);

  final Object? cause;

  @override
  String toString() =>
      'FinancialAccountingUnavailableException(${cause ?? 'canonical CF unavailable'})';
}

/// Whether a failed CF call may fall back to client-side full scan.
bool financeAllowsClientFullFallback({
  required bool requireCanonicalServer,
  required bool driverScoped,
}) {
  if (driverScoped) return true;
  return !requireCanonicalServer;
}
