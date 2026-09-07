import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_auth_session_owner.dart';
import 'package:admin_arawatan/backend/admin_perf_trace.dart';
import 'package:admin_arawatan/components/admin_shell_scope.dart';

void main() {
  setUp(() {
    AdminPerfTrace.enabled = true;
    AdminPerfTrace.resetCounters();
    AdminAuthSessionOwner.stop();
  });

  tearDown(() {
    AdminAuthSessionOwner.stop();
    AdminPerfTrace.resetCounters();
  });

  group('PERF-P3F AdminShellScope', () {
    testWidgets('isInside is true under AdminShellScope', (tester) async {
      var inside = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShellScope(
            child: Builder(
              builder: (context) {
                inside = AdminShellScope.isInside(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(inside, isTrue);
    });

    testWidgets('isInside is false outside shell', (tester) async {
      var inside = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              inside = AdminShellScope.isInside(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(inside, isFalse);
    });
  });

  group('PERF-P3F session owner counters', () {
    test('stop is safe when never started', () {
      expect(AdminAuthSessionOwner.isActive, isFalse);
      AdminAuthSessionOwner.stop();
      expect(AdminAuthSessionOwner.isActive, isFalse);
    });

    test('shell mount/dispose counters track balance', () {
      AdminPerfTrace.shellMount();
      AdminPerfTrace.shellMount();
      expect(AdminPerfTrace.shellBalance, 2);
      AdminPerfTrace.shellDispose();
      expect(AdminPerfTrace.shellBalance, 1);
      AdminPerfTrace.shellDispose();
      expect(AdminPerfTrace.shellBalance, 0);
    });
  });
}
