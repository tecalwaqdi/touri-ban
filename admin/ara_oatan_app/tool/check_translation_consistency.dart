// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final glossary = <String, Map<String, String>>{
    'current_location_label': {
      'ar': 'الموقع الحالي',
      'en': 'Current location',
      'ru': 'Текущее местоположение',
      'ky': 'Учурдагы жайгашуу',
    },
    'view_route_label': {
      'ar': 'عرض المسار',
      'en': 'View route',
      'ru': 'Посмотреть маршрут',
      'ky': 'Багытты көрүү',
    },
    'pay_cash_option': {
      'ar': 'الدفع نقداً',
      'en': 'Pay with cash',
      'ru': 'Оплата наличными',
      'ky': 'Накталай төлөм',
    },
    'my_bookings_nav': {
      'ar': 'حجوزاتي',
      'en': 'My Bookings',
      'ru': 'Мои бронирования',
      'ky': 'Менин брондорум',
    },
    'status_pending_driver': {
      'ar': 'بانتظار قبول السائق',
      'en': 'Waiting for driver acceptance',
      'ru': 'Ожидает подтверждения водителя',
      'ky': 'Айдоочунун кабыл алуусун күтүүдө',
    },
  };

  final errors = <String>[];
  for (final locale in ['en', 'ar', 'ru', 'ky']) {
    final map = jsonDecode(
      File('${Directory.current.path}/assets/langs/$locale.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final entry in glossary.entries) {
      final expected = entry.value[locale]!;
      final actual = map[entry.key]?.toString();
      if (actual != expected) {
        errors.add(
          '${entry.key}@$locale expected "$expected" got "${actual ?? "MISSING"}"',
        );
      }
    }
  }

  if (errors.isEmpty) {
    print('check_translation_consistency: OK');
    exit(0);
  }
  print('check_translation_consistency: FAIL');
  for (final e in errors) {
    print(' - $e');
  }
  exit(1);
}
