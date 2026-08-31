import '/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import '/backend/admin_ops_country_scope.dart';
import '/backend/admin_ops_counters.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_search.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/core/admin_booking_status_label.dart';
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

  /// Same predicates as [AdminOpsQueryBuilder.applyOrderFilters] without orderBy
  /// (safe for Aggregate Count).
  static Query applyFiltersCore(Query q, AdminOpsFilterState filters) {
    q = AdminOpsCountryScope.applyCountryFieldFilter(
      q,
      field: 'Rev_dolh',
      explicitCountry: filters.effectiveCountryRef,
    );

    final codes = AdminOpsQueryBuilder.statusCodesFor(filters.orderLifecycle);
    if (filters.orderLifecycle == AdminOrderLifecycleFilter.active) {
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

    if (filters.cityRef != null) {
      q = q.where('vill', isEqualTo: filters.cityRef);
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
  }) {
    if (serverSearchHits != null) {
      return _applyExtra(serverSearchHits, extra);
    }

    var list = bookings;
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

  final int results;
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
}
