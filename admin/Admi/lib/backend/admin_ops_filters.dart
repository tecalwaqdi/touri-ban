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

/// Driver registration / review pipeline (`registration_status` SoT).
enum AdminDriverReviewFilter {
  all,
  pendingReview,
  approved,
  rejected,
  needsChanges,
  inactive,
  unknownLegacy,
}

/// Document completeness — authoritative `registration_documents_status` SoT.
enum AdminDriverDocumentsFilter {
  all,
  complete,
  missing,
  needsReupload,
  unknownLegacy,
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
    this.driverReview = AdminDriverReviewFilter.all,
    this.driverDocuments = AdminDriverDocumentsFilter.all,
    this.vehicleTypeRef,
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
  final AdminDriverReviewFilter driverReview;
  final AdminDriverDocumentsFilter driverDocuments;
  final DocumentReference? vehicleTypeRef;
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
      driverReview.name,
      driverDocuments.name,
      vehicleTypeRef?.path ?? '',
      supportStatus.name,
      countryRef?.path ?? '',
      regionRef?.path ?? '',
      cityRef?.path ?? '',
      searchQuery.trim().toLowerCase(),
    ].join('|');
  }

  /// PII-safe filter evidence for QA semantics (ids only, no names/emails).
  ///
  /// Example: `country=sa|status=pending_review|activation=all|vehicle=all|docs=missing|date=30d`
  String get qaEvidenceSignature => [
        'country=$qaCountryToken',
        'status=$qaStatusToken',
        'activation=$qaActivationToken',
        'vehicle=$qaVehicleToken',
        'docs=$qaDocumentsToken',
        'date=$qaDateToken',
      ].join('|');

  String get qaCountryToken => effectiveCountryRef?.id ?? 'all';

  String get qaStatusToken => switch (driverReview) {
        AdminDriverReviewFilter.all => 'all',
        AdminDriverReviewFilter.pendingReview => 'pending_review',
        AdminDriverReviewFilter.approved => 'approved',
        AdminDriverReviewFilter.rejected => 'rejected',
        AdminDriverReviewFilter.needsChanges => 'needs_changes',
        AdminDriverReviewFilter.inactive => 'inactive',
        AdminDriverReviewFilter.unknownLegacy => 'unknown_legacy',
      };

  String get qaActivationToken => switch (driverActivation) {
        AdminDriverActivationFilter.all => 'all',
        AdminDriverActivationFilter.activated => 'activated',
        AdminDriverActivationFilter.deactivated => 'deactivated',
        AdminDriverActivationFilter.unknown => 'unknown',
      };

  String get qaVehicleToken => vehicleTypeRef?.id ?? 'all';

  String get qaDocumentsToken => switch (driverDocuments) {
        AdminDriverDocumentsFilter.all => 'all',
        AdminDriverDocumentsFilter.complete => 'complete',
        AdminDriverDocumentsFilter.missing => 'missing',
        AdminDriverDocumentsFilter.needsReupload => 'needs_reupload',
        AdminDriverDocumentsFilter.unknownLegacy => 'unknown_legacy',
      };

  String get qaDateToken => switch (datePreset) {
        AdminDatePreset.all => 'all',
        AdminDatePreset.today => 'today',
        AdminDatePreset.yesterday => 'yesterday',
        AdminDatePreset.last7Days => '7d',
        AdminDatePreset.last30Days => '30d',
        AdminDatePreset.thisMonth => 'this_month',
        AdminDatePreset.lastMonth => 'last_month',
        AdminDatePreset.thisYear => 'this_year',
        AdminDatePreset.custom => 'custom',
      };

  /// Count of non-default filters (for chip / badge UX).
  int get activeFilterCount {
    var n = 0;
    if (datePreset != AdminDatePreset.all) n++;
    if (orderLifecycle != AdminOrderLifecycleFilter.all) n++;
    if (driverActivation != AdminDriverActivationFilter.all) n++;
    if (driverReview != AdminDriverReviewFilter.all) n++;
    if (driverDocuments != AdminDriverDocumentsFilter.all) n++;
    if (vehicleTypeRef != null) n++;
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
    AdminDriverReviewFilter? driverReview,
    AdminDriverDocumentsFilter? driverDocuments,
    DocumentReference? vehicleTypeRef,
    bool clearVehicleType = false,
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
      driverReview: driverReview ?? this.driverReview,
      driverDocuments: driverDocuments ?? this.driverDocuments,
      vehicleTypeRef:
          clearVehicleType ? null : (vehicleTypeRef ?? this.vehicleTypeRef),
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
      driverReview != AdminDriverReviewFilter.all ||
      driverDocuments != AdminDriverDocumentsFilter.all ||
      vehicleTypeRef != null ||
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

  /// Drivers (`ismndob`) with activation + review + geo + optional date.
  static Query applyDriverFilters(Query q, AdminOpsFilterState filters) {
    q = applyDriverFiltersCore(q, filters);

    final range = filters.resolvedDateRange;
    if (range != null) {
      q = q
          .where('created_time', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('created_time', isLessThan: range.endTimestamp)
          .orderBy('created_time', descending: true);
    } else {
      q = q.orderBy(FieldPath.documentId);
    }

    return q;
  }

  /// Human-readable Firestore constraints for QA evidence (no live Query needed).
  ///
  /// Documents use authoritative [registration_documents_status] (server-side).
  static List<String> describeDriverFilterConstraints(
    AdminOpsFilterState filters,
  ) {
    return describeDriverFilterPaths(
      countryPath: filters.effectiveCountryRef?.path,
      vehiclePath: filters.vehicleTypeRef?.path,
      cityPath: filters.cityRef?.path,
      driverActivation: filters.driverActivation,
      driverReview: filters.driverReview,
      driverDocuments: filters.driverDocuments,
      dateRange: filters.resolvedDateRange,
    );
  }

  /// Path-based variant for unit tests (no DocumentReference required).
  static List<String> describeDriverFilterPaths({
    String? countryPath,
    String? vehiclePath,
    String? cityPath,
    AdminDriverActivationFilter driverActivation =
        AdminDriverActivationFilter.all,
    AdminDriverReviewFilter driverReview = AdminDriverReviewFilter.all,
    AdminDriverDocumentsFilter driverDocuments =
        AdminDriverDocumentsFilter.all,
    AdminDateRange? dateRange,
  }) {
    final out = <String>['ismndob==true'];
    if (countryPath != null && countryPath.isNotEmpty) {
      out.add('Rev_dolh==$countryPath');
    }
    switch (driverActivation) {
      case AdminDriverActivationFilter.all:
        break;
      case AdminDriverActivationFilter.activated:
        out.add('actev_mndob==true');
        break;
      case AdminDriverActivationFilter.deactivated:
        out.add('actev_mndob==false');
        break;
      case AdminDriverActivationFilter.unknown:
        out.add('client_side:activation_unknown');
        break;
    }
    switch (driverReview) {
      case AdminDriverReviewFilter.all:
        break;
      case AdminDriverReviewFilter.pendingReview:
        out.add('registration_status==pending_review');
        break;
      case AdminDriverReviewFilter.approved:
        out.add('registration_status==approved');
        break;
      case AdminDriverReviewFilter.rejected:
        out.add('registration_status==rejected');
        break;
      case AdminDriverReviewFilter.needsChanges:
        out.add('registration_status in [needs_changes,changes_requested]');
        break;
      case AdminDriverReviewFilter.inactive:
        out.add('actev_mndob==false');
        break;
      case AdminDriverReviewFilter.unknownLegacy:
        out.add('client_side:review_unknown_legacy');
        break;
    }
    if (vehiclePath != null && vehiclePath.isNotEmpty) {
      out.add('mndob_type_car==$vehiclePath');
    }
    if (cityPath != null && cityPath.isNotEmpty) {
      out.add('mndob_vill==$cityPath');
    }
    if (dateRange != null) {
      out.add(
        'created_time>=${dateRange.startInclusive.toUtc().toIso8601String()}',
      );
      out.add(
        'created_time<${dateRange.endExclusive.toUtc().toIso8601String()}',
      );
    }
    switch (driverDocuments) {
      case AdminDriverDocumentsFilter.all:
        break;
      case AdminDriverDocumentsFilter.complete:
        out.add('registration_documents_status==complete');
        break;
      case AdminDriverDocumentsFilter.missing:
        out.add('registration_documents_status==missing');
        break;
      case AdminDriverDocumentsFilter.needsReupload:
        out.add('registration_documents_status==needs_reupload');
        break;
      case AdminDriverDocumentsFilter.unknownLegacy:
        out.add('registration_documents_status==unknown_legacy');
        break;
    }
    return out;
  }

  /// Same predicates as [applyDriverFilters] without `orderBy` (for aggregates).
  static Query applyDriverFiltersCore(Query q, AdminOpsFilterState filters) {
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
        break;
    }

    switch (filters.driverReview) {
      case AdminDriverReviewFilter.all:
        break;
      case AdminDriverReviewFilter.pendingReview:
        q = q.where('registration_status', isEqualTo: 'pending_review');
        break;
      case AdminDriverReviewFilter.approved:
        q = q.where('registration_status', isEqualTo: 'approved');
        break;
      case AdminDriverReviewFilter.rejected:
        q = q.where('registration_status', isEqualTo: 'rejected');
        break;
      case AdminDriverReviewFilter.needsChanges:
        q = q.where(
          'registration_status',
          whereIn: const ['needs_changes', 'changes_requested'],
        );
        break;
      case AdminDriverReviewFilter.inactive:
        q = q.where('actev_mndob', isEqualTo: false);
        break;
      case AdminDriverReviewFilter.unknownLegacy:
        break;
    }

    if (filters.vehicleTypeRef != null) {
      q = q.where('mndob_type_car', isEqualTo: filters.vehicleTypeRef);
    }

    if (filters.cityRef != null) {
      q = q.where('mndob_vill', isEqualTo: filters.cityRef);
    }

    switch (filters.driverDocuments) {
      case AdminDriverDocumentsFilter.all:
        break;
      case AdminDriverDocumentsFilter.complete:
        q = q.where('registration_documents_status', isEqualTo: 'complete');
        break;
      case AdminDriverDocumentsFilter.missing:
        q = q.where('registration_documents_status', isEqualTo: 'missing');
        break;
      case AdminDriverDocumentsFilter.needsReupload:
        q = q.where(
          'registration_documents_status',
          isEqualTo: 'needs_reupload',
        );
        break;
      case AdminDriverDocumentsFilter.unknownLegacy:
        q = q.where(
          'registration_documents_status',
          isEqualTo: 'unknown_legacy',
        );
        break;
    }

    final range = filters.resolvedDateRange;
    if (range != null) {
      q = q
          .where('created_time', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('created_time', isLessThan: range.endTimestamp);
    }

    return q;
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
