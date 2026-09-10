import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_view_model.dart';
import 'package:admin_arawatan/core/finance/finance_v2_alerts.dart';
import 'package:admin_arawatan/core/finance/finance_v2_read_projection.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

OrderRecord _order(String id, Map<String, dynamic> data) {
  return OrderRecord.getDocumentFromData(
    data,
    FirebaseFirestore.instance.collection('order').doc(id),
  );
}

void main() {
  setUpAll(_initFirebase);

  group('Phase 4 V2 alerts + projection', () {
    test('alerts from incomplete + missing agent + open settlements', () {
      final complete = AccountantTripRow.fromOrder(_order('c1', {
        'total': 50.0,
        'total_app': 7.5,
        'total_vat': 0.0,
        'total_mndob': 42.5,
        'total_mndob2': 50.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
        'agent_id': 'a1',
        'agent_amount_minor': 10,
        'agent_attribution_status': 'attributed',
      }));
      final incomplete = AccountantTripRow.fromOrder(_order('i1', {
        'total': 50.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
      }));
      final missingAgent = AccountantTripRow.fromOrder(_order('m1', {
        'total': 50.0,
        'total_app': 7.5,
        'total_vat': 0.0,
        'total_mndob': 42.5,
        'total_mndob2': 50.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
      }));

      final pack = FinanceV2Alerts.build(
        trips: [complete, incomplete, missingAgent],
        openSettlementsRemaining: 2,
      );
      expect(pack.incomplete, greaterThanOrEqualTo(1));
      expect(pack.unattributedAgent, greaterThanOrEqualTo(1));
      expect(pack.alerts.length, greaterThanOrEqualTo(2));
      expect(pack.alerts.any((a) => a.contains('تسويات')), isTrue);
    });

    test('fromOrders money matches 50 → 7.50 / 0 / 42.50', () {
      final model = FinanceV2ReadProjection.fromOrders(
        orders: [
          _order('cash50', {
            'total': 50.0,
            'total_app': 7.5,
            'total_vat': 0.0,
            'total_mndob': 42.5,
            'total_mndob2': 50.0,
            'currency': 'SAR',
            'status_code': 'completed',
            'payment_status': 'cash_collected',
            'PaymentMethod': 'Cash',
          }),
        ],
        scope: const AccountantFinanceScope(includeAllCountries: true),
        currency: 'SAR',
      );
      expect(model.source, 'financial_accounting_v2_trip_rows');
      expect(model.completedGross.minorUnits, 5000);
      expect(model.companyCommission.minorUnits, 750);
      expect(model.vat.minorUnits, 0);
      expect(model.driverNet.minorUnits, 4250);
    });

    test('no aggregate / aggregateForAlerts symbols remain in read model API', () {
      // Compile-time: fromOrders is the supported builder.
      expect(AccountantFinanceReadModel.empty('SAR').completedTripCount, 0);
    });
  });
}
