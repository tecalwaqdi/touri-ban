import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import 'package:admin_arawatan/admin/admin_booking_details/admin_booking_details_adapter.dart';
import 'package:admin_arawatan/backend/schema/enums/enums.dart';
import 'package:admin_arawatan/backend/schema/order_record.dart';
import 'package:admin_arawatan/core/admin_booking_status_label.dart';
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

OrderRecord _order(Map<String, dynamic> data, [String id = 'test-order']) {
  final ref = FirebaseFirestore.instance.collection('order').doc(id);
  return OrderRecord.getDocumentFromData(data, ref);
}

void main() {
  setUpAll(() async {
    await _initFirebase();
  });

  group('AdminBookingDetailsView.formatPhone', () {
    test('formats Saudi 966 numbers', () {
      expect(
        AdminBookingDetailsView.formatPhone('966555075548'),
        '+966 55 507 5548',
      );
    });

    test('empty returns em dash', () {
      expect(AdminBookingDetailsView.formatPhone(''), '—');
    });
  });

  group('AdminBookingDetailsView.fromOrder', () {
    test('uses canonical financial fields from order', () {
      final view = AdminBookingDetailsView.fromOrder(_order({
        'IDorder': 'CASH-ABC123',
        'status_code': TourySystemStatusCodes.completed,
        'total': 50.0,
        'total_app': 7.5,
        'total_mndob': 42.5,
        'total_mndob2': 50.0,
        'total_vat': 0,
        'naim_user_text': 'شاكر',
        'phone_numper': 555075548,
        'vill_text': 'مكة المكرمة',
        'payment_method': 'Cash',
        'data_order': DateTime(2026, 3, 1, 10),
        'completedAt': DateTime(2026, 3, 1, 11),
      }));

      expect(view.row.orderId, 'CASH-ABC123');
      expect(view.row.amount, 50.0);
      expect(view.row.commission, 7.5);
      expect(view.row.driverNet, 42.5);
      expect(view.showVat, isFalse);
      expect(view.row.statusLabel, 'مكتملة');
    });

    test('terminal completed overrides legacy active flags', () {
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.completed,
        'halh_text': 'بإنتظار قبول المندوب',
        'ALLNOW': true,
        'ActiveOrder': true,
        'total': 100,
      }));

      expect(view.row.isTerminal, isTrue);
      expect(view.row.statusLabel, 'مكتملة');
      expect(
        AdminBookingStatusLabel.toneOf(view.row.order),
        AdminBookingStatusTone.completed,
      );
    });

    test('cancelled booking resolves actor and reason', () {
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.cancelledByCustomer,
        'cancelled_by_code': TourySystemStatusCodes.cancelledByCustomer,
        'cancel_reason': 'تغيير الخطط',
        'cancelledAt': DateTime(2026, 3, 2, 9),
        'total': 30,
      }));

      expect(view.cancellationByLabel, 'العميل');
      expect(view.cancellationReason, 'تغيير الخطط');
      expect(view.row.statusTone, AdminBookingStatusTone.canceled);
    });

    test('pickup and destination labels stay separate from city', () {
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.pendingDriver,
        'vill_text': 'مكة المكرمة',
        'listAmakn': [
          {
            'naim': 'فندق الحرم',
            'textivill': 'مكة',
          },
          {
            'naim': 'مطار جدة',
            'textivill': 'جدة',
          },
        ],
        'LOKESHN': const GeoPoint(21.4, 39.8),
        'total': 0,
      }));

      expect(view.row.city, 'مكة المكرمة');
      expect(view.row.pickupLabel, 'فندق الحرم');
      expect(view.row.destinationLabel, 'مطار جدة');
      expect(view.pickupCity, 'مكة');
      expect(view.destinationCity, 'جدة');
      expect(view.pickupCoords, contains('21.4'));
      expect(view.destinationCoords, isEmpty);
    });

    test('missing driver shows hasDriver false', () {
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.pendingDriver,
        'total': 0,
      }));
      expect(view.hasDriver, isFalse);
    });

    test('assigned driver detected from ref or name', () {
      final ref = FirebaseFirestore.instance.collection('users').doc('d1');
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.driverAssigned,
        'mndob_user': ref,
        'naim_mndob_text': 'محمد',
        'total': 0,
      }));
      expect(view.hasDriver, isTrue);
      expect(view.row.driverName, 'محمد');
    });

    test('timeline only includes present timestamps', () {
      final created = DateTime(2026, 1, 1, 8);
      final accepted = DateTime(2026, 1, 1, 8, 5);
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.driverAssigned,
        'data_order': created,
        'acceptedAt': accepted,
        'total': 0,
      }));

      expect(view.timeline.length, 2);
      expect(view.timeline.first.label, 'تم إنشاء الطلب');
      expect(view.timeline.last.label, 'قبول المندوب');
    });

    test('payment method cash maps to Arabic label', () {
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.pendingDriver,
        'PaymentMethod': PaymentMethod.Cash,
        'total': 10,
      }));
      expect(view.row.paymentLabel, 'نقداً');
    });

    test('technical fields exclude empty legacy values', () {
      final view = AdminBookingDetailsView.fromOrder(_order({
        'status_code': TourySystemStatusCodes.pendingDriver,
        'halh_text': 'انتظار',
        'total': 0,
      }));
      final tech = view.technicalFields();
      expect(tech['status_code'], TourySystemStatusCodes.pendingDriver);
      expect(tech.containsKey('halh_text'), isTrue);
      expect(tech['doc_id'], 'test-order');
    });
  });

  group('AdminBookingRow financial invariant', () {
    test('driver net prefers total_mndob (not gross total_mndob2)', () {
      final row = AdminBookingRow.fromOrder(_order({
        'total': 50,
        'total_app': 7.5,
        'total_mndob': 42.5,
        'total_mndob2': 50,
      }));
      expect(row.driverNet, 42.5);
      expect(row.commission, 7.5);
      expect(row.amount, 50.0);
    });

    test('preserves fractional platform fee without int rounding', () {
      final row = AdminBookingRow.fromOrder(_order({
        'total': 50.0,
        'total_app': 7.5,
        'total_vat': 0,
        'total_mndob': 42.5,
      }));
      expect(row.commission, 7.5);
      expect(row.commission, isNot(8));
    });
  });
}
