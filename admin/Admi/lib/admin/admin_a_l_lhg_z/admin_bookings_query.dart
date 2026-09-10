import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/backend/admin_ops_country_scope.dart';
import '/backend/admin_ops_counters.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/core/admin_booking_status_label.dart';
import '/core/admin_qa_fixture.dart';
import '/core/toury_system_status_codes.dart';

/// Bookings-page-only filter extensions (never written into shared ops state).
class AdminBookingsExtraFilters {
  const AdminBookingsExtraFilters({
    this.customerQuery = '',
    this.driverQuery = '',
    this.paymentMethod,
    this.vehicleTypeRef,
    this.amountMin,
    this.amountMax,
  });

  final String customerQuery;
  final String driverQuery;
  final PaymentMethod? paymentMethod;
  final DocumentReference? vehicleTypeRef;
  final double? amountMin;
  final double? amountMax;

  static const empty = AdminBookingsExtraFilters();

  bool get hasAny =>
      customerQuery.trim().isNotEmpty ||
      driverQuery.trim().isNotEmpty ||
      paymentMethod != null ||
      vehicleTypeRef != null ||
      amountMin != null ||
      amountMax != null;

  int get activeCount {
    var n = 0;
    if (customerQuery.trim().isNotEmpty) n++;
    if (driverQuery.trim().isNotEmpty) n++;
    if (paymentMethod != null) n++;
    if (vehicleTypeRef != null) n++;
    if (amountMin != null || amountMax != null) n++;
    return n;
  }

  String get signature => [
        customerQuery.trim().toLowerCase(),
        driverQuery.trim().toLowerCase(),
        paymentMethod?.name ?? '',
        vehicleTypeRef?.path ?? '',
        amountMin?.toString() ?? '',
        amountMax?.toString() ?? '',
      ].join('|');

  AdminBookingsExtraFilters copyWith({
    String? customerQuery,
    String? driverQuery,
    PaymentMethod? paymentMethod,
    bool clearPayment = false,
    DocumentReference? vehicleTypeRef,
    bool clearVehicle = false,
    double? amountMin,
    double? amountMax,
    bool clearAmount = false,
  }) {
    return AdminBookingsExtraFilters(
      customerQuery: customerQuery ?? this.customerQuery,
      driverQuery: driverQuery ?? this.driverQuery,
      paymentMethod:
          clearPayment ? null : (paymentMethod ?? this.paymentMethod),
      vehicleTypeRef:
          clearVehicle ? null : (vehicleTypeRef ?? this.vehicleTypeRef),
      amountMin: clearAmount ? null : (amountMin ?? this.amountMin),
      amountMax: clearAmount ? null : (amountMax ?? this.amountMax),
    );
  }

  AdminBookingsExtraFilters reset() => empty;
}

/// Firestore query helpers for the admin bookings page only.
abstract final class AdminBookingsQuery {
  AdminBookingsQuery._();

  /// Scope filters shared by table + KPI buckets (no lifecycle predicate).
  ///
  /// Country / city / date only — lifecycle is applied per KPI bucket.
  static Query applyScopeFiltersCore(Query q, AdminOpsFilterState filters) {
    q = AdminOpsCountryScope.applyCountryFieldFilter(
      q,
      field: 'Rev_dolh',
      explicitCountry: filters.effectiveCountryRef,
    );

    final range = filters.resolvedDateRange;
    if (range != null) {
      q = q
          .where('data_order', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('data_order', isLessThan: range.endTimestamp);
    }

    if (filters.cityRef != null) {
      q = q.where('vill', isEqualTo: filters.cityRef);
    }

    return q;
  }

  /// Same predicates as [AdminOpsQueryBuilder.applyOrderFilters] without orderBy
  /// (safe for Aggregate Count).
  static Query applyFiltersCore(Query q, AdminOpsFilterState filters) {
    q = applyScopeFiltersCore(q, filters);

    final codes = AdminOpsQueryBuilder.statusCodesFor(filters.orderLifecycle);
    if (filters.orderLifecycle == AdminOrderLifecycleFilter.active) {
      q = q.where('ALLNOW', isEqualTo: true);
    } else if (codes.length == 1) {
      q = q.where('status_code', isEqualTo: codes.first);
    } else if (codes.length > 1) {
      q = q.where('status_code', whereIn: codes.take(30).toList());
    }

    return q;
  }

  static Query applyFilters(Query q, AdminOpsFilterState filters) =>
      applyFiltersCore(q, filters).orderBy('data_order', descending: true);

  /// Client-side advanced filters + free-text on the loaded page.
  static List<OrderRecord> applyClientFilters(
    List<OrderRecord> bookings, {
    required AdminOpsFilterState filters,
    required AdminBookingsExtraFilters extra,
    List<OrderRecord>? serverSearchHits,
    bool includeQaFixtures = false,
  }) {
    if (serverSearchHits != null) {
      return _applyExtra(
        _applyQaFilter(serverSearchHits, includeQaFixtures),
        extra,
      );
    }

    var list = _applyQaFilter(bookings, includeQaFixtures);
    final q = filters.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      final plan = AdminOpsSearch.classify(q);
      if (plan.isServerSide) {
        // Waiting for / using server path — don't empty the page prematurely.
        return _applyExtra(list, extra);
      }
      list = list.where((b) => AdminBookingsSearch.matchesLoadedPage(b, q)).toList();
    }
    return _applyExtra(list, extra);
  }

  static List<OrderRecord> _applyQaFilter(
    List<OrderRecord> list,
    bool includeQaFixtures,
  ) {
    if (includeQaFixtures) return list;
    return list.where((b) => !AdminQaFixture.isFixtureOrder(b)).toList();
  }

  static List<OrderRecord> _applyExtra(
    List<OrderRecord> list,
    AdminBookingsExtraFilters extra,
  ) {
    if (!extra.hasAny) return list;
    return list.where((b) {
      final row = AdminBookingRow.fromOrder(b);
      final cq = extra.customerQuery.trim().toLowerCase();
      if (cq.isNotEmpty) {
        final hay =
            '${row.customerName} ${row.customerPhone}'.toLowerCase();
        if (!hay.contains(cq)) return false;
      }
      final dq = extra.driverQuery.trim().toLowerCase();
      if (dq.isNotEmpty) {
        final hay = '${row.driverName} ${row.driverPhone}'.toLowerCase();
        if (!hay.contains(dq)) return false;
      }
      if (extra.paymentMethod != null &&
          b.paymentMethod != extra.paymentMethod) {
        return false;
      }
      if (extra.vehicleTypeRef != null &&
          b.carRev?.path != extra.vehicleTypeRef!.path) {
        return false;
      }
      if (extra.amountMin != null && b.total < extra.amountMin!) {
        return false;
      }
      if (extra.amountMax != null && b.total > extra.amountMax!) {
        return false;
      }
      return true;
    }).toList();
  }
}

/// Bookings search — extends shared classify with order phone / names.
abstract final class AdminBookingsSearch {
  AdminBookingsSearch._();

  static bool matchesLoadedPage(OrderRecord b, String qLower) {
    final row = AdminBookingRow.fromOrder(b);
    final status = row.statusLabel.toLowerCase();
    return row.orderId.toLowerCase().contains(qLower) ||
        row.customerName.toLowerCase().contains(qLower) ||
        row.driverName.toLowerCase().contains(qLower) ||
        row.customerPhone.contains(qLower) ||
        row.driverPhone.contains(qLower) ||
        row.city.toLowerCase().contains(qLower) ||
        row.plateLabel.toLowerCase().contains(qLower) ||
        row.vehicleLabel.toLowerCase().contains(qLower) ||
        b.halhText.toLowerCase().contains(qLower) ||
        status.contains(qLower) ||
        b.reference.id.toLowerCase().contains(qLower);
  }

  /// Server search: doc id, IDorder, customer phone.
  static Future<List<OrderRecord>> searchServer(
    AdminSearchPlan plan,
    AdminOpsFilterState filters, {
    int limit = 40,
  }) async {
    if (!plan.isServerSide || plan.normalized == null) return const [];

    final country = filters.effectiveCountryRef;
    final n = plan.normalized!;

    if (plan.mode == AdminSearchMode.exactId) {
      try {
        final doc = await OrderRecord.collection.doc(n).get();
        if (doc.exists) {
          final rec = OrderRecord.fromSnapshot(doc);
          if (country == null || rec.revDolh?.path == country.path) {
            return [rec];
          }
        }
      } catch (_) {}

      final byId = await queryOrderRecordOnce(
        queryBuilder: (qq) {
          var x = qq.where('IDorder', isEqualTo: n);
          if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
          return x;
        },
        limit: limit,
      );
      if (byId.isNotEmpty) return byId;
    }

    if (plan.mode == AdminSearchMode.exactContact && !n.contains('@')) {
      // phone_numper is stored as int on many docs — try both.
      final digits = n.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length >= 7) {
        final asInt = int.tryParse(digits);
        final byPhone = await queryOrderRecordOnce(
          queryBuilder: (qq) {
            var x = asInt != null
                ? qq.where('phone_numper', isEqualTo: asInt)
                : qq.where('phone_numper', isEqualTo: digits);
            if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
            return x;
          },
          limit: limit,
        );
        if (byPhone.isNotEmpty) return byPhone;
      }
    }

    return const [];
  }
}

/// Lightweight lifecycle summary — prefers dashboard cache; never invents zeros.
class AdminBookingsSummaryCounts {
  const AdminBookingsSummaryCounts({
    required this.results,
    this.total,
    this.active,
    this.completed,
    this.cancelled,
    this.expired,
    this.fromDashboard = false,
  });

  /// Rows in the current visible/prepared working set (page).
  final int results;

  /// Scoped dataset total (same filters as table, lifecycle=all).
  final int? total;
  final int? active;
  final int? completed;
  final int? cancelled;
  final int? expired;
  final bool fromDashboard;
}

/// Status code sets for summary chips (admin display only).
abstract final class AdminBookingsLifecycle {
  AdminBookingsLifecycle._();

  static bool isExpiredCode(String code) =>
      code == TourySystemStatusCodes.expired;

  static bool isCancelledCode(String code) =>
      AdminOpsCounters.cancelledStatusCodes.contains(code) ||
      code.startsWith('cancelled') ||
      code.startsWith('canceled');

  static bool isCompletedCode(String code) =>
      AdminOpsCounters.completedStatusCodes.contains(code);

  static bool isActiveTone(AdminBookingStatusTone tone) =>
      tone == AdminBookingStatusTone.assigned ||
      tone == AdminBookingStatusTone.onTheWay ||
      tone == AdminBookingStatusTone.arrived ||
      tone == AdminBookingStatusTone.inTrip ||
      tone == AdminBookingStatusTone.pending;

  /// Operational lifecycle counts from a working set (not a capped page).
  ///
  /// Excludes QA fixtures unless [includeQaFixtures] is true.
  static ({
    int active,
    int completed,
    int cancelled,
    int expired,
  }) countOperational(
    Iterable<OrderRecord> orders, {
    bool includeQaFixtures = false,
  }) {
    final list = includeQaFixtures
        ? orders.toList(growable: false)
        : orders.where((o) => !AdminQaFixture.isFixtureOrder(o)).toList();
    var active = 0;
    var completed = 0;
    var cancelled = 0;
    var expired = 0;
    for (final o in list) {
      final tone = AdminBookingStatusLabel.toneOf(o);
      if (tone == AdminBookingStatusTone.completed) {
        completed++;
      } else if (tone == AdminBookingStatusTone.canceled) {
        cancelled++;
      } else if (tone == AdminBookingStatusTone.expired) {
        expired++;
      } else if (isActiveTone(tone)) {
        active++;
      }
    }
    return (
      active: active,
      completed: completed,
      cancelled: cancelled,
      expired: expired,
    );
  }

  /// Loads lifecycle buckets via status queries (not page `.length`).
  ///
  /// Uses the **same** country/city/date scope as the table
  /// ([AdminBookingsQuery.applyScopeFiltersCore]) plus client extras / QA gate.
  /// Completed / cancelled / expired use `status_code` sets; active uses ALLNOW.
  static Future<({
    int total,
    int active,
    int completed,
    int cancelled,
    int expired,
  })> loadOperational({
    required AdminOpsFilterState filters,
    AdminBookingsExtraFilters extra = AdminBookingsExtraFilters.empty,
    bool includeQaFixtures = false,
    int limitPerBucket = 500,
  }) async {
    // Ignore selected lifecycle chip — each bucket applies its own predicate.
    final scope = filters.copyWith(
      orderLifecycle: AdminOrderLifecycleFilter.all,
    );

    Future<List<OrderRecord>> scoped(
      Query Function(Query q) bucket,
    ) async {
      return queryOrderRecordOnce(
        queryBuilder: (q) => bucket(AdminBookingsQuery.applyScopeFiltersCore(q, scope)),
        limit: limitPerBucket,
      );
    }

    final parts = await Future.wait([
      scoped((q) => q), // total / all scoped
      scoped((q) => q.where('ALLNOW', isEqualTo: true)),
      scoped(
        (q) => q.where(
          'status_code',
          whereIn: AdminOpsCounters.completedStatusCodes.take(30).toList(),
        ),
      ),
      scoped(
        (q) => q.where(
          'status_code',
          whereIn: AdminOpsCounters.cancelledStatusCodes.take(30).toList(),
        ),
      ),
      scoped(
        (q) => q.where(
          'status_code',
          isEqualTo: TourySystemStatusCodes.expired,
        ),
      ),
    ]);

    List<OrderRecord> finish(List<OrderRecord> raw) {
      return AdminBookingsQuery.applyClientFilters(
        raw,
        filters: scope,
        extra: extra,
        includeQaFixtures: includeQaFixtures,
      );
    }

    final all = finish(parts[0]);
    final activeN = countOperational(
      finish(parts[1]),
      includeQaFixtures: true,
    ).active;
    final completedN = countOperational(
      finish(parts[2]),
      includeQaFixtures: true,
    ).completed;
    final cancelledN = countOperational(
      finish(parts[3]),
      includeQaFixtures: true,
    ).cancelled;
    final expiredN = countOperational(
      finish(parts[4]),
      includeQaFixtures: true,
    ).expired;

    return (
      total: all.length,
      active: activeN,
      completed: completedN,
      cancelled: cancelledN,
      expired: expiredN,
    );
  }
}
