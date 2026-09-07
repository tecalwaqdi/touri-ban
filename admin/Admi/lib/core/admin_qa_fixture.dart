import '/backend/schema/order_record.dart';
import '/core/admin_finance_demo_mode.dart';

/// Controlled production QA / finance test fixture detection (presentation + ops filter).
///
/// Does not rewrite historical data. Explicit metadata preferred; ID prefixes are
/// a legacy fallback for fixtures created before the contract.
///
/// Admin finance demo fixtures (`admin_demo_fixture`) are excluded from normal
/// KPIs unless [AdminFinanceDemoMode.enabled] is ON (controlled group only).
abstract final class AdminQaFixture {
  AdminQaFixture._();

  static const metaIsTest = 'is_test_fixture';
  static const metaScope = 'test_scope';
  static const metaRunId = 'test_run_id';
  static const metaType = 'fixture_type';
  static const metaCreatedBy = 'created_by_qa';

  static const metaAdminDemo = 'admin_demo_fixture';
  static const metaDemoSeedGroup = 'demo_seed_group';
  static const metaExcludeFromRealReporting = 'exclude_from_real_reporting';

  static final RegExp _legacyIdPrefix = RegExp(
    r'^(fin7_ctrl_|fin9_ctrl_|fin_rt_cash_|fin_rt_cash_ui_|fin_rt_)',
  );

  /// Deterministic Admin finance demo IDs (`demo_fin_*`).
  static final RegExp _adminFinanceDemoIdPrefix =
      RegExp(r'^demo_fin_', caseSensitive: false);

  /// FIN-8 controlled settlement payment refs (repository-proven).
  static final RegExp _fin8PaymentRef = RegExp(r'^FIN8-', caseSensitive: false);

  static bool isFixtureId(String orderId) => _legacyIdPrefix.hasMatch(orderId);

  static bool isAdminFinanceDemoId(String id) =>
      _adminFinanceDemoIdPrefix.hasMatch(id.trim());

  /// Controlled removable demo seed (see seed_admin_finance_demo.js).
  static bool isControlledAdminFinanceDemo(
    Map<String, dynamic> data, {
    String? id,
  }) {
    if (data[metaAdminDemo] != true) return false;
    final group = '${data[metaDemoSeedGroup] ?? ''}'.trim();
    if (group == AdminFinanceDemoMode.seedGroup) return true;
    final docId = (id ?? '').trim();
    return docId.isNotEmpty && isAdminFinanceDemoId(docId);
  }

  /// Hide from normal finance reporting / lists.
  ///
  /// - Classic QA / fin* fixtures: always hide (diagnostics chip separate).
  /// - Controlled admin demo: hide unless [AdminFinanceDemoMode.enabled].
  /// - Unknown `admin_demo_fixture` without our seed group: always hide.
  static bool shouldExcludeFromFinanceReporting(
    Map<String, dynamic> data, {
    String? orderId,
  }) {
    if (isControlledAdminFinanceDemo(data, id: orderId)) {
      return !AdminFinanceDemoMode.enabled;
    }
    if (data[metaAdminDemo] == true) return true;
    return isClassicQaFixtureMap(data, orderId: orderId);
  }

  /// Classic QA markers only (never toggled by Demo Mode).
  static bool isClassicQaFixtureMap(
    Map<String, dynamic> data, {
    String? orderId,
  }) {
    if (data[metaIsTest] == true) return true;
    if (data['qa_fixture'] == true || data['test_fixture'] == true) {
      return true;
    }
    final id = (orderId ?? '').trim();
    if (id.isNotEmpty && isFixtureId(id)) return true;
    return false;
  }

  static bool isFixtureMap(Map<String, dynamic> data, {String? orderId}) {
    return shouldExcludeFromFinanceReporting(data, orderId: orderId);
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
  /// Controlled Admin finance demos are **not** QA-diagnostics rows — they are
  /// gated solely by [AdminFinanceDemoMode] via
  /// [shouldExcludeFromFinanceReporting].
  static bool isFinanceQaSettlement(
    Map<String, dynamic> data, {
    String? settlementId,
    Iterable<String>? paymentExternalRefs,
  }) {
    if (isControlledAdminFinanceDemo(data, id: settlementId)) {
      return false;
    }
    if (isClassicQaFixtureMap(data, orderId: settlementId)) return true;

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
    final data = Map<String, dynamic>.from(order.snapshotData);
    if (isControlledAdminFinanceDemo(data, id: order.reference.id)) {
      return 'وضع تجريبي';
    }
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

  /// Markers for Admin finance UI demo seed (never real reporting).
  static Map<String, dynamic> adminFinanceDemoStamp({
    String seedVersion = AdminFinanceDemoMode.seedVersion,
  }) =>
      {
        'is_demo': true,
        metaAdminDemo: true,
        'demo_seed_version': seedVersion,
        metaDemoSeedGroup: AdminFinanceDemoMode.seedGroup,
        metaExcludeFromRealReporting: true,
      };
}
