# -*- coding: utf-8 -*-
import re
from pathlib import Path

ff = Path('lib/flutter_flow/internationalization.dart')
text = ff.read_text(encoding='utf-8')

def replace_block(src, key, new_block):
    pattern = rf"'{key}': \{{.*?\}},\n"
    m = re.search(pattern, src, flags=re.S)
    if not m:
        print('NOT FOUND', key)
        return src
    print('patched', key)
    return src[:m.start()] + new_block + src[m.end():]

patches = {
    '04e2w4m3': """    '04e2w4m3': {
      'en': 'Trip scheduling',
      'ar': 'جدولة الرحلة',
      'ru': 'Планирование поездки',
      'ky': 'Сапарды пландоо',
    },
""",
    '97gi9omv': """    '97gi9omv': {
      'en': 'Payment method.',
      'ar': 'طريقة الدفع.',
      'ru': 'Способ оплаты.',
      'ky': 'Төлөм ыкмасы.',
    },
""",
    '4pp7yghj': """    '4pp7yghj': {
      'en': 'Book now',
      'ar': 'احجز الآن',
      'ru': 'Забронировать',
      'ky': 'Азыр брондоо',
    },
""",
    '6o9re56s': """    '6o9re56s': {
      'en': 'Book now',
      'ar': 'احجز الآن',
      'ru': 'Забронировать',
      'ky': 'Азыр брондоо',
    },
""",
    'k3s4rdw2': """    'k3s4rdw2': {
      'en': 'View route',
      'ar': 'عرض المسار',
      'ru': 'Посмотреть маршрут',
      'ky': 'Багытты көрүү',
    },
""",
}

for key, block in patches.items():
    text = replace_block(text, key, block)

ff.write_text(text, encoding='utf-8')
print('done')
