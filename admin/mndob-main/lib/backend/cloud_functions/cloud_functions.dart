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
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : {};
  } on FirebaseFunctionsException catch (e) {
    debugPrint(
      'Cloud call error!\n$callName '
      'Code: ${e.code}\n'
      'Message: ${e.message}',
    );
    return {
      'error': e.message ?? 'cloud_call_failed',
      'code': e.code,
    };
  } catch (e) {
    debugPrint('Cloud call error:$callName $e');
    return {
      'error': 'cloud_call_failed',
      'code': 'deadline-exceeded',
    };
  }
}
