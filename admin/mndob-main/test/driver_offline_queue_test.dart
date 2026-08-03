import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_offline_queue.dart';

void main() {
  group('DriverOfflineAction serde', () {
    test('round-trips json', () {
      final op = DriverOfflineAction(
        operationId: 'op-1',
        type: DriverOfflineOpType.acceptOrder,
        status: DriverOfflineOpStatus.queued,
        retryCount: 0,
        createdAt: DateTime.utc(2026, 7, 28),
        orderPath: 'order/abc',
        payload: const {'k': 'v'},
      );
      final again = DriverOfflineAction.fromJson(op.toJson());
      expect(again.operationId, 'op-1');
      expect(again.type, DriverOfflineOpType.acceptOrder);
      expect(again.status, DriverOfflineOpStatus.queued);
      expect(again.orderPath, 'order/abc');
      expect(again.payload['k'], 'v');
    });
  });

  group('DriverOfflineReconcileResult', () {
    test('defaults', () {
      const r = DriverOfflineReconcileResult(alreadyDone: true, message: 'x');
      expect(r.alreadyDone, isTrue);
      expect(r.applied, isFalse);
      expect(r.requiresOnlineUi, isFalse);
    });
  });

  group('DriverRuntimeDiagnostics', () {
    test('snapshot bounded', () {
      for (var i = 0; i < 50; i++) {
        DriverRuntimeDiagnostics.note('t', '$i');
      }
      expect(DriverRuntimeDiagnostics.snapshot().length, lessThanOrEqualTo(40));
    });
  });
}
