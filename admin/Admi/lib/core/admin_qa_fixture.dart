import '/backend/schema/order_record.dart';

/// Controlled production QA / finance test fixture detection (presentation + ops filter).
///
/// Does not rewrite historical data. Explicit metadata preferred; ID prefixes are
/// a legacy fallback for fixtures created before the contract.
abstract final class AdminQaFixture {
  AdminQaFixture._();

  static const metaIsTest = 'is_test_fixture';
  static const metaScope = 'test_scope';
  static const metaRunId = 'test_run_id';
  static const metaType = 'fixture_type';
  static const metaCreatedBy = 'created_by_qa';

  static final RegExp _legacyIdPrefix = RegExp(
    r'^(fin7_ctrl_|fin9_ctrl_|fin_rt_cash_|fin_rt_cash_ui_|fin_rt_)',
  );

  /// FIN-8 controlled settlement payment refs (repository-proven).
  static final RegExp _fin8PaymentRef = RegExp(r'^FIN8-', caseSensitive: false);

  static bool isFixtureId(String orderId) => _legacyIdPrefix.hasMatch(orderId);

  static bool isFixtureMap(Map<String, dynamic> data, {String? orderId}) {
    if (data[metaIsTest] == true) return true;
    if (data['qa_fixture'] == true || data['test_fixture'] == true) {
      return true;
    }
    final id = (orderId ?? '').trim();
    if (id.isNotEmpty && isFixtureId(id)) return true;
    return false;
  }

  static bool isFixtureOrder(OrderRecord order) => isFixtureMap(
        Map<String, dynamic>.from(order.snapshotData),
        orderId: order.reference.id,
      );

  /// FIN-8 / controlled settlement payment external references.
  static bool isFinanceQaPaymentRef(String? ref) {
    final r = (ref ?? '').trim();
    if (r.isEmpty) return false;
    return _fin8PaymentRef.hasMatch(r);
  }

  /// Settlement docs created by controlled finance scripts (e.g. FIN-8).
  ///
  /// Proven markers (do not delete live docs — filter presentation only):
  /// - explicit QA metadata
  /// - [eligibleOrderIds] / line ids matching trip fixture prefixes
  /// - idempotencyKey `fin8_*` / embedded fixture order ids
  /// - payment refs `FIN8-*` when provided
  static bool isFinanceQaSettlement(
    Map<String, dynamic> data, {
    String? settlementId,
    Iterable<String>? paymentExternalRefs,
  }) {
    if (isFixtureMap(data, orderId: settlementId)) return true;

    final idemp = '${data['idempotencyKey'] ?? ''}'.trim().toLowerCase();
    if (idemp.startsWith('fin8_') ||
        idemp.startsWith('fin7_') ||
        idemp.startsWith('fin9_') ||
        idemp.contains('fin7_ctrl_') ||
        idemp.contains('fin9_ctrl_') ||
        idemp.contains('fin_rt_')) {
      return true;
    }

    for (final key in ['eligibleOrderIds', 'orderIds', 'lineOrderIds']) {
      final raw = data[key];
      if (raw is! List) continue;
      for (final id in raw) {
        if (isFixtureId('$id')) return true;
      }
    }

    final excluded = data['excluded'];
    if (excluded is List) {
      for (final e in excluded) {
        final oid = e is Map ? '${e['orderId'] ?? ''}' : '$e';
        if (isFixtureId(oid)) return true;
      }
    }

    if (paymentExternalRefs != null) {
      for (final ref in paymentExternalRefs) {
        if (isFinanceQaPaymentRef(ref)) return true;
      }
    }

    return false;
  }

  /// Badge for intentional Super Admin inspection of QA rows.
  static String badgeAr(OrderRecord order) {
    final scope =
        (order.snapshotData[metaScope] ?? order.snapshotData['test_scope'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    if (scope == 'finance' || isFixtureId(order.reference.id)) {
      return 'سجل اختبار مالي';
    }
    return 'سجل اختبار مراقب';
  }

  /// Firestore metadata to stamp on future controlled fixtures.
  static Map<String, dynamic> stamp({
    required String scope,
    required String fixtureType,
    required String runId,
    String createdBy = 'qa_agent',
  }) =>
      {
        metaIsTest: true,
        metaScope: scope,
        metaType: fixtureType,
        metaRunId: runId,
        metaCreatedBy: createdBy,
      };
}
