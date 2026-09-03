/// Feature / recognition version for Finance V3 evolution.
abstract final class FinancialEngineVersion {
  FinancialEngineVersion._();

  static const legacy = 'legacy';
  static const v2 = 'v2';
  static const v3 = 'v3';

  /// Production default until cutover: V2 recognition.
  static const productionDefault = v2;

  static bool isSupported(String raw) {
    final v = raw.trim().toLowerCase();
    return v == legacy || v == v2 || v == v3;
  }

  /// V3 may prefer `order.financial_snapshot` when present; else V2 fields.
  static bool preferSnapshotWhenPresent(String version) =>
      version.trim().toLowerCase() == v3;
}
