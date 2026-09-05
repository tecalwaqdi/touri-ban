import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_labels.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_loader.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_text.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_view_model.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/settlement_state_labels.dart';
import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/flutter_flow/flutter_flow_theme.dart';

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

Map<String, dynamic> _completeCash({bool fixture = false}) => {
      'status_code': 'completed',
      'payment_status': 'cash_collected',
      'PaymentMethod': 'Cash',
      'total': 50,
      'total_app': 7.5,
      'total_vat': 0,
      'total_mndob': 42.5,
      'total_mndob2': 50,
      'currency': 'SAR',
      'naim_mndob_text': 'سائق تجريبي',
      'Rev_dolh': FirebaseFirestore.instance.doc('countries/saudi_arabia'),
      if (fixture) 'is_test_fixture': true,
    };

void main() {
  setUpAll(_initFirebase);

  group('F2.1 consistency + presentation', () {
    test('1 QA fixture excluded from summary', () {
      final live = _order(_completeCash(), 'live_ok');
      final fix = _order(_completeCash(fixture: true), 'fin7_ctrl_x');
      final model = AccountantFinanceReadModel.aggregate(
        orders: [live, fix],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.qaFixturesExcluded, 1);
      expect(model.completedTripCount, 1);
      expect(model.completedGross.majorUnits, 50);
    });

    test('2 QA fixture excluded from normal money table filter', () {
      final live = AccountantTripRow.fromOrder(_order(_completeCash(), 'live_ok'));
      final fix = AccountantTripRow.fromOrder(
        _order(_completeCash(fixture: true), 'fin_rt_cash_ui_1'),
      );
      final filtered = AccountantTripFilters.apply([live, fix]);
      expect(filtered.length, 1);
      expect(filtered.first.orderId, 'live_ok');
      expect(AdminQaFixture.isFixtureId('fin9_ctrl_abc'), isTrue);
    });

    test('3 QA fixture excluded from on-screen report set (= same filter)', () {
      final rows = [
        AccountantTripRow.fromOrder(_order(_completeCash(), 'a')),
        AccountantTripRow.fromOrder(
          _order(_completeCash(fixture: true), 'fin9_ctrl_z'),
        ),
      ];
      expect(AccountantTripFilters.apply(rows).length, 1);
    });

    test('4 Hub vs Report same scope = same canonical totals', () {
      final orders = [
        _order(_completeCash(), 'r1'),
        _order(_completeCash(), 'r2'),
        _order(_completeCash(fixture: true), 'fin7_ctrl_1'),
      ];
      final hub = AccountantFinanceReadModel.aggregate(
        orders: orders,
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      final report = AccountantFinanceReadModel.aggregate(
        orders: orders,
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(hub.completedTripCount, report.completedTripCount);
      expect(hub.completedGross.minorUnits, report.completedGross.minorUnits);
      expect(
        hub.companyCommission.minorUnits,
        report.companyCommission.minorUnits,
      );
      expect(hub.completedTripCount, 2);
      expect(hub.completedGross.majorUnits, 100);
    });

    test('5 real zero vs missing data presentation', () {
      final incomplete = AccountantTripRow.fromOrder(_order({
        'status_code': 'completed',
        'payment_status': 'pending_cash',
        'PaymentMethod': 'Cash',
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'currency': 'SAR',
      }));
      expect(incomplete.grossDisplay, '—');
      expect(incomplete.grossDisplay, isNot('0.00'));
    });

    test('6 raw country paths hidden', () {
      final row = AccountantTripRow.fromOrder(_order(_completeCash()));
      expect(row.countryLabel, 'السعودية');
      expect(row.countryLabel.contains('countries/'), isFalse);
      expect(
        AccountantFinanceLabels.countryHumanAr('countries/saudi_arabia'),
        'السعودية',
      );
    });

    test('7 raw driver UID hidden from business label', () {
      final row = AccountantTripRow.fromOrder(_order({
        ..._completeCash(),
        'mndob_user': FirebaseFirestore.instance.doc('user/ABCDEF123'),
        'naim_mndob_text': 'أحمد السائق',
      }));
      expect(row.driverLabel, 'أحمد السائق');
      expect(row.driverLabel.contains('ABCDEF'), isFalse);
    });

    test('8 agent amount label is share of commission', () {
      expect(
        AccountantFinanceLabels.agentShareOfCommissionLabel(),
        contains('عمولة الشركة'),
      );
      expect(
        AccountantFinanceLabels.agentShareOfCommissionLabel().contains('50'),
        isFalse,
      );
      final row = AccountantTripRow.fromOrder(_order({
        ..._completeCash(),
        'agent_id': 'ag1',
        'agent_amount_minor': 38,
        'agent_attribution_status': 'attributed',
      }));
      expect(row.agentAmountIsShareOfCommission, isTrue);
      expect(row.grossDisplay.contains('50'), isTrue);
    });

    test('9 no Rev_dolh / server_v2 in labels', () {
      expect(AccountantFinanceLabels.countryHumanAr('countries/saudi_arabia'),
          isNot(contains('Rev_dolh')));
      expect(
        AccountantFinanceLabels.settlementStatusAr('draft'),
        isNot(contains('server_v2')),
      );
    });

    test('10 settlement due/paid/remaining Arabic status', () {
      expect(AccountantFinanceLabels.settlementStatusAr('settled'), 'مسددة');
      expect(
        AccountantFinanceLabels.settlementStatusAr('partially_paid'),
        'مسددة جزئيًا',
      );
      expect(AccountantFinanceLabels.settlementStatusAr('draft'), 'غير مسددة');
      expect(
        SettlementStateLabels.directionAr('DRIVER_PAYS_COMPANY'),
        isNot(contains('DRIVER')),
      );
    });

    test('11 no raw enum leakage in quality labels', () {
      final q =
          AccountantTripRow.fromOrder(_order(_completeCash())).dataQuality;
      final ar = AccountantFinanceLabels.dataQualityAr(q);
      expect(ar.toUpperCase(), isNot(contains('COMPLETE')));
      expect(ar.toUpperCase(), isNot(contains('PARTIAL')));
    });

    test('12 light surface finance ink is dark (not theme.info white)', () {
      final ff = LightModeTheme();
      final ink = AccountantFinanceText.ink(ff);
      expect(ink.computeLuminance(), lessThan(0.4));
      expect(ff.info.computeLuminance(), greaterThan(0.9));
      expect(ink, isNot(equals(ff.info)));
    });
  });
}
