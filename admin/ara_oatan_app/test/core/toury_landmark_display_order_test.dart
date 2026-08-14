import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_landmark_display_order.dart';

void main() {
  test('Masjid al-Haram aliases are recognized', () {
    expect(
      TouryLandmarkDisplayOrder.isMasjidAlHaramName('المسجد الحرام'),
      isTrue,
    );
    expect(
      TouryLandmarkDisplayOrder.isMasjidAlHaramName('Masjid al-Haram'),
      isTrue,
    );
    expect(
      TouryLandmarkDisplayOrder.isMasjidAlHaramName('Al-Masjid Al-Haram'),
      isTrue,
    );
  });

  test('other mosques are not pinned', () {
    expect(
      TouryLandmarkDisplayOrder.isMasjidAlHaramName('المسجد النبوي'),
      isFalse,
    );
    expect(
      TouryLandmarkDisplayOrder.isMasjidAlHaramName('مسجد التنعيم'),
      isFalse,
    );
    expect(
      TouryLandmarkDisplayOrder.isMasjidAlHaramName('أبراج البيت'),
      isFalse,
    );
  });
}
