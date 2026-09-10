import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_view_model.dart';
import 'package:admin_arawatan/core/finance/finance_sot_settlement_index.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/financial_trip_semantics.dart';

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

Map<String, dynamic> _cash50({String? settlementFlagOnOrder}) => {
      'total': 50.0,
      'total_app': 7.5,
      'total_vat': 0.0,
      'total_mndob': 42.5,
      'total_mndob2': 50.0,
      'currency': 'SAR',
      'status_code': 'completed',
      'payment_status': 'cash_collected',
      'PaymentMethod': 'Cash',
      if (settlementFlagOnOrder != null)
        'settlement_status': settlementFlagOnOrder,
    };

void main() {
  setUpAll(_initFirebase);

  group('Phase 3 V2 trip rows', () {
    test('cash 50 → fee 7.50 / VAT 0 / driver 42.50', () {
      final row = AccountantTripRow.fromOrder(_order('t50', _cash50()));
      expect(row.source, 'financial_accounting_v2');
      expect(row.grossDisplay, contains('50.00'));
      expect(row.companyCommissionDisplay, contains('7.50'));
      expect(row.vatDisplay, contains('0.00'));
      expect(row.driverNetDisplay, contains('42.50'));
      expect(row.paymentChannelLabel, 'نقدي');
    });

    test('VAT 800 → 120 / 120 / 560', () {
      final row = AccountantTripRow.fromOrder(_order('t800', {
        'total': 800.0,
        'total_app': 120.0,
        'total_vat': 120.0,
        'total_mndob': 560.0,
        'total_mndob2': 800.0,
        'currency': 'SAR',
        'status_code': 'completed',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
      }));
      expect(row.companyCommissionDisplay, contains('120.00'));
      expect(row.vatDisplay, contains('120.00'));
      expect(row.driverNetDisplay, contains('560.00'));
    });

    test('settlement status ignores order flags; uses ledger only', () {
      final withOrderFlag = AccountantTripRow.fromOrder(
        _order('s1', _cash50(settlementFlagOnOrder: 'settled')),
      );
      // No ledger → not settled from order flag.
      expect(withOrderFlag.settlementStatusLabel, isNot('مسددة'));

      final fromLedger = AccountantTripRow.fromOrder(
        _order('s2', _cash50(settlementFlagOnOrder: 'settled')),
        settlementStatusFromLedger: 'settled',
      );
      expect(fromLedger.settlementStatusLabel, 'مسددة');
    });

    test('FinanceSotSettlementIndex maps eligibleOrderIds', () {
      final idx = FinanceSotSettlementIndex.statusByOrderId([
        {
          'id': 'stl1',
          'status': 'partially_paid',
          'eligibleOrderIds': ['ord_a', 'ord_b'],
        },
        {
          'id': 'demo',
          'status': 'settled',
          'is_demo': true,
          'eligibleOrderIds': ['ord_a'],
        },
        {
          'id': 'stl2',
          'status': 'settled',
          'eligibleOrderIds': ['ord_a'],
        },
      ]);
      expect(idx['ord_a'], 'settled');
      expect(idx['ord_b'], 'partially_paid');
    });

    test('agent attribution still historical from trip snapshot', () {
      final row = AccountantTripRow.fromOrder(_order('ag1', {
        ..._cash50(),
        'agent_id': 'agent_x',
        'agent_attribution_status': 'confident',
        'agent_amount_minor': 150,
        'agent_rate': 10,
        'agent_rate_type': 'percent',
        'agent_currency': 'SAR',
        'agent_snapshot_at': '2026-01-01T00:00:00Z',
      }));
      expect(row.agentId, 'agent_x');
      expect(
        row.agentAttribution,
        anyOf(
          FinancialAgentAttribution.confident,
          FinancialAgentAttribution.missing,
        ),
      );
    });

    test('engine line identity matches row money minors', () {
      const snap = FinancialOrderSnapshot(
        orderId: 'parity',
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
      expect(line.platformFee?.minorUnits, 750);
      expect(line.recordedVat?.minorUnits, 0);
      expect(line.driverNet?.minorUnits, 4250);
    });
  });
}
