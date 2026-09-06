import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_perf_trace.dart';
import '/backend/admin_role_service.dart';

/// Stable Firestore query identity for the Settlements list (PERF-P1).
///
/// Status / QA chips filter **client-side** and must not change this key.
abstract final class AdminSettlementsQuery {
  AdminSettlementsQuery._();

  static const int pageLimit = 200;

  /// Deterministic key for the server query (scope + limit only).
  static String keyForCurrentUser() {
    final scopedPath = _scopedCountryPath();
    if (scopedPath != null) {
      return 'financial_settlements|countryId=$scopedPath|limit=$pageLimit';
    }
    return 'financial_settlements|all|limit=$pageLimit';
  }

  /// Same predicate as the historical Settlements widget query.
  ///
  /// Country Agent (non–Super Admin): filter `countryId`.
  /// Global Accountant / Super Admin: unscoped soft-cap list.
  static Query<Map<String, dynamic>> buildForCurrentUser() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('financial_settlements');
    final scopedPath = _scopedCountryPath();
    if (scopedPath != null) {
      q = q.where('countryId', isEqualTo: scopedPath);
    }
    return q.limit(pageLimit);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> snapshotsForCurrentUser() {
    final key = keyForCurrentUser();
    AdminPerfTrace.settlementStreamCreate(key);
    return buildForCurrentUser().snapshots();
  }

  /// Matches pre-P1 Settlements widget: country agent scope only.
  static String? _scopedCountryPath() {
    if (AdminRoleService.isCountryAgent && !AdminRoleService.isSuperAdmin) {
      return AdminRoleService.scopedCountryIdClaim;
    }
    return null;
  }
}

/// Owns one Settlements snapshots subscription until [queryKey] changes.
class AdminSettlementsStreamOwner {
  AdminSettlementsStreamOwner({
    String Function()? keyFactory,
    Stream<QuerySnapshot<Map<String, dynamic>>> Function(String key)?
        streamFactory,
  })  : _keyFactory = keyFactory ?? AdminSettlementsQuery.keyForCurrentUser,
        _streamFactory = streamFactory ??
            ((key) {
              AdminPerfTrace.settlementStreamCreate(key);
              return AdminSettlementsQuery.buildForCurrentUser().snapshots();
            });

  final String Function() _keyFactory;
  final Stream<QuerySnapshot<Map<String, dynamic>>> Function(String key)
      _streamFactory;

  String? _key;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  String? get queryKey => _key;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForCurrentUser() {
    final nextKey = _keyFactory();
    if (_stream != null && _key == nextKey) {
      return _stream!;
    }
    if (_key != null) {
      AdminPerfTrace.settlementStreamDispose(_key);
    }
    _key = nextKey;
    _stream = _streamFactory(nextKey);
    return _stream!;
  }

  void dispose() {
    if (_key != null) {
      AdminPerfTrace.settlementStreamDispose(_key);
    }
    _key = null;
    _stream = null;
  }
}
