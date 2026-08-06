import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/core/toury_payment_flags.dart';

/// Typed client for the Vercel payment-api. Never holds provider secrets.
class PaymentApiClient {
  PaymentApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 25),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration timeout;

  Uri _uri(String path) {
    final base = TouryPaymentFlags.paymentApiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path');
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
    String? email,
    String? description,
    String locale = 'ar',
  }) async {
    final token = await _idToken();
    final response = await _http
        .post(
          _uri('/api/payments/create'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'paymentMethod': 'card',
            'paymentPurpose': 'booking',
            'idempotencyKey': idempotencyKey,
            'carPath': carPath,
            'countryPath': countryPath,
            'bookingHours': bookingHours,
            'additionalHours': additionalHours,
            if (email != null && email.isNotEmpty) 'email': email,
            if (description != null) 'description': description,
            'locale': locale,
          }),
        )
        .timeout(timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> getStatus(String sessionId) async {
    final token = await _idToken();
    final response = await _http
        .get(
          _uri('/api/payments/status/$sessionId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(timeout);
    return _decode(response);
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
        : 'UNKNOWN_ERROR';
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
