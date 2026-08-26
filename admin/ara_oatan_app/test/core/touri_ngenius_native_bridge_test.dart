import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/payments/touri_ngenius_native_bridge.dart';
import 'package:ara_oatan_app/core/toury_payment_flags.dart';

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

  test('mobile payment mode defaults to native SDK primary', () {
    expect(TouryPaymentFlags.mobilePaymentMode, 'sdk');
    expect(TouryPaymentFlags.preferMobileSdk, isTrue);
    expect(TouryPaymentFlags.forceHostedPaymentPage, isFalse);
  });

  test('native bridge maps success without card data', () async {
    final bridge = TouryNgeniusNativeBridge();
    final result = await bridge.startCardPayment(
      gatewayAuthorizationUrl:
          'https://api-gateway.sandbox.ngenius-payments.com/transactions/paymentAuthorization',
      payPageUrl:
          'https://paypage.sandbox.ngenius-payments.com/?code=abc',
      paymentCode: 'abc',
      languageCode: 'ar',
    );
    expect(result.isCompleted, isTrue);
    expect(log, isNotEmpty);
    final args = log.first.arguments as Map;
    expect(args.containsKey('gatewayAuthorizationUrl'), isTrue);
    expect(args.containsKey('paymentCode'), isTrue);
    expect(args.containsKey('pan'), isFalse);
    expect(args.containsKey('cvv'), isFalse);
    expect(args.containsKey('apiKey'), isFalse);
  });

  test('native bridge rejects empty session', () async {
    final bridge = TouryNgeniusNativeBridge();
    final result = await bridge.startCardPayment(
      gatewayAuthorizationUrl: '',
      payPageUrl: '',
      paymentCode: '',
    );
    expect(result.outcome, TouryNativePaymentOutcome.error);
    expect(result.errorCategory, 'INVALID_SDK_SESSION');
  });
}
