import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';
import 'package:admin_arawatan/core/finance/finance_reconciliation_qa.dart';
import 'package:admin_arawatan/core/finance/finance_reconciliation_read_model.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

OrderRecord _order(Map<String, dynamic> data, [String id = 'o1']) {
  final ref = FirebaseFirestore.instance.collection('order').doc(id);
  return OrderRecord.getDocumentFromData(data, ref);
}

Map<String, dynamic> _completeCash({
  String status = 'completed',
  String payment = 'cash_collected',
  String method = 'Cash',
  num total = 50,
  num app = 7.5,
  num vat = 0,
  num mndob = 42.5,
  num mndob2 = 50,
  String country = 'countries/saudi_arabia',
  String? agentStatus,
  String? agentId,
  int? agentAmountMinor,
  num? agentRate,
  String? agentRateType,
  bool fixture = false,
  bool functionalTest = false,
  String? goldenCycle,
}) {
  return {
    if (status.isNotEmpty) 'status_code': status,
    'payment_status': payment,
    if (payment == 'cash_collected') 'cash_collection_status': 'collected',
    if (payment == 'pending_cash') 'cash_collection_status': 'pending',
    'PaymentMethod': method,
    'total': total,
    'total_app': app,
    'total_vat': vat,
    'total_mndob': mndob,
    'total_mndob2': mndob2,
    'currency': 'SAR',
    'Rev_dolh': FirebaseFirestore.instance.doc(country),
    if (fixture) 'is_test_fixture': true,
    if (functionalTest) 'functional_test': true,
    if (goldenCycle != null) 'golden_cycle': goldenCycle,
    if (agentStatus != null) 'agent_attribution_status': agentStatus,
    if (agentId != null) 'agent_id': agentId,
    if (agentAmountMinor != null) 'agent_amount_minor': agentAmountMinor,
    if (agentRate != null) 'agent_rate': agentRate,
    if (agentRateType != null) 'agent_rate_type': agentRateType,
  };
}

const _saudi = AccountantFinanceScope(
  includeAllCountries: false,
  countryPaths: ['countries/saudi_arabia'],
);

const _all = AccountantFinanceScope(includeAllCountries: true);

FinanceReconciliationResult _build(
  List<OrderRecord> orders, {
  AccountantFinanceScope scope = _all,
  List<Map<String, dynamic>> settlements = const [],
  List<Map<String, dynamic>> unallocated = const [],
}) {
  return FinanceReconciliationReadModel.buildReconciliation(
    orders: orders,
    scope: scope,
    currency: 'SAR',
    settlements: settlements,
    unallocatedPayments: unallocated,
  );
}

void main() {
  setUpAll(_initFirebase);

  group('F3-B1 reconciliation matrix', () {
    test('1 completed + complete + cash collected + unsettled', () {
      final o = _order(_completeCash(
        agentStatus: 'none',
      ));
      final r = _build([o]).records.single;
      expect(r.operationalStatus, RecOperationalStatus.completed);
      expect(r.financialSnapshotStatus, RecFinancialSnapshotStatus.complete);
      expect(r.collectionStatus, RecCollectionStatus.collected);
      expect(r.settlementStatus, RecSettlementStatus.unsettled);
      expect(r.reconciliationStatus, RecReconciliationStatus.needsReview);
      expect(
        r.businessStateIssues.any((i) => i.code == RecIssueCode.noSettlement),
        isTrue,
      );
    });

    test('2 completed + complete + cash uncollected', () {
      final o = _order(_completeCash(payment: 'pending_cash'));
      final r = _build([o]).records.single;
      expect(r.collectionStatus, RecCollectionStatus.uncollected);
      expect(
        r.businessStateIssues
            .any((i) => i.code == RecIssueCode.cashNotCollected),
        isTrue,
      );
      expect(r.reconciliationStatus, isNot(RecReconciliationStatus.reconciled));
    });

    test('3 completed + partial financial', () {
      final data = _completeCash();
      data.remove('total_mndob2');
      data.remove('total_mndob');
      final r = _build([_order(data)]).records.single;
      expect(r.financialSnapshotStatus, RecFinancialSnapshotStatus.partial);
      expect(r.reconciliationStatus,
          RecReconciliationStatus.blockedByMissingData);
      // Engine may derive gross from total — still PARTIAL; obligations stay null.
      expect(r.companyReceivable, isNull);
      expect(r.driverNet, isNull);
    });

    test('4 completed + unresolved financial', () {
      final data = {
        'status_code': 'completed',
        'PaymentMethod': 'Cash',
        'payment_status': 'pending_cash',
        'currency': 'SAR',
        'Rev_dolh': FirebaseFirestore.instance.doc('countries/saudi_arabia'),
      };
      final r = _build([_order(data)]).records.single;
      expect(r.financialSnapshotStatus, RecFinancialSnapshotStatus.unresolved);
      expect(r.reconciliationStatus,
          RecReconciliationStatus.blockedByMissingData);
    });

    test('5 operational not completed', () {
      final o = _order(_completeCash(status: 'driver_arrived'));
      final r = _build([o]).records.single;
      expect(r.operationalStatus, RecOperationalStatus.notCompleted);
      expect(r.reconciliationStatus,
          RecReconciliationStatus.blockedByMissingData);
    });

    test('6 explicit no-agent snapshot', () {
      final o = _order(_completeCash(agentStatus: 'none'));
      final r = _build([o]).records.single;
      expect(r.agentStatus, RecAgentStatus.none);
      expect(
        r.dataQualityIssues
            .any((i) => i.code == RecIssueCode.missingAgentHistory),
        isFalse,
      );
    });

    test('7 complete agent snapshot', () {
      final o = _order(_completeCash(
        agentStatus: 'attributed',
        agentId: 'agent_a',
        agentAmountMinor: 38,
        agentRate: 5,
        agentRateType: 'percent_of_platform_fee',
      ));
      final r = _build([o]).records.single;
      expect(r.agentStatus, RecAgentStatus.complete);
      expect(r.agentAmount?.minorUnits, 38);
    });

    test('8 ambiguous agent snapshot', () {
      final o = _order(_completeCash(agentStatus: 'ambiguous'));
      final r = _build([o]).records.single;
      expect(r.agentStatus, RecAgentStatus.ambiguous);
      expect(
        r.dataQualityIssues.any((i) => i.code == RecIssueCode.ambiguousAgent),
        isTrue,
      );
      expect(r.reconciliationStatus, RecReconciliationStatus.needsReview);
    });

    test('9 legacy missing agent', () {
      final o = _order(_completeCash());
      final r = _build([o]).records.single;
      expect(r.agentStatus, RecAgentStatus.missing);
      expect(
        r.dataQualityIssues
            .any((i) => i.code == RecIssueCode.missingAgentHistory),
        isTrue,
      );
      expect(r.reconciliationStatus,
          RecReconciliationStatus.blockedByMissingData);
    });

    test('10 cash flow direction — companyReceivable / driverPayable', () {
      final o = _order(_completeCash(agentStatus: 'none'));
      final r = _build([o]).records.single;
      expect(r.companyReceivable, isNotNull);
      expect(r.driverPayable, isNotNull);
      expect(r.companyPayable, isNull);
      expect(r.driverReceivable, isNull);
      // 7.5 + 0 = 750 minor
      expect(r.companyReceivable!.minorUnits, 750);
    });

    test('11 online flow direction — companyPayable / driverReceivable', () {
      final data = _completeCash(
        method: 'OnlinePayment',
        payment: 'paid',
        agentStatus: 'none',
      );
      data.remove('cash_collection_status');
      final r = _build([_order(data)]).records.single;
      expect(r.paymentMethod, RecPaymentMethod.online);
      expect(r.collectionStatus, RecCollectionStatus.notApplicable);
      expect(r.companyPayable, isNotNull);
      expect(r.driverReceivable, isNotNull);
      expect(r.companyReceivable, isNull);
      expect(r.driverPayable, isNull);
      expect(r.driverReceivable!.minorUnits, 4250);
    });

    test('12 no settlement when eligible', () {
      final o = _order(_completeCash(agentStatus: 'none'));
      final r = _build([o]).records.single;
      expect(r.settlementStatus, RecSettlementStatus.unsettled);
      expect(r.settlementEligibility, RecSettlementEligibility.eligible);
      expect(
        r.businessStateIssues.any((i) => i.code == RecIssueCode.noSettlement),
        isTrue,
      );
    });

    test('13 partially paid settlement', () {
      final o = _order(_completeCash(agentStatus: 'none'), 'trip_partial_set');
      final r = _build(
        [o],
        settlements: [
          {
            'id': 's1',
            'status': 'partially_paid',
            'direction': 'driver_to_company',
            'dueMinor': 750,
            'paidMinor': 300,
            'remainingMinor': 450,
            'eligibleOrderIds': ['trip_partial_set'],
          },
        ],
      ).records.single;
      expect(r.settlementStatus, RecSettlementStatus.partial);
      expect(
        r.businessStateIssues
            .any((i) => i.code == RecIssueCode.settlementPartial),
        isTrue,
      );
    });

    test('14 settled settlement', () {
      final o = _order(_completeCash(agentStatus: 'none'), 'trip_settled');
      final r = _build(
        [o],
        settlements: [
          {
            'id': 's2',
            'status': 'settled',
            'dueMinor': 750,
            'paidMinor': 750,
            'remainingMinor': 0,
            'eligibleOrderIds': ['trip_settled'],
          },
        ],
      ).records.single;
      expect(r.settlementStatus, RecSettlementStatus.settled);
      expect(r.reconciliationStatus, RecReconciliationStatus.reconciled);
    });

    test('15 settlement mismatch', () {
      final o = _order(_completeCash(agentStatus: 'none'), 'trip_mm');
      final r = _build(
        [o],
        settlements: [
          {
            'id': 's3',
            'status': 'partially_paid',
            'dueMinor': 750,
            'paidMinor': 300,
            'remainingMinor': 999, // wrong
            'eligibleOrderIds': ['trip_mm'],
          },
        ],
      ).records.single;
      expect(
        r.dataQualityIssues
            .any((i) => i.code == RecIssueCode.settlementMismatch),
        isTrue,
      );
      expect(r.reconciliationStatus, RecReconciliationStatus.needsReview);
    });

    test('16 missing != zero', () {
      final data = _completeCash();
      data.remove('total_mndob2');
      data.remove('total_mndob');
      final r = _build([_order(data)]).records.single;
      // Prefer null obligations over fabricated zeros when snapshot incomplete.
      expect(r.driverNet, isNull);
      expect(r.companyReceivable, isNull);
      expect(r.companyPayable, isNull);
      expect(r.driverPayable, isNull);
      expect(r.driverReceivable, isNull);
    });

    test('17 explicit zero remains valid', () {
      final o = _order(_completeCash(vat: 0, agentStatus: 'none'));
      final r = _build([o]).records.single;
      expect(r.vat, isNotNull);
      expect(r.vat!.minorUnits, 0);
      expect(r.financialSnapshotStatus, RecFinancialSnapshotStatus.complete);
    });

    test('18 agent share validation mismatch', () {
      final o = _order(_completeCash(
        agentStatus: 'attributed',
        agentId: 'a1',
        agentAmountMinor: 1, // wrong vs 5% of 750 = 38
        agentRate: 5,
        agentRateType: 'percent_of_platform_fee',
      ));
      final r = _build([o]).records.single;
      expect(
        r.dataQualityIssues
            .any((i) => i.code == RecIssueCode.agentAmountMismatch),
        isTrue,
      );
      // Does not overwrite
      expect(r.agentAmount!.minorUnits, 1);
    });

    test('19 historical current-agent fallback forbidden', () {
      // No agent fields — must stay MISSING even if we "know" a country agent.
      final o = _order(_completeCash());
      final r = _build([o]).records.single;
      expect(r.agentStatus, RecAgentStatus.missing);
      expect(r.agentAmount, isNull);
    });

    test('20 QA fin7 excluded', () {
      final o = _order(_completeCash(fixture: true), 'fin7_ctrl_123');
      final res = _build([o]);
      expect(res.records, isEmpty);
      expect(res.summary.qaFixturesExcluded, 1);
      expect(res.diagnosticsExcluded, isNotEmpty);
    });

    test('21 QA fin9 excluded', () {
      final o = _order(_completeCash(), 'fin9_ctrl_456');
      final res = _build([o]);
      expect(res.records, isEmpty);
      expect(res.summary.qaFixturesExcluded, 1);
    });

    test('22 QA fin_rt excluded', () {
      final o = _order(_completeCash(), 'fin_rt_cash_789');
      final res = _build([o]);
      expect(res.records, isEmpty);
      expect(res.summary.qaFixturesExcluded, 1);
    });

    test('23 functional_test excluded', () {
      final o = _order(_completeCash(functionalTest: true), '03392f80a1');
      expect(
        FinanceReconciliationQa.isReconciliationQaOrder(o),
        isTrue,
      );
      final res = _build([o]);
      expect(res.records, isEmpty);
      expect(res.summary.qaFixturesExcluded, 1);
    });

    test('24 TOURi_GOLDEN_1 excluded', () {
      final o = _order(
        _completeCash(goldenCycle: 'TOURi_GOLDEN_1'),
        '03392f80a1xx',
      );
      final res = _build([o]);
      expect(res.records, isEmpty);
      expect(res.summary.completedTrips, 0);
      expect(res.summary.qaFixturesExcluded, 1);
    });

    test('25 normal trip not falsely excluded', () {
      final o = _order(
        _completeCash(agentStatus: 'none'),
        '7b9a80c306ab',
      );
      final res = _build([o]);
      expect(res.records.length, 1);
      expect(res.summary.qaFixturesExcluded, 0);
    });

    test('26 Super Admin all-country', () {
      final a = _order(
        _completeCash(country: 'countries/saudi_arabia', agentStatus: 'none'),
        'sa1',
      );
      final b = _order(
        _completeCash(country: 'countries/uae', agentStatus: 'none'),
        'uae1',
      );
      final res = _build([a, b], scope: _all);
      expect(res.records.length, 2);
    });

    test('27 Country Agent own-country only', () {
      final a = _order(
        _completeCash(country: 'countries/saudi_arabia', agentStatus: 'none'),
        'sa1',
      );
      final b = _order(
        _completeCash(country: 'countries/uae', agentStatus: 'none'),
        'uae1',
      );
      final res = _build([a, b], scope: _saudi);
      expect(res.records.length, 1);
      expect(res.records.single.orderId, 'sa1');
    });

    test('28 cross-country row leakage = 0', () {
      final foreign = _order(
        _completeCash(country: 'countries/uae', agentStatus: 'none'),
        'uae_only',
      );
      final res = _build([foreign], scope: _saudi);
      expect(res.records, isEmpty);
    });

    test('29 cross-country totals leakage = 0', () {
      final foreign = _order(
        _completeCash(country: 'countries/uae', agentStatus: 'none'),
        'uae_money',
      );
      final res = _build([foreign], scope: _saudi);
      expect(res.summary.completedTrips, 0);
      expect(res.summary.completedGross, isNull);
      expect(res.summary.financialComplete, 0);
    });

    test('30 unallocated company payment does not auto-match', () {
      final o = _order(_completeCash(agentStatus: 'none'), 'live_trip');
      final res = _build(
        [o],
        unallocated: [
          {
            'id': 'cp1',
            'amountMinor': 5000,
            'currency': 'SAR',
            'externalRef': 'LEGACY-CP',
          },
        ],
      );
      expect(res.records.single.settlementLinks, isEmpty);
      expect(res.unallocatedPayments.length, 1);
      expect(res.unallocatedPayments.single.amountMinor, 5000);
      expect(res.records.single.settlementStatus, RecSettlementStatus.unsettled);
    });

    test('31 financial formula mismatch becomes issue', () {
      final data = _completeCash(
        mndob: 10, // wrong vs 50-7.5-0=42.5
        agentStatus: 'none',
      );
      final r = _build([_order(data)]).records.single;
      expect(
        r.dataQualityIssues
            .any((i) => i.code == RecIssueCode.financialSnapshotMismatch),
        isTrue,
      );
      expect(r.reconciliationStatus, RecReconciliationStatus.needsReview);
    });

    test('32 settlement formula mismatch becomes issue', () {
      final o = _order(_completeCash(agentStatus: 'none'), 'trip_smm');
      final r = _build(
        [o],
        settlements: [
          {
            'id': 'sx',
            'status': 'open',
            'dueMinor': 100,
            'paidMinor': 10,
            'remainingMinor': 50,
            'eligibleOrderIds': ['trip_smm'],
          },
        ],
      ).records.single;
      expect(
        r.dataQualityIssues
            .any((i) => i.code == RecIssueCode.settlementMismatch),
        isTrue,
      );
    });

    test('33 partial trip excluded from unsafe money totals', () {
      final partial = _order({
        'status_code': 'completed',
        'PaymentMethod': 'Cash',
        'payment_status': 'pending_cash',
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'currency': 'SAR',
        'Rev_dolh':
            FirebaseFirestore.instance.doc('countries/saudi_arabia'),
      });
      final complete = _order(
        _completeCash(agentStatus: 'none'),
        'complete_trip',
      );
      final res = _build([partial, complete]);
      expect(res.summary.financialPartial, 1);
      expect(res.summary.financialComplete, 1);
      expect(res.summary.completedGross!.minorUnits, 5000); // only complete
    });

    test('34 partial count remains visible', () {
      final partial = _order({
        'status_code': 'completed',
        'PaymentMethod': 'Cash',
        'payment_status': 'pending_cash',
        'total': 50,
        'total_app': 7.5,
        'currency': 'SAR',
        'Rev_dolh':
            FirebaseFirestore.instance.doc('countries/saudi_arabia'),
      });
      final res = _build([partial]);
      expect(res.summary.completedTrips, 1);
      expect(res.summary.financialPartial, greaterThanOrEqualTo(1));
      expect(res.summary.moneyOmittedIncompleteCount, greaterThanOrEqualTo(1));
    });

    test('35 no Firestore writes (pure transform)', () {
      // Smoke: build never throws and returns structured result.
      final o = _order(_completeCash(agentStatus: 'none'));
      final res = _build([o]);
      expect(res.records, isNotEmpty);
      expect(res.summary.currency, 'SAR');
    });

    test('P historical CASH-7B9A80C306-like → BLOCKED PARTIAL', () {
      final data = {
        'status_code': 'completed',
        'PaymentMethod': 'Cash',
        'payment_status': 'pending_cash',
        'cash_collection_status': 'pending',
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'currency': 'SAR',
        'Rev_dolh':
            FirebaseFirestore.instance.doc('countries/saudi_arabia'),
        'display_reference': 'CASH-7B9A80C306',
      };
      final r = _build([_order(data, '7b9a80c306ab')]).records.single;
      expect(r.displayReference, 'CASH-7B9A80C306');
      expect(r.operationalStatus, RecOperationalStatus.completed);
      expect(r.financialSnapshotStatus, RecFinancialSnapshotStatus.partial);
      expect(r.paymentMethod, RecPaymentMethod.cash);
      expect(r.collectionStatus, RecCollectionStatus.uncollected);
      expect(r.agentStatus, RecAgentStatus.missing);
      expect(r.settlementStatus, RecSettlementStatus.unsettled);
      expect(r.reconciliationStatus,
          RecReconciliationStatus.blockedByMissingData);
    });

    test('computeAgentAmountMinor matches C2 rounding', () {
      expect(
        FinanceReconciliationReadModel.computeAgentAmountMinor(750, 5),
        38,
      );
      expect(
        FinanceReconciliationReadModel.computeAgentAmountMinor(750, 10),
        75,
      );
      expect(
        FinanceReconciliationReadModel.computeAgentAmountMinor(null, 5),
        isNull,
      );
    });
  });
}
