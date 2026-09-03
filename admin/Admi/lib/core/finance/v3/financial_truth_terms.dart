/// Canonical financial metric names for Admin UI / reports.
/// Never label GMV as "Revenue". Never invent a single cross-currency total.
abstract final class FinancialTruthTerms {
  FinancialTruthTerms._();

  static const bookingValue = 'booking_value';
  static const gmv = 'gmv';
  static const completedTripValue = 'completed_trip_value';
  static const collectedAmount = 'collected_amount';
  static const cashHeldByDrivers = 'cash_held_by_drivers';
  static const onlineFundsHeld = 'online_funds_held';
  static const platformCommission = 'platform_commission';
  static const agentCommission = 'agent_commission';
  static const driverGrossEarnings = 'driver_gross_earnings';
  static const driverNetEarnings = 'driver_net_earnings';
  static const vatLiability = 'vat_liability';
  static const discounts = 'discounts';
  static const refunds = 'refunds';
  static const chargebacks = 'chargebacks';
  static const gatewayFees = 'gateway_fees';
  static const companyReceivable = 'company_receivable';
  static const companyPayable = 'company_payable';
  static const settledAmount = 'settled_amount';
  static const outstandingAmount = 'outstanding_amount';
  static const netPlatformRevenue = 'net_platform_revenue';
  static const reconciliationDifference = 'reconciliation_difference';
  static const unverifiedAmount = 'unverified_amount';

  /// Arabic labels for production Admin (stable keys above).
  static String labelAr(String key) {
    switch (key) {
      case bookingValue:
        return 'قيمة الحجز';
      case gmv:
        return 'إجمالي قيمة الرحلات (GMV)';
      case completedTripValue:
        return 'قيمة الرحلات المكتملة';
      case collectedAmount:
        return 'المبلغ المحصل';
      case cashHeldByDrivers:
        return 'نقد مع المناديب';
      case onlineFundsHeld:
        return 'أموال إلكترونية محتجزة';
      case platformCommission:
        return 'عمولة المنصة';
      case agentCommission:
        return 'عمولة الوكيل';
      case driverGrossEarnings:
        return 'إجمالي استحقاق المندوب';
      case driverNetEarnings:
        return 'صافي المندوب';
      case vatLiability:
        return 'ضريبة مستحقة';
      case discounts:
        return 'الخصومات';
      case refunds:
        return 'المستردات';
      case chargebacks:
        return 'النزاعات البنكية';
      case gatewayFees:
        return 'رسوم بوابة الدفع';
      case companyReceivable:
        return 'مستحق للشركة';
      case companyPayable:
        return 'مستحق على الشركة';
      case settledAmount:
        return 'المسدّد';
      case outstandingAmount:
        return 'المتبقي';
      case netPlatformRevenue:
        return 'صافي إيراد المنصة';
      case reconciliationDifference:
        return 'فرق المطابقة';
      case unverifiedAmount:
        return 'مبلغ غير متحقق';
      default:
        return key;
    }
  }

  static String labelEn(String key) {
    switch (key) {
      case bookingValue:
        return 'Booking Value';
      case gmv:
        return 'GMV / Gross Trip Value';
      case completedTripValue:
        return 'Completed Trip Value';
      case collectedAmount:
        return 'Collected Amount';
      case cashHeldByDrivers:
        return 'Cash Held By Drivers';
      case onlineFundsHeld:
        return 'Online Funds Held';
      case platformCommission:
        return 'Platform Commission';
      case agentCommission:
        return 'Agent Commission';
      case driverGrossEarnings:
        return 'Driver Gross Earnings';
      case driverNetEarnings:
        return 'Driver Net Earnings';
      case vatLiability:
        return 'VAT / Tax Liability';
      case discounts:
        return 'Discounts';
      case refunds:
        return 'Refunds';
      case chargebacks:
        return 'Chargebacks';
      case gatewayFees:
        return 'Gateway Fees';
      case companyReceivable:
        return 'Company Receivable';
      case companyPayable:
        return 'Company Payable';
      case settledAmount:
        return 'Settled Amount';
      case outstandingAmount:
        return 'Outstanding Amount';
      case netPlatformRevenue:
        return 'Net Platform Revenue';
      case reconciliationDifference:
        return 'Reconciliation Difference';
      case unverifiedAmount:
        return 'Unverified Financial Amount';
      default:
        return key;
    }
  }
}

/// How a KPI value should be presented when the backend fails.
enum FinancialMetricAvailability {
  /// Proven numeric zero or positive from canonical engine.
  available,

  /// Backend failed / incomplete aggregate — must NOT show 0.
  unavailable,
}

class FinancialMetricValue {
  const FinancialMetricValue.available({
    required this.metricId,
    required this.byCurrencyMinor,
    required this.source,
    this.confidenceNote,
  }) : availability = FinancialMetricAvailability.available;

  const FinancialMetricValue.unavailable({
    required this.metricId,
    required this.source,
    this.confidenceNote,
  })  : availability = FinancialMetricAvailability.unavailable,
        byCurrencyMinor = const {};

  final String metricId;
  final FinancialMetricAvailability availability;
  final Map<String, int> byCurrencyMinor;
  final String source;
  final String? confidenceNote;

  /// UI must never treat [unavailable] as zero.
  bool get isFakeZeroRisk =>
      availability == FinancialMetricAvailability.unavailable;
}
