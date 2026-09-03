import '/core/finance/money_amount.dart';

/// Prospective immutable trip financial snapshot (Finance V3).
///
/// Historical orders typically lack this map. Recognition falls back to V2
/// order majors. Do not invent snapshot fields for unprovable history.
class TripFinancialSnapshot {
  const TripFinancialSnapshot({
    required this.schemaVersion,
    required this.generatedAt,
    required this.orderId,
    required this.currency,
    required this.customerTotalMinor,
    required this.platformCommissionMinor,
    required this.vatMinor,
    required this.driverNetMinor,
    required this.confidence,
    required this.source,
    this.customerId,
    this.driverId,
    this.countryId,
    this.countryCode,
    this.regionId,
    this.cityId,
    this.cityNameSnapshot,
    this.agentId,
    this.agentScopeId,
    this.agentAssignmentType,
    this.agentAttributionStatus,
    this.paymentMethod,
    this.paymentChannel,
    this.baseFareMinor,
    this.extrasMinor,
    this.discountMinor,
    this.platformCommissionRate,
    this.vatRate,
    this.vatBasis,
    this.agentCommissionRate,
    this.agentCommissionType,
    this.agentCommissionBaseMinor,
    this.agentCommissionMinor,
    this.driverGrossMinor,
    this.gatewayFeeMinor,
    this.companyNetMinor,
    this.pricingRuleVersion,
    this.attributionVersion,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime generatedAt;
  final String orderId;
  final String? customerId;
  final String? driverId;
  final String? countryId;
  final String? countryCode;
  final String? regionId;
  final String? cityId;
  final String? cityNameSnapshot;
  final String? agentId;
  final String? agentScopeId;
  final String? agentAssignmentType;
  final String? agentAttributionStatus;
  final String currency;
  final String? paymentMethod;
  final String? paymentChannel;
  final int? baseFareMinor;
  final int? extrasMinor;
  final int? discountMinor;
  final int customerTotalMinor;
  final double? platformCommissionRate;
  final int platformCommissionMinor;
  final double? vatRate;
  final int vatMinor;
  final String? vatBasis;
  final double? agentCommissionRate;
  final String? agentCommissionType;
  final int? agentCommissionBaseMinor;
  final int? agentCommissionMinor;
  final int? driverGrossMinor;
  final int driverNetMinor;
  final int? gatewayFeeMinor;
  final int? companyNetMinor;
  final String? pricingRuleVersion;
  final String? attributionVersion;
  final String confidence; // high | derived | incomplete
  final String source;

  MoneyAmount get customerTotal =>
      MoneyAmount(currency: currency, minorUnits: customerTotalMinor);
  MoneyAmount get platformCommission =>
      MoneyAmount(currency: currency, minorUnits: platformCommissionMinor);
  MoneyAmount get vat => MoneyAmount(currency: currency, minorUnits: vatMinor);
  MoneyAmount get driverNet =>
      MoneyAmount(currency: currency, minorUnits: driverNetMinor);

  Map<String, dynamic> toMap() => {
        'schema_version': schemaVersion,
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'order_id': orderId,
        if (customerId != null) 'customer_id': customerId,
        if (driverId != null) 'driver_id': driverId,
        if (countryId != null) 'country_id': countryId,
        if (countryCode != null) 'country_code': countryCode,
        if (regionId != null) 'region_id': regionId,
        if (cityId != null) 'city_id': cityId,
        if (cityNameSnapshot != null) 'city_name_snapshot': cityNameSnapshot,
        if (agentId != null) 'agent_id': agentId,
        if (agentScopeId != null) 'agent_scope_id': agentScopeId,
        if (agentAssignmentType != null)
          'agent_assignment_type': agentAssignmentType,
        if (agentAttributionStatus != null)
          'agent_attribution_status': agentAttributionStatus,
        'currency': currency,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (paymentChannel != null) 'payment_channel': paymentChannel,
        if (baseFareMinor != null) 'base_fare_minor': baseFareMinor,
        if (extrasMinor != null) 'extras_minor': extrasMinor,
        if (discountMinor != null) 'discount_minor': discountMinor,
        'customer_total_minor': customerTotalMinor,
        if (platformCommissionRate != null)
          'platform_commission_rate': platformCommissionRate,
        'platform_commission_minor': platformCommissionMinor,
        if (vatRate != null) 'vat_rate': vatRate,
        'vat_minor': vatMinor,
        if (vatBasis != null) 'vat_basis': vatBasis,
        if (agentCommissionRate != null)
          'agent_commission_rate': agentCommissionRate,
        if (agentCommissionType != null)
          'agent_commission_type': agentCommissionType,
        if (agentCommissionBaseMinor != null)
          'agent_commission_base_minor': agentCommissionBaseMinor,
        if (agentCommissionMinor != null)
          'agent_commission_minor': agentCommissionMinor,
        if (driverGrossMinor != null) 'driver_gross_minor': driverGrossMinor,
        'driver_net_minor': driverNetMinor,
        if (gatewayFeeMinor != null) 'gateway_fee_minor': gatewayFeeMinor,
        if (companyNetMinor != null) 'company_net_minor': companyNetMinor,
        if (pricingRuleVersion != null)
          'pricing_rule_version': pricingRuleVersion,
        if (attributionVersion != null)
          'attribution_version': attributionVersion,
        'confidence': confidence,
        'source': source,
      };

  static TripFinancialSnapshot? tryParse(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final currency = (raw['currency'] ?? '').toString().trim().toUpperCase();
    if (currency.isEmpty) return null;
    final orderId = (raw['order_id'] ?? '').toString().trim();
    if (orderId.isEmpty) return null;
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse(v.toString());
    }

    final customerTotal = asInt(raw['customer_total_minor']);
    final platform = asInt(raw['platform_commission_minor']);
    final vat = asInt(raw['vat_minor']);
    final driverNet = asInt(raw['driver_net_minor']);
    if (customerTotal == null ||
        platform == null ||
        vat == null ||
        driverNet == null) {
      return null;
    }
    final generatedRaw = raw['generated_at']?.toString();
    final generatedAt =
        DateTime.tryParse(generatedRaw ?? '')?.toUtc() ?? DateTime.now().toUtc();
    return TripFinancialSnapshot(
      schemaVersion: asInt(raw['schema_version']) ?? currentSchemaVersion,
      generatedAt: generatedAt,
      orderId: orderId,
      customerId: raw['customer_id']?.toString(),
      driverId: raw['driver_id']?.toString(),
      countryId: raw['country_id']?.toString(),
      countryCode: raw['country_code']?.toString(),
      regionId: raw['region_id']?.toString(),
      cityId: raw['city_id']?.toString(),
      cityNameSnapshot: raw['city_name_snapshot']?.toString(),
      agentId: raw['agent_id']?.toString(),
      agentScopeId: raw['agent_scope_id']?.toString(),
      agentAssignmentType: raw['agent_assignment_type']?.toString(),
      agentAttributionStatus: raw['agent_attribution_status']?.toString(),
      currency: currency,
      paymentMethod: raw['payment_method']?.toString(),
      paymentChannel: raw['payment_channel']?.toString(),
      baseFareMinor: asInt(raw['base_fare_minor']),
      extrasMinor: asInt(raw['extras_minor']),
      discountMinor: asInt(raw['discount_minor']),
      customerTotalMinor: customerTotal,
      platformCommissionRate: (raw['platform_commission_rate'] as num?)?.toDouble(),
      platformCommissionMinor: platform,
      vatRate: (raw['vat_rate'] as num?)?.toDouble(),
      vatMinor: vat,
      vatBasis: raw['vat_basis']?.toString(),
      agentCommissionRate: (raw['agent_commission_rate'] as num?)?.toDouble(),
      agentCommissionType: raw['agent_commission_type']?.toString(),
      agentCommissionBaseMinor: asInt(raw['agent_commission_base_minor']),
      agentCommissionMinor: asInt(raw['agent_commission_minor']),
      driverGrossMinor: asInt(raw['driver_gross_minor']),
      driverNetMinor: driverNet,
      gatewayFeeMinor: asInt(raw['gateway_fee_minor']),
      companyNetMinor: asInt(raw['company_net_minor']),
      pricingRuleVersion: raw['pricing_rule_version']?.toString(),
      attributionVersion: raw['attribution_version']?.toString(),
      confidence: (raw['confidence'] ?? 'incomplete').toString(),
      source: (raw['source'] ?? 'unknown').toString(),
    );
  }

  /// Soft invariant: platform + vat + driverNet should not exceed customer by >1 minor
  /// when companyNet is absent (cash split heuristic). Returns null if OK.
  String? validateSoftBalance() {
    final sum = platformCommissionMinor + vatMinor + driverNetMinor;
    if ((sum - customerTotalMinor).abs() > 1 && companyNetMinor == null) {
      return 'SOFT_BREAKDOWN_MISMATCH';
    }
    return null;
  }
}

/// Agent attribution status for snapshots / DQ.
abstract final class AgentAttributionStatusV3 {
  static const attributed = 'attributed';
  static const unattributed = 'unattributed';
  static const ambiguous = 'ambiguous';
  static const legacyUnprovable = 'legacy_unprovable';
  static const missingRate = 'missing_rate';
}
