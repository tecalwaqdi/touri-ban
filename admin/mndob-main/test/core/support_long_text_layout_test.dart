import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSupport(WidgetTester tester, String text, TextDirection direction) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: Row(
                  children: [
                    const Icon(Icons.contact_support_outlined, size: 24),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                        child: Text(text, softWrap: true, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final box = tester.getSize(find.text(text));
    expect(box.width, greaterThan(40));
    expect(box.height, greaterThan(16));
    expect(box.height, lessThan(160));
  }

  testWidgets('long English support text wraps', (tester) async {
    await pumpSupport(
      tester,
      'Having a problem? Contact us directly through your country support.',
      TextDirection.ltr,
    );
  });

  testWidgets('long Kyrgyz support text wraps', (tester) async {
    await pumpSupport(
      tester,
      'Көйгөй чыктыбы? Өлкөңүздүн колдоо кызматы аркылуу түз байланышыңыз.',
      TextDirection.ltr,
    );
  });

  testWidgets('long Russian support text wraps', (tester) async {
    await pumpSupport(
      tester,
      'Возникла проблема? Свяжитесь с нами напрямую через службу поддержки.',
      TextDirection.ltr,
    );
  });

  testWidgets('long French support text wraps', (tester) async {
    await pumpSupport(
      tester,
      'Un problème ? Contactez-nous directement via le support de votre pays.',
      TextDirection.ltr,
    );
  });

  testWidgets('long Portuguese support text wraps', (tester) async {
    await pumpSupport(
      tester,
      'Tem um problema? Fale conosco diretamente pelo suporte do seu país.',
      TextDirection.ltr,
    );
  });

  testWidgets('Arabic support text stays RTL', (tester) async {
    await pumpSupport(
      tester,
      'هل تواجه مشكلة؟ تواصل معنا مباشرة.',
      TextDirection.rtl,
    );
  });

  testWidgets('Urdu support text stays RTL', (tester) async {
    await pumpSupport(
      tester,
      'مسئلہ ہے؟ براہ راست ہم سے رابطہ کریں۔',
      TextDirection.rtl,
    );
  });
}
