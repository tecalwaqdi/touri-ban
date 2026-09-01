/// Canonical document expiry states (client + shared semantics with CF).
enum DriverDocumentExpiryState {
  notApplicable,
  valid,
  expiringSoon,
  expired,
  missingExpiry,
}

/// Pure expiry resolver — uses an injected [now] for tests (UTC date).
abstract final class DriverDocumentExpiryResolver {
  DriverDocumentExpiryResolver._();

  static const defaultWarningDays = 30;

  /// Compare calendar dates in UTC (no local TZ drift).
  static DriverDocumentExpiryState resolve({
    required DateTime? expiryDate,
    required bool expiryRequired,
    int warningDays = defaultWarningDays,
    DateTime? now,
  }) {
    if (!expiryRequired) return DriverDocumentExpiryState.notApplicable;
    if (expiryDate == null) return DriverDocumentExpiryState.missingExpiry;
    final today = _utcDay(now ?? DateTime.now().toUtc());
    final expiryDay = _utcDay(expiryDate.toUtc());
    if (expiryDay.isBefore(today)) return DriverDocumentExpiryState.expired;
    final warn = warningDays < 1 ? defaultWarningDays : warningDays;
    final soon = today.add(Duration(days: warn));
    if (!expiryDay.isAfter(soon)) {
      return DriverDocumentExpiryState.expiringSoon;
    }
    return DriverDocumentExpiryState.valid;
  }

  static bool blocksNewOperations(DriverDocumentExpiryState state) =>
      state == DriverDocumentExpiryState.expired ||
      state == DriverDocumentExpiryState.missingExpiry;

  static DateTime _utcDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  static DateTime? parseExpiry(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) {
      final t = DateTime.tryParse(raw.trim());
      return t?.toUtc();
    }
    // Firestore Timestamp duck-typing without importing firebase in pure tests.
    try {
      final dyn = raw as dynamic;
      final dt = dyn.toDate();
      if (dt is DateTime) return dt.toUtc();
    } catch (_) {}
    return null;
  }
}
