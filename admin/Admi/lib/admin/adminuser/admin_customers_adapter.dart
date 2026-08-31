import '/backend/backend.dart';

/// Account status — orthogonal to “has active booking”.
enum AdminCustomerAccountStatus {
  active,
  suspended,
  unknown,
}

/// List-row hint for active booking (resolved deeply only in details).
enum AdminCustomerTripHint {
  none,
  lockPresent,
  confirmedActive,
  staleLock,
}

/// Admin customer (app user) row — excludes drivers/agents.
class AdminCustomerRow {
  const AdminCustomerRow({
    required this.user,
    required this.displayName,
    required this.phone,
    required this.email,
    required this.photoUrl,
    required this.city,
    required this.accountStatus,
    required this.accountActive,
    required this.activeOrderId,
    required this.tripHint,
    required this.createdAt,
    required this.lastLoginAt,
    required this.bookingsCountLabel,
  });

  final UserRecord user;
  final String displayName;
  final String phone;
  final String email;
  final String photoUrl;
  final String city;
  final AdminCustomerAccountStatus accountStatus;
  final bool accountActive;
  final String activeOrderId;
  final AdminCustomerTripHint tripHint;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String bookingsCountLabel;

  static String _str(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return '';
    return v.toString().trim();
  }

  static String activeOrderIdFromData(Map<String, dynamic> data) {
    final a = _str(data, 'active_order_id');
    if (a.isNotEmpty) return a;
    return _str(data, 'activeOrderId');
  }

  static String activeOrderIdOf(UserRecord user) =>
      activeOrderIdFromData(user.snapshotData);

  /// Profile / registration city — not live GPS.
  static String cityFromData(Map<String, dynamic> data) {
    for (final k in [
      'city_display',
      'mndob_vill_text',
      'vill_text',
      'city',
      'SuggestedPlaceCity',
    ]) {
      final v = _str(data, k);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static String cityOf(UserRecord user) {
    final fromData = cityFromData(user.snapshotData);
    if (fromData.isNotEmpty) return fromData;
    if (user.mndobVillText.trim().isNotEmpty) return user.mndobVillText.trim();
    return '';
  }

  static AdminCustomerAccountStatus accountStatusFromData(
    Map<String, dynamic> data,
  ) {
    if (data.containsKey('actev_user')) {
      final v = data['actev_user'];
      final active = v == true;
      return active
          ? AdminCustomerAccountStatus.active
          : AdminCustomerAccountStatus.suspended;
    }
    // Legacy missing flag — treat as unknown (not “active booking”).
    return AdminCustomerAccountStatus.unknown;
  }

  static AdminCustomerAccountStatus accountStatusOf(UserRecord user) =>
      accountStatusFromData(user.snapshotData);

  static DateTime? createdAtOf(UserRecord user) {
    if (user.hasCreatedTime()) return user.createdTime;
    final data = user.snapshotData;
    final v = data['created_at'] ?? data['createdAt'];
    if (v is DateTime) return v;
    return null;
  }

  static DateTime? lastLoginOf(UserRecord user) {
    final data = user.snapshotData;
    final v = data['last_login_at'] ?? data['lastLoginAt'] ?? data['last_activity_at'];
    if (v is DateTime) return v;
    return null;
  }

  static String bookingsCountOf(UserRecord user) {
    final data = user.snapshotData;
    final v = data['Bookings_User'] ??
        data['bookings_count'] ??
        data['total_bookings'] ??
        data['orders_count'];
    if (v == null) return '—';
    return '$v';
  }

  /// Pure row from user doc — does not fetch the order.
  static AdminCustomerRow fromUser(
    UserRecord user, {
    AdminCustomerTripHint tripHint = AdminCustomerTripHint.none,
  }) {
    final aid = activeOrderIdOf(user);
    final account = accountStatusOf(user);
    var hint = tripHint;
    if (hint == AdminCustomerTripHint.none && aid.isNotEmpty) {
      hint = AdminCustomerTripHint.lockPresent;
    }
    return AdminCustomerRow(
      user: user,
      displayName: user.displayName.trim().isNotEmpty
          ? user.displayName.trim()
          : (user.email.trim().isNotEmpty ? user.email.trim() : '—'),
      phone: user.phoneNumber.trim().isNotEmpty
          ? user.phoneNumber.trim()
          : (user.phoneN > 0 ? '${user.phoneN}' : '—'),
      email: user.email.trim().isNotEmpty ? user.email.trim() : '—',
      photoUrl: user.photoUrl.trim(),
      city: cityOf(user).isNotEmpty ? cityOf(user) : '—',
      accountStatus: account,
      accountActive: account == AdminCustomerAccountStatus.active,
      activeOrderId: aid,
      tripHint: hint,
      createdAt: createdAtOf(user),
      lastLoginAt: lastLoginOf(user),
      bookingsCountLabel: bookingsCountOf(user),
    );
  }

  bool matchesSearch(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'[\s\-]'), '');
    return displayName.toLowerCase().contains(q) ||
        email.toLowerCase().contains(q) ||
        phone.toLowerCase().contains(q) ||
        phone.replaceAll(RegExp(r'[\s\-]'), '').contains(digits) ||
        user.reference.id.toLowerCase().contains(q) ||
        user.uid.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q);
  }

  /// Display-only phone formatting — does not mutate stored values.
  static String formatPhoneDisplay(String raw) {
    if (raw.trim().isEmpty || raw == '—') return '—';
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 12 && digits.startsWith('966')) {
      return '+966 ${digits.substring(3, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 10 && digits.startsWith('05')) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    if (digits.length == 9 && digits.startsWith('5')) {
      return '+966 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    return raw.trim();
  }

  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

enum AdminCustomerAccountFilter { all, active, suspended, unknown }
enum AdminCustomerTripFilter { all, hasLiveTrip, noLiveTrip }
enum AdminCustomerBookingsFilter { all, withBookings, withoutBookings }
enum AdminCustomerSort { newest, nameAsc, lastActivity, bookings }

class AdminCustomerExtraFilters {
  const AdminCustomerExtraFilters({
    this.account = AdminCustomerAccountFilter.all,
    this.trip = AdminCustomerTripFilter.all,
    this.bookings = AdminCustomerBookingsFilter.all,
    this.newTodayOnly = false,
    this.newThisMonthOnly = false,
    this.sort = AdminCustomerSort.newest,
  });

  final AdminCustomerAccountFilter account;
  final AdminCustomerTripFilter trip;
  final AdminCustomerBookingsFilter bookings;
  final bool newTodayOnly;
  final bool newThisMonthOnly;
  final AdminCustomerSort sort;

  static const empty = AdminCustomerExtraFilters();

  bool get hasAny =>
      account != AdminCustomerAccountFilter.all ||
      trip != AdminCustomerTripFilter.all ||
      bookings != AdminCustomerBookingsFilter.all ||
      newTodayOnly ||
      newThisMonthOnly ||
      sort != AdminCustomerSort.newest;

  int get activeCount =>
      (account != AdminCustomerAccountFilter.all ? 1 : 0) +
      (trip != AdminCustomerTripFilter.all ? 1 : 0) +
      (bookings != AdminCustomerBookingsFilter.all ? 1 : 0) +
      (newTodayOnly ? 1 : 0) +
      (newThisMonthOnly ? 1 : 0) +
      (sort != AdminCustomerSort.newest ? 1 : 0);

  String get signature =>
      '${account.name}|${trip.name}|${bookings.name}|$newTodayOnly|$newThisMonthOnly|${sort.name}';

  AdminCustomerExtraFilters copyWith({
    AdminCustomerAccountFilter? account,
    AdminCustomerTripFilter? trip,
    AdminCustomerBookingsFilter? bookings,
    bool? newTodayOnly,
    bool? newThisMonthOnly,
    AdminCustomerSort? sort,
  }) =>
      AdminCustomerExtraFilters(
        account: account ?? this.account,
        trip: trip ?? this.trip,
        bookings: bookings ?? this.bookings,
        newTodayOnly: newTodayOnly ?? this.newTodayOnly,
        newThisMonthOnly: newThisMonthOnly ?? this.newThisMonthOnly,
        sort: sort ?? this.sort,
      );

  List<AdminCustomerRow> apply(List<AdminCustomerRow> rows) {
    var out = rows;
    switch (account) {
      case AdminCustomerAccountFilter.active:
        out = out
            .where((r) => r.accountStatus == AdminCustomerAccountStatus.active)
            .toList(growable: false);
        break;
      case AdminCustomerAccountFilter.suspended:
        out = out
            .where(
              (r) => r.accountStatus == AdminCustomerAccountStatus.suspended,
            )
            .toList(growable: false);
        break;
      case AdminCustomerAccountFilter.unknown:
        out = out
            .where((r) => r.accountStatus == AdminCustomerAccountStatus.unknown)
            .toList(growable: false);
        break;
      case AdminCustomerAccountFilter.all:
        break;
    }
    switch (trip) {
      case AdminCustomerTripFilter.hasLiveTrip:
        out = out
            .where((r) => r.tripHint == AdminCustomerTripHint.confirmedActive)
            .toList(growable: false);
        break;
      case AdminCustomerTripFilter.noLiveTrip:
        out = out
            .where((r) => r.tripHint != AdminCustomerTripHint.confirmedActive)
            .toList(growable: false);
        break;
      case AdminCustomerTripFilter.all:
        break;
    }
    switch (bookings) {
      case AdminCustomerBookingsFilter.withBookings:
        out = out
            .where((r) =>
                r.bookingsCountLabel != '—' && r.bookingsCountLabel != '0')
            .toList(growable: false);
        break;
      case AdminCustomerBookingsFilter.withoutBookings:
        out = out
            .where((r) =>
                r.bookingsCountLabel == '—' || r.bookingsCountLabel == '0')
            .toList(growable: false);
        break;
      case AdminCustomerBookingsFilter.all:
        break;
    }
    if (newTodayOnly) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      out = out.where((r) {
        final c = r.createdAt;
        return c != null && !c.isBefore(start);
      }).toList(growable: false);
    }
    if (newThisMonthOnly) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      out = out.where((r) {
        final c = r.createdAt;
        return c != null && !c.isBefore(start);
      }).toList(growable: false);
    }
    return sortRows(out, sort);
  }

  static List<AdminCustomerRow> sortRows(
    List<AdminCustomerRow> rows,
    AdminCustomerSort sort,
  ) {
    final out = List<AdminCustomerRow>.from(rows);
    switch (sort) {
      case AdminCustomerSort.newest:
        out.sort((a, b) {
          final ac = a.createdAt;
          final bc = b.createdAt;
          if (ac == null && bc == null) return 0;
          if (ac == null) return 1;
          if (bc == null) return -1;
          return bc.compareTo(ac);
        });
        break;
      case AdminCustomerSort.nameAsc:
        out.sort(
          (a, b) =>
              a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
        );
        break;
      case AdminCustomerSort.lastActivity:
        out.sort((a, b) {
          final al = a.lastLoginAt ?? a.createdAt;
          final bl = b.lastLoginAt ?? b.createdAt;
          if (al == null && bl == null) return 0;
          if (al == null) return 1;
          if (bl == null) return -1;
          return bl.compareTo(al);
        });
        break;
      case AdminCustomerSort.bookings:
        out.sort((a, b) {
          final an = int.tryParse(a.bookingsCountLabel) ?? -1;
          final bn = int.tryParse(b.bookingsCountLabel) ?? -1;
          return bn.compareTo(an);
        });
        break;
    }
    return out;
  }
}

bool adminIsAppCustomer(UserRecord u) => !u.isagent && !u.ismndob && !u.ismndom;
