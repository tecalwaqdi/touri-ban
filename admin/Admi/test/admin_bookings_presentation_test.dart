import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admin_a_l_lhg_z/admin_bookings_presentation.dart';

void main() {
  group('AdminBookingsPresentation', () {
    test('tableDate pads day/month', () {
      expect(
        AdminBookingsPresentation.tableDate(DateTime(2026, 8, 31, 10, 18)),
        '31/08/2026',
      );
      expect(
        AdminBookingsPresentation.tableDate(DateTime(2026, 1, 5, 9, 5)),
        '05/01/2026',
      );
      expect(AdminBookingsPresentation.tableDate(null), '—');
    });

    test('tableTime pads hour/minute', () {
      expect(
        AdminBookingsPresentation.tableTime(DateTime(2026, 8, 31, 10, 18)),
        '10:18',
      );
      expect(
        AdminBookingsPresentation.tableTime(DateTime(2026, 8, 31, 9, 5)),
        '09:05',
      );
      expect(AdminBookingsPresentation.tableTime(null), '');
    });
  });
}
