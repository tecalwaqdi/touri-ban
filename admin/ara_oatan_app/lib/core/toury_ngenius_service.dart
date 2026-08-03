import '/backend/api_requests/api_manager.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Network International (N-Genius) — الدفع عبر Cloud Functions.
abstract final class TouryNGeniusService {
  TouryNGeniusService._();

  static Future<ApiCallResponse> createPayment({
    required String description,
    required int amountHalalas,
    String? email,
    String paymentPurpose = 'generic',
    String? carPath,
    String? countryPath,
    int? bookingHours,
    int? additionalHours,
    String? orderPath,
    int? extraHours,
    String? packageId,
    String? countryCode,
  }) async {
    final app = FFAppState();
    if (app.paymentIdempotencyKey.isEmpty) {
      app.paymentIdempotencyKey =
          '${paymentPurpose}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    }
    final data = await makeCloudCall('createNGeniusPayment', {
      'description': description,
      // Booking / extra_hours ignore client amount; wallet must not send it.
      if (paymentPurpose != 'wallet') 'amount': amountHalalas,
      'idempotencyKey': app.paymentIdempotencyKey,
      'paymentPurpose': paymentPurpose,
      if (carPath != null) 'carPath': carPath,
      if (countryPath != null) 'countryPath': countryPath,
      if (bookingHours != null) 'bookingHours': bookingHours,
      if (additionalHours != null) 'additionalHours': additionalHours,
      if (orderPath != null) 'orderPath': orderPath,
      if (extraHours != null) 'extraHours': extraHours,
      if (packageId != null && packageId.isNotEmpty) 'packageId': packageId,
      if (countryCode != null && countryCode.isNotEmpty)
        'countryCode': countryCode,
      if (email != null && email.isNotEmpty) 'email': email,
    });

    if (data.containsKey('error')) {
      return ApiCallResponse(
        data,
        const {},
        500,
        exception: data['error']?.toString(),
      );
    }

    return ApiCallResponse(data, const {}, 200);
  }

  static Future<ApiCallResponse> finalizeBooking({
    required String sessionId,
    required Map<String, dynamic> booking,
  }) async {
    final data = await makeCloudCall('finalizeNGeniusBooking', {
      'id': sessionId.trim(),
      'booking': booking,
    });
    if (data.containsKey('error')) {
      return ApiCallResponse(
        data,
        const {},
        500,
        exception: data['error']?.toString(),
      );
    }
    return ApiCallResponse(data, const {}, 200);
  }

  static Future<ApiCallResponse> finalizeWalletTopUp({
    required String sessionId,
  }) async {
    final data = await makeCloudCall('finalizeNGeniusWalletTopUp', {
      'id': sessionId.trim(),
    });
    if (data.containsKey('error')) {
      return ApiCallResponse(
        data,
        const {},
        500,
        exception: data['error']?.toString(),
      );
    }
    return ApiCallResponse(data, const {}, 200);
  }

  static Future<ApiCallResponse> finalizeExtraHours({
    required String sessionId,
  }) async {
    final data = await makeCloudCall('finalizeNGeniusExtraHours', {
      'id': sessionId.trim(),
    });
    if (data.containsKey('error')) {
      return ApiCallResponse(
        data,
        const {},
        500,
        exception: data['error']?.toString(),
      );
    }
    return ApiCallResponse(data, const {}, 200);
  }

  static Future<ApiCallResponse> requestWalletWithdrawal({
    required int amountHalalas,
  }) async {
    final data = await makeCloudCall('createWalletWithdrawalRequest', {
      'amount': amountHalalas,
    });
    if (data.containsKey('error')) {
      return ApiCallResponse(
        data,
        const {},
        500,
        exception: data['error']?.toString(),
      );
    }
    return ApiCallResponse(data, const {}, 200);
  }

  static Future<ApiCallResponse> getPayment({required String orderId}) async {
    final data = await makeCloudCall('getNGeniusPayment', {
      'id': orderId.trim(),
    });

    if (data.containsKey('error')) {
      return ApiCallResponse(
        data,
        const {},
        500,
        exception: data['error']?.toString(),
      );
    }

    return ApiCallResponse(data, const {}, 200);
  }

  static Future<ApiCallResponse> refundPayment({
    required String orderId,
    int? amountHalalas,
  }) async {
    final data = await makeCloudCall('refundNGeniusPayment', {
      'id': orderId.trim(),
      if (amountHalalas != null) 'amount': amountHalalas,
    });

    if (data.containsKey('error')) {
      return ApiCallResponse(
        data,
        const {},
        500,
        exception: data['error']?.toString(),
      );
    }

    return ApiCallResponse(data, const {}, 200);
  }

  static String? paymentId(dynamic jsonBody) =>
      castToType<String>(getJsonField(jsonBody, r'''$.id''')) ??
      castToType<String>(getJsonField(jsonBody, r'''$.orderReference'''));

  static int? amountHalalas(dynamic jsonBody) {
    final value = getJsonField(jsonBody, r'''$.amount_halalas''') ??
        getJsonField(jsonBody, r'''$.amountHalalas''');
    if (value is int) return value;
    return int.tryParse('$value');
  }

  static String? transactionUrl(dynamic jsonBody) => castToType<String>(
        getJsonField(jsonBody, r'''$.source.transaction_url'''),
      );

  static String? status(dynamic jsonBody) =>
      castToType<String>(getJsonField(jsonBody, r'''$.status'''));

  static bool isPaid(dynamic jsonBody) => status(jsonBody) == 'paid';

  static bool isFailed(dynamic jsonBody) => status(jsonBody) == 'failed';

  static bool isPending(dynamic jsonBody) => status(jsonBody) == 'pending';

  static bool isRefunded(dynamic jsonBody) => status(jsonBody) == 'refunded';

  static String? orderIdFromResponse(dynamic jsonBody) =>
      paymentId(jsonBody) ??
      castToType<String>(getJsonField(jsonBody, r'''$.orderReference'''));

  static bool createReady(ApiCallResponse? response) {
    if (response?.succeeded != true) return false;
    final body = response!.jsonBody;
    final id = paymentId(body);
    if (id == null || id.isEmpty) return false;
    if (isPaid(body)) return true;
    final url = transactionUrl(body);
    return url != null && url.isNotEmpty;
  }

  static bool httpOk(ApiCallResponse? response) => response?.succeeded == true;
}
