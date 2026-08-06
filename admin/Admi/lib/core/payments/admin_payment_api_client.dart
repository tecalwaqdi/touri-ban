import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Admin client for Vercel payment-api refunds. Server still enforces finance role.
class AdminPaymentApiClient {
  AdminPaymentApiClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const String baseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: '',
  );

  Uri _uri(String path) {
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      throw StateError('PAYMENT_API_BASE_URL missing');
    }
    if (kReleaseMode &&
        (base.contains('localhost') || base.contains('127.0.0.1'))) {
      throw StateError('PAYMENT_API_BASE_URL invalid for release');
    }
    return Uri.parse('$base$path');
  }

  Future<Map<String, dynamic>> refund({
    required String sessionId,
    required String idempotencyKey,
    int? amountMinor,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('AUTH_REQUIRED');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw StateError('AUTH_INVALID');

    final response = await _http
        .post(
          _uri('/api/payments/refund'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'sessionId': sessionId,
            'idempotencyKey': idempotencyKey,
            if (amountMinor != null) 'amountMinor': amountMinor,
            if (reason != null && reason.isNotEmpty) 'reason': reason,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final err = body['error'];
    final code = err is Map && err['code'] is String
        ? err['code'] as String
        : 'UNKNOWN_ERROR';
    throw StateError(code);
  }
}
