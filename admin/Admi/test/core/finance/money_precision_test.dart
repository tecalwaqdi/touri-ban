import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

void main() {
  setUpAll(_initFirebase);

  group('MoneyAmount precision', () {
    test('7.50 SAR stays 750 halalas', () {
      final m = MoneyAmount.fromMajor('SAR', 7.5)!;
      expect(m.minorUnits, 750);
      expect(m.majorUnits.toStringAsFixed(2), '7.50');
    });
  });

  group('OrderRecord money fields preserve fractions', () {
    test('total_app 7.5 is not rounded to 8', () {
      final order = OrderRecord.getDocumentFromData(
        {
          'total': 50.0,
          'total_app': 7.5,
          'total_vat': 0.0,
          'total_mndob': 42.5,
          'total_mndob2': 50.0,
          'currency': 'SAR',
        },
        FirebaseFirestore.instance.collection('order').doc('o1'),
      );
      expect(order.totalApp, 7.5);
      expect(order.totalMndob, 42.5);
      expect(7.5.round(), 8);
      expect(order.totalApp, isNot(8));
    });
  });

  group('FinancialAccountingEngine cash 50 SAR sample', () {
    test('driver net = gross − platform − vat', () {
      const snap = FinancialOrderSnapshot(
        orderId: 'cash50',
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
      );
      final line = FinancialAccountingEngine.analyze(snap);
      expect(line.platformFee?.majorUnits, 7.5);
      expect(line.driverNet?.majorUnits, 42.5);
      expect(line.grossBase?.majorUnits, 50.0);
    });

    test('cancelled orders are not settlement eligible', () {
      const snap = FinancialOrderSnapshot(
        orderId: 'c1',
        currency: 'SAR',
        paymentMethodRaw: 'Cash',
        statusCode: 'cancelled_by_driver',
        paymentStatus: 'pending_cash',
        total: 50,
        totalApp: 7.5,
        totalVat: 0,
        totalMndob: 42.5,
        hasTotal: true,
        hasTotalApp: true,
        hasTotalVat: true,
        hasTotalMndob: true,
      );
      final line = FinancialAccountingEngine.analyze(snap);
      expect(line.lifecycle, FinancialLifecycle.cancelled);
      expect(line.settlementEligible, isFalse);
    });
  });
}
