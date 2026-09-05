import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_labels.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_view_model.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/financial_amount_resolution.dart';
import 'package:admin_arawatan/core/finance/financial_trip_semantics.dart';
import 'package:admin_arawatan/core/finance/settlement_state_labels.dart';
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
  bool fixture = false,
  String? agentId,
}) {
  return {
    'status_code': status,
    if (payment != null) 'payment_status': payment,
    'PaymentMethod': method,
    if (total != null) 'total': total,
    if (app != null) 'total_app': app,
    if (vat != null) 'total_vat': vat,
    if (mndob != null) 'total_mndob': mndob,
    if (mndob2 != null) 'total_mndob2': mndob2,
    'currency': 'SAR',
    if (fixture) 'is_test_fixture': true,
    if (agentId != null) 'agent_id': agentId,
    if (agentId != null) 'agent_attribution_status': 'attributed',
    if (agentId != null) 'agent_amount_minor': 38,
  };
}

void main() {
  setUpAll(_initFirebase);

  group('F2 accountant presentation', () {
    test('1 completed count independent of payment', () {
      final unpaid = _order(_base(payment: 'pending_cash'));
      final paid = _order(_base(
        payment: 'paid',
        method: 'OnlinePayment',
        mndob: 42.5,
        mndob2: 50,
      ));
      final model = AccountantFinanceReadModel.aggregate(
        orders: [unpaid, paid],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.completedTripCount, 2);
    });

    test('2 completed cash uncollected displays holder/collection correctly',
        () {
      final row = AccountantTripRow.fromOrder(
        _order(_base(payment: 'pending_cash', method: 'Cash')),
      );
      expect(row.operationallyCompleted, isTrue);
      expect(row.collectionStatusLabel, 'غير محصّل');
      expect(row.moneyHolderLabel, 'لم يُحصّل بعد');
      expect(row.paymentMethodLabel, 'نقدي');
    });

    test('3 cancelled paid trip excluded from completed rows', () {
      final o = _order(_base(
        status: TourySystemStatusCodes.cancelledByDriver,
        payment: 'paid',
        method: 'OnlinePayment',
        mndob: 42.5,
        mndob2: 50,
      ));
      final row = AccountantTripRow.fromOrder(o);
      expect(row.operationallyCompleted, isFalse);
      final model = AccountantFinanceReadModel.aggregate(
        orders: [o],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.completedTripCount, 0);
    });

    test('4 partial financial trip shows dash not zero', () {
      final row = AccountantTripRow.fromOrder(_order(_base(
        payment: 'pending_cash',
        mndob: null,
        mndob2: null,
      )));
      expect(row.dataQuality, isNot(FinancialDataQuality.complete));
      expect(row.grossDisplay, '—');
      expect(row.dataQualityLabel, isNot(contains('COMPLETE')));
    });

    test('5 QA fixture excluded from live model', () {
      final live = _order(
        _base(mndob: 42.5, mndob2: 50, payment: 'cash_collected'),
        'live1',
      );
      final fix = _order(
        _base(
          mndob: 42.5,
          mndob2: 50,
          payment: 'cash_collected',
          fixture: true,
        ),
        'fin7_ctrl_x',
      );
      final model = AccountantFinanceReadModel.aggregate(
        orders: [live, fix],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.qaFixturesExcluded, 1);
      expect(model.completedTripCount, 1);
    });

    test('6 Country Agent scope via countryPaths', () {
      final sa = _order({
        ..._base(mndob: 42.5, mndob2: 50, payment: 'cash_collected'),
        'Rev_dolh': FirebaseFirestore.instance.doc('countries/saudi'),
      }, 'sa');
      final eg = _order({
        ..._base(mndob: 42.5, mndob2: 50, payment: 'cash_collected'),
        'Rev_dolh': FirebaseFirestore.instance.doc('countries/egypt'),
      }, 'eg');
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

    test('7 missing agent attribution Arabic label', () {
      final row = AccountantTripRow.fromOrder(_order(_base()));
      expect(row.agentAttribution, FinancialAgentAttribution.missing);
      expect(row.agentLabel, contains('غير محدد'));
    });

    test('8 settlement direction Arabic — no raw enums', () {
      expect(
        SettlementStateLabels.directionAr('DRIVER_PAYS_COMPANY'),
        isNot(contains('DRIVER_PAYS')),
      );
      expect(
        AccountantFinanceLabels.dueDirectionAr(
          channel: FinancialPaymentChannel.cash,
          operationallyCompleted: true,
          cashCollected: true,
          paymentPaid: true,
        ),
        'مستحق للشركة على السائق',
      );
      expect(
        AccountantFinanceLabels.dueDirectionAr(
          channel: FinancialPaymentChannel.online,
          operationallyCompleted: true,
          cashCollected: false,
          paymentPaid: true,
        ),
        'مستحق للسائق على الشركة',
      );
    });

    test('9 no raw financial quality enums in labels', () {
      for (final q in FinancialDataQuality.values) {
        final ar = AccountantFinanceLabels.dataQualityAr(q);
        expect(ar.toUpperCase(), isNot(contains('COMPLETE')));
        expect(ar.toUpperCase(), isNot(contains('PARTIAL')));
        expect(ar.toUpperCase(), isNot(contains('UNRESOLVED')));
      }
    });

    test('10 settlement status Arabic — no developer workflow English', () {
      for (final s in ['draft', 'locked', 'settled', 'partially_paid']) {
        final ar = AccountantFinanceLabels.settlementStatusAr(s);
        expect(ar.toLowerCase(), isNot(contains('draft')));
        expect(ar.toLowerCase(), isNot(contains('lock')));
        expect(ar.toLowerCase(), isNot(contains('preview')));
        expect(ar.toLowerCase(), isNot(contains('ledger')));
      }
    });

    test('11 same scope → same completed count for summary vs table rows', () {
      final orders = [
        _order(_base(payment: 'pending_cash'), 'a'),
        _order(
          _base(
            payment: 'cash_collected',
            mndob: 42.5,
            mndob2: 50,
          ),
          'b',
        ),
        _order(
          _base(
            status: 'arrived',
            payment: 'paid',
            method: 'OnlinePayment',
          ),
          'c',
        ),
      ];
      final model = AccountantFinanceReadModel.aggregate(
        orders: orders,
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      final rows = orders
          .map(AccountantTripRow.fromOrder)
          .where((r) => r.operationallyCompleted)
          .toList();
      expect(rows.length, model.completedTripCount);
    });

    test('12 labels never expose DRIVER_PAYS_COMPANY raw', () {
      final ar = SettlementStateLabels.directionAr('DRIVER_PAYS_COMPANY');
      expect(ar.contains('_'), isFalse);
    });

    test('13 presentation is read-only construction (no writes)', () {
      final o = _order(_base());
      final before = Map<String, dynamic>.from(o.snapshotData);
      AccountantTripRow.fromOrder(o);
      expect(o.snapshotData, before);
    });
  });
}
