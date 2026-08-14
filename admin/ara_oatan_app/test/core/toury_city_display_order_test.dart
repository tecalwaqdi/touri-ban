import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_city_display_order.dart';

void main() {
  test('Saudi cities rank in the requested display order', () {
    const names = [
      'مكة المكرمة',
      'المدينة المنورة',
      'الطائف',
      'جدة',
      'الرياض',
      'الدمام',
      'تبوك',
      'الخبر',
      'أبها',
    ];
    for (var i = 0; i < names.length; i++) {
      expect(TouryCityDisplayOrder.rankForName(names[i]), i, reason: names[i]);
    }
  });

  test('English and alternate spellings map to the same ranks', () {
    expect(TouryCityDisplayOrder.rankForName('Makkah'), 0);
    expect(TouryCityDisplayOrder.rankForName('Madinah'), 1);
    expect(TouryCityDisplayOrder.rankForName('Taif'), 2);
    expect(TouryCityDisplayOrder.rankForName('Jeddah'), 3);
    expect(TouryCityDisplayOrder.rankForName('Riyadh'), 4);
    expect(TouryCityDisplayOrder.rankForName('Dammam'), 5);
    expect(TouryCityDisplayOrder.rankForName('Tabuk'), 6);
    expect(TouryCityDisplayOrder.rankForName('Khobar'), 7);
    expect(TouryCityDisplayOrder.rankForName('Abha'), 8);
    expect(TouryCityDisplayOrder.rankForName('ابها'), 8);
  });

  test('unknown cities rank after the pinned list', () {
    expect(
      TouryCityDisplayOrder.rankForName('القصيم'),
      TouryCityDisplayOrder.unranked,
    );
  });
}
