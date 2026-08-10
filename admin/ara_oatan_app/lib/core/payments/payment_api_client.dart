import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/core/toury_payment_flags.dart';

/// Typed client for the external Express Payment API on Render.
/// Never holds provider secrets. Paths match Express (no `/api` prefix).
class PaymentApiClient {
  PaymentApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 25),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration timeout;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base =
        TouryPaymentFlags.paymentApiBaseUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      throw PaymentApiException('CONFIG_ERROR');
    }
    if (!base.startsWith('https://') &&
        !base.startsWith('http://127.0.0.1') &&
        !base.startsWith('http://localhost')) {
      throw PaymentApiException('CONFIG_ERROR');
    }
    if (kReleaseMode &&
        (base.contains('localhost') || base.contains('127.0.0.1'))) {
      throw PaymentApiException('CONFIG_ERROR');
    }
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw PaymentApiException('AUTH_REQUIRED');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw PaymentApiException('AUTH_INVALID');
    }
    return token;
  }

  Future<Map<String, dynamic>> createCardBookingPayment({
    required String idempotencyKey,
    required String carPath,
    required String countryPath,
    required int bookingHours,
    required int additionalHours,
    required Map<String, dynamic> booking,
    String? email,
    String? description,
    String locale = 'ar',
  }) async {
    // Wake Render free-tier cold starts before the authenticated create.
    unawaited(_warmUp());

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final token = await _idToken();
        final response = await _http
            .post(
              _uri('/payments/create'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'paymentMethod': 'card',
                'paymentPurpose': 'booking',
                // Body field (not HTTP header) — matches Express createSchema.
                'idempotencyKey': idempotencyKey,
                'carPath': carPath,
                'countryPath': countryPath,
                'bookingHours': bookingHours,
                'additionalHours': additionalHours,
                'booking': booking,
                if (email != null && email.isNotEmpty) 'email': email,
                if (description != null) 'description': description,
                'locale': locale,
              }),
            )
            .timeout(timeout);
        return _decode(response);
      } on PaymentApiException catch (e) {
        lastError = e;
        final retryable = e.code == 'PROVIDER_UNAVAILABLE' ||
            e.code == 'NETWORK_ERROR' ||
            e.code == 'UNKNOWN_ERROR';
        if (!retryable || attempt == 1) rethrow;
        if (kDebugMode) {
          debugPrint('PaymentApiClient create retry after ${e.code}');
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt == 1) {
          throw PaymentApiException('NETWORK_ERROR');
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    if (lastError is PaymentApiException) throw lastError;
    throw PaymentApiException('NETWORK_ERROR');
  }

  Future<void> _warmUp() async {
    try {
      await _http.get(_uri('/health')).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Best-effort only — create still runs.
    }
  }

  Future<Map<String, dynamic>> getStatus(String sessionId) async {
    final token = await _idToken();
    final response = await _http
        .get(
          _uri('/payments/status', {'sessionId': sessionId}),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(timeout);
    return _decode(response);
  }

  /// Polls until webhook/status creates the booking, or fails/times out.
  Future<Map<String, dynamic>> waitForPaidBooking({
    required String sessionId,
    int attempts = 15,
    Duration interval = const Duration(seconds: 2),
  }) async {
    Map<String, dynamic> last = {};
    for (var i = 0; i < attempts; i++) {
      last = await getStatus(sessionId);
      final status = last['status']?.toString() ?? '';
      final bookingCreated = last['bookingCreated'] == true;
      final bookingId = last['bookingId']?.toString();
      if (bookingCreated && bookingId != null && bookingId.isNotEmpty) {
        return last;
      }
      if (status == 'failed' ||
          status == 'cancelled' ||
          status == 'expired') {
        throw PaymentApiException(status.toUpperCase());
      }
      if (i < attempts - 1) {
        await Future<void>.delayed(interval);
      }
    }
    // Do not invent a booking id — require server bookingCreated.
    throw PaymentApiException(
      (last['status']?.toString() == 'paid' ||
              last['status']?.toString() == 'captured')
          ? 'BOOKING_PENDING'
          : 'PAYMENT_PENDING',
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } catch (_) {
      throw PaymentApiException('NETWORK_ERROR');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final err = body['error'];
    final code = err is Map && err['code'] is String
        ? err['code'] as String
        : (err is Map && err['message'] is String
            ? err['message'] as String
            : 'UNKNOWN_ERROR');
    if (kDebugMode) {
      debugPrint('PaymentApiClient HTTP ${response.statusCode} code=$code');
    }
    throw PaymentApiException(code);
  }
}

class PaymentApiException implements Exception {
  PaymentApiException(this.code);
  final String code;

  @override
  String toString() => 'PaymentApiException($code)';
}
