import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_adapter.dart';
import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import 'package:admin_arawatan/core/admin_booking_status_label.dart';
import 'package:admin_arawatan/core/toury_system_status_codes.dart';

void main() {
  group('AdminBookingStatusLabel', () {
    test('maps granular status codes to Arabic', () {
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.pendingDriver,
        ),
        'بانتظار قبول مندوب',
      );
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.driverAssigned,
        ),
        'تم إسناد مندوب',
      );
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.driverArriving,
        ),
        'المندوب في الطريق',
      );
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.driverArrived,
        ),
        'وصل لنقطة الانطلاق',
      );
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.tripStarted,
        ),
        'الرحلة بدأت',
      );
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.completed,
        ),
        'مكتملة',
      );
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.cancelledByAdmin,
        ),
        'ملغية',
      );
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.expired,
        ),
        'منتهية الصلاحية',
      );
    });

    test('legacy Arabic maps with compatibility', () {
      expect(
        AdminBookingStatusLabel.arabic(halhText: 'بإنتظار قبول المندوب'),
        'بانتظار قبول مندوب',
      );
      expect(
        AdminBookingStatusLabel.arabic(halhText: 'مقبول'),
        'تم إسناد مندوب',
      );
      expect(
        AdminBookingStatusLabel.arabic(halhText: 'مكتمل'),
        'مكتملة',
      );
      expect(
        AdminBookingStatusLabel.arabic(halhText: 'ملغي'),
        'ملغية',
      );
    });

    test('tone buckets are granular', () {
      expect(
        AdminBookingStatusLabel.resolveCode(
          statusCode: TourySystemStatusCodes.driverArriving,
        ),
        TourySystemStatusCodes.driverArriving,
      );
      // Code preference over legacy text.
      expect(
        AdminBookingStatusLabel.arabic(
          statusCode: TourySystemStatusCodes.completed,
          halhText: 'ملغي',
        ),
        'مكتملة',
      );
    });
  });

  group('AdminBookingsExtraFilters', () {
    test('activeCount and signature', () {
      const empty = AdminBookingsExtraFilters.empty;
      expect(empty.hasAny, isFalse);
      expect(empty.activeCount, 0);

      final filled = empty.copyWith(
        customerQuery: 'Ali',
        amountMin: 10,
      );
      expect(filled.hasAny, isTrue);
      expect(filled.activeCount, 2);
      expect(filled.signature.contains('ali'), isTrue);
    });
  });

  group('AdminBookingsSorter', () {
    test('sort key enum covers required fields', () {
      expect(AdminBookingsSortKey.values.length, greaterThanOrEqualTo(4));
      expect(
        AdminBookingsSortKey.values.contains(AdminBookingsSortKey.dateDesc),
        isTrue,
      );
      expect(
        AdminBookingsSortKey.values.contains(AdminBookingsSortKey.amountDesc),
        isTrue,
      );
      expect(
        AdminBookingsSortKey.values.contains(AdminBookingsSortKey.status),
        isTrue,
      );
      expect(
        AdminBookingsSortKey.values.contains(AdminBookingsSortKey.orderId),
        isTrue,
      );
    });
  });
}
