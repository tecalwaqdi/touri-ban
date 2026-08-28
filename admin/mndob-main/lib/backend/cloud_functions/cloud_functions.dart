import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  try {
    final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable(
          callName,
          options: HttpsCallableOptions(timeout: timeout),
        )
        .call(input)
        .timeout(timeout);
    if (response.data is! Map) return {};
    final map = Map<String, dynamic>.from(response.data as Map);
    // Normalize thrown-style payloads returned as `{ok:false,...}`.
    if (map['ok'] == false && map['errorCode'] == null) {
      final err = (map['error'] ?? map['message'] ?? '').toString();
      final guessed = _guessCallableErrorCode(err, (map['code'] ?? '').toString());
      if (guessed != null) map['errorCode'] = guessed;
    }
    return map;
  } on FirebaseFunctionsException catch (e) {
    debugPrint(
      'Cloud call error!\n$callName '
      'Code: ${e.code}\n'
      'Message: ${e.message}',
    );
    final msg = (e.message ?? '').trim();
    final errorCode = _guessCallableErrorCode(msg, e.code) ?? e.code;
    return {
      'ok': false,
      'error': msg.isEmpty ? 'cloud_call_failed' : msg,
      'code': e.code,
      'errorCode': errorCode,
    };
  } catch (e) {
    debugPrint('Cloud call error:$callName $e');
    return {
      'ok': false,
      'error': 'cloud_call_failed',
      'code': 'deadline-exceeded',
      'errorCode': 'BOOKING_SERVICE_UNAVAILABLE',
    };
  }
}

String? _guessCallableErrorCode(String message, String cfCode) {
  final msg = message.trim();
  if (msg.isEmpty) {
    if (cfCode == 'internal' || cfCode == 'INTERNAL') return 'INTERNAL';
    if (cfCode == 'already-exists') return 'BOOKING_ALREADY_ASSIGNED';
    if (cfCode == 'not-found') return 'BOOKING_NOT_FOUND';
    return null;
  }
  const known = <String>{
    'BOOKING_NOT_FOUND',
    'BOOKING_ALREADY_ASSIGNED',
    'BOOKING_EXPIRED',
    'BOOKING_INVALID_STATE',
    'BOOKING_SERVICE_UNAVAILABLE',
    'DRIVER_WALLET_INSUFFICIENT',
    'DRIVER_DISABLED',
    'insufficient-wallet',
    'driver-disabled',
  };
  if (known.contains(msg)) {
    if (msg == 'insufficient-wallet') return 'DRIVER_WALLET_INSUFFICIENT';
    if (msg == 'driver-disabled') return 'DRIVER_DISABLED';
    return msg;
  }
  final upper = msg.toUpperCase();
  if (upper == 'INTERNAL' || cfCode == 'internal') return 'INTERNAL';
  if (cfCode == 'already-exists') return 'BOOKING_ALREADY_ASSIGNED';
  return null;
}
