import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/toury_notification_localizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('localeFromPreferred maps production codes', () {
    expect(TouryNotificationLocalizer.localeFromPreferred('ur-PK'), 'ur');
    expect(TouryNotificationLocalizer.localeFromPreferred('fr_FR'), 'fr');
    expect(TouryNotificationLocalizer.localeFromPreferred(''), 'en');
    expect(TouryNotificationLocalizer.localeFromPreferred('xx'), 'en');
  });

  test('customer push strings resolve by preferredLocale', () async {
    final ar = await TouryNotificationLocalizer.text(
      'ar',
      'notification_order_accepted_title',
    );
    expect(ar, 'تم قبول الطلب');

    final urBody = await TouryNotificationLocalizer.text(
      'ur',
      'notification_driver_arrived_body',
      args: {'driver': 'أحمد'},
    );
    expect(urBody.contains('أحمد'), isTrue);
    expect(urBody.toLowerCase().contains('arrived'), isFalse);

    final fr = await TouryNotificationLocalizer.text(
      'fr',
      'notification_order_cancelled_by_driver_body',
    );
    expect(fr.toLowerCase().contains('cancelled by the driver'), isFalse);
  });
}
