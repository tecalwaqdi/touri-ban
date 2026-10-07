import 'dart:typed_data';

import 'finance_binary_download_stub.dart'
    if (dart.library.html) 'finance_binary_download_web.dart' as impl;

/// Web-first binary download for PDF/XLSX finance exports.
abstract final class FinanceBinaryDownload {
  FinanceBinaryDownload._();

  static Future<void> download({
    required Uint8List bytes,
    required String filename,
    required String mime,
  }) =>
      impl.downloadFinanceBytes(
        bytes: bytes,
        filename: filename,
        mime: mime,
      );
}
