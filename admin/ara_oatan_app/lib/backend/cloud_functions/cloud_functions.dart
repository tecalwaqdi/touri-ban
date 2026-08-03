import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input,
) async {
  try {
    final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable(callName, options: HttpsCallableOptions())
        .call(input);
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : {};
  } on FirebaseFunctionsException catch (e) {
    debugPrint(
      'Cloud call error!\n $callName'
      'Code: ${e.code}\n'
      'Details: ${e.details}\n'
      'Message: ${e.message}',
    );
    return {
      'error': e.message ?? 'cloud_call_failed',
      'code': e.code,
      // Surface mapped user text via callers — never leak raw NOT_FOUND alone.
    };
  } catch (e) {
    debugPrint('Cloud call error:$callName $e');
    return {'error': e.toString()};
  }
}
