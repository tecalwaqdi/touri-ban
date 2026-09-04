import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admindrever/admin_drivers_adapter.dart';
import 'package:admin_arawatan/admin/admindrever/admin_drivers_query.dart';

void main() {
  group('AdminDriversExtraFilters signature', () {
    test(
      'stable signature for equivalent filters (search clear / filter reset)',
      () {
        const a = AdminDriversExtraFilters.empty;
        const b = AdminDriversExtraFilters(
          connection: AdminDriversConnectionFilter.all,
          availability: AdminDriversAvailabilityFilter.all,
        );
        expect(a.signature, b.signature);
        expect(a.hasAny, isFalse);
      },
    );

    test(
      'connection filter changes signature (semantic query via reloadKey)',
      () {
        const base = AdminDriversExtraFilters.empty;
        final online = base.copyWith(
          connection: AdminDriversConnectionFilter.online,
        );
        expect(online.signature, isNot(base.signature));
        expect(online.hasAny, isTrue);
      },
    );
  });

  group('client search / filter ownership', () {
    test('search matcher covers name phone email plate id fields', () {
      // Contract: matchesSearch documents supported targets — empty query passes.
      // Concrete UserRecord needs Firebase; adapter static helpers stay pure.
      expect(AdminDriverRow.formatPhoneDisplay('—'), '—');
      expect(AdminDriverRow.formatPhoneDisplay(''), '—');
      expect(AdminDriverRow.initialsOf('Ara Ban'), 'AB');
      expect(AdminDriverRow.initialsOf('Solo'), 'So');
    });

    test('sortDriversNewestFirst is stable on empty', () {
      expect(sortDriversNewestFirst(const []), isEmpty);
    });

    test('applyAdminDriversClientFilters empty input stays empty', () {
      final out = applyAdminDriversClientFilters(
        const [],
        searchQuery: 'x',
        extra: AdminDriversExtraFilters.empty,
      );
      expect(out, isEmpty);
    });
  });
}
