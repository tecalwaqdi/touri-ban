import 'package:cloud_functions/cloud_functions.dart';

/// Client wrapper for Firebase Cloud Functions (no API keys in app).
class CloudFunctionsClient {
  CloudFunctionsClient._();

  // Keep the client pinned to the region used by the deployed Admin
  // functions.  Relying on the SDK default makes a callable look like
  // `NOT_FOUND` when the app is configured for another region.
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  static Future<Map<String, dynamic>> createPanelUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final result = await _functions.httpsCallable('createPanelUser').call({
      'email': email,
      'password': password,
      'userData': userData,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> refreshMyClaims() async {
    final result = await _functions.httpsCallable('refreshMyClaims').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<String?> geminiGenerateText(String prompt) async {
    final result = await _functions.httpsCallable('geminiGenerateText').call({
      'prompt': prompt,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['text'] as String?;
  }

  static Future<Map<String, dynamic>> aggregateFinancialSummary({
    String? countryPath,
    DateTime? periodStart,
  }) async {
    final result =
        await _functions.httpsCallable('aggregateFinancialSummary').call({
      if (countryPath != null) 'countryPath': countryPath,
      if (periodStart != null) 'periodStart': periodStart.toIso8601String(),
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<void> recordAuditLog({
    required String action,
    required String target,
    String details = '',
  }) async {
    await _functions.httpsCallable('recordAuditLog').call({
      'action': action,
      'target': target,
      'details': details,
    });
  }

  static Future<Map<String, dynamic>> reviewDriver({
    required String action,
    required String driverId,
    String reason = '',
    String section = 'general',
  }) async {
    final functionName = switch (action) {
      'approved' => 'approveDriverRegistration',
      'rejected' => 'rejectDriverRegistration',
      'changes_requested' => 'requestDriverChanges',
      _ => throw ArgumentError('Unsupported driver review action: $action'),
    };
    final result = await _functions.httpsCallable(functionName).call({
      'driverId': driverId,
      if (reason.isNotEmpty) 'reason': reason,
      if (section.isNotEmpty) 'section': section,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
