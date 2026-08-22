import '/core/cloud_functions/cloud_functions_client.dart';

/// Phase 7A finance control-plane callables. No wallet / payout.
abstract final class FinanceControlsClient {
  FinanceControlsClient._();

  static Future<Map<String, dynamic>> accountantHome() =>
      CloudFunctionsClient.callMap('accountantHomeV2');

  static Future<Map<String, dynamic>> scanExceptions({
    String? countryRef,
    String? currency,
    DateTime? startAt,
    DateTime? endAt,
  }) =>
      CloudFunctionsClient.callMap('scanFinancialExceptionsV2', {
        if (countryRef != null) 'countryRef': countryRef,
        if (currency != null) 'currency': currency,
        if (startAt != null) 'startAt': startAt.toUtc().toIso8601String(),
        if (endAt != null) 'endAt': endAt.toUtc().toIso8601String(),
      });

  static Future<Map<String, dynamic>> listIncomplete({
    String? countryRef,
    String? currency,
  }) =>
      CloudFunctionsClient.callMap('listIncompleteOrdersV2', {
        if (countryRef != null) 'countryRef': countryRef,
        if (currency != null) 'currency': currency,
      });

  static Future<Map<String, dynamic>> detectOrphans() =>
      CloudFunctionsClient.callMap('detectFinanceOrphansV2');

  static Future<Map<String, dynamic>> driverStatement({
    required String driverId,
    required String currency,
  }) =>
      CloudFunctionsClient.callMap('loadDriverStatementV2', {
        'driverId': driverId,
        'currency': currency,
      });

  static Future<Map<String, dynamic>> companyPosition({String? currency}) =>
      CloudFunctionsClient.callMap('aggregateCompanyPositionV2', {
        if (currency != null) 'currency': currency,
      });

  static Future<Map<String, dynamic>> createPeriod(Map<String, dynamic> data) =>
      CloudFunctionsClient.callMap('createFinancialPeriodV2', data);

  static Future<Map<String, dynamic>> closePeriod(Map<String, dynamic> data) =>
      CloudFunctionsClient.callMap('closeFinancialPeriodV2', data);

  static Future<Map<String, dynamic>> reopenPeriod(Map<String, dynamic> data) =>
      CloudFunctionsClient.callMap('reopenFinancialPeriodV2', data);

  static Future<Map<String, dynamic>> periodChecklist(String periodId) =>
      CloudFunctionsClient.callMap('periodCloseChecklistV2', {
        'periodId': periodId,
      });

  static Future<Map<String, dynamic>> periodDashboard(String periodId) =>
      CloudFunctionsClient.callMap('periodDashboardV2', {'periodId': periodId});

  static Future<Map<String, dynamic>> createAdjustment(
    Map<String, dynamic> data,
  ) =>
      CloudFunctionsClient.callMap('createAdjustmentDraftV2', data);

  static Future<Map<String, dynamic>> approveAdjustment(String adjustmentId) =>
      CloudFunctionsClient.callMap('approveAdjustmentV2', {
        'adjustmentId': adjustmentId,
      });

  static Future<Map<String, dynamic>> reverseAdjustment({
    required String adjustmentId,
    required String reason,
  }) =>
      CloudFunctionsClient.callMap('reverseAdjustmentV2', {
        'adjustmentId': adjustmentId,
        'reason': reason,
      });

  static Future<Map<String, dynamic>> createOpeningBalance(
    Map<String, dynamic> data,
  ) =>
      CloudFunctionsClient.callMap('createOpeningBalanceV2', data);

  static Future<Map<String, dynamic>> verifySettlementSource(
    String settlementId,
  ) =>
      CloudFunctionsClient.callMap('verifySettlementSourceV2', {
        'settlementId': settlementId,
      });

  static Future<Map<String, dynamic>> searchAudit(Map<String, dynamic> data) =>
      CloudFunctionsClient.callMap('searchFinanceAuditV2', data);

  static Future<Map<String, dynamic>> report(Map<String, dynamic> data) =>
      CloudFunctionsClient.callMap('financialReportV2', data);

  static Future<Map<String, dynamic>> approvalPolicy() =>
      CloudFunctionsClient.callMap('financeApprovalPolicyV2');
}
