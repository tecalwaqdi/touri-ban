import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Read-only money field resolution quality.
enum FinancialDataQuality {
  complete,
  partial,
  unresolved,
}

/// Read-only resolution of preferred money fields — no silent fabrication.
class FinancialAmountResolution {
  const FinancialAmountResolution({
    required this.quality,
    required this.source,
    required this.confidence,
    required this.missingFields,
    this.gross,
    this.companyCommission,
    this.vat,
    this.driverNet,
    this.currency,
  });

  final MoneyAmount? gross;
  final MoneyAmount? companyCommission;
  final MoneyAmount? vat;
  final MoneyAmount? driverNet;
  final String? currency;
  final FinancialDataQuality quality;

  /// e.g. total_mndob2+total_app+total_vat+total_mndob | financial_snapshot | incomplete
  final String source;
  final FinancialConfidence confidence;
  final List<String> missingFields;

  bool get isComplete => quality == FinancialDataQuality.complete;

  /// Builds from an already-analyzed [FinancialOrderLine] (no new formulas).
  static FinancialAmountResolution fromLine(FinancialOrderLine line) {
    final missing = <String>[];
    if (line.grossBase == null) missing.add('gross');
    if (line.platformFee == null) missing.add('companyCommission');
    if (line.recordedVat == null) missing.add('vat');
    if (line.driverNet == null) missing.add('driverNet');

    if (!line.currencySupported) {
      return FinancialAmountResolution(
        quality: FinancialDataQuality.unresolved,
        source: 'unsupported_currency',
        confidence: FinancialConfidence.incomplete,
        missingFields: ['currency', ...missing],
        currency: line.currency,
      );
    }

    final hasAll = missing.isEmpty;
    final highOk = hasAll &&
        line.confidence == FinancialConfidence.high &&
        !line.notes.contains('MISSING_FEE_OR_VAT') &&
        !line.notes.contains('MISSING_TOTAL_FOR_DERIVE');

    final quality = highOk
        ? FinancialDataQuality.complete
        : (line.grossBase != null ||
                line.platformFee != null ||
                line.driverNet != null)
            ? FinancialDataQuality.partial
            : FinancialDataQuality.unresolved;

    final source = highOk
        ? 'preferred_fields_or_engine_high'
        : (missing.isEmpty
            ? 'engine_${line.confidence.name}'
            : 'incomplete:${missing.join(",")}');

    return FinancialAmountResolution(
      gross: line.grossBase,
      companyCommission: line.platformFee,
      vat: line.recordedVat,
      driverNet: line.driverNet,
      currency: line.currency,
      quality: quality,
      source: source,
      confidence: line.confidence,
      missingFields: missing,
    );
  }

  static FinancialAmountResolution fromSnapshot(FinancialOrderSnapshot o) {
    final line = FinancialAccountingEngine.analyze(o);
    return fromLine(line);
  }
}
