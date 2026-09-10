import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/finance/finance_runtime_gate.dart';

void main() {
  tearDown(() {
    FinanceRuntimeGate.setAuthoritativeBackendData(false);
  });

  test('authoritativeBackendData true allows write attempts', () {
    FinanceRuntimeGate.setAuthoritativeBackendData(true);
    expect(FinanceRuntimeGate.authoritativeBackendData, isTrue);
    expect(FinanceRuntimeGate.canAttemptFinanceWrites, isTrue);
  });

  test('authoritativeBackendData false blocks write attempts', () {
    FinanceRuntimeGate.setAuthoritativeBackendData(false);
    expect(FinanceRuntimeGate.authoritativeBackendData, isFalse);
    expect(FinanceRuntimeGate.canAttemptFinanceWrites, isFalse);
  });

  test('markAuthoritative sticks until explicit clear', () {
    FinanceRuntimeGate.markAuthoritativeBackendData();
    expect(FinanceRuntimeGate.canAttemptFinanceWrites, isTrue);
    FinanceRuntimeGate.markAuthoritativeBackendData();
    expect(FinanceRuntimeGate.canAttemptFinanceWrites, isTrue);
    FinanceRuntimeGate.setAuthoritativeBackendData(false);
    expect(FinanceRuntimeGate.canAttemptFinanceWrites, isFalse);
  });
}
