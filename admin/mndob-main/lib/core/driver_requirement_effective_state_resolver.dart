/// Canonical effective-state for country driver document requirements.
///
/// Newly-required docs must not mass-block already-approved drivers without
/// an explicit rollout (`effectiveFrom` + `gracePeriodDays`).
enum DriverRequirementEffectiveState {
  /// Before effectiveFrom — do not enforce.
  notEffective,

  /// Inside grace window — warn only; operations stay allowed.
  gracePeriod,

  /// Past grace — requirement is enforceable.
  effective,

  /// Missing rollout fields for an existing approved driver — do NOT mass-block.
  configurationIncomplete,
}

abstract final class DriverRequirementEffectiveStateResolver {
  DriverRequirementEffectiveStateResolver._();

  static DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) {
      final t = DateTime.tryParse(raw.trim());
      return t?.toUtc();
    }
    try {
      final dyn = raw as dynamic;
      final dt = dyn.toDate();
      if (dt is DateTime) return dt.toUtc();
    } catch (_) {}
    return null;
  }

  static DateTime _utcDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  /// Resolve enforcement window for one requirement against one driver.
  ///
  /// [driverApprovedAt] null → new/pre-approval application (apply immediately).
  static DriverRequirementEffectiveState resolve({
    required bool requirementEnabled,
    required bool requirementRequired,
    required DateTime? effectiveFrom,
    required int? gracePeriodDays,
    required DateTime? driverApprovedAt,
    DateTime? now,
  }) {
    if (!requirementEnabled || !requirementRequired) {
      return DriverRequirementEffectiveState.notEffective;
    }

    final today = _utcDay(now ?? DateTime.now().toUtc());

    // New applications / not yet approved: apply immediately.
    if (driverApprovedAt == null) {
      return DriverRequirementEffectiveState.effective;
    }

    final approvedDay = _utcDay(driverApprovedAt.toUtc());

    // Driver approved on/after effectiveFrom → new cohort, enforce immediately.
    if (effectiveFrom != null) {
      final fromDay = _utcDay(effectiveFrom.toUtc());
      if (!approvedDay.isBefore(fromDay)) {
        return DriverRequirementEffectiveState.effective;
      }
    }

    // Existing approved cohort: need complete rollout config.
    if (effectiveFrom == null || gracePeriodDays == null) {
      return DriverRequirementEffectiveState.configurationIncomplete;
    }

    final fromDay = _utcDay(effectiveFrom.toUtc());
    if (today.isBefore(fromDay)) {
      return DriverRequirementEffectiveState.notEffective;
    }

    final graceEnd =
        fromDay.add(Duration(days: gracePeriodDays.clamp(0, 3650)));
    // Inclusive grace through graceEnd calendar day.
    if (!today.isAfter(graceEnd)) {
      return DriverRequirementEffectiveState.gracePeriod;
    }
    return DriverRequirementEffectiveState.effective;
  }

  static bool mayBlockOperations(DriverRequirementEffectiveState state) =>
      state == DriverRequirementEffectiveState.effective;

  static bool showGraceWarning(DriverRequirementEffectiveState state) =>
      state == DriverRequirementEffectiveState.gracePeriod;
}
