import 'package:ara_oatan_app/core/toury_image.dart';
import 'package:ara_oatan_app/core/toury_ngenius.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  group('touryPrioritizeReliableImageUrls', () {
    test('يفضّل روابط Firebase Storage على JetAdmin', () {
      const firebase =
          'https://firebasestorage.googleapis.com/v0/b/tutorial-multi-language-70gx4j.firebasestorage.app/o/mkan%2Fa.jpg?alt=media';
      const google =
          'https://firebasestorage.googleapis.com/v0/b/tutorial-multi-language-70gx4j.firebasestorage.app/o/mkan%2Fa.jpg?alt=media';
      const jetadmin = 'https://cdn-api.jetadmin.app/files/abc.jpg';
      final sorted = touryPrioritizeReliableImageUrls([
        google,
        jetadmin,
        firebase,
      ]);
      expect(sorted.first, firebase);
      expect(sorted.last, jetadmin);
    });
  });

  group('TouryNGeniusService', () {
    test('يقرأ حالة الدفع من كائن واحد', () {
      const body = {'id': 'pay_1', 'status': 'paid'};
      expect(TouryNGeniusService.status(body), 'paid');
      expect(TouryNGeniusService.paymentId(body), 'pay_1');
      expect(TouryNGeniusService.isPaid(body), isTrue);
    });

    test('يقرأ حالة الدفع الفاشلة', () {
      const body = {'id': 'pay_2', 'status': 'failed'};
      expect(TouryNGeniusService.status(body), 'failed');
      expect(TouryNGeniusService.isPaid(body), isFalse);
      expect(TouryNGeniusService.isFailed(body), isTrue);
    });
  });
}
