import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_ops_filters.dart';

/// Asia/Riyadh accounting clock for Admin finance (and shared date presets).
///
/// Saudi Arabia does **not** observe DST. Offset is fixed at UTC+03:00 —
/// same contract as Driver Financial Summary V2 Cloud Function.
///
/// No `timezone` package dependency: keeps Admin publish surface stable.
/// If KSA ever adopts DST, replace this isolated class only.
abstract final class AdminFinanceRiyadhClock {
  AdminFinanceRiyadhClock._();

  static const String ianaId = 'Asia/Riyadh';
  static const Duration offsetFromUtc = Duration(hours: 3);

  /// Riyadh wall-clock parts for an absolute [instant] (any zone).
  static ({int year, int month, int day, int weekday}) parts(
    DateTime instant,
  ) {
    final shifted = instant.toUtc().add(offsetFromUtc);
    return (
      year: shifted.year,
      month: shifted.month,
      day: shifted.day,
      // DateTime.weekday: Mon=1 … Sun=7
      weekday: shifted.weekday,
    );
  }

  /// UTC instant of Riyadh-local calendar midnight on [year]-[month]-[day].
  ///
  /// Example: 2026-09-01 00:00 Riyadh → 2026-08-31 21:00 UTC.
  static DateTime midnightUtc(int year, int month, int day) {
    return DateTime.utc(year, month, day).subtract(offsetFromUtc);
  }

  /// Start of the Riyadh calendar day containing [instant].
  static DateTime startOfDayUtc(DateTime instant) {
    final p = parts(instant);
    return midnightUtc(p.year, p.month, p.day);
  }

  /// Format absolute time for accountant-facing UI (Riyadh wall clock).
  static String formatDateTime(DateTime instant) {
    final local = instant.toUtc().add(offsetFromUtc);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h24 = local.hour;
    final min = local.minute.toString().padLeft(2, '0');
    final isAm = h24 < 12;
    var h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    final period = isAm ? 'ص' : 'م';
    return '$d/$m/$y · ${h12.toString().padLeft(2, '0')}:$min $period';
  }

  static String formatDateOnly(DateTime instant) {
    final local = instant.toUtc().add(offsetFromUtc);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }
}

/// Resolved finance date window — half-open `[start, end)`.
class AdminFinanceDateRange {
  const AdminFinanceDateRange({
    required this.queryStartUtc,
    required this.queryEndUtcExclusive,
    required this.displayLabelAr,
    required this.preset,
  });

  final DateTime queryStartUtc;
  final DateTime queryEndUtcExclusive;
  final String displayLabelAr;
  final AdminDatePreset preset;

  Timestamp get startTimestamp => Timestamp.fromDate(queryStartUtc);
  Timestamp get endTimestamp => Timestamp.fromDate(queryEndUtcExclusive);

  /// Convert to the shared [AdminDateRange] used by ops / accounting loaders.
  AdminDateRange toAdminDateRange() => AdminDateRange(
        startInclusive: queryStartUtc,
        endExclusive: queryEndUtcExclusive,
      );
}

/// Canonical finance (+ ops) date presets in Asia/Riyadh.
///
/// Week rule for [AdminDatePreset.last7Days]: rolling last 7 Riyadh calendar
/// days ending today (inclusive), half-open end = tomorrow Riyadh midnight.
///
/// Driver Summary V2 uses Sunday-start weeks for its own buckets — Admin
/// `last7Days` stays a rolling window (existing Admin UX).
abstract final class AdminFinanceDateRangeResolver {
  AdminFinanceDateRangeResolver._();

  static AdminFinanceDateRange? resolve({
    required AdminDatePreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? now,
  }) {
    final instant = (now ?? DateTime.now()).toUtc();
    final todayStart = AdminFinanceRiyadhClock.startOfDayUtc(instant);
    final p = AdminFinanceRiyadhClock.parts(instant);

    switch (preset) {
      case AdminDatePreset.all:
        return null;
      case AdminDatePreset.today:
        // Half-open [Riyadh midnight, now) — not full calendar day, not device-local.
        return AdminFinanceDateRange(
          queryStartUtc: todayStart,
          queryEndUtcExclusive: instant,
          displayLabelAr: 'اليوم',
          preset: preset,
        );
      case AdminDatePreset.yesterday:
        return AdminFinanceDateRange(
          queryStartUtc: AdminFinanceRiyadhClock.midnightUtc(
            p.year,
            p.month,
            p.day - 1,
          ),
          queryEndUtcExclusive: todayStart,
          displayLabelAr: 'أمس',
          preset: preset,
        );
      case AdminDatePreset.last7Days:
        // Inclusive window of 7 Riyadh days ending today.
        return AdminFinanceDateRange(
          queryStartUtc: AdminFinanceRiyadhClock.midnightUtc(
            p.year,
            p.month,
            p.day - 6,
          ),
          queryEndUtcExclusive:
              AdminFinanceRiyadhClock.midnightUtc(p.year, p.month, p.day + 1),
          displayLabelAr: 'آخر 7 أيام',
          preset: preset,
        );
      case AdminDatePreset.last30Days:
        return AdminFinanceDateRange(
          queryStartUtc: AdminFinanceRiyadhClock.midnightUtc(
            p.year,
            p.month,
            p.day - 29,
          ),
          queryEndUtcExclusive:
              AdminFinanceRiyadhClock.midnightUtc(p.year, p.month, p.day + 1),
          displayLabelAr: 'آخر 30 يومًا',
          preset: preset,
        );
      case AdminDatePreset.thisMonth:
        final start = AdminFinanceRiyadhClock.midnightUtc(p.year, p.month, 1);
        final end = AdminFinanceRiyadhClock.midnightUtc(p.year, p.month + 1, 1);
        return AdminFinanceDateRange(
          queryStartUtc: start,
          queryEndUtcExclusive: end,
          displayLabelAr: 'هذا الشهر',
          preset: preset,
        );
      case AdminDatePreset.lastMonth:
        final start =
            AdminFinanceRiyadhClock.midnightUtc(p.year, p.month - 1, 1);
        final end = AdminFinanceRiyadhClock.midnightUtc(p.year, p.month, 1);
        return AdminFinanceDateRange(
          queryStartUtc: start,
          queryEndUtcExclusive: end,
          displayLabelAr: 'الشهر السابق',
          preset: preset,
        );
      case AdminDatePreset.thisYear:
        final start = AdminFinanceRiyadhClock.midnightUtc(p.year, 1, 1);
        final end = AdminFinanceRiyadhClock.midnightUtc(p.year + 1, 1, 1);
        return AdminFinanceDateRange(
          queryStartUtc: start,
          queryEndUtcExclusive: end,
          displayLabelAr: 'هذه السنة',
          preset: preset,
        );
      case AdminDatePreset.custom:
        if (customStart == null || customEnd == null) return null;
        // Calendar Y/M/D chosen by Admin are interpreted as Riyadh dates.
        final start = AdminFinanceRiyadhClock.midnightUtc(
          customStart.year,
          customStart.month,
          customStart.day,
        );
        final end = AdminFinanceRiyadhClock.midnightUtc(
          customEnd.year,
          customEnd.month,
          customEnd.day + 1,
        );
        if (!end.isAfter(start)) return null;
        return AdminFinanceDateRange(
          queryStartUtc: start,
          queryEndUtcExclusive: end,
          displayLabelAr:
              '${AdminFinanceRiyadhClock.formatDateOnly(start)} → ${AdminFinanceRiyadhClock.formatDateOnly(AdminFinanceRiyadhClock.midnightUtc(customEnd.year, customEnd.month, customEnd.day))}',
          preset: preset,
        );
    }
  }

  /// True when custom calendar dates are invalid (from after to).
  static bool isInvalidCustom({
    required DateTime? customStart,
    required DateTime? customEnd,
  }) {
    if (customStart == null || customEnd == null) return false;
    final start = DateTime(customStart.year, customStart.month, customStart.day);
    final end = DateTime(customEnd.year, customEnd.month, customEnd.day);
    return end.isBefore(start);
  }
}
