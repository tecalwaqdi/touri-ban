import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';
import 'package:admin_arawatan/core/finance/finance_v2_read_projection.dart';
import 'package:admin_arawatan/core/finance/finance_f1_v2_parity.dart';
import 'package:admin_arawatan/core/finance/finance_sot_settlement_stats.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

OrderRecord _order(
  String id,
  Map<String, dynamic> data,
) {
  return OrderRecord.getDocumentFromData(
    data,
    FirebaseFirestore.instance.collection('order').doc(id),
  );
}

void main() {
  setUpAll(_initFirebase);

  group('Finance F1↔V2 parity harness', () {
    test('same-order IDs: cash 50 regression amounts match on complete line', () {
      final o = _order('cash50_live', {
        'total': 50.0,
        'total_app': 7.5,
        'total_vat': 0.0,
        'total_mndob': 42.5,
        'total_mndob2': 50.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
      });
      final report = FinanceF1V2Parity.compareOrders([o]);
      expect(report.orderIds, ['cash50_live']);
      expect(report.fixturesExcluded, 0);
      expect(report.f1GrossMinor, 5000);
      expect(report.f1PlatformFeeMinor, 750);
      expect(report.f1VatMinor, 0);
      expect(report.f1DriverNetMinor, 4250);
      // V2 platform/vat/driver on economics path should match line.
      final line = FinancialAccountingEngine.analyze(
        FinancialOrderSnapshot(
          orderId: 'cash50_live',
          currency: 'SAR',
          paymentMethodRaw: 'Cash',
          statusCode: 'completed',
          paymentStatus: 'cash_collected',
          total: 50,
          totalApp: 7.5,
          totalVat: 0,
          totalMndob: 42.5,
          totalMndob2: 50,
          hasTotal: true,
          hasTotalApp: true,
          hasTotalVat: true,
          hasTotalMndob: true,
          hasTotalMndob2: true,
        ),
      );
      expect(line.platformFee?.minorUnits, 750);
      expect(line.driverNet?.minorUnits, 4250);
    });

    test('VAT case 800/120/120 → driver 560', () {
      const snap = FinancialOrderSnapshot(
        orderId: 'vat800',
        currency: 'SAR',
        paymentMethodRaw: 'Cash',
        statusCode: 'completed',
        paymentStatus: 'cash_collected',
        total: 800,
        totalApp: 120,
        totalVat: 120,
        totalMndob: 560,
        totalMndob2: 800,
        hasTotal: true,
        hasTotalApp: true,
        hasTotalVat: true,
        hasTotalMndob: true,
        hasTotalMndob2: true,
      );
      final line = FinancialAccountingEngine.analyze(snap);
      expect(line.driverNet?.majorUnits, 560);
      expect(line.platformFee?.majorUnits, 120);
      expect(line.recordedVat?.majorUnits, 120);
    });

    test('fixture orders excluded from parity set', () {
      final real = _order('real_1', {
        'total': 50.0,
        'total_app': 7.5,
        'total_vat': 0.0,
        'total_mndob': 42.5,
        'total_mndob2': 50.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
      });
      final demo = _order('demo_fin_x1', {
        'total': 999.0,
        'total_app': 99.0,
        'total_vat': 0.0,
        'total_mndob': 900.0,
        'total_mndob2': 999.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
        'is_demo': true,
      });
      final report = FinanceF1V2Parity.compareOrders([real, demo]);
      expect(report.fixturesExcluded, 1);
      expect(report.f1GrossMinor, 5000);
    });

    test('country isolation: foreign country path excluded from F1 aggregate', () {
      final sa = _order('sa_1', {
        'total': 50.0,
        'total_app': 7.5,
        'total_vat': 0.0,
        'total_mndob': 42.5,
        'total_mndob2': 50.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
        'Rev_dolh': FirebaseFirestore.instance.doc('country/SA'),
      });
      final eg = _order('eg_1', {
        'total': 80.0,
        'total_app': 8.0,
        'total_vat': 0.0,
        'total_mndob': 72.0,
        'total_mndob2': 80.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
        'Rev_dolh': FirebaseFirestore.instance.doc('country/EG'),
      });
      final scope = AccountantFinanceScope(
        includeAllCountries: false,
        countryPaths: ['country/SA'],
      );
      final f1 = FinanceV2ReadProjection.fromOrders(
        orders: [sa, eg],
        scope: scope,
        currency: 'SAR',
      );
      expect(f1.completedTripCount, 1);
      expect(f1.completedGross.minorUnits, 5000);
      final report = FinanceF1V2Parity.compareOrders(
        [sa, eg],
        scope: scope,
      );
      expect(report.f1TripCount, 1);
      expect(report.v2TripCount, 1);
    });
  });

  group('Fixture exclusion markers', () {
    test('demo / exclude_from_real_reporting detected', () {
      expect(AdminQaFixture.isFixtureId('demo_fin_abc'), isTrue);
      expect(AdminQaFixture.isFixtureId('demo_xyz'), isTrue);
      expect(
        AdminQaFixture.isFixtureMap({'is_demo': true}, orderId: 'x'),
        isTrue,
      );
      expect(
        AdminQaFixture.isFixtureMap(
          {'admin_demo_fixture': true},
          orderId: 'x',
        ),
        isTrue,
      );
      expect(
        AdminQaFixture.isFixtureMap(
          {'exclude_from_real_reporting': true},
          orderId: 'x',
        ),
        isTrue,
      );
      expect(
        AdminQaFixture.isFinanceQaSettlement(
          {'is_demo': true, 'status': 'draft', 'outstandingMinor': 100},
          settlementId: 'stl_demo',
        ),
        isTrue,
      );
    });
  });

  group('Settlement open counter excludes fixtures', () {
    test('countOpen skips demo settlement', () {
      final open = FinanceSotSettlementStats.countOpen([
        {
          'id': 'real',
          'status': 'partially_paid',
          'outstandingMinor': 500,
        },
        {
          'id': 'demo',
          'status': 'draft',
          'outstandingMinor': 9999,
          'is_demo': true,
        },
      ]);
      expect(open, 1);
    });
  });
}
