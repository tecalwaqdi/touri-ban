import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/core/driver_payment_flags.dart';

/// Typed client for Render Payment API — wallet top-up only in driver app.
class DriverPaymentApiClient {
  DriverPaymentApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 25),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration timeout;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base =
        DriverPaymentFlags.paymentApiBaseUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      throw DriverPaymentApiException('CONFIG_ERROR');
    }
    if (!base.startsWith('https://') &&
        !base.startsWith('http://127.0.0.1') &&
        !base.startsWith('http://localhost')) {
      throw DriverPaymentApiException('CONFIG_ERROR');
    }
    if (kReleaseMode &&
        (base.contains('localhost') || base.contains('127.0.0.1'))) {
      throw DriverPaymentApiException('CONFIG_ERROR');
    }
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<String> _idToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw DriverPaymentApiException('AUTH_REQUIRED');
    }
    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw DriverPaymentApiException('AUTH_INVALID');
    }
    return token;
  }

  Future<void> _warmUp() async {
    try {
      await _http.get(_uri('/health')).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Creates a wallet_topup payment session. UID comes from Firebase ID token
  /// on the server — never send driverId from the client.
  Future<Map<String, dynamic>> createWalletTopUp({
    required String idempotencyKey,
    required double amountMajor,
    String? packageId,
    String? email,
    String? description,
    String locale = 'ar',
  }) async {
    unawaited(_warmUp());

    Object? lastError;
    var forceRefreshToken = false;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final token = await _idToken(forceRefresh: forceRefreshToken);
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
                'paymentPurpose': 'wallet_topup',
                'idempotencyKey': idempotencyKey,
                'amountMajor': amountMajor,
                if (packageId != null && packageId.isNotEmpty)
                  'packageId': packageId,
                if (email != null && email.isNotEmpty) 'email': email,
                if (description != null) 'description': description,
                'locale': locale,
              }),
            )
            .timeout(timeout);
        return _decode(response);
      } on DriverPaymentApiException catch (e) {
        lastError = e;
        final authRetry = e.code == 'AUTH_INVALID' && !forceRefreshToken;
        final retryable = authRetry ||
            e.code == 'PROVIDER_UNAVAILABLE' ||
            e.code == 'NETWORK_ERROR' ||
            e.code == 'UNKNOWN_ERROR';
        if (!retryable || attempt == 1) rethrow;
        if (authRetry) forceRefreshToken = true;
        await Future<void>.delayed(const Duration(seconds: 2));
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt == 1) {
          throw DriverPaymentApiException('NETWORK_ERROR');
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    if (lastError is DriverPaymentApiException) throw lastError;
    throw DriverPaymentApiException('NETWORK_ERROR');
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

  /// Poll until server credits wallet (webhook or status-side verification).
  /// Opening HPP / returning from browser is never treated as success.
  Future<Map<String, dynamic>> waitForWalletCredit({
    required String sessionId,
    int attempts = 20,
    Duration interval = const Duration(seconds: 2),
  }) async {
    Map<String, dynamic> last = {};
    for (var i = 0; i < attempts; i++) {
      last = await getStatus(sessionId);
      final status = (last['status']?.toString() ?? '').toLowerCase();
      final credited = last['walletCredited'] == true;
      if (credited) return last;
      if (status == 'failed' ||
          status == 'cancelled' ||
          status == 'canceled' ||
          status == 'expired') {
        throw DriverPaymentApiException(status.toUpperCase());
      }
      if (i < attempts - 1) {
        await Future<void>.delayed(interval);
      }
    }
    final status = (last['status']?.toString() ?? '').toLowerCase();
    throw DriverPaymentApiException(
      (status == 'paid' || status == 'captured')
          ? 'WALLET_CREDIT_PENDING'
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
      throw DriverPaymentApiException('NETWORK_ERROR');
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
      debugPrint('DriverPaymentApiClient HTTP ${response.statusCode} code=$code');
    }
    throw DriverPaymentApiException(code);
  }
}

class DriverPaymentApiException implements Exception {
  DriverPaymentApiException(this.code);
  final String code;

  @override
  String toString() => 'DriverPaymentApiException($code)';
}
