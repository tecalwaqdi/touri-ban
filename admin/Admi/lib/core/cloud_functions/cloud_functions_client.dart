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

  /// Read-only Financial Accounting V2 — full dataset totals.
  static Future<Map<String, dynamic>> aggregateFinancialAccountingV2({
    String? countryPath,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? driverId,
    String? channel,
    String? lifecycle,
    String? payment,
    String? confidence,
    String? currency,
    String mode = 'totals',
  }) async {
    final result = await _functions
        .httpsCallable('aggregateFinancialAccountingV2')
        .call({
      if (countryPath != null) 'countryPath': countryPath,
      if (periodStart != null) 'periodStart': periodStart.toIso8601String(),
      if (periodEnd != null) 'periodEnd': periodEnd.toIso8601String(),
      if (driverId != null) 'driverId': driverId,
      if (channel != null) 'channel': channel,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (payment != null) 'payment': payment,
      if (confidence != null) 'confidence': confidence,
      if (currency != null) 'currency': currency,
      'mode': mode,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Credits/debits a driver wallet via Admin SDK (finance / super_admin).
  /// [amount] > 0 credits, < 0 debits. Writes a `transactions` ledger row.
  static Future<Map<String, dynamic>> adminAdjustDriverWallet({
    required String driverId,
    required double amount,
    String note = '',
    String currency = 'SAR',
  }) async {
    final result =
        await _functions.httpsCallable('adminAdjustDriverWallet').call({
      'driverId': driverId,
      'amount': amount,
      if (note.isNotEmpty) 'note': note,
      'currency': currency,
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
    List<String>? fieldsToFix,
    int? reviewVersion,
    String? idempotencyKey,
    bool useRegistrationV2 = false,
  }) async {
    if (useRegistrationV2) {
      final v2Action = switch (action) {
        'approved' => 'approve',
        'rejected' => 'reject',
        'changes_requested' => 'request_changes',
        'approve' || 'reject' || 'request_changes' => action,
        _ => throw ArgumentError('Unsupported driver review action: $action'),
      };
      final result =
          await _functions.httpsCallable('reviewDriverApplicationV2').call({
        'action': v2Action,
        'driverId': driverId,
        if (reason.isNotEmpty) 'reason': reason,
        if (fieldsToFix != null && fieldsToFix.isNotEmpty)
          'fieldsToFix': fieldsToFix,
        if (reviewVersion != null) 'reviewVersion': reviewVersion,
        'idempotencyKey': idempotencyKey ??
            'rev_${driverId}_${v2Action}_${DateTime.now().millisecondsSinceEpoch}',
      });
      return Map<String, dynamic>.from(result.data as Map);
    }
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

  static Future<Map<String, dynamic>> createSettlementDraftV2({
    required String driverId,
    required String countryId,
    required String currency,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String idempotencyKey,
  }) async {
    final result = await _functions.httpsCallable('createSettlementDraftV2').call({
      'driverId': driverId,
      'countryId': countryId,
      'currency': currency,
      'periodStart': periodStart.toUtc().toIso8601String(),
      'periodEnd': periodEnd.toUtc().toIso8601String(),
      'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> refreshSettlementDraftV2({
    required String settlementId,
  }) async {
    final result =
        await _functions.httpsCallable('refreshSettlementDraftV2').call({
      'settlementId': settlementId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> lockSettlementV2({
    required String settlementId,
    required String idempotencyKey,
  }) async {
    final result = await _functions.httpsCallable('lockSettlementV2').call({
      'settlementId': settlementId,
      'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> markSettlementSettledV2({
    required String settlementId,
    required String settlementMethod,
    required String paymentReference,
    required int amountMinor,
    required String idempotencyKey,
    String? notes,
    DateTime? settledAt,
  }) async {
    final result =
        await _functions.httpsCallable('markSettlementSettledV2').call({
      'settlementId': settlementId,
      'settlementMethod': settlementMethod,
      'paymentReference': paymentReference,
      'amountMinor': amountMinor,
      'idempotencyKey': idempotencyKey,
      if (notes != null) 'notes': notes,
      if (settledAt != null) 'settledAt': settledAt.toUtc().toIso8601String(),
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> voidSettlementV2({
    required String settlementId,
    required String reason,
    required String idempotencyKey,
  }) async {
    final result = await _functions.httpsCallable('voidSettlementV2').call({
      'settlementId': settlementId,
      'reason': reason,
      'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> createSettlementPaymentV2({
    required String settlementId,
    required int amountMinor,
    required String method,
    required String idempotencyKey,
    String? direction,
    String? externalReference,
    String? notes,
    String? receivedBy,
    DateTime? paidAt,
    String? bankName,
    String? transferReference,
  }) async {
    final result =
        await _functions.httpsCallable('createSettlementPaymentV2').call({
      'settlementId': settlementId,
      'amountMinor': amountMinor,
      'method': method,
      'idempotencyKey': idempotencyKey,
      if (direction != null) 'direction': direction,
      if (externalReference != null) 'externalReference': externalReference,
      if (notes != null) 'notes': notes,
      if (receivedBy != null) 'receivedBy': receivedBy,
      if (paidAt != null) 'paidAt': paidAt.toUtc().toIso8601String(),
      if (bankName != null) 'bankName': bankName,
      if (transferReference != null) 'transferReference': transferReference,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> confirmSettlementPaymentV2({
    required String paymentId,
    required String idempotencyKey,
  }) async {
    final result =
        await _functions.httpsCallable('confirmSettlementPaymentV2').call({
      'paymentId': paymentId,
      'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> reverseSettlementPaymentV2({
    required String paymentId,
    required String reason,
    required String idempotencyKey,
    int? reversalAmountMinor,
  }) async {
    final result =
        await _functions.httpsCallable('reverseSettlementPaymentV2').call({
      'paymentId': paymentId,
      'reason': reason,
      'idempotencyKey': idempotencyKey,
      if (reversalAmountMinor != null) 'reversalAmountMinor': reversalAmountMinor,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> allocateExistingPaymentV2({
    required String settlementId,
    required String sourceId,
    required int amountMinor,
    required String idempotencyKey,
  }) async {
    final result =
        await _functions.httpsCallable('allocateExistingPaymentV2').call({
      'settlementId': settlementId,
      'sourceId': sourceId,
      'amountMinor': amountMinor,
      'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> aggregateSettlementExposureV2() async {
    final result =
        await _functions.httpsCallable('aggregateSettlementExposureV2').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> callMap(
    String name, [
    Map<String, dynamic>? payload,
  ]) async {
    final result = await _functions.httpsCallable(name).call(payload ?? {});
    if (result.data is Map) {
      return Map<String, dynamic>.from(result.data as Map);
    }
    return {'value': result.data};
  }
}
