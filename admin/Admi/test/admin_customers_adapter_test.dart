import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/adminuser/admin_customer_active_order.dart';
import 'package:admin_arawatan/admin/adminuser/admin_customers_adapter.dart';

void main() {
  group('AdminCustomerExtraFilters', () {
    test('signature and activeCount', () {
      expect(AdminCustomerExtraFilters.empty.hasAny, isFalse);
      expect(AdminCustomerExtraFilters.empty.activeCount, 0);
      final f = AdminCustomerExtraFilters.empty.copyWith(
        account: AdminCustomerAccountFilter.suspended,
        trip: AdminCustomerTripFilter.hasLiveTrip,
        newTodayOnly: true,
        sort: AdminCustomerSort.nameAsc,
      );
      expect(f.hasAny, isTrue);
      expect(f.activeCount, 4);
      expect(f.signature.contains('suspended'), isTrue);
      expect(f.signature.contains('nameAsc'), isTrue);
    });
  });

  group('AdminCustomer contract maps', () {
    test('city prefers profile aliases not GPS keys alone', () {
      expect(
        AdminCustomerRow.cityFromData({'city_display': 'جدة'}),
        'جدة',
      );
      expect(
        AdminCustomerRow.cityFromData({'mndob_vill_text': 'الرياض'}),
        'الرياض',
      );
      expect(AdminCustomerRow.cityFromData({'gps_city': 'x'}), '');
    });

    test('active_order_id legacy alias', () {
      expect(
        AdminCustomerRow.activeOrderIdFromData({'active_order_id': 'o1'}),
        'o1',
      );
      expect(
        AdminCustomerRow.activeOrderIdFromData({'activeOrderId': 'o2'}),
        'o2',
      );
      expect(AdminCustomerRow.activeOrderIdFromData({}), '');
    });

    test('account status orthogonal to trip lock', () {
      expect(
        AdminCustomerRow.accountStatusFromData({'actev_user': true}),
        AdminCustomerAccountStatus.active,
      );
      expect(
        AdminCustomerRow.accountStatusFromData({'actev_user': false}),
        AdminCustomerAccountStatus.suspended,
      );
      expect(
        AdminCustomerRow.accountStatusFromData({}),
        AdminCustomerAccountStatus.unknown,
      );
      expect(
        AdminCustomerRow.accountStatusFromData({
          'actev_user': false,
          'active_order_id': 'still_locked',
        }),
        AdminCustomerAccountStatus.suspended,
      );
    });
  });

  group('AdminCustomer display helpers', () {
    test('formatPhoneDisplay formats Saudi numbers', () {
      expect(
        AdminCustomerRow.formatPhoneDisplay('966555075548'),
        '+966 5 550 75548',
      );
    });

    test('initialsOf extracts name initials', () {
      expect(AdminCustomerRow.initialsOf('محمد أحمد'), 'مأ');
      expect(AdminCustomerRow.initialsOf('Ali'), 'AL');
    });
  });

  group('AdminCustomerActiveOrderTruth', () {
    test('empty lock → none', () {
      final t = AdminCustomerActiveOrderTruth.fromOrder(
        orderId: '',
        order: null,
      );
      expect(t.hasLiveTrip, isFalse);
      expect(t.isStaleLock, isFalse);
      expect(t.tripHint, AdminCustomerTripHint.none);
    });

    test('missing order → stale, not live trip', () {
      final t = AdminCustomerActiveOrderTruth.fromOrder(
        orderId: 'order_x',
        order: null,
      );
      expect(t.hasLiveTrip, isFalse);
      expect(t.isStaleLock, isTrue);
      expect(t.orderMissing, isTrue);
      expect(t.tripHint, AdminCustomerTripHint.staleLock);
      expect(t.tripHint, isNot(AdminCustomerTripHint.confirmedActive));
    });
  });
}
