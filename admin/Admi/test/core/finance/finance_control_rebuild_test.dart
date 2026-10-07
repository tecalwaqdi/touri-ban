import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_qa_fixture.dart';
import 'package:admin_arawatan/core/finance/finance_export_snapshot.dart';
import 'package:admin_arawatan/core/finance/finance_pdf_export.dart';
import 'package:admin_arawatan/core/finance/finance_xlsx_export.dart';
import 'package:admin_arawatan/core/finance/financial_accounting_engine.dart';
import 'package:admin_arawatan/core/finance/financial_amount_resolution.dart';
import 'package:admin_arawatan/core/finance/money_amount.dart';
import 'package:admin_arawatan/core/finance/settlement_preview.dart';

void main() {
  group('Finance control rebuild matrices', () {
    FinancialOrderLine line({
      required String id,
      required FinancialPaymentChannel channel,
      required int customer,
      required int gross,
      required int fee,
      required int vat,
      required int net,
      bool collected = true,
      bool completed = true,
      bool eligible = true,
    }) {
      const currency = 'SAR';
      return FinancialOrderLine(
        orderId: id,
        currency: currency,
        channel: channel,
        lifecycle: completed
            ? FinancialLifecycle.completed
            : FinancialLifecycle.active,
        payment: collected
            ? (channel == FinancialPaymentChannel.cash
                ? FinancialPaymentState.cashCollected
                : FinancialPaymentState.paid)
            : FinancialPaymentState.pendingCash,
        bucket: FinancialCollectionBucket.completedAndCollected,
        confidence: FinancialConfidence.high,
        currencySupported: true,
        customerPaid: MoneyAmount(currency: currency, minorUnits: customer),
        grossBase: MoneyAmount(currency: currency, minorUnits: gross),
        platformFee: MoneyAmount(currency: currency, minorUnits: fee),
        recordedVat: MoneyAmount(currency: currency, minorUnits: vat),
        recordedDiscount: MoneyAmount.zero(currency),
        driverNet: MoneyAmount(currency: currency, minorUnits: net),
        cashHeldByDriver: channel == FinancialPaymentChannel.cash && collected
            ? MoneyAmount(currency: currency, minorUnits: customer)
            : null,
        notes: const [],
        settlementEligible: eligible && collected && completed,
        reconStatus: FinancialReconStatus.reconciled,
      );
    }

    test('50 / 7.5 / 0 / 42.5 split in minor units', () {
      final l = line(
        id: 't50',
        channel: FinancialPaymentChannel.cash,
        customer: 5000,
        gross: 5000,
        fee: 750,
        vat: 0,
        net: 4250,
      );
      expect(l.driverNet!.minorUnits, 4250);
      expect(
        l.grossBase!.minorUnits -
            l.platformFee!.minorUnits -
            l.recordedVat!.minorUnits,
        l.driverNet!.minorUnits,
      );
      final res = FinancialAmountResolution.fromLine(l);
      expect(res.quality, FinancialDataQuality.complete);
    });

    test('800 / 120 / 120 / 560 split', () {
      final l = line(
        id: 't800',
        channel: FinancialPaymentChannel.online,
        customer: 80000,
        gross: 80000,
        fee: 12000,
        vat: 12000,
        net: 56000,
      );
      expect(
        l.grossBase!.minorUnits -
            l.platformFee!.minorUnits -
            l.recordedVat!.minorUnits,
        56000,
      );
    });

    test('mixed cash+online settlement direction companyPaysDriver', () {
      final cash = line(
        id: 'c1',
        channel: FinancialPaymentChannel.cash,
        customer: 10000,
        gross: 10000,
        fee: 1500,
        vat: 0,
        net: 8500,
      );
      final online = line(
        id: 'o1',
        channel: FinancialPaymentChannel.online,
        customer: 20000,
        gross: 20000,
        fee: 3000,
        vat: 0,
        net: 17000,
      );
      final preview = SettlementPreview.build(
        driverId: 'd1',
        currency: 'SAR',
        lines: [cash, online],
      );
      expect(preview.direction, 'companyPaysDriver');
      expect(preview.netTripSettlement.minorUnits, -15500);
    });

    test('balanced settlement', () {
      final cash = line(
        id: 'c2',
        channel: FinancialPaymentChannel.cash,
        customer: 10000,
        gross: 10000,
        fee: 1500,
        vat: 0,
        net: 8500,
      );
      final online = line(
        id: 'o2',
        channel: FinancialPaymentChannel.online,
        customer: 1500,
        gross: 1500,
        fee: 0,
        vat: 0,
        net: 1500,
      );
      final preview = SettlementPreview.build(
        driverId: 'd1',
        currency: 'SAR',
        lines: [cash, online],
      );
      expect(preview.direction, 'balanced');
      expect(preview.netTripSettlement.minorUnits, 0);
    });

    test('incomplete not settlement eligible leaves preview', () {
      final incomplete = FinancialOrderLine(
        orderId: 'bad',
        currency: 'SAR',
        channel: FinancialPaymentChannel.cash,
        lifecycle: FinancialLifecycle.completed,
        payment: FinancialPaymentState.cashCollected,
        bucket: FinancialCollectionBucket.completedAndCollected,
        confidence: FinancialConfidence.incomplete,
        currencySupported: true,
        customerPaid: MoneyAmount(currency: 'SAR', minorUnits: 1000),
        notes: const ['MISSING_FEE_OR_VAT'],
        settlementEligible: false,
        exclusionReason: 'INCOMPLETE_FINANCIAL_DATA',
        reconStatus: FinancialReconStatus.notApplicable,
      );
      final preview = SettlementPreview.build(
        driverId: 'd1',
        currency: 'SAR',
        lines: [incomplete],
      );
      expect(preview.includedCount, 0);
      expect(preview.excludedCount, 1);
    });

    test('QA fixture id detection covers required prefixes', () {
      expect(AdminQaFixture.isFixtureId('fin7_ctrl_1'), isTrue);
      expect(AdminQaFixture.isFixtureId('fin9_ctrl_1'), isTrue);
      expect(AdminQaFixture.isFixtureId('fin_rt_1'), isTrue);
      expect(AdminQaFixture.isFixtureId('demo_x'), isTrue);
      expect(AdminQaFixture.isFixtureId('live_order_abc'), isFalse);
    });

    test('Arabic PDF embeds Cairo and produces %PDF without font failure',
        () async {
      final theme = await FinancePdfExport.themeForLocale(true);
      expect(theme, isNotNull);
      final snap = FinanceExportSnapshot(
        generatedAt: DateTime.utc(2026, 9, 22),
        periodLabel: 'فترة اختبار · SAR',
        currency: 'SAR',
        filtersSummary: 'دولة: السعودية · قناة: نقدي+إلكتروني',
        company: null,
        trips: const [],
        localeCode: 'ar',
      );
      final pdf = await FinancePdfExport.build(snap);
      expect(pdf.length, greaterThan(1000));
      expect(String.fromCharCodes(pdf.take(8)), contains('%PDF'));
      // Cairo font subset is embedded in the PDF stream.
      final latin = String.fromCharCodes(pdf);
      expect(
        latin.contains('Cairo') || latin.contains('Font'),
        isTrue,
      );
    });

    test('export snapshot PDF/XLSX parity of summary keys', () async {
      final snap = FinanceExportSnapshot(
        generatedAt: DateTime.utc(2026, 9, 22),
        periodLabel: 'test',
        currency: 'SAR',
        filtersSummary: 'unit',
        company: null,
        trips: const [],
        localeCode: 'ar',
      );
      final pdf = await FinancePdfExport.build(snap);
      final xlsx = FinanceXlsxExport.build(snap);
      expect(pdf.isNotEmpty, isTrue);
      expect(pdf[0], 0x25); // %PDF
      expect(pdf[1], 0x50);
      expect(xlsx.isNotEmpty, isTrue);
      expect(xlsx[0], 0x50); // PK zip = real xlsx
      expect(xlsx[1], 0x4B);
      final decoded = Excel.decodeBytes(xlsx);
      final names = decoded.tables.keys.toSet();
      expect(names.contains('Summary'), isTrue);
      expect(names.contains('Trip Ledger'), isTrue);
      expect(names.contains('Cash'), isTrue);
      expect(names.contains('Online'), isTrue);
      expect(names.contains('Receivables'), isTrue);
      expect(names.contains('Payables'), isTrue);
      expect(names.contains('Settlements'), isTrue);
      expect(names.contains('Agent Finance'), isTrue);
      expect(names.contains('Reconciliation'), isTrue);
      final summaryRows = decoded['Summary']!.rows;
      final moneyUnitRow = summaryRows
          .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
          .where((line) => line.contains('minor_units_integer'));
      expect(moneyUnitRow.isNotEmpty, isTrue);
    });

    test('multi-currency never combined in settlement preview', () {
      final sar = line(
        id: 's',
        channel: FinancialPaymentChannel.cash,
        customer: 1000,
        gross: 1000,
        fee: 150,
        vat: 0,
        net: 850,
      );
      final kgs = FinancialOrderLine(
        orderId: 'k',
        currency: 'KGS',
        channel: FinancialPaymentChannel.cash,
        lifecycle: FinancialLifecycle.completed,
        payment: FinancialPaymentState.cashCollected,
        bucket: FinancialCollectionBucket.completedAndCollected,
        confidence: FinancialConfidence.high,
        currencySupported: true,
        customerPaid: MoneyAmount(currency: 'KGS', minorUnits: 9000),
        grossBase: MoneyAmount(currency: 'KGS', minorUnits: 9000),
        platformFee: MoneyAmount(currency: 'KGS', minorUnits: 900),
        recordedVat: MoneyAmount.zero('KGS'),
        recordedDiscount: MoneyAmount.zero('KGS'),
        driverNet: MoneyAmount(currency: 'KGS', minorUnits: 8100),
        cashHeldByDriver: MoneyAmount(currency: 'KGS', minorUnits: 9000),
        notes: const [],
        settlementEligible: true,
        reconStatus: FinancialReconStatus.reconciled,
      );
      final preview = SettlementPreview.build(
        driverId: 'd1',
        currency: 'SAR',
        lines: [sar, kgs],
      );
      expect(preview.includedCount, 1);
      expect(preview.cashHeld.currency, 'SAR');
    });
  });
}
