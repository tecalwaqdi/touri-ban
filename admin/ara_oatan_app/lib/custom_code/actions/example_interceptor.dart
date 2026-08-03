// Automatic FlutterFlow imports
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/backend/api_requests/api_interceptor.dart';

class ExampleInterceptor extends FFApiInterceptor {
  @override
  Future<ApiCallOptions> onRequest({
    required ApiCallOptions options,
  }) async {
    // Perform any necessary calls or modifications to the [options] before
    // the API call is made.
    return options;
  }

  @override
  Future<ApiCallResponse> onResponse({
    required ApiCallResponse response,
    required Future<ApiCallResponse> Function() retryFn,
  }) async {
    // Perform any necessary calls or modifications to the [response] prior
    // to returning it.
    return response;
  }
}
