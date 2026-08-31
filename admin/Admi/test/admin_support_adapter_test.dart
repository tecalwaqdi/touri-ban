import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_suport/admin_support_adapter.dart';
import 'package:admin_arawatan/backend/schema/enums/enums.dart';

void main() {
  group('AdminSupportRow dual schema', () {
    test('customer legacy fields', () {
      final data = {
        'id': 42,
        'naim': 'أحمد',
        'osf': 'وصف المشكلة',
        'tsnef': 'شكوى',
        'halh': 'Open',
        'phone': 512345678,
        'data': DateTime(2026, 1, 2),
      };
      expect(AdminSupportRow.isDriverSchemaData(data), isFalse);
      expect(AdminSupportRow.subjectOf(data), 'شكوى');
      expect(AdminSupportRow.messageOf(data), 'وصف المشكلة');
      expect(AdminSupportRow.ownerNameOf(data), 'أحمد');
      expect(
        AdminSupportRow.displayStatusOf(halh: HalhSupport.Open),
        AdminSupportDisplayStatus.open,
      );
    });

    test('driver schema fields', () {
      final data = {
        'user': 'user/x',
        'sub': 'Trip issue: late pickup',
        'msg': 'Driver waited 20 minutes',
        'status': 'open',
        'phon_n': 555,
        'email': 'driver@example.com',
        'category': 'trip',
        'created_at': DateTime(2026, 2, 1),
      };
      expect(AdminSupportRow.isDriverSchemaData(data), isTrue);
      expect(AdminSupportRow.subjectOf(data), contains('Trip issue'));
      expect(AdminSupportRow.messageOf(data), contains('waited'));
      expect(
        AdminSupportRow.displayStatusOf(status: 'open'),
        AdminSupportDisplayStatus.open,
      );
      expect(
        AdminSupportRow.displayStatusOf(status: 'resolved'),
        AdminSupportDisplayStatus.resolved,
      );
    });

    test('terminal status not treated as open', () {
      expect(
        AdminSupportRow.displayStatusOf(halh: HalhSupport.Resolved),
        AdminSupportDisplayStatus.resolved,
      );
      expect(
        AdminSupportRow.displayStatusOf(status: 'closed'),
        AdminSupportDisplayStatus.closed,
      );
    });

    test('admin workflow maps to display buckets', () {
      expect(
        AdminSupportRow.displayStatusOf(
          halh: HalhSupport.Open,
          adminWorkflow: 'in_progress',
        ),
        AdminSupportDisplayStatus.inProgress,
      );
      expect(
        AdminSupportRow.displayStatusOf(
          halh: HalhSupport.Open,
          adminWorkflow: 'waiting_user',
        ),
        AdminSupportDisplayStatus.waitingUser,
      );
    });

    test('order ref aliases', () {
      expect(
        AdminSupportRow.orderRefOf({'order_ref': 'order/abc'}),
        isNull,
      );
    });
  });

  group('AdminSupportExtraFilters', () {
    test('signature and hasAny', () {
      expect(AdminSupportExtraFilters.empty.hasAny, isFalse);
      final f = AdminSupportExtraFilters.empty.copyWith(
        status: AdminSupportTicketStatusFilter.open,
        owner: AdminSupportOwnerFilter.driver,
      );
      expect(f.hasAny, isTrue);
      expect(f.signature.contains('open'), isTrue);
    });
  });

  group('adminSupportStatusPatch', () {
    test('dual-writes halh and status', () {
      final patch = adminSupportStatusPatch(
        target: AdminSupportDisplayStatus.resolved,
        isDriverSchema: true,
      );
      expect(patch['halh'], 'Resolved');
      expect(patch['status'], 'resolved');
      expect(patch.containsKey('updated_at'), isTrue);
    });
  });
}
