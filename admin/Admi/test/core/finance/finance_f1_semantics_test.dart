import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/financial_amount_resolution.dart';
import 'package:admin_arawatan/core/finance/financial_engine.dart';
import 'package:admin_arawatan/core/finance/financial_order_adapter.dart';
import 'package:admin_arawatan/core/finance/financial_trip_semantics.dart';
import 'package:admin_arawatan/core/toury_system_status_codes.dart';

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

Map<String, dynamic> _base({
  String status = 'completed',
  String? payment = 'pending_cash',
  String method = 'Cash',
  num? total = 50,
  num? app = 7.5,
  num? vat = 0,
  num? mndob,
  num? mndob2,
  String? country = 'countries/saudi',
  bool fixture = false,
  String? agentId,
  int? agentAmountMinor,
}) {
  return {
    if (status.isNotEmpty) 'status_code': status,
    if (payment != null) 'payment_status': payment,
    'PaymentMethod': method,
    if (total != null) 'total': total,
    if (app != null) 'total_app': app,
    if (vat != null) 'total_vat': vat,
    if (mndob != null) 'total_mndob': mndob,
    if (mndob2 != null) 'total_mndob2': mndob2,
    'currency': 'SAR',
    if (country != null) 'Rev_dolh':
        FirebaseFirestore.instance.doc(country),
    if (fixture) 'is_test_fixture': true,
    if (agentId != null) 'agent_id': agentId,
    if (agentAmountMinor != null) 'agent_amount_minor': agentAmountMinor,
    if (agentId != null) 'agent_attribution_status': 'attributed',
  };
}

void main() {
  setUpAll(_initFirebase);

  group('F1 semantics matrix', () {
    test('A completed + cash + uncollected → completed YES, paid NO', () {
      final o = _order(_base(payment: 'pending_cash', method: 'Cash'));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isTrue);
      expect(OrderStatusHelper.isOperationallyCompleted(o), isTrue);
      expect(OrderStatusHelper.isPaid(o), isFalse);
      expect(FinancialTripSemantics.isCashCollected(o), isFalse);
    });

    test('B completed + cash + collected → completed YES, cash YES', () {
      final o = _order(_base(
        payment: 'cash_collected',
        method: 'Cash',
        mndob: 42.5,
        mndob2: 50,
      ));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isTrue);
      expect(OrderStatusHelper.isPaid(o), isTrue);
      expect(FinancialTripSemantics.isCashCollected(o), isTrue);
    });

    test('C completed + card + paid → completed YES', () {
      final o = _order(_base(
        payment: 'paid',
        method: 'OnlinePayment',
        mndob: 42.5,
        mndob2: 50,
      ));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isTrue);
      expect(OrderStatusHelper.isPaid(o), isTrue);
    });

    test('D arrived + paid → completed NO', () {
      final o = _order(_base(
        status: TourySystemStatusCodes.driverArrived,
        payment: 'paid',
        method: 'OnlinePayment',
      ));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isFalse);
      expect(OrderStatusHelper.isPaid(o), isTrue);
    });

    test('E started + cash_collected → completed NO', () {
      final o = _order(_base(
        status: TourySystemStatusCodes.tripStarted,
        payment: 'cash_collected',
        method: 'Cash',
      ));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isFalse);
      expect(FinancialTripSemantics.isCashCollected(o), isTrue);
    });

    test('F cancelled + paid online → completed NO', () {
      final o = _order(_base(
        status: TourySystemStatusCodes.cancelledByDriver,
        payment: 'paid',
        method: 'OnlinePayment',
        mndob: 42.5,
        mndob2: 50,
      ));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isFalse);
      // Legacy isPaid still false when canceled (refund/statusOf compat).
      expect(OrderStatusHelper.isPaid(o), isFalse);
      expect(
        FinancialTripSemantics.isPaymentPaidSnapshot(
          FinancialOrderAdapter.fromOrder(o),
        ),
        isTrue,
      );
    });

    test('G Arabic مكتملة is operational-only, NOT payment paid', () {
      final o = _order({
        'halh': 'مكتملة',
        'halh_text': 'مكتملة',
        'PaymentMethod': 'Cash',
        'payment_status': 'pending_cash',
        'total': 50,
        'currency': 'SAR',
      });
      expect(OrderStatusHelper.isPaid(o), isFalse);
      expect(OrderStatusHelper.isOperationallyCompleted(o), isTrue);
      expect(OrderStatusHelper.countsTowardRevenue(o), isFalse);
    });

    test('H QA fixture excluded from live KPI aggregation', () {
      final live = _order(
        _base(mndob: 42.5, mndob2: 50, payment: 'cash_collected'),
        'live_1',
      );
      final fixture = _order(
        _base(
          mndob: 42.5,
          mndob2: 50,
          payment: 'cash_collected',
          fixture: true,
        ),
        'fin7_ctrl_x',
      );
      final model = AccountantFinanceReadModel.aggregate(
        orders: [live, fixture],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.qaFixturesExcluded, 1);
      expect(model.completedTripCount, 1);
      expect(FinancialTripSemantics.isFinanceQaFixture(fixture), isTrue);
    });

    test('I completed + missing money → count YES, financial PARTIAL, no zero fabricate',
        () {
      final o = _order(_base(
        payment: 'pending_cash',
        total: 50,
        app: 7.5,
        vat: 0,
        mndob: null,
        mndob2: null,
      ));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isTrue);
      final line =
          FinancialAccountingEngine.analyze(FinancialOrderAdapter.fromOrder(o));
      final res = FinancialAmountResolution.fromLine(line);
      expect(res.quality, isNot(FinancialDataQuality.complete));

      final model = AccountantFinanceReadModel.aggregate(
        orders: [o],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.completedTripCount, 1);
      expect(model.completedTripsWithCompleteFinancialData, 0);
      expect(
        model.completedTripsWithPartialFinancialData +
            model.completedTripsWithUnresolvedFinancialData,
        greaterThan(0),
      );
      expect(model.completedGross.minorUnits, 0);
    });

    test('J historical agent snapshot present → confident', () {
      final snap = FinancialOrderAdapter.fromOrder(_order(_base(
        agentId: 'agentA',
        agentAmountMinor: 38,
        payment: 'cash_collected',
        mndob: 42.5,
        mndob2: 50,
      )));
      expect(
        FinancialAgentAttributionResolver.classify(snap),
        FinancialAgentAttribution.confident,
      );
      expect(FinancialAgentAttributionResolver.historicalAgentId(snap), 'agentA');
    });

    test('K agent snapshot missing → do NOT infer current agent', () {
      final snap = FinancialOrderAdapter.fromOrder(_order(_base(
        payment: 'pending_cash',
      )));
      expect(
        FinancialAgentAttributionResolver.classify(snap),
        FinancialAgentAttribution.missing,
      );
      expect(FinancialAgentAttributionResolver.historicalAgentId(snap), isNull);
    });

    test('L Country Agent scope — no other-country totals', () {
      final sa = _order(
        _base(
          country: 'countries/saudi',
          payment: 'cash_collected',
          mndob: 42.5,
          mndob2: 50,
        ),
        'sa1',
      );
      final eg = _order(
        _base(
          country: 'countries/egypt',
          payment: 'cash_collected',
          mndob: 42.5,
          mndob2: 50,
        ),
        'eg1',
      );
      final model = AccountantFinanceReadModel.aggregate(
        orders: [sa, eg],
        scope: const AccountantFinanceScope(
          includeAllCountries: false,
          countryPaths: ['countries/saudi'],
        ),
        currency: 'SAR',
      );
      expect(model.completedTripCount, 1);
    });

    test('fixture 50 SAR split reproduces exactly when complete', () {
      final o = _order(_base(
        payment: 'cash_collected',
        total: 50,
        app: 7.5,
        vat: 0,
        mndob: 42.5,
        mndob2: 50,
      ));
      final line =
          FinancialAccountingEngine.analyze(FinancialOrderAdapter.fromOrder(o));
      final res = FinancialAmountResolution.fromLine(line);
      expect(res.quality, FinancialDataQuality.complete);
      expect(res.gross!.majorUnits, 50);
      expect(res.companyCommission!.majorUnits, 7.5);
      expect(res.vat!.majorUnits, 0);
      expect(res.driverNet!.majorUnits, 42.5);
    });

    test('legacy trip_completed counts as operational complete', () {
      final o = _order(_base(status: 'trip_completed', payment: 'pending_cash'));
      expect(FinancialTripSemantics.isOperationallyCompleted(o), isTrue);
    });
  });
}
