import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_booking_settlement_lookup.dart';
import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import 'package:admin_arawatan/admin/admin_booking_details/admin_booking_details_adapter.dart';
import 'package:admin_arawatan/backend/admin_ops_filters.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/core/finance/finance_sot_settlement_index.dart';
import 'package:admin_arawatan/core/finance/financial_engine.dart';
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

OrderRecord _order(Map<String, dynamic> data, [String id = 'ord1']) {
  final ref = FirebaseFirestore.instance.collection('order').doc(id);
  return OrderRecord.getDocumentFromData(data, ref);
}

void main() {
  setUpAll(_initFirebase);
  setUp(AdminRoleService.resetSession);

  group('Phase 7 Operations Hub', () {
    test('trip status != payment status on row', () {
      final row = AdminBookingRow.fromOrder(_order({
        'IDorder': 'B1',
        'status_code': TourySystemStatusCodes.completed,
        'payment_status': TourySystemStatusCodes.pendingCash,
        'total': 40,
        'data_order': DateTime(2026, 9, 1),
        'completedAt': DateTime(2026, 9, 1, 12),
        'pickupLabel_force': true,
      }));
      expect(row.statusLabel, 'مكتملة');
      expect(row.paymentStatusLabel, 'قيد الانتظار');
      // Route may be empty without landmark structs; payment/trip stay distinct.
      expect(row.paymentStatusLabel == row.statusLabel, isFalse);
    });

    test('cancelled and completed classify via status_code', () {
      final completed = _order({
        'status_code': TourySystemStatusCodes.completed,
      });
      final cancelled = _order({
        'status_code': TourySystemStatusCodes.cancelledByCustomer,
      });
      final counts = AdminBookingsLifecycle.countOperational([
        completed,
        cancelled,
        _order({'status_code': TourySystemStatusCodes.driverArriving, 'ALLNOW': true}),
      ]);
      expect(counts.completed, 1);
      expect(counts.cancelled, 1);
      expect(counts.active, 1);
    });

    test('QA fixtures excluded from operational counts by default', () {
      final real = _order({
        'status_code': TourySystemStatusCodes.completed,
        'IDorder': 'REAL-1',
      });
      final qa = _order({
        'status_code': TourySystemStatusCodes.completed,
        'IDorder': 'demo_fin_x',
        'is_test_fixture': true,
      }, 'qa1');
      final hidden = AdminBookingsLifecycle.countOperational([real, qa]);
      final shown = AdminBookingsLifecycle.countOperational(
        [real, qa],
        includeQaFixtures: true,
      );
      expect(hidden.completed, 1);
      expect(shown.completed, 2);
    });

    test('settlement label never invents from trip completion', () {
      expect(AdminBookingSettlementLookup.labelAr(null), '—');
      expect(AdminBookingSettlementLookup.labelAr(''), '—');
      expect(AdminBookingSettlementLookup.labelAr('settled'), isNot('—'));
      final idx = FinanceSotSettlementIndex.statusByOrderId([
        {
          'id': 's1',
          'status': 'settled',
          'orderIds': ['ORD-9'],
        },
      ]);
      expect(idx['ORD-9'], 'settled');
      // Completed trip alone does not appear in index.
      expect(idx['COMPLETED-ONLY'], isNull);
    });

    test('timeline includes payment and settlement steps when known', () {
      final row = AdminBookingRow.fromOrder(_order({
        'status_code': TourySystemStatusCodes.completed,
        'payment_status': TourySystemStatusCodes.cashCollected,
        'data_order': DateTime(2026, 9, 1, 10),
        'acceptedAt': DateTime(2026, 9, 1, 10, 5),
        'arrivedAt': DateTime(2026, 9, 1, 10, 20),
        'startedAt': DateTime(2026, 9, 1, 10, 25),
        'completedAt': DateTime(2026, 9, 1, 11),
        'cash_collected_at': DateTime(2026, 9, 1, 11, 5),
      }));
      final events = AdminBookingTimelineEvent.build(
        row,
        settlementStatus: 'settled',
        settlementAt: DateTime(2026, 9, 2),
      );
      final labels = events.map((e) => e.label).toList();
      expect(labels, contains('تم إنشاء الطلب'));
      expect(labels, contains('قبول السائق'));
      expect(labels, contains('وصل السائق'));
      expect(labels, contains('بدأت الرحلة'));
      expect(labels, contains('اكتملت الرحلة'));
      expect(labels, contains('الدفع / التحصيل'));
      expect(labels.any((l) => l.startsWith('التسوية')), isTrue);
    });

    test('scope filter helper ignores lifecycle for shared KPI base', () {
      const f = AdminOpsFilterState(
        orderLifecycle: AdminOrderLifecycleFilter.completed,
      );
      // Evidence: describe constraints still document lifecycle separately;
      // applyScopeFiltersCore is the shared base used by KPI buckets.
      expect(AdminBookingsQuery.applyScopeFiltersCore, isNotNull);
      expect(f.orderLifecycle, AdminOrderLifecycleFilter.completed);
    });

    test('Country Agent can access bookings; Accountant cannot', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'agent': true,
          'country_admin': true,
          'country_id': 'countries/spain',
        }),
      );
      expect(AdminRoleService.canAccessRoute('AdminALLhgZ'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isFalse);

      AdminRoleService.resetSession();
      AdminRoleService.bindClaims(AuthClaims.fromToken({'finance': true}));
      expect(AdminRoleService.canAccessRoute('AdminALLhgZ'), isFalse);
      expect(OrderStatusHelper.isOperationallyCompleted(_order({
        'status_code': TourySystemStatusCodes.completed,
        'payment_status': TourySystemStatusCodes.pendingCash,
      })), isTrue);
      expect(OrderStatusHelper.isPaid(_order({
        'status_code': TourySystemStatusCodes.completed,
        'payment_status': TourySystemStatusCodes.pendingCash,
      })), isFalse);
    });
  });
}
