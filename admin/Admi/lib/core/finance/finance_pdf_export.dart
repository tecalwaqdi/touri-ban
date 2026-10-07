import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '/core/finance/finance_export_snapshot.dart';

/// Dedicated PDF builder — numbers only from [FinanceExportSnapshot].
///
/// Arabic production requires embedded Cairo TTF (project asset). Fail closed
/// when Arabic is requested and fonts cannot be loaded (no tofu/default Helvetica).
abstract final class FinancePdfExport {
  FinancePdfExport._();

  static const _cairoRegularAsset = 'assets/fonts/Cairo-Regular.ttf';
  static const _cairoBoldAsset = 'assets/fonts/Cairo-Bold.ttf';

  static Future<Uint8List> build(FinanceExportSnapshot snap) async {
    final doc = pw.Document();
    final isAr = snap.localeCode.toLowerCase().startsWith('ar');
    final summary = snap.summaryLabelsAr().entries.toList();
    final theme = await themeForLocale(isAr);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              isAr ? 'تقرير مالي — Toury' : 'Toury Finance Report',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${snap.periodLabel} · ${snap.currency} · ${snap.filtersSummary}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Generated: ${snap.generatedAt.toIso8601String()}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.Divider(),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: isAr ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: pw.Text(
            isAr
                ? 'صفحة ${ctx.pageNumber}/${ctx.pagesCount}'
                : 'Page ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (ctx) => [
          pw.Text(
            isAr ? 'ملخص' : 'Summary',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [isAr ? 'البند' : 'Metric', isAr ? 'القيمة' : 'Value'],
            data: summary.map((e) => [e.key, e.value]).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerRight,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            isAr ? 'دفتر الرحلات' : 'Trip Ledger',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'ID',
              isAr ? 'قناة' : 'Ch',
              isAr ? 'أساسي' : 'Gross',
              isAr ? 'عمولة' : 'Fee',
              isAr ? 'ضريبة' : 'VAT',
              isAr ? 'صافي' : 'Net',
              isAr ? 'جودة' : 'Q',
            ],
            data: snap.trips
                .map(
                  (t) => [
                    t.tripRefLabel,
                    t.paymentChannelLabel,
                    t.grossDisplay,
                    t.companyCommissionDisplay,
                    t.vatDisplay,
                    t.driverNetDisplay,
                    t.dataQualityLabel,
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerRight,
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Visible for tests — Arabic must embed Cairo.
  static Future<pw.ThemeData?> themeForLocale(bool arabic) async {
    if (!arabic) return null;
    final regular = await loadFontBytes(_cairoRegularAsset);
    final bold = await loadFontBytes(_cairoBoldAsset);
    if (regular == null || bold == null) {
      throw StateError(
        'PDF_ARABIC_FONT_MISSING: embed Cairo assets before Arabic export',
      );
    }
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }

  static Future<ByteData?> loadFontBytes(String assetPath) async {
    try {
      return await rootBundle.load(assetPath);
    } catch (_) {
      try {
        final file = File(assetPath);
        if (!file.existsSync()) return null;
        final bytes = file.readAsBytesSync();
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      } catch (_) {
        return null;
      }
    }
  }
}
