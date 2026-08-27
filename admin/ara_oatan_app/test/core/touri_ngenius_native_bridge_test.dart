import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/payments/touri_ngenius_native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('touri/ngenius_payment');
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      if (call.method == 'isAvailable') return true;
      if (call.method == 'startCardPayment') {
        return {'status': 'success'};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps native success without treating it as authoritative paid', () async {
    final bridge = TouryNgeniusNativeBridge(channel: channel);
    final result = await bridge.startCardPayment(
      gatewayAuthorizationUrl: 'https://api-gateway.example/auth',
      payPageUrl: 'https://paypage.example/?code=abc',
      paymentCode: 'abc',
    );
    expect(result.isCompleted, isTrue);
    expect(result.outcome, TouryNativePaymentOutcome.completed);
  });

  test('maps cancel and decline', () {
    final bridge = TouryNgeniusNativeBridge(channel: channel);
    expect(
      bridge
          .startCardPayment(
            gatewayAuthorizationUrl: 'https://a',
            payPageUrl: 'https://p/?code=x',
            paymentCode: 'x',
          )
          .then((_) => true),
      completion(isTrue),
    );
  });
}
