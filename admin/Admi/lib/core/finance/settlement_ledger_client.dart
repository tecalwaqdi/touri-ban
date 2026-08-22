import '/core/cloud_functions/cloud_functions_client.dart';

/// Client for Settlement Ledger V2 callables (no direct Firestore writes).
abstract final class SettlementLedgerClient {
  SettlementLedgerClient._();

  static String newIdempotencyKey(String op) =>
      '$op-${DateTime.now().toUtc().microsecondsSinceEpoch}';

  static Future<Map<String, dynamic>> createDraft({
    required String driverId,
    required String countryId,
    required String currency,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String idempotencyKey,
  }) {
    return CloudFunctionsClient.createSettlementDraftV2(
      driverId: driverId,
      countryId: countryId,
      currency: currency,
      periodStart: periodStart,
      periodEnd: periodEnd,
      idempotencyKey: idempotencyKey,
    );
  }

  static Future<Map<String, dynamic>> refreshDraft({
    required String settlementId,
  }) =>
      CloudFunctionsClient.refreshSettlementDraftV2(settlementId: settlementId);

  static Future<Map<String, dynamic>> lock({
    required String settlementId,
    required String idempotencyKey,
  }) =>
      CloudFunctionsClient.lockSettlementV2(
        settlementId: settlementId,
        idempotencyKey: idempotencyKey,
      );

  static Future<Map<String, dynamic>> markSettled({
    required String settlementId,
    required String settlementMethod,
    required String paymentReference,
    required int amountMinor,
    required String idempotencyKey,
    String? notes,
    DateTime? settledAt,
  }) =>
      CloudFunctionsClient.markSettlementSettledV2(
        settlementId: settlementId,
        settlementMethod: settlementMethod,
        paymentReference: paymentReference,
        amountMinor: amountMinor,
        idempotencyKey: idempotencyKey,
        notes: notes,
        settledAt: settledAt,
      );

  static Future<Map<String, dynamic>> voidSettlement({
    required String settlementId,
    required String reason,
    required String idempotencyKey,
  }) =>
      CloudFunctionsClient.voidSettlementV2(
        settlementId: settlementId,
        reason: reason,
        idempotencyKey: idempotencyKey,
      );

  static Future<Map<String, dynamic>> createPayment({
    required String settlementId,
    required int amountMinor,
    required String method,
    required String idempotencyKey,
    String? externalReference,
    String? notes,
    String? receivedBy,
    DateTime? paidAt,
  }) =>
      CloudFunctionsClient.createSettlementPaymentV2(
        settlementId: settlementId,
        amountMinor: amountMinor,
        method: method,
        idempotencyKey: idempotencyKey,
        externalReference: externalReference,
        notes: notes,
        receivedBy: receivedBy,
        paidAt: paidAt,
      );

  static Future<Map<String, dynamic>> confirmPayment({
    required String paymentId,
    required String idempotencyKey,
  }) =>
      CloudFunctionsClient.confirmSettlementPaymentV2(
        paymentId: paymentId,
        idempotencyKey: idempotencyKey,
      );

  static Future<Map<String, dynamic>> reversePayment({
    required String paymentId,
    required String reason,
    required String idempotencyKey,
    int? reversalAmountMinor,
  }) =>
      CloudFunctionsClient.reverseSettlementPaymentV2(
        paymentId: paymentId,
        reason: reason,
        idempotencyKey: idempotencyKey,
        reversalAmountMinor: reversalAmountMinor,
      );
}
