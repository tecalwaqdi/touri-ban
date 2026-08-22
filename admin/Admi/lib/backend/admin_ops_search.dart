import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/backend.dart';

/// How the admin search bar resolves a query.
enum AdminSearchMode {
  /// Empty query — no search.
  none,

  /// Document id / booking id / driver uid equality (server).
  exactId,

  /// `email ==` or `phone_number ==` (server).
  exactContact,

  /// Prefix range on email/phone when query looks like a prefix (server).
  prefixContact,

  /// Free-text name — **loaded page only** (no collection scan).
  loadedPageName,
}

/// Result of classifying + optionally running a server search.
class AdminSearchPlan {
  const AdminSearchPlan({
    required this.mode,
    required this.rawQuery,
    this.normalized,
    this.userMessageKey,
  });

  final AdminSearchMode mode;
  final String rawQuery;
  final String? normalized;

  /// i18n / uiTr key explaining limits to the admin.
  final String? userMessageKey;

  bool get isServerSide =>
      mode == AdminSearchMode.exactId ||
      mode == AdminSearchMode.exactContact ||
      mode == AdminSearchMode.prefixContact;

  bool get isLoadedPageOnly => mode == AdminSearchMode.loadedPageName;

  static const limitHintKey = 'search_limit_loaded_page';
  static const exactHintKey = 'search_exact_server';
  static const prefixHintKey = 'search_prefix_server';
}

/// Classifies admin search input without scanning collections.
abstract final class AdminOpsSearch {
  AdminOpsSearch._();

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _emailPrefixRe = RegExp(r'^[^@\s]+@?[^@\s]*$');
  static final _phoneRe = RegExp(r'^\+?[\d\s\-]{7,18}$');
  static final _idRe = RegExp(r'^[A-Za-z0-9_\-]{6,128}$');

  static AdminSearchPlan classify(String raw) {
    final q = raw.trim();
    if (q.isEmpty) {
      return const AdminSearchPlan(mode: AdminSearchMode.none, rawQuery: '');
    }

    if (_emailRe.hasMatch(q)) {
      return AdminSearchPlan(
        mode: AdminSearchMode.exactContact,
        rawQuery: q,
        normalized: q.toLowerCase(),
        userMessageKey: AdminSearchPlan.exactHintKey,
      );
    }

    final digits = q.replaceAll(RegExp(r'[\s\-]'), '');
    if (_phoneRe.hasMatch(q) && digits.replaceAll('+', '').length >= 7) {
      return AdminSearchPlan(
        mode: AdminSearchMode.exactContact,
        rawQuery: q,
        normalized: digits,
        userMessageKey: AdminSearchPlan.exactHintKey,
      );
    }

    if (_idRe.hasMatch(q) && !q.contains(' ')) {
      return AdminSearchPlan(
        mode: AdminSearchMode.exactId,
        rawQuery: q,
        normalized: q,
        userMessageKey: AdminSearchPlan.exactHintKey,
      );
    }

    // Short email-ish prefix (e.g. "ali@") — bounded prefix query.
    if (q.length >= 3 && _emailPrefixRe.hasMatch(q) && q.contains('@')) {
      return AdminSearchPlan(
        mode: AdminSearchMode.prefixContact,
        rawQuery: q,
        normalized: q.toLowerCase(),
        userMessageKey: AdminSearchPlan.prefixHintKey,
      );
    }

    return AdminSearchPlan(
      mode: AdminSearchMode.loadedPageName,
      rawQuery: q,
      normalized: q.toLowerCase(),
      userMessageKey: AdminSearchPlan.limitHintKey,
    );
  }

  /// Users: equality / prefix server queries (scoped by [filters] country).
  static Future<List<UserRecord>> searchUsersServer(
    AdminSearchPlan plan,
    AdminOpsFilterState filters, {
    int limit = 40,
  }) async {
    if (!plan.isServerSide || plan.normalized == null) return const [];

    Query q = UserRecord.collection;
    final country = filters.effectiveCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }

    switch (plan.mode) {
      case AdminSearchMode.exactId:
        // Try doc id first, then driverid / uid fields.
        try {
          final doc = await UserRecord.collection.doc(plan.normalized!).get();
          if (doc.exists) {
            final rec = UserRecord.fromSnapshot(doc);
            if (country == null || rec.revDolh?.path == country.path) {
              return [rec];
            }
          }
        } catch (_) {}
        final byUid = await queryUserRecordOnce(
          queryBuilder: (qq) {
            var x = qq.where('uid', isEqualTo: plan.normalized);
            if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
            return x;
          },
          limit: limit,
        );
        if (byUid.isNotEmpty) return byUid;
        return queryUserRecordOnce(
          queryBuilder: (qq) {
            var x = qq.where('driverid', isEqualTo: plan.normalized);
            if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
            return x;
          },
          limit: limit,
        );
      case AdminSearchMode.exactContact:
        final n = plan.normalized!;
        if (n.contains('@')) {
          return queryUserRecordOnce(
            queryBuilder: (qq) {
              var x = qq.where('email', isEqualTo: n);
              if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
              return x;
            },
            limit: limit,
          );
        }
        return queryUserRecordOnce(
          queryBuilder: (qq) {
            var x = qq.where('phone_number', isEqualTo: n);
            if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
            return x;
          },
          limit: limit,
        );
      case AdminSearchMode.prefixContact:
        final n = plan.normalized!;
        final field = n.contains('@') ? 'email' : 'phone_number';
        return queryUserRecordOnce(
          queryBuilder: (qq) {
            var x = qq
                .where(field, isGreaterThanOrEqualTo: n)
                .where(field, isLessThan: '$n\uf8ff');
            if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
            return x;
          },
          limit: limit,
        );
      default:
        return const [];
    }
  }

  /// Orders: IDorder equality or document id.
  static Future<List<OrderRecord>> searchOrdersServer(
    AdminSearchPlan plan,
    AdminOpsFilterState filters, {
    int limit = 40,
  }) async {
    if (plan.mode != AdminSearchMode.exactId || plan.normalized == null) {
      return const [];
    }
    final n = plan.normalized!;
    final country = filters.effectiveCountryRef;

    try {
      final doc = await OrderRecord.collection.doc(n).get();
      if (doc.exists) {
        final rec = OrderRecord.fromSnapshot(doc);
        if (country == null || rec.revDolh?.path == country.path) {
          return [rec];
        }
      }
    } catch (_) {}

    return queryOrderRecordOnce(
      queryBuilder: (qq) {
        var x = qq.where('IDorder', isEqualTo: n);
        if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
        return x;
      },
      limit: limit,
    );
  }

  /// Human-readable Arabic/English limit note (via uiTr keys).
  static String hintFor(AdminSearchPlan plan) {
    switch (plan.mode) {
      case AdminSearchMode.none:
        return '';
      case AdminSearchMode.exactId:
      case AdminSearchMode.exactContact:
        return 'بحث دقيق على الخادم';
      case AdminSearchMode.prefixContact:
        return 'بحث بادئة على البريد/الهاتف (محدود)';
      case AdminSearchMode.loadedPageName:
        return 'بحث الاسم على الصفحة المحمّلة فقط — استخدم المعرف أو الهاتف أو البريد للبحث الكامل';
    }
  }
}
