import 'dart:typed_data';

import 'package:excel/excel.dart';

import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_export_snapshot.dart';
import '/core/finance/finance_unsettled_exposure.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/money_amount.dart';

/// Real `.xlsx` workbook from [FinanceExportSnapshot] — no CSV rename.
///
/// Money columns are integer **minor units** ([IntCellValue]) when complete;
/// incomplete amounts stay blank (never fabricated `0`). Trip IDs are text.
abstract final class FinanceXlsxExport {
  FinanceXlsxExport._();

  static Uint8List build(FinanceExportSnapshot snap) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Summary');

    final summary = excel['Summary'];
    summary.appendRow([
      TextCellValue('Period'),
      TextCellValue(snap.periodLabel),
    ]);
    summary.appendRow([
      TextCellValue('Currency'),
      TextCellValue(snap.currency),
    ]);
    summary.appendRow([
      TextCellValue('Filters'),
      TextCellValue(snap.filtersSummary),
    ]);
    summary.appendRow([
      TextCellValue('Generated'),
      TextCellValue(snap.generatedAt.toIso8601String()),
    ]);
    summary.appendRow([
      TextCellValue('Money unit'),
      TextCellValue('minor_units_integer'),
    ]);
    summary.appendRow([TextCellValue('')]);
    _appendCompanySummary(summary, snap);

    _tripSheet(excel, 'Trip Ledger', snap.trips);
    _tripSheet(excel, 'Cash', snap.cashTrips);
    _tripSheet(excel, 'Online', snap.onlineTrips);
    _tripSheet(
      excel,
      'Receivables',
      FinanceUnsettledExposure.companyReceivables(snap.trips),
    );
    _tripSheet(
      excel,
      'Payables',
      FinanceUnsettledExposure.driverPayables(snap.trips),
    );
    _agentSheet(excel, snap.trips);
    _settlementStatusSheet(excel, snap.trips);
    _tripSheet(excel, 'Reconciliation', snap.exceptionTrips);

    final meta = excel['Meta'];
    meta.appendRow([
      TextCellValue('source'),
      TextCellValue('FinanceExportSnapshot'),
    ]);
    meta.appendRow([
      TextCellValue('engine'),
      TextCellValue('financial_accounting_v2'),
    ]);
    meta.appendRow([
      TextCellValue('trip_count'),
      IntCellValue(snap.trips.length),
    ]);
    meta.appendRow([
      TextCellValue('money_cells'),
      TextCellValue('IntCellValue_minor_units'),
    ]);

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('XLSX_ENCODE_FAILED');
    }
    return Uint8List.fromList(bytes);
  }

  static void _appendCompanySummary(Sheet summary, FinanceExportSnapshot snap) {
    final c = snap.company;
    if (c == null) {
      for (final e in snap.summaryLabelsAr().entries) {
        summary.appendRow([TextCellValue(e.key), TextCellValue(e.value)]);
      }
      return;
    }
    void moneyRow(String label, MoneyAmount m) {
      summary.appendRow([
        TextCellValue(label),
        IntCellValue(m.minorUnits),
        TextCellValue(m.currency),
      ]);
    }

    summary.appendRow([
      TextCellValue('رحلات مكتملة'),
      IntCellValue(c.completedTrips),
    ]);
    moneyRow('قيمة مكتملة', c.completedTripValue);
    moneyRow('محصّل', c.collectedTripValue);
    moneyRow('غير محصّل', c.unCollectedTripValue);
    moneyRow('عمولة منصة محققة', c.realizedPlatformFee);
    moneyRow('ضريبة محققة', c.realizedVat);
    moneyRow('صافي مندوبين محقق', c.realizedDriverNet);
    moneyRow('نقد محصّل', c.cashCollectedValue);
    moneyRow('إلكتروني مدفوع', c.onlinePaidValue);
    moneyRow('مستحق للشركة', c.companyReceivable);
    moneyRow('مستحق على الشركة', c.companyPayable);
    moneyRow('متبقي ذمم', c.outstandingReceivable);
  }

  static void _agentSheet(Excel excel, List<AccountantTripRow> trips) {
    final sheet = excel['Agent Finance'];
    sheet.appendRow([
      TextCellValue('Trip ID'),
      TextCellValue('Country'),
      TextCellValue('Agent Attribution'),
      TextCellValue('Agent Share Minor'),
      TextCellValue('Platform Fee Minor'),
      TextCellValue('Currency'),
    ]);
    for (final t in trips) {
      final resolved = _resolve(t);
      sheet.appendRow([
        TextCellValue(t.orderId),
        TextCellValue(t.countryLabel),
        TextCellValue(t.agentAttribution.name),
        _agentMinorCell(t),
        _minorCell(resolved.companyCommission, resolved.quality),
        TextCellValue(t.currency),
      ]);
    }
  }

  static void _settlementStatusSheet(
    Excel excel,
    List<AccountantTripRow> trips,
  ) {
    final sheet = excel['Settlements'];
    sheet.appendRow([
      TextCellValue('Trip ID'),
      TextCellValue('Settlement Status'),
      TextCellValue('Channel'),
      TextCellValue('Driver'),
      TextCellValue('Currency'),
      TextCellValue('Driver Net Minor'),
    ]);
    for (final t in trips) {
      final resolved = _resolve(t);
      sheet.appendRow([
        TextCellValue(t.orderId),
        TextCellValue(t.settlementStatusLabel),
        TextCellValue(t.paymentChannelLabel),
        TextCellValue(t.driverLabel),
        TextCellValue(t.currency),
        _minorCell(resolved.driverNet, resolved.quality),
      ]);
    }
  }

  static void _tripSheet(
    Excel excel,
    String name,
    List<AccountantTripRow> trips,
  ) {
    final sheet = excel[name];
    sheet.appendRow([
      TextCellValue('Trip ID'),
      TextCellValue('Date'),
      TextCellValue('Country'),
      TextCellValue('Currency'),
      TextCellValue('Driver'),
      TextCellValue('Channel'),
      TextCellValue('Ops Status'),
      TextCellValue('Payment Status'),
      TextCellValue('Collection'),
      TextCellValue('Settlement'),
      TextCellValue('Gross Minor'),
      TextCellValue('Platform Fee Minor'),
      TextCellValue('VAT Minor'),
      TextCellValue('Driver Net Minor'),
      TextCellValue('Agent Share Minor'),
      TextCellValue('Quality'),
    ]);
    for (final t in trips) {
      final resolved = _resolve(t);
      sheet.appendRow([
        TextCellValue(t.orderId),
        TextCellValue(
          t.orderedAt == null ? '—' : t.orderedAt!.toIso8601String(),
        ),
        TextCellValue(t.countryLabel),
        TextCellValue(t.currency),
        TextCellValue(t.driverLabel),
        TextCellValue(t.paymentChannelLabel),
        TextCellValue(t.tripStatusLabel),
        TextCellValue(t.paymentStatusLabel),
        TextCellValue(t.collectionStatusLabel),
        TextCellValue(t.settlementStatusLabel),
        _minorCell(resolved.gross, resolved.quality),
        _minorCell(resolved.companyCommission, resolved.quality),
        _minorCell(resolved.vat, resolved.quality),
        _minorCell(resolved.driverNet, resolved.quality),
        _agentMinorCell(t),
        TextCellValue(t.dataQualityLabel),
      ]);
    }
  }

  static FinancialAmountResolution _resolve(AccountantTripRow t) {
    final snap = FinancialOrderAdapter.fromOrder(t.order);
    final line = FinancialAccountingEngine.analyze(snap);
    return FinancialAmountResolution.fromLine(line);
  }

  static CellValue _minorCell(
    MoneyAmount? amount,
    FinancialDataQuality quality,
  ) {
    if (amount == null || quality != FinancialDataQuality.complete) {
      return TextCellValue('');
    }
    return IntCellValue(amount.minorUnits);
  }

  static CellValue _agentMinorCell(AccountantTripRow t) {
    if (!t.agentAmountIsShareOfCommission) {
      return TextCellValue('');
    }
    final snap = FinancialOrderAdapter.fromOrder(t.order);
    final minor = snap.agentAmountMinor;
    if (minor == null) {
      return TextCellValue('');
    }
    return IntCellValue(minor);
  }
}
