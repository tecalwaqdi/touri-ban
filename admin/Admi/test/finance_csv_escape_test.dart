import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/core/finance/csv_export.dart';

void main() {
  group('financeCsvEscape formula injection', () {
    test('neutralizes leading formula characters', () {
      expect(financeCsvEscape('=1+1'), "'=1+1");
      expect(financeCsvEscape('+cmd'), "'+cmd");
      expect(financeCsvEscape('-2'), "'-2");
      expect(financeCsvEscape('@SUM'), "'@SUM");
    });

    test('quotes commas and keeps safe text', () {
      expect(financeCsvEscape('hello'), 'hello');
      expect(financeCsvEscape('a,b'), '"a,b"');
      expect(financeCsvEscape('say "hi"'), '"say ""hi"""');
    });
  });
}
