import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadFinanceBytes({
  required Uint8List bytes,
  required String filename,
  required String mime,
}) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
