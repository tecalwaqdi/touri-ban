# -*- coding: utf-8 -*-
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

extra_json = {
    'landmark_cat_all': {
        'en': 'All',
        'ar': 'الكل',
        'ru': 'Все',
        'ky': 'Баары',
    },
    'landmark_cat_religious': {
        'en': 'Religious landmarks',
        'ar': 'معالم دينية',
        'ru': 'Религиозные места',
        'ky': 'Диний жерлер',
    },
    'landmark_cat_entertainment': {
        'en': 'Entertainment',
        'ar': 'أماكن ترفيهية',
        'ru': 'Развлечения',
        'ky': 'Оюн-зоок жайлары',
    },
    'landmark_cat_tourism': {
        'en': 'Tourist landmarks',
        'ar': 'معالم سياحية',
        'ru': 'Туристические места',
        'ky': 'Туристтик жерлер',
    },
    'landmark_cat_historical': {
        'en': 'Historical landmarks',
        'ar': 'معالم تاريخية',
        'ru': 'Исторические места',
        'ky': 'Тарыхый жерлер',
    },
    'landmark_search_hint': {
        'en': 'Search for a place or landmark',
        'ar': 'البحث عن مكان أو معلم',
        'ru': 'Поиск места или достопримечательности',
        'ky': 'Жерди же туристтик жайды издөө',
    },
    'trip_scheduling': {
        'en': 'Trip scheduling',
        'ar': 'جدولة الرحلة',
        'ru': 'Планирование поездки',
        'ky': 'Сапарды пландоо',
    },
    'payment_method_label': {
        'en': 'Payment method',
        'ar': 'طريقة الدفع',
        'ru': 'Способ оплаты',
        'ky': 'Төлөм ыкмасы',
    },
}

for lang in ['en', 'ar', 'ru', 'ky']:
    path = ROOT / 'assets' / 'langs' / f'{lang}.json'
    data = json.loads(path.read_text(encoding='utf-8'))
    for key, translations in extra_json.items():
        data[key] = translations[lang]
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

print('JSON category keys added')

ff_path = ROOT / 'lib' / 'flutter_flow' / 'internationalization.dart'
text = ff_path.read_text(encoding='utf-8')


def replace_block(src: str, key: str, new_block: str) -> str:
    pattern = rf"'{key}': \{{.*?\}},\n"
    match = re.search(pattern, src, flags=re.S)
    if not match:
        print('NOT FOUND', key)
        return src
    print('patched', key)
    return src[: match.start()] + new_block + src[match.end() :]


text = replace_block(
    text,
    'q0xxfq1y',
    """    'q0xxfq1y': {
      'en': 'My trip list',
      'ar': 'قائمة رحلاتي',
      'ru': 'Мой список поездок',
      'ky': 'Менин сапарларымдын тизмеси',
    },
""",
)
text = replace_block(
    text,
    'jdq5i83p',
    """    'jdq5i83p': {
      'en': 'Total Amount:',
      'ar': 'المبلغ الإجمالي:',
      'ru': 'Общая сумма:',
      'ky': 'Жалпы сумма:',
    },
""",
)
text = replace_block(
    text,
    '3im46sag',
    """    '3im46sag': {
      'en': 'List of added locations.',
      'ar': 'قائمة المواقع المضافة.',
      'ru': 'Список добавленных локаций.',
      'ky': 'Кошулган жерлердин тизмеси.',
    },
""",
)
text = replace_block(
    text,
    'hgw4quay',
    """    'hgw4quay': {
      'en': 'Pay Now',
      'ar': 'الدفع الآن',
      'ru': 'Оплатить сейчас',
      'ky': 'Азыр төлөө',
    },
""",
)

# Ensure Looking for destination keeps ky
text = replace_block(
    text,
    '6bdi3tuo',
    """    '6bdi3tuo': {
      'en': 'Looking for a destination...',
      'ar': 'البحث عن وجهة...',
      'ru': 'Поиск пункта назначения...',
      'ky': 'Бара турган жер изделүүдө...',
    },
""",
)

ff_path.write_text(text, encoding='utf-8')
print('FF patches written')
