import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/finance/accountant_finance_read_model.dart';
import 'package:admin_arawatan/core/finance/finance_order_query.dart';
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

Map<String, dynamic> _complete({
  String status = 'completed',
  String country = 'countries/sa',
  num total = 100,
  num app = 20,
  num vat = 15,
  num mndob = 65,
  num mndob2 = 100,
  bool fixture = false,
  String? idHint,
}) {
  return {
    if (status.isNotEmpty) 'status_code': status,
    'payment_status': 'cash_collected',
    'cash_collection_status': 'collected',
    'PaymentMethod': 'Cash',
    'total': total,
    'total_app': app,
    'total_vat': vat,
    'total_mndob': mndob,
    'total_mndob2': mndob2,
    'currency': 'SAR',
    'Rev_dolh': FirebaseFirestore.instance.doc(country),
    if (fixture) 'is_test_fixture': true,
    if (idHint != null) 'display_id': idHint,
  };
}

void main() {
  setUpAll(_initFirebase);

  group('PERF-P2A finance query constants', () {
    test('modern completed codes match frozen semantics', () {
      expect(
        FinanceOrderQuery.modernCompletedCodes,
        containsAll([
          TourySystemStatusCodes.completed,
          TourySystemStatusCodes.legacyTripCompleted,
        ]),
      );
      expect(FinanceOrderQuery.tablePageSize, 40);
      expect(FinanceOrderQuery.scanCap, 100000);
    });

    test('legacy halh candidates are narrow equality set', () {
      expect(FinanceOrderQuery.legacyHalhEquals, contains('مكتمل'));
      expect(FinanceOrderQuery.legacyHalhEquals, contains('completed'));
    });
  });

  group('PERF-P2A summary != visible page', () {
    test('100 completed / page 25 → summary completedTripCount 100', () {
      final orders = List.generate(
        100,
        (i) => _order(_complete(idHint: 'p2a_$i'), 'p2a_$i'),
      );
      final page = orders.take(25).toList();
      expect(page.length, 25);

      const scope = AccountantFinanceScope(includeAllCountries: true);
      final model = AccountantFinanceReadModel.aggregate(
        orders: orders,
        scope: scope,
        currency: 'SAR',
      );
      final pageModel = AccountantFinanceReadModel.aggregate(
        orders: page,
        scope: scope,
        currency: 'SAR',
      );

      expect(model.completedTripCount, 100);
      expect(pageModel.completedTripCount, 25);
      expect(model.completedTripCount, isNot(equals(pageModel.completedTripCount)));
      expect(
        model.completedGross.minorUnits,
        greaterThan(pageModel.completedGross.minorUnits),
      );
    });

    test('QA fixtures excluded from summary population', () {
      final live = _order(_complete(), 'live_ok');
      final qa = _order(_complete(fixture: true, total: 999), 'TOURi_GOLDEN_1');
      const scope = AccountantFinanceScope(includeAllCountries: true);
      final model = AccountantFinanceReadModel.aggregate(
        orders: [live, qa],
        scope: scope,
        currency: 'SAR',
      );
      expect(model.completedTripCount, 1);
      expect(model.qaFixturesExcluded, greaterThanOrEqualTo(1));
    });

    test('country scope rejects foreign totals', () {
      final own = _order(
        _complete(country: 'countries/spain'),
        'own',
      );
      final foreign = _order(
        _complete(country: 'countries/sa', total: 500),
        'foreign',
      );
      const scope = AccountantFinanceScope(
        includeAllCountries: false,
        countryPaths: ['countries/spain'],
      );
      final model = AccountantFinanceReadModel.aggregate(
        orders: [own, foreign],
        scope: scope,
        currency: 'SAR',
      );
      expect(model.completedTripCount, 1);
      expect(model.completedGross.minorUnits, 10000);
    });

    test('modern + legacy completion still uses frozen helper', () {
      final modern = _order(_complete(), 'modern');
      final legacy = _order({
        'halh': 'مكتمل',
        'payment_status': 'cash_collected',
        'PaymentMethod': 'Cash',
        'total': 50,
        'total_app': 7.5,
        'total_vat': 0,
        'total_mndob': 42.5,
        'total_mndob2': 50,
        'currency': 'SAR',
        'Rev_dolh': FirebaseFirestore.instance.doc('countries/sa'),
      }, 'legacy');
      expect(FinancialTripSemantics.isOperationallyCompleted(modern), isTrue);
      expect(FinancialTripSemantics.isOperationallyCompleted(legacy), isTrue);
    });

    test('stable page IDs unique across synthetic pages', () {
      final all = List.generate(90, (i) => 'id_$i');
      const pageSize = 30;
      final p1 = all.sublist(0, pageSize);
      final p2 = all.sublist(pageSize, pageSize * 2);
      final p3 = all.sublist(pageSize * 2, pageSize * 3);
      final combined = [...p1, ...p2, ...p3];
      expect(combined.toSet().length, combined.length);
      expect(combined, all);
    });
  });
}
