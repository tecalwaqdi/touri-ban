import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_cache_policy.dart';
import '/backend/admin_ops_counters.dart';
import '/backend/admin_role_service.dart';
import '/core/toury_system_status_codes.dart';

/// Preset date windows for ops list filters.
///
/// See [AdminTimezonePolicy]: calendar days in **UTC** until countries gain a
/// trusted timezone field. Range is **start inclusive / end exclusive**.
enum AdminDatePreset {
  all,
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

/// Order lifecycle buckets for list filters (`status_code` SoT).
enum AdminOrderLifecycleFilter {
  all,
  pending,
  active,
  completed,
  cancelled,
  expired,
}

/// Driver activation buckets (`actev_mndob` SoT only — no other field).
enum AdminDriverActivationFilter {
  all,
  activated,
  deactivated,
  unknown,
}

/// Support ticket status (`halh` string).
enum AdminSupportStatusFilter {
  all,
  open,
  closed,
  resolved,
}

/// Unified ops filter state — one model shared by list pages + counts.
class AdminOpsFilterState {
  const AdminOpsFilterState({
    this.datePreset = AdminDatePreset.all,
    this.customStart,
    this.customEnd,
    this.orderLifecycle = AdminOrderLifecycleFilter.all,
    this.driverActivation = AdminDriverActivationFilter.all,
    this.supportStatus = AdminSupportStatusFilter.all,
    this.countryRef,
    this.regionRef,
    this.cityRef,
    this.searchQuery = '',
  });

  final AdminDatePreset datePreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final AdminOrderLifecycleFilter orderLifecycle;
  final AdminDriverActivationFilter driverActivation;
  final AdminSupportStatusFilter supportStatus;
  final DocumentReference? countryRef;
  final DocumentReference? regionRef;
  final DocumentReference? cityRef;
  final String searchQuery;

  static const empty = AdminOpsFilterState();

  /// Stable key for [AdminFirestoreList.reloadKey] / FutureBuilder.
  String get signature {
    final start = resolvedDateRange?.startInclusive.toUtc().toIso8601String() ?? '';
    final end = resolvedDateRange?.endExclusive.toUtc().toIso8601String() ?? '';
    return [
      datePreset.name,
      start,
      end,
      orderLifecycle.name,
      driverActivation.name,
      supportStatus.name,
      countryRef?.path ?? '',
      regionRef?.path ?? '',
      cityRef?.path ?? '',
      searchQuery.trim().toLowerCase(),
    ].join('|');
  }

  /// Count of non-default filters (for chip / badge UX).
  int get activeFilterCount {
    var n = 0;
    if (datePreset != AdminDatePreset.all) n++;
    if (orderLifecycle != AdminOrderLifecycleFilter.all) n++;
    if (driverActivation != AdminDriverActivationFilter.all) n++;
    if (supportStatus != AdminSupportStatusFilter.all) n++;
    if (countryRef != null && !AdminRoleService.isCountryAgent) n++;
    if (regionRef != null) n++;
    if (cityRef != null) n++;
    if (searchQuery.trim().isNotEmpty) n++;
    return n;
  }

  AdminOpsFilterState copyWith({
    AdminDatePreset? datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    bool clearCustomDates = false,
    AdminOrderLifecycleFilter? orderLifecycle,
    AdminDriverActivationFilter? driverActivation,
    AdminSupportStatusFilter? supportStatus,
    DocumentReference? countryRef,
    DocumentReference? regionRef,
    DocumentReference? cityRef,
    bool clearCountry = false,
    bool clearRegion = false,
    bool clearCity = false,
    String? searchQuery,
  }) {
    return AdminOpsFilterState(
      datePreset: datePreset ?? this.datePreset,
      customStart: clearCustomDates ? null : (customStart ?? this.customStart),
      customEnd: clearCustomDates ? null : (customEnd ?? this.customEnd),
      orderLifecycle: orderLifecycle ?? this.orderLifecycle,
      driverActivation: driverActivation ?? this.driverActivation,
      supportStatus: supportStatus ?? this.supportStatus,
      countryRef: clearCountry ? null : (countryRef ?? this.countryRef),
      regionRef: clearRegion ? null : (regionRef ?? this.regionRef),
      cityRef: clearCity ? null : (cityRef ?? this.cityRef),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  AdminOpsFilterState reset() => const AdminOpsFilterState();

  /// Effective date window, or null when [AdminDatePreset.all].
  AdminDateRange? get resolvedDateRange =>
      AdminDateRangeResolver.resolve(
        preset: datePreset,
        customStart: customStart,
        customEnd: customEnd,
      );

  /// Country agent cannot widen beyond their locked country.
  DocumentReference? get effectiveCountryRef {
    if (AdminRoleService.isCountryAgent) {
      return AdminRoleService.scopedCountryRef ?? countryRef;
    }
    return countryRef;
  }

  bool get hasActiveFilters =>
      datePreset != AdminDatePreset.all ||
      orderLifecycle != AdminOrderLifecycleFilter.all ||
      driverActivation != AdminDriverActivationFilter.all ||
      supportStatus != AdminSupportStatusFilter.all ||
      effectiveCountryRef != null ||
      regionRef != null ||
      cityRef != null ||
      searchQuery.trim().isNotEmpty;
}

/// Inclusive start / exclusive end in UTC for Firestore range queries.
class AdminDateRange {
  const AdminDateRange({
    required this.startInclusive,
    required this.endExclusive,
  });

  final DateTime startInclusive;
  final DateTime endExclusive;

  Timestamp get startTimestamp => Timestamp.fromDate(startInclusive);
  Timestamp get endTimestamp => Timestamp.fromDate(endExclusive);
}

/// Resolves presets as **UTC calendar days** ([AdminTimezonePolicy]).
abstract final class AdminDateRangeResolver {
  AdminDateRangeResolver._();

  static DateTime _utcNow([DateTime? now]) => (now ?? DateTime.now()).toUtc();

  static DateTime _startOfUtcDay(DateTime utc) =>
      DateTime.utc(utc.year, utc.month, utc.day);

  static AdminDateRange? resolve({
    required AdminDatePreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? now,
  }) {
    final utc = _utcNow(now);
    switch (preset) {
      case AdminDatePreset.all:
        return null;
      case AdminDatePreset.today:
        final start = _startOfUtcDay(utc);
        return AdminDateRange(
          startInclusive: start,
          endExclusive: start.add(const Duration(days: 1)),
        );
      case AdminDatePreset.yesterday:
        final todayStart = _startOfUtcDay(utc);
        return AdminDateRange(
          startInclusive: todayStart.subtract(const Duration(days: 1)),
          endExclusive: todayStart,
        );
      case AdminDatePreset.last7Days:
        final todayStart = _startOfUtcDay(utc);
        return AdminDateRange(
          startInclusive: todayStart.subtract(const Duration(days: 6)),
          endExclusive: todayStart.add(const Duration(days: 1)),
        );
      case AdminDatePreset.last30Days:
        final todayStart = _startOfUtcDay(utc);
        return AdminDateRange(
          startInclusive: todayStart.subtract(const Duration(days: 29)),
          endExclusive: todayStart.add(const Duration(days: 1)),
        );
      case AdminDatePreset.thisMonth:
        final start = DateTime.utc(utc.year, utc.month, 1);
        final end = DateTime.utc(utc.year, utc.month + 1, 1);
        return AdminDateRange(startInclusive: start, endExclusive: end);
      case AdminDatePreset.lastMonth:
        final start = DateTime.utc(utc.year, utc.month - 1, 1);
        final end = DateTime.utc(utc.year, utc.month, 1);
        return AdminDateRange(startInclusive: start, endExclusive: end);
      case AdminDatePreset.thisYear:
        final start = DateTime.utc(utc.year, 1, 1);
        final end = DateTime.utc(utc.year + 1, 1, 1);
        return AdminDateRange(startInclusive: start, endExclusive: end);
      case AdminDatePreset.custom:
        if (customStart == null || customEnd == null) return null;
        final start = DateTime.utc(
          customStart.year,
          customStart.month,
          customStart.day,
        );
        final end = DateTime.utc(
          customEnd.year,
          customEnd.month,
          customEnd.day,
        ).add(const Duration(days: 1));
        if (!end.isAfter(start)) return null;
        return AdminDateRange(startInclusive: start, endExclusive: end);
    }
  }
}

/// Applies [AdminOpsFilterState] to Firestore queries (server-side).
abstract final class AdminOpsQueryBuilder {
  AdminOpsQueryBuilder._();

  static List<String> statusCodesFor(AdminOrderLifecycleFilter filter) {
    switch (filter) {
      case AdminOrderLifecycleFilter.all:
        return const [];
      case AdminOrderLifecycleFilter.pending:
        return AdminOpsCounters.pendingStatusCodes;
      case AdminOrderLifecycleFilter.active:
        return AdminOpsCounters.activeStatusCodes;
      case AdminOrderLifecycleFilter.completed:
        return AdminOpsCounters.completedStatusCodes;
      case AdminOrderLifecycleFilter.cancelled:
        return AdminOpsCounters.cancelledStatusCodes;
      case AdminOrderLifecycleFilter.expired:
        return [TourySystemStatusCodes.expired];
    }
  }

  /// Orders list / aggregate query.
  static Query applyOrderFilters(Query q, AdminOpsFilterState filters) {
    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }

    final codes = statusCodesFor(filters.orderLifecycle);
    if (filters.orderLifecycle == AdminOrderLifecycleFilter.active) {
      // Match dashboard "active bookings" SoT (`ALLNOW`).
      q = q.where('ALLNOW', isEqualTo: true);
    } else if (codes.length == 1) {
      q = q.where('status_code', isEqualTo: codes.first);
    } else if (codes.length > 1) {
      q = q.where('status_code', whereIn: codes.take(30).toList());
    }

    final range = filters.resolvedDateRange;
    if (range != null) {
      q = q
          .where('data_order', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('data_order', isLessThan: range.endTimestamp);
    }

    // City filter when present (orders store village ref as `vill`).
    if (filters.cityRef != null) {
      q = q.where('vill', isEqualTo: filters.cityRef);
    }

    return q.orderBy('data_order', descending: true);
  }

  /// Drivers (`ismndob`) with activation + geo + optional date on `created_time`.
  static Query applyDriverFilters(Query q, AdminOpsFilterState filters) {
    q = q.where('ismndob', isEqualTo: true);

    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }

    switch (filters.driverActivation) {
      case AdminDriverActivationFilter.all:
        break;
      case AdminDriverActivationFilter.activated:
        q = q.where('actev_mndob', isEqualTo: true);
        break;
      case AdminDriverActivationFilter.deactivated:
        q = q.where('actev_mndob', isEqualTo: false);
        break;
      case AdminDriverActivationFilter.unknown:
        // Firestore cannot query "field missing" with equality alone.
        // Unknown is handled client-side on the page + aggregate via
        // total − active − inactive. Keep server query as all drivers
        // when unknown is selected (parent must client-filter).
        break;
    }

    if (filters.cityRef != null) {
      q = q.where('mndob_vill', isEqualTo: filters.cityRef);
    }

    return q.orderBy(FieldPath.documentId);
  }

  /// True when unknown activation needs a client-side pass.
  static bool driversNeedClientUnknownFilter(AdminOpsFilterState filters) =>
      filters.driverActivation == AdminDriverActivationFilter.unknown;

  /// Use [hasActevMndob] — the typed getter coerces null → false.
  static bool isDriverActivationUnknown({required bool hasField}) => !hasField;

  /// App users (non-agent / non-driver) — geo only; role math stays in counters.
  static Query applyUserFilters(Query q, AdminOpsFilterState filters) {
    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q.orderBy(FieldPath.documentId);
  }

  static Query applySupportFilters(Query q, AdminOpsFilterState filters) {
    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    switch (filters.supportStatus) {
      case AdminSupportStatusFilter.all:
        break;
      case AdminSupportStatusFilter.open:
        q = q.where('halh', isEqualTo: AdminOpsCounters.supportOpenHalh);
        break;
      case AdminSupportStatusFilter.closed:
        q = q.where('halh', isEqualTo: 'Closed');
        break;
      case AdminSupportStatusFilter.resolved:
        q = q.where('halh', isEqualTo: 'Resolved');
        break;
    }
    final range = filters.resolvedDateRange;
    if (range != null) {
      q = q
          .where('data', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('data', isLessThan: range.endTimestamp)
          .orderBy('data', descending: true);
    } else {
      q = q.orderBy('data', descending: true);
    }
    return q;
  }

  static Query applyLandmarkFilters(Query q, AdminOpsFilterState filters) {
    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    if (filters.cityRef != null) {
      q = q.where('vill', isEqualTo: filters.cityRef);
    }
    return q.orderBy(FieldPath.documentId);
  }

  static Query applyTransportCompanyFilters(
    Query q,
    AdminOpsFilterState filters,
  ) {
    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q.orderBy(FieldPath.documentId);
  }

  static Query applyGuideFilters(Query q, AdminOpsFilterState filters) {
    q = q.where('is_tour_guide', isEqualTo: true);
    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q.orderBy(FieldPath.documentId);
  }

  /// Exact-ID shortcuts for search (avoid collection scans).
  static String? exactSearchToken(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return null;
    // Order / doc style ids — keep alnum and dashes.
    if (q.length >= 6 && RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(q)) {
      return q;
    }
    return null;
  }
}
