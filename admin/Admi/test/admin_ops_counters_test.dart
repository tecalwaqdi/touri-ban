import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_ops_counters.dart';

void main() {
  group('AdminOpsCounters', () {
    test('appUsersFromParts uses inclusion-exclusion', () {
      // 100 users, 10 agents, 20 drivers, 2 both → 72 app users
      expect(
        AdminOpsCounters.appUsersFromParts(
          totalUsers: 100,
          agents: 10,
          drivers: 20,
          agentAndDriver: 2,
        ),
        72,
      );
    });

    test('appUsersFromParts never negative', () {
      expect(
        AdminOpsCounters.appUsersFromParts(
          totalUsers: 5,
          agents: 10,
          drivers: 10,
          agentAndDriver: 0,
        ),
        0,
      );
    });

    test('driversUnknown balances total', () {
      expect(
        AdminOpsCounters.driversUnknown(
          totalDrivers: 327,
          active: 244,
          inactive: 2,
        ),
        81,
      );
    });

    test('sumStatusCodeCounts aggregates sequentially', () async {
      final calls = <String>[];
      final total = await AdminOpsCounters.sumStatusCodeCounts(
        codes: const ['a', 'b', 'c'],
        countForCode: (code) async {
          calls.add(code);
          return code == 'a'
              ? 3
              : code == 'b'
                  ? 5
                  : 7;
        },
      );
      expect(total, 15);
      expect(calls, ['a', 'b', 'c']);
    });

    test('cancelled and completed code lists are non-empty and distinct', () {
      expect(AdminOpsCounters.cancelledStatusCodes, isNotEmpty);
      expect(AdminOpsCounters.completedStatusCodes, isNotEmpty);
      expect(
        AdminOpsCounters.cancelledStatusCodes
            .toSet()
            .intersection(AdminOpsCounters.completedStatusCodes.toSet()),
        isEmpty,
      );
    });
    test('sumStatusCodeCounts returns -1 when any code fails', () async {
      final result = await AdminOpsCounters.sumStatusCodeCounts(
        codes: const ['a', 'b'],
        countForCode: (code) async => code == 'a' ? 2 : -1,
      );
      expect(result, -1);
    });
  });
}
