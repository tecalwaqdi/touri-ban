import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/admin_money_presentation.dart';
import 'package:admin_arawatan/core/finance/finance_ledger_service.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/financial_order_adapter.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';
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

void main() {
  setUpAll(_initFirebase);

  group('Phase A — driver net display safety', () {
    test('50 SAR missing total_mndob → derived 42.50, never 50', () {
      final order = _order({
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'currency': 'SAR',
        'PaymentMethod': 'Cash',
        'status_code': TourySystemStatusCodes.completed,
        'payment_status': 'pending_cash',
      });

      final money = AdminOrderMoneyDisplay.fromOrder(order);
      expect(money.grossMajor, 50.0);
      expect(money.platformFeeMajor, 7.5);
      expect(money.vatMajor, 0.0);
      expect(money.driverNetMajor, 42.5);
      expect(money.driverNetIsDerived, isTrue);
      expect(money.driverNetMajor, isNot(50));

      final row = AdminBookingRow.fromOrder(order);
      expect(row.amount, 50.0);
      expect(row.commission, 7.5);
      expect(row.driverNet, 42.5);
      expect(row.driverNetIsDerived, isTrue);
      expect(row.driverNetLabel.contains('42.50'), isTrue);
      expect(row.driverNetLabel.contains('50.00'), isFalse);
    });

    test('mndob2 never used as net when mndob missing and mndob2=gross', () {
      final order = _order({
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'total_mndob2': 50,
        'currency': 'SAR',
        'PaymentMethod': 'Cash',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
      });
      final row = AdminBookingRow.fromOrder(order);
      expect(row.driverNet, 42.5);
      expect(row.driverNet, isNot(50));
    });

    test('stored total_mndob preferred when present', () {
      final order = _order({
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'total_mndob': 42.5,
        'total_mndob2': 50,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
      });
      final row = AdminBookingRow.fromOrder(order);
      expect(row.driverNet, 42.5);
      expect(row.driverNetIsDerived, isFalse);
    });

    test('unprovable net displays as null / em dash', () {
      final order = _order({
        'total': 50,
        'currency': 'SAR',
        'status_code': 'completed',
        'PaymentMethod': 'Cash',
      });
      final money = AdminOrderMoneyDisplay.fromOrder(order);
      expect(money.driverNet, isNull);
      expect(money.hasDriverNet, isFalse);

      final row = AdminBookingRow.fromOrder(order);
      expect(row.driverNet, isNull);
      expect(row.driverNetLabel, '—');
    });

    test('poison cancelled legacy never settlement-eligible', () {
      final order = _order({
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'total_mndob': 43,
        'total_mndob2': 42.5,
        'currency': 'SAR',
        'PaymentMethod': 'Cash',
        'status_code': 'cancelled_by_driver',
        'payment_status': 'pending_cash',
      }, 'poison');

      final line = FinancialOrderAdapter.analyzeOrder(order);
      expect(line.lifecycle, FinancialLifecycle.cancelled);
      expect(line.settlementEligible, isFalse);
      expect(line.exclusionReason, 'CANCELLED');

      final totals = FinancialAccountingEngine.aggregateByCurrency([line]);
      final sar = totals['SAR']!;
      expect(sar.completedAndCollected, 0);
      expect(sar.cashDriversOweCompany.minorUnits, 0);
      expect(sar.platformFeeAll.minorUnits, 0);
      expect(sar.cancelledOrExpired, 1);
    });

    test('money format keeps two decimals', () {
      final m = MoneyAmount.fromMajor('SAR', 7.5)!;
      expect(
        AdminOrderMoneyDisplay.formatMoneyAmount(m, symbolOverride: 'ر.س'),
        contains('7.50'),
      );
    });
  });

  group('Phase A — Hub snapshot field semantics', () {
    test('FinanceHubSnapshot exposes V2-named fields only', () {
      const snap = FinanceHubSnapshot(
        primaryCurrency: 'SAR',
        collectedTripValue: MoneyAmount(currency: 'SAR', minorUnits: 0),
        platformFees: MoneyAmount(currency: 'SAR', minorUnits: 0),
        recordedVat: MoneyAmount(currency: 'SAR', minorUnits: 0),
        driverNet: MoneyAmount(currency: 'SAR', minorUnits: 0),
        settlementEligibleDue: MoneyAmount(currency: 'SAR', minorUnits: 0),
        companyOwesDrivers: MoneyAmount(currency: 'SAR', minorUnits: 0),
        completedAndCollected: 0,
        completedButNotCollected: 2,
        cancelledOrExpired: 46,
        pendingPayment: 0,
        totalsSource: 'server_v2',
        periodLabel: 'ent_period_this_month',
        driverBalances: {},
        ledger: [],
      );
      expect(snap.totalsSource, 'server_v2');
      expect(snap.settlementEligibleDue.majorUnits, 0);
      expect(snap.completedButNotCollected, 2);
      expect(snap.isApproximate, isFalse);
    });
  });
}
