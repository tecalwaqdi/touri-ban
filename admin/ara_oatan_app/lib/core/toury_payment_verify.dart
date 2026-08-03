import '/backend/api_requests/api_manager.dart';
import '/core/toury_ngenius_service.dart';

/// نتيجة التحقق من الدفع عبر Network International.
enum TouryPaymentVerifyResult { paid, pending, failed, error }

class TouryPaymentVerification {
  const TouryPaymentVerification({
    required this.result,
    this.response,
    this.orderId,
    this.status,
  });

  final TouryPaymentVerifyResult result;
  final ApiCallResponse? response;
  final String? orderId;
  final String? status;

  bool get isPaid => result == TouryPaymentVerifyResult.paid;
  bool get isPending => result == TouryPaymentVerifyResult.pending;
  bool get isFailed => result == TouryPaymentVerifyResult.failed;
}

/// يتحقق من حالة الدفع مع N-Genius قبل اعتماد الطلب أو شحن المحفظة.
Future<TouryPaymentVerification> touryVerifyGatewayPayment(
  String orderId,
) async {
  final trimmed = orderId.trim();
  if (trimmed.isEmpty) {
    return const TouryPaymentVerification(
      result: TouryPaymentVerifyResult.error,
    );
  }

  final response = await TouryNGeniusService.getPayment(orderId: trimmed);
  if (!TouryNGeniusService.httpOk(response)) {
    return TouryPaymentVerification(
      result: TouryPaymentVerifyResult.error,
      response: response,
    );
  }

  final body = response.jsonBody;
  final status = TouryNGeniusService.status(body);
  final resolvedId = TouryNGeniusService.orderIdFromResponse(body) ?? trimmed;

  if (TouryNGeniusService.isPaid(body)) {
    return TouryPaymentVerification(
      result: TouryPaymentVerifyResult.paid,
      response: response,
      orderId: resolvedId,
      status: status,
    );
  }
  if (TouryNGeniusService.isFailed(body)) {
    return TouryPaymentVerification(
      result: TouryPaymentVerifyResult.failed,
      response: response,
      orderId: resolvedId,
      status: status,
    );
  }
  return TouryPaymentVerification(
    result: TouryPaymentVerifyResult.pending,
    response: response,
    orderId: resolvedId,
    status: status,
  );
}
