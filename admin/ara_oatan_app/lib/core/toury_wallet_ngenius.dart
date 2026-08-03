import 'package:easy_localization/easy_localization.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/core/toury_ngenius_service.dart';
import '/core/toury_payment_notifications.dart';
import '/core/toury_payment_verify.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// يبدأ شحن المحفظة عبر Network International باستخدام packageId فقط.
Future<ApiCallResponse?> touryStartWalletTopUp({
  required String userId,
  required String packageId,
  String? countryCode,
  int? displayAmountMinor,
}) async {
  final id = packageId.trim();
  if (id.isEmpty) {
    return null;
  }

  final response = await TouryNGeniusService.createPayment(
    description: '${'wallet_add_description'.tr()} — $currentUserDisplayName',
    amountHalalas: 0,
    paymentPurpose: 'wallet',
    packageId: id,
    countryCode: countryCode,
  );

  if (!TouryNGeniusService.createReady(response)) {
    return response;
  }

  final paymentId = TouryNGeniusService.paymentId(response.jsonBody);
  if (paymentId == null || paymentId.isEmpty) {
    return response;
  }

  final bodyAmount = TouryNGeniusService.amountHalalas(response.jsonBody);
  final amountMinor = bodyAmount ?? displayAmountMinor ?? 0;

  final app = FFAppState();
  app.update(() {
    app.paymentOrderId = paymentId;
    app.walletTopUpAmount = amountMinor / 100.0;
    app.walletTopUpPaymentMethodId = 'ngenius_hosted';
    app.walletTopUpUserId = userId;
    app.paymentFlowKind = TypeHgz.Wallet;
    app.paymentInProgress = true;
    app.DonePay = false;
  });

  return response;
}

/// بعد نجاح الدفع — يُضاف الرصيد للمحفظة (مرة واحدة لكل payment id).
Future<bool> touryFinalizeWalletTopUp() async {
  final app = FFAppState();
  final paymentId = app.paymentOrderId.trim();
  if (paymentId.isEmpty) {
    return false;
  }

  final verify = await touryVerifyGatewayPayment(paymentId);
  if (!verify.isPaid) {
    return false;
  }

  final userId = app.walletTopUpUserId.isNotEmpty
      ? app.walletTopUpUserId
      : (currentUserUid ?? '');
  final paymentMethodId = app.walletTopUpPaymentMethodId;
  final amount = app.walletTopUpAmount;

  if (userId.isEmpty || paymentMethodId.isEmpty || amount <= 0) {
    return false;
  }

  final finalize = await TouryNGeniusService.finalizeWalletTopUp(
    sessionId: verify.orderId ?? paymentId,
  );
  if (!TouryNGeniusService.httpOk(finalize)) {
    return false;
  }

  touryNotifyWalletTopUpSuccess(amountSar: amount);

  app.update(() {
    app.paymentInProgress = false;
    app.DonePay = true;
    app.walletTopUpAmount = 0;
    app.walletTopUpPaymentMethodId = '';
    app.walletTopUpUserId = '';
    app.clearSensitivePaymentSession();
  });

  return true;
}

void touryClearWalletTopUpPending() {
  final app = FFAppState();
  app.update(() {
    app.paymentInProgress = false;
    app.walletTopUpAmount = 0;
    app.walletTopUpPaymentMethodId = '';
    app.walletTopUpUserId = '';
    app.clearSensitivePaymentSession();
  });
}

/// سحب عبر طلب مراجعة على الخادم (ليس refund بوابة مباشر).
Future<bool> touryRequestWalletWithdrawal({
  required double amountSar,
}) async {
  if (amountSar <= 0) {
    return false;
  }
  final response = await TouryNGeniusService.requestWalletWithdrawal(
    amountHalalas: (amountSar * 100).round(),
  );
  return TouryNGeniusService.httpOk(response);
}
