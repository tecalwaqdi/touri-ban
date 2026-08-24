
import '/backend/admin_ops_counters.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Aggregate driver counters (Firestore count aggregates).
///
/// ## Bucket definitions (no double-count in registration identity)
///
/// Registration identity (mutually exclusive by `registration_status`):
/// - pendingReview: `pending_review` | `submitted`
/// - needsChanges: `needs_changes` | `changes_requested`
/// - approved / rejected / draft / suspended|blocked
/// - unknownLegacy: total − known registration statuses
///
/// Activation (orthogonal — may overlap registration):
/// - activated / deactivated / activationUnknown
///
/// V2 vs Legacy:
/// - v2Total: `registration_flow_version == 2`
/// - legacyTotal: total − v2Total
/// Equation: v2Total + legacyTotal == total
class DriverAdminStats {
  const DriverAdminStats({
    required this.total,
    required this.activated,
    required this.deactivated,
    required this.activationUnknown,
    required this.pendingReview,
    required this.rejected,
    required this.needsChanges,
    required this.approved,
    required this.draft,
    required this.suspended,
    required this.unknownLegacy,
    required this.v2Total,
    required this.legacyTotal,
    required this.docsComplete,
    required this.docsMissing,
    required this.docsNeedsReupload,
    required this.docsUnknownLegacy,
    this.scopedNote = '',
  });

  final int total;
  final int activated;
  final int deactivated;
  final int activationUnknown;
  final int pendingReview;
  final int rejected;
  final int needsChanges;
  final int approved;
  final int draft;
  final int suspended;
  final int unknownLegacy;
  final int v2Total;
  final int legacyTotal;
  final int docsComplete;
  final int docsMissing;
  final int docsNeedsReupload;
  final int docsUnknownLegacy;

  /// When non-empty, counters match the active table filter dataset.
  final String scopedNote;

  int get reviewKnownSum =>
      pendingReview + rejected + needsChanges + approved + draft + suspended;

  bool get reviewBucketsBalance =>
      total == 0 || (reviewKnownSum + unknownLegacy) == total;

  bool get v2LegacyBalance => total == 0 || (v2Total + legacyTotal) == total;

  int get docsKnownSum => docsComplete + docsMissing + docsNeedsReupload;

  bool get docsBucketsBalance =>
      total == 0 || (docsKnownSum + docsUnknownLegacy) == total;

  static const empty = DriverAdminStats(
    total: 0,
    activated: 0,
    deactivated: 0,
    activationUnknown: 0,
    pendingReview: 0,
    rejected: 0,
    needsChanges: 0,
    approved: 0,
    draft: 0,
    suspended: 0,
    unknownLegacy: 0,
    v2Total: 0,
    legacyTotal: 0,
    docsComplete: 0,
    docsMissing: 0,
    docsNeedsReupload: 0,
    docsUnknownLegacy: 0,
  );
}

abstract final class DriverAdminStatsLoader {
  DriverAdminStatsLoader._();

  static Future<int> _count(Query Function(Query q) build) async {
    try {
      return await queryCollectionCount(
        UserRecord.collection,
        queryBuilder: build,
      );
    } catch (_) {
      return 0;
    }
  }

  /// Apply the same server-side filters as the drivers table (excludes
  /// unknownLegacy review / name search — those stay client-side).
  static Query _scopedBase(Query q, AdminOpsFilterState? filters) {
    if (filters != null) {
      return AdminOpsQueryBuilder.applyDriverFiltersCore(q, filters);
    }
    q = q.where('ismndob', isEqualTo: true);
    final c = AdminRoleService.isCountryAgent
        ? AdminRoleService.scopedCountryRef
        : null;
    if (c != null) q = q.where('Rev_dolh', isEqualTo: c);
    return q;
  }

  static Future<DriverAdminStats> load({
    DocumentReference? countryRef,
    AdminOpsFilterState? filters,
  }) async {
    // Prefer explicit filter state so counters match the table dataset.
    final scoped = filters ??
        (countryRef != null
            ? AdminOpsFilterState(countryRef: countryRef)
            : null);

    Query base(Query q) => _scopedBase(q, scoped);

    // When review filter already pins one status, avoid nested where clashes.
    final reviewPinned = scoped != null &&
        scoped.driverReview != AdminDriverReviewFilter.all &&
        scoped.driverReview != AdminDriverReviewFilter.unknownLegacy &&
        scoped.driverReview != AdminDriverReviewFilter.inactive;

    final results = await Future.wait([
      _count(base),
      _count((q) => base(q).where('actev_mndob', isEqualTo: true)),
      _count((q) => base(q).where('actev_mndob', isEqualTo: false)),
      if (!reviewPinned) ...[
        _count((q) =>
            base(q).where('registration_status', isEqualTo: 'pending_review')),
        _count((q) =>
            base(q).where('registration_status', isEqualTo: 'submitted')),
        _count((q) =>
            base(q).where('registration_status', isEqualTo: 'rejected')),
        _count((q) => base(q)
            .where('registration_status', isEqualTo: 'changes_requested')),
        _count((q) =>
            base(q).where('registration_status', isEqualTo: 'needs_changes')),
        _count((q) =>
            base(q).where('registration_status', isEqualTo: 'approved')),
        _count(
            (q) => base(q).where('registration_status', isEqualTo: 'draft')),
        _count((q) =>
            base(q).where('registration_status', isEqualTo: 'suspended')),
        _count((q) =>
            base(q).where('registration_status', isEqualTo: 'blocked')),
      ] else
        ...List.filled(10, Future.value(0)),
      _count((q) =>
          base(q).where('registration_flow_version', isEqualTo: 2)),
      _count((q) => base(q)
          .where('registration_documents_status', isEqualTo: 'complete')),
      _count((q) =>
          base(q).where('registration_documents_status', isEqualTo: 'missing')),
      _count((q) => base(q).where(
            'registration_documents_status',
            isEqualTo: 'needs_reupload',
          )),
      _count((q) => base(q).where(
            'registration_documents_status',
            isEqualTo: 'unknown_legacy',
          )),
    ]);

    final total = results[0];
    final activated = results[1];
    final deactivated = results[2];
    int pending;
    int rejected;
    int needsChanges;
    int approved;
    int draft;
    int suspended;
    if (!reviewPinned) {
      pending = results[3] + results[4];
      rejected = results[5];
      needsChanges = results[6] + results[7];
      approved = results[8];
      draft = results[9];
      suspended = results[10] + results[11];
    } else {
      // Scoped to one review bucket — put total into that bucket for clarity.
      pending = rejected = needsChanges = approved = draft = suspended = 0;
      switch (scoped.driverReview) {
        case AdminDriverReviewFilter.pendingReview:
          pending = total;
          break;
        case AdminDriverReviewFilter.rejected:
          rejected = total;
          break;
        case AdminDriverReviewFilter.needsChanges:
          needsChanges = total;
          break;
        case AdminDriverReviewFilter.approved:
          approved = total;
          break;
        default:
          break;
      }
    }
    final v2Idx = reviewPinned ? 3 : 12;
    final v2Total = results[v2Idx];
    final docsComplete = results[v2Idx + 1];
    final docsMissing = results[v2Idx + 2];
    final docsNeedsReupload = results[v2Idx + 3];
    final docsUnknownExplicit = results[v2Idx + 4];
    final docsKnown = docsComplete + docsMissing + docsNeedsReupload;
    // Unknown = explicit unknown_legacy + drivers with no authoritative field yet.
    final docsUnknownLegacy = AdminOpsCounters.driversUnknown(
      totalDrivers: total,
      active: docsKnown + docsUnknownExplicit,
      inactive: 0,
    ).clamp(0, total);
    // Prefer explicit unknown_legacy count when it already reconciles.
    final docsUnknownFinal =
        (docsKnown + docsUnknownExplicit) == total
            ? docsUnknownExplicit
            : docsUnknownLegacy;
    final known =
        pending + rejected + needsChanges + approved + draft + suspended;
    final unknownLegacy = reviewPinned
        ? 0
        : AdminOpsCounters.driversUnknown(
            totalDrivers: total,
            active: known,
            inactive: 0,
          );
    final legacyTotal = total >= v2Total ? total - v2Total : 0;

    final noteParts = <String>[];
    if (scoped != null) {
      if (scoped.effectiveCountryRef != null) noteParts.add('country');
      if (scoped.driverActivation != AdminDriverActivationFilter.all) {
        noteParts.add('activation');
      }
      if (scoped.driverReview != AdminDriverReviewFilter.all) {
        noteParts.add('review');
      }
      if (scoped.vehicleTypeRef != null) noteParts.add('vehicle');
      if (scoped.cityRef != null) noteParts.add('city');
      if (scoped.resolvedDateRange != null) noteParts.add('date');
    }

    return DriverAdminStats(
      total: total,
      activated: activated,
      deactivated: deactivated,
      activationUnknown: AdminOpsCounters.driversUnknown(
        totalDrivers: total,
        active: activated,
        inactive: deactivated,
      ),
      pendingReview: pending,
      rejected: rejected,
      needsChanges: needsChanges,
      approved: approved,
      draft: draft,
      suspended: suspended,
      unknownLegacy: unknownLegacy,
      v2Total: v2Total,
      legacyTotal: legacyTotal,
      docsComplete: docsComplete,
      docsMissing: docsMissing,
      docsNeedsReupload: docsNeedsReupload,
      docsUnknownLegacy: docsUnknownFinal,
      scopedNote: noteParts.isEmpty
          ? ''
          : 'Counters scoped to: ${noteParts.join(', ')}',
    );
  }
}
