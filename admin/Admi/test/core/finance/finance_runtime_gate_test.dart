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
}
