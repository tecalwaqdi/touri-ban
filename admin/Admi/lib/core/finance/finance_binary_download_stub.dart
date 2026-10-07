import 'dart:typed_data';

Future<void> downloadFinanceBytes({
  required Uint8List bytes,
  required String filename,
  required String mime,
}) async {
  throw UnsupportedError('downloadFinanceBytes requires web or stub override');
}
