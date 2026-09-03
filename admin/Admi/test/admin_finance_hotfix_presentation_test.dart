import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/core/finance/admin_finance_ui_labels.dart';
import 'package:admin_arawatan/core/finance/admin_money_presentation.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';
import 'package:admin_arawatan/core/finance/settlement_exposure.dart';
import 'package:admin_arawatan/core/finance/settlement_state_labels.dart';
import 'package:admin_arawatan/core/toury_system_status_codes.dart';
import 'package:admin_arawatan/components/admin_format.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

OrderRecord _order(Map<String, dynamic> data, String id) {
  final ref = FirebaseFirestore.instance.collection('order').doc(id);
  return OrderRecord.getDocumentFromData(data, ref);
}

void main() {
  setUpAll(() async {
    await _initFirebase();
  });

  group('Bookings operational completed KPI', () {
    test('6 completed = 4 QA + 2 real → ops KPI 2', () {
      final orders = <OrderRecord>[
        _order({'status_code': TourySystemStatusCodes.completed}, 'real_a'),
        _order({'status_code': TourySystemStatusCodes.completed}, 'real_b'),
        _order(
          {'status_code': TourySystemStatusCodes.completed},
          'fin7_ctrl_1',
        ),
        _order(
          {'status_code': TourySystemStatusCodes.completed},
          'fin9_ctrl_1',
        ),
        _order(
          {'status_code': TourySystemStatusCodes.completed},
          'fin_rt_cash_1',
        ),
        _order(
          {'status_code': TourySystemStatusCodes.completed},
          'fin_rt_cash_ui_1',
        ),
      ];

      final codeCompleted = orders
          .where(
            (o) => AdminBookingsLifecycle.isCompletedCode(
              (o.snapshotData['status_code'] ?? '').toString(),
            ),
          )
          .length;
      expect(codeCompleted, 6);

      final qa = orders.where(AdminQaFixture.isFixtureOrder).length;
      expect(qa, 4);

      final ops = AdminBookingsLifecycle.countOperational(orders);
      expect(ops.completed, 2);

      final drillDown = orders.where((o) => !AdminQaFixture.isFixtureOrder(o));
      expect(
        AdminBookingsLifecycle.countOperational(drillDown).completed,
        ops.completed,
      );
    });
  });

  group('Settlement presentation', () {
    test('settled → مسددة; DRIVER_PAYS_COMPANY Arabic', () {
      expect(SettlementStateLabels.statusAr('settled'), 'مسددة');
      expect(AdminFinanceUiLabels.settlementStatusAr('settled'), 'مسددة');
      expect(
        AdminFinanceUiLabels.settlementDirectionAr('DRIVER_PAYS_COMPANY'),
        'مستحق للشركة على المندوب',
      );
      expect(
        AdminFinanceUiLabels.settlementDirectionAr('COMPANY_PAYS_DRIVER'),
        'مستحق للمندوب على الشركة',
      );
      expect(SettlementStateLabels.statusAr('draft'), 'مسودة');
      expect(SettlementStateLabels.statusAr('voided'), 'ملغاة');
    });
  });

  group('SAR money presentation', () {
    test('shared formatters use symbol + 2 decimals', () {
      final m = MoneyAmount(currency: 'SAR', minorUnits: 500000);
      expect(m.displayLabel, contains('5,000.00'));
      expect(m.displayLabel, contains('ر.س'));
      expect(m.displayLabel.contains('SAR'), isFalse);

      expect(AdminFormat.money(m), contains('ر.س'));
      expect(AdminFormat.money(m), contains('5,000.00'));

      final bucket = SettlementExposureBucket(currency: 'SAR');
      expect(bucket.money(750), contains('7.50'));
      expect(bucket.money(750), contains('ر.س'));

      expect(
        AdminOrderMoneyDisplay.formatMajor(7.5, symbol: 'ر.س'),
        contains('7.50'),
      );
    });

    test('non-SAR keeps its own symbol', () {
      final m = MoneyAmount(currency: 'EUR', minorUnits: 1250);
      expect(m.displayLabel, contains('12.50'));
      expect(m.displayLabel.contains('SAR'), isFalse);
    });
  });
}
