# -*- coding: utf-8 -*-
import json
from pathlib import Path

PROD = ['en', 'ar', 'ru', 'ky']
data = {
    l: json.loads(Path(f'assets/langs/{l}.json').read_text(encoding='utf-8'))
    for l in PROD
}

fixes = {
    'ux_step_trip_type': {
        'en': 'Trip type',
        'ar': 'نوع الرحلة',
        'ru': 'Тип поездки',
        'ky': 'Сапардын түрү',
    },
    'ux_step_details': {
        'en': 'Details',
        'ar': 'التفاصيل',
        'ru': 'Детали',
        'ky': 'Чоо-жайы',
    },
    'ux_step_payment': {
        'en': 'Payment',
        'ar': 'الدفع',
        'ru': 'Оплата',
        'ky': 'Төлөм',
    },
    'ux_choose_trip_type': {
        'en': 'How do you want to explore?',
        'ar': 'كيف تريد الاستكشاف؟',
        'ru': 'Как вы хотите путешествовать?',
        'ky': 'Кантип изилдегиңиз келет?',
    },
    'ux_new_booking': {
        'en': 'Book a new trip',
        'ar': 'احجز رحلة جديدة',
        'ru': 'Забронировать новую поездку',
        'ky': 'Жаңы сапарды брондоо',
    },
    'landmarks_custom_banner': {
        'en': "Can't find your place? Add a custom location on the map",
        'ar': 'لم تجد مكانك؟ أضف موقعاً مخصصاً على الخريطة',
        'ru': 'Не нашли нужное место? Добавьте точку на карте',
        'ky': 'Жериңизди таппадыңызбы? Картадан өзүңүз кошуңуз',
    },
    'landmarks_custom_list_title': {
        'en': "Can't find your place in the list?",
        'ar': 'لم تجد مكانك في القائمة؟',
        'ru': 'Не нашли место в списке?',
        'ky': 'Тизмеден жериңизди таппадыңызбы?',
    },
    'checkout_complete_options_prompt': {
        'en': 'Complete all options or add more hours to match your trip',
        'ar': 'أكمل كل الخيارات أو أضف ساعات إضافية لتناسب رحلتك',
        'ru': 'Заполните все параметры или добавьте часы под вашу поездку',
        'ky': 'Бардык параметрлерди толтуруңуз же сапарга саат кошуңуз',
    },
    'wallet_tx_transfer': {
        'en': 'Transfer',
        'ar': 'تحويل',
        'ru': 'Перевод',
        'ky': 'Которуу',
    },
    'Welcome to Become a Success Partner': {
        'en': 'Welcome to Become a Success Partner',
        'ar': 'مرحباً بك كشريك نجاح',
        'ru': 'Добро пожаловать в программу партнёров',
        'ky': 'Ийгилик өнөктөштүгүнө кош келиңиз',
    },
    'Join us as a Success Partner to enhance our service quality and accelerate outreach, whether you are a government entity, a company, or an individual.': {
        'en': 'Join us as a Success Partner to enhance our service quality and accelerate outreach, whether you are a government entity, a company, or an individual.',
        'ar': 'انضم إلينا كشريك نجاح لتحسين جودة الخدمة وتوسيع الوصول، سواء كنت جهة حكومية أو شركة أو فرداً.',
        'ru': 'Присоединяйтесь как партнёр, чтобы улучшить качество сервиса и расширить охват — для госучреждений, компаний и частных лиц.',
        'ky': 'Кызмат сапатын жогорулатуу жана камтууну кеңейтүү үчүн өнөктөш болуңуз — мамлекеттик орган, компания же жеке адам.',
    },
    'Planning for a longer trip? Add more hours and enjoy the ride!': {
        'en': 'Planning for a longer trip? Add more hours and enjoy the ride!',
        'ar': 'تخطط لرحلة أطول؟ أضف المزيد من الساعات واستمتع بالرحلة!',
        'ru': 'Планируете более длинную поездку? Добавьте часы и наслаждайтесь поездкой!',
        'ky': 'Узунураак сапарды пландап жатасызбы? Саат кошуп, сапардан ырахат алыңыз!',
    },
    'Select My Own Tour Route': {
        'en': 'Select my own tour route',
        'ar': 'اختيار مساري السياحي',
        'ru': 'Выбрать свой маршрут',
        'ky': 'Өз багытымды тандоо',
    },
    'Get Help from the Driver Guide': {
        'en': 'Get help from the driver guide',
        'ar': 'الاستعانة بدليل السائق',
        'ru': 'Помощь водителя-гида',
        'ky': 'Айдоочу-гиддин жардамы',
    },
    'Outside your city prices are agreed upon with the captain': {
        'en': 'Outside your city, prices are agreed with the driver',
        'ar': 'خارج مدينتك يتم الاتفاق على الأسعار مع السائق',
        'ru': 'За пределами города цена согласовывается с водителем',
        'ky': 'Шаардын сыртында баа айдоочу менен макулдашылат',
    },
}

for key, translations in fixes.items():
    for lang in PROD:
        data[lang][key] = translations[lang]

for lang in PROD:
    Path(f'assets/langs/{lang}.json').write_text(
        json.dumps(data[lang], ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

print('patched leftover UI strings')
