# -*- coding: utf-8 -*-
"""Bootstrap Touri Taxi localization: archive extras, fix keys, emit ARB + audit."""
import hashlib
import json
import re
import shutil
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGS = ROOT / 'assets' / 'langs'
ARCHIVE = ROOT / 'assets' / 'langs_archive'
L10N = ROOT / 'lib' / 'l10n'
DOCS_AUDIT = ROOT / 'docs' / 'audits'
PROD = ['en', 'ar', 'ru', 'ky']

ARCHIVE.mkdir(parents=True, exist_ok=True)
L10N.mkdir(parents=True, exist_ok=True)
DOCS_AUDIT.mkdir(parents=True, exist_ok=True)


def load_json(path: Path) -> OrderedDict:
    def hook(pairs):
        d = OrderedDict()
        for k, v in pairs:
            d[k] = v
        return d

    return json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=hook)


archived = []
for p in list(LANGS.glob('*.json')):
    if p.stem not in PROD:
        dest = ARCHIVE / p.name
        if dest.exists():
            dest.unlink()
        shutil.move(str(p), str(dest))
        archived.append(p.stem)
print('Archived locales:', archived)

data = {lang: load_json(LANGS / f'{lang}.json') for lang in PROD}
en = data['en']

CRITICAL_FIXES = {
    'checkout_order_status_pending': {
        'en': 'Waiting for driver acceptance',
        'ar': 'بانتظار قبول السائق',
        'ru': 'Ожидает подтверждения водителя',
        'ky': 'Айдоочунун кабыл алуусун күтүүдө',
    },
    'status_pending_driver': {
        'en': 'Waiting for driver acceptance',
        'ar': 'بانتظار قبول السائق',
        'ru': 'Ожидает подтверждения водителя',
        'ky': 'Айдоочунун кабыл алуусун күтүүдө',
    },
    'status_driver_assigned': {
        'en': 'Driver assigned',
        'ar': 'تم تعيين السائق',
        'ru': 'Водитель назначен',
        'ky': 'Айдоочу дайындалды',
    },
    'status_driver_arrived': {
        'en': 'Driver arrived',
        'ar': 'وصل السائق',
        'ru': 'Водитель прибыл',
        'ky': 'Айдоочу келди',
    },
    'status_trip_started': {
        'en': 'Trip started',
        'ar': 'بدأت الرحلة',
        'ru': 'Поездка началась',
        'ky': 'Сапар башталды',
    },
    'status_trip_completed': {
        'en': 'Trip completed',
        'ar': 'اكتملت الرحلة',
        'ru': 'Поездка завершена',
        'ky': 'Сапар аяктады',
    },
    'status_cancelled': {
        'en': 'Cancelled',
        'ar': 'تم الإلغاء',
        'ru': 'Отменено',
        'ky': 'Жокко чыгарылды',
    },
    'status_payment_pending': {
        'en': 'Payment pending',
        'ar': 'قيد الانتظار',
        'ru': 'Ожидает оплаты',
        'ky': 'Төлөм күтүлүүдө',
    },
    'status_paid': {
        'en': 'Paid',
        'ar': 'تم الدفع',
        'ru': 'Оплачено',
        'ky': 'Төлөндү',
    },
    'status_payment_failed': {
        'en': 'Payment failed',
        'ar': 'فشل الدفع',
        'ru': 'Ошибка оплаты',
        'ky': 'Төлөм ишке ашкан жок',
    },
    'looking_for_destination': {
        'en': 'Looking for a destination...',
        'ar': 'البحث عن وجهة...',
        'ru': 'Поиск пункта назначения...',
        'ky': 'Бара турган жер изделүүдө...',
    },
    'map_selected_location': {
        'en': 'Selected location on map',
        'ar': 'موقع محدد على الخريطة',
        'ru': 'Точка, выбранная на карте',
        'ky': 'Картадан тандалган жер',
    },
    'current_location_label': {
        'en': 'Current location',
        'ar': 'الموقع الحالي',
        'ru': 'Текущее местоположение',
        'ky': 'Учурдагы жайгашуу',
    },
    'pickup_location_label': {
        'en': 'Pickup location',
        'ar': 'نقطة الانطلاق',
        'ru': 'Место отправления',
        'ky': 'Баштапкы пункт',
    },
    'destination_label': {
        'en': 'Destination',
        'ar': 'الوجهة',
        'ru': 'Пункт назначения',
        'ky': 'Бара турган жер',
    },
    'stops_label': {
        'en': 'Stops',
        'ar': 'المحطات',
        'ru': 'Остановки',
        'ky': 'Токтоочу жайлар',
    },
    'view_route_label': {
        'en': 'View route',
        'ar': 'عرض المسار',
        'ru': 'Посмотреть маршрут',
        'ky': 'Багытты көрүү',
    },
    'trip_details_label': {
        'en': 'Trip details',
        'ar': 'تفاصيل الرحلة',
        'ru': 'Детали поездки',
        'ky': 'Сапардын чоо-жайы',
    },
    'choose_payment_method': {
        'en': 'Choose payment method',
        'ar': 'اختر طريقة الدفع',
        'ru': 'Выберите способ оплаты',
        'ky': 'Төлөм ыкмасын тандаңыз',
    },
    'pay_online_option': {
        'en': 'Pay online',
        'ar': 'الدفع الإلكتروني',
        'ru': 'Оплата картой',
        'ky': 'Электрондук төлөм',
    },
    'pay_cash_option': {
        'en': 'Pay with cash',
        'ar': 'الدفع نقداً',
        'ru': 'Оплата наличными',
        'ky': 'Накталай төлөм',
    },
    'driver_fee_label': {
        'en': 'Driver fee',
        'ar': 'رسوم السائق',
        'ru': 'Стоимость услуг водителя',
        'ky': 'Айдоочунун акысы',
    },
    'app_fee_label': {
        'en': 'App fee',
        'ar': 'رسوم التطبيق',
        'ru': 'Комиссия приложения',
        'ky': 'Колдонмонун комиссиясы',
    },
    'vat_label': {
        'en': 'VAT',
        'ar': 'ضريبة القيمة المضافة',
        'ru': 'НДС',
        'ky': 'Кошумча нарк салыгы',
    },
    'total_amount_label': {
        'en': 'Total amount',
        'ar': 'المبلغ الإجمالي',
        'ru': 'Итоговая сумма',
        'ky': 'Жалпы сумма',
    },
    'my_bookings_nav': {
        'en': 'My Bookings',
        'ar': 'حجوزاتي',
        'ru': 'Мои бронирования',
        'ky': 'Менин брондорум',
    },
    'my_account_nav': {
        'en': 'My Account',
        'ar': 'حسابي',
        'ru': 'Мой аккаунт',
        'ky': 'Менин аккаунтум',
    },
    'home_nav': {
        'en': 'Home',
        'ar': 'الرئيسية',
        'ru': 'Главная',
        'ky': 'Башкы бет',
    },
    'error_generic_user': {
        'en': 'Something went wrong. Please try again.',
        'ar': 'حدث خطأ. يرجى المحاولة مرة أخرى.',
        'ru': 'Что-то пошло не так. Попробуйте ещё раз.',
        'ky': 'Бир жерден ката кетти. Кайра аракет кылыңыз.',
    },
    'error_network_user': {
        'en': 'No internet connection. Check your network and try again.',
        'ar': 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.',
        'ru': 'Нет подключения к интернету. Проверьте сеть и попробуйте снова.',
        'ky': 'Интернет байланышы жок. Тармакты текшерип, кайра аракет кылыңыз.',
    },
    'error_location_permission': {
        'en': 'Location permission is required.',
        'ar': 'يلزم السماح بالوصول إلى الموقع.',
        'ru': 'Требуется разрешение на доступ к местоположению.',
        'ky': 'Жайгашууга уруксат керек.',
    },
    'error_route_unavailable': {
        'en': 'Route unavailable',
        'ar': 'المسار غير متاح',
        'ru': 'Маршрут недоступен',
        'ky': 'Багыт жеткиликсиз',
    },
    'error_outside_service_area': {
        'en': 'Outside service area',
        'ar': 'خارج منطقة الخدمة',
        'ru': 'Вне зоны обслуживания',
        'ky': 'Тейлөө аймагынан тышкары',
    },
    'kyrgyz_char_sample': {
        'en': 'Kyrgyz: ң ө ү Ң Ө Ү',
        'ar': 'القرغيزية: ң ө ү Ң Ө Ү',
        'ru': 'Кыргызский: ң ө ү Ң Ө Ү',
        'ky': 'Кыргыз тили: ң ө ү Ң Ө Ү',
    },
    'booking_hours': {
        'en': '{count, plural, =0{No booking hours} one{1 booking hour} other{{count} booking hours}}',
        'ar': '{count, plural, =0{لا توجد ساعات حجز} one{ساعة حجز واحدة} two{ساعتا حجز} few{{count} ساعات حجز} many{{count} ساعة حجز} other{{count} ساعة حجز}}',
        'ru': '{count, plural, =0{Нет часов бронирования} one{{count} час бронирования} few{{count} часа бронирования} many{{count} часов бронирования} other{{count} часа бронирования}}',
        'ky': '{count, plural, =0{Брондоо сааты жок} one{{count} брондоо сааты} other{{count} брондоо сааты}}',
    },
    'minutes_count': {
        'en': '{count, plural, =0{0 minutes} one{1 minute} other{{count} minutes}}',
        'ar': '{count, plural, =0{٠ دقيقة} one{دقيقة واحدة} two{دقيقتان} few{{count} دقائق} many{{count} دقيقة} other{{count} دقيقة}}',
        'ru': '{count, plural, =0{0 минут} one{{count} минута} few{{count} минуты} many{{count} минут} other{{count} минуты}}',
        'ky': '{count, plural, =0{0 мүнөт} one{{count} мүнөт} other{{count} мүнөт}}',
    },
}

for key, translations in CRITICAL_FIXES.items():
    for lang in PROD:
        data[lang][key] = translations[lang]

for lang in PROD:
    for k, v in list(data[lang].items()):
        if isinstance(v, str) and 'Ara Watan' in v:
            data[lang][k] = v.replace('Ara Watan', 'Touri Taxi')

PHRASE_ALIGN = {
    'My current location': {
        'en': 'Current location',
        'ar': 'الموقع الحالي',
        'ru': 'Текущее местоположение',
        'ky': 'Учурдагы жайгашуу',
    },
    'Change': {
        'en': 'Change',
        'ar': 'تغيير',
        'ru': 'Изменить',
        'ky': 'Өзгөртүү',
    },
    'Book now': {
        'en': 'Book now',
        'ar': 'احجز الآن',
        'ru': 'Забронировать',
        'ky': 'Азыр брондоо',
    },
    'Reservations': {
        'en': 'My Bookings',
        'ar': 'حجوزاتي',
        'ru': 'Мои бронирования',
        'ky': 'Менин брондорум',
    },
}
for key, translations in PHRASE_ALIGN.items():
    if key in en:
        for lang in PROD:
            data[lang][key] = translations[lang]

# Ensure key parity with en (track English copies separately)
english_copies = {lang: [] for lang in PROD if lang != 'en'}
for lang in PROD:
    if lang == 'en':
        continue
    for k in list(data['en'].keys()):
        cur = data[lang].get(k)
        if cur is None or not str(cur).strip():
            data[lang][k] = data['en'][k]
            english_copies[lang].append(k)
        elif data[lang][k] == data['en'][k] and str(data['en'][k]).strip():
            english_copies[lang].append(k)

for lang in PROD:
    out = OrderedDict()
    for k in data['en']:
        out[k] = data[lang].get(k, data['en'][k])
    for k, v in data[lang].items():
        if k not in out:
            out[k] = v
    (LANGS / f'{lang}.json').write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
    )

print('Wrote cleaned JSON for', PROD, 'keys=', len(data['en']))


def sanitize_key(raw: str) -> str:
    if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', raw):
        reserved = {
            'continue', 'default', 'assert', 'break', 'case', 'class', 'const',
            'else', 'enum', 'extends', 'false', 'true', 'for', 'if', 'in', 'is',
            'new', 'null', 'return', 'super', 'this', 'throw', 'try', 'var',
            'void', 'while', 'with',
        }
        return f'k_{raw}' if raw in reserved else raw
    s = re.sub(r'[^A-Za-z0-9]+', '_', raw).strip('_')
    if not s:
        s = 'k_' + hashlib.md5(raw.encode()).hexdigest()[:10]
    if s[0].isdigit():
        s = 'n_' + s
    if not re.match(r'^[A-Za-z_]', s):
        s = 'k_' + s
    return s[:80]


keymap = OrderedDict()
used = set()
for raw in data['en'].keys():
    base = sanitize_key(raw)
    cand = base
    i = 2
    while cand in used:
        cand = f'{base}_{i}'
        i += 1
    used.add(cand)
    keymap[cand] = raw


def to_arb(lang: str) -> OrderedDict:
    arb = OrderedDict()
    arb['@@locale'] = lang
    for arb_key, raw_key in keymap.items():
        val = data[lang].get(raw_key, data['en'].get(raw_key, ''))
        arb[arb_key] = val
        meta = {'description': f'UI string (source key: {raw_key})'}
        phs = re.findall(r'\{([a-zA-Z_][a-zA-Z0-9_]*)\}', str(val))
        if 'plural,' in str(val):
            meta['placeholders'] = {'count': {'type': 'num', 'example': '3'}}
            for p in phs:
                if p != 'count':
                    meta.setdefault('placeholders', {})[p] = {'type': 'String'}
        elif phs:
            meta['placeholders'] = {
                p: {'type': 'String', 'example': p} for p in phs
            }
        arb[f'@{arb_key}'] = meta
    return arb


for lang in PROD:
    path = L10N / f'app_{lang}.arb'
    path.write_text(
        json.dumps(to_arb(lang), ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    print('Wrote', path.name)

(L10N / 'easy_key_map.json').write_text(
    json.dumps(keymap, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
)


def nontrivial_identical(lang: str) -> int:
    n = 0
    for k in data['en']:
        v = str(data['en'][k])
        if data[lang].get(k) != v or not v.strip():
            continue
        if v in {'Touri Taxi', 'OK', 'ID', 'VAT', 'SMS', 'GPS', 'N/A'}:
            continue
        if re.fullmatch(r'[\d\W]+', v) or len(v) <= 2:
            continue
        n += 1
    return n


stats = {}
for lang in PROD:
    empty = sum(1 for k in data['en'] if not str(data[lang].get(k, '')).strip())
    real_ident = 0 if lang == 'en' else nontrivial_identical(lang)
    coverage = 100.0 if lang == 'en' else round(
        100.0 * (len(data['en']) - empty - real_ident) / max(1, len(data['en'])), 1
    )
    stats[lang] = {
        'keys': len(data['en']),
        'empty': empty,
        'identical_nontrivial': real_ident,
        'estimated_coverage_pct': coverage,
    }

ky_text = ''.join(str(v) for v in data['ky'].values())
ky_chars = {ch: (ch in ky_text) for ch in list('ңөүҢӨҮ')}

hardcoded_patterns = []
rx = re.compile(r"""Text\(\s*['\"]([^'\"]{2,})['\"]""")
for p in (ROOT / 'lib').rglob('*.dart'):
    try:
        txt = p.read_text(encoding='utf-8')
    except OSError:
        continue
    for m in rx.finditer(txt):
        s = m.group(1)
        if s.startswith(('ui_text_', 'ux_', 'assets/', 'http')):
            continue
        window = txt[max(0, m.start() - 30): m.end() + 20]
        if '.tr(' in window:
            continue
        if re.search(r'[\u0600-\u06FF]', s) or re.search(r'[A-Za-z]{3,}', s):
            hardcoded_patterns.append(
                (str(p.relative_to(ROOT)).replace('\\', '/'), s[:80])
            )

audit_lines = [
    '# Touri Taxi Localization Audit (Initial)',
    '',
    '**Date:** 2026-07-18',
    '**Production customer app:** `admin/ara_oatan_app` (Touri Taxi)',
    '**Production driver app:** `admin/mndob-main`',
    '**Stale duplicates ignored:** `ara/mndob-main`, `arawatan/` (redirect only)',
    '',
    '## Localization architecture (before fix)',
    '',
    '- Dual stack: **EasyLocalization** (`assets/langs/*.json`) + FlutterFlow **FFLocalizations**',
    '- No `l10n.yaml` / ARB / `flutter gen-l10n` initially',
    '- Locale discovery from JSON assets (11 languages including fr, tr, ur, az, ka, id, zh-Hans)',
    '- Persistence: SharedPreferences `__locale_key__` + Firestore `preferred_locale`',
    '- Fallback: English (silent for missing FF / notifications)',
    '',
    '## Required languages',
    '',
    '| Code | Name |',
    '|------|------|',
    '| ar | العربية |',
    '| en | English |',
    '| ru | Русский |',
    '| ky | Кыргызча |',
    '',
    '## Languages found before fix',
    '',
    'en, ar, ru, ky, fr, tr, ur, az, ka, id, zh-Hans',
    '',
    f'**Archived out of runtime assets:** {", ".join(archived) if archived else "(none)"}',
    '',
    '## Completeness (after JSON key parity pass)',
    '',
    '| Language | Keys | Empty | Identical to EN (nontrivial) | Est. coverage |',
    '|----------|------|-------|------------------------------|---------------|',
]
for lang, label in [('en', 'English'), ('ar', 'Arabic'), ('ru', 'Russian'), ('ky', 'Kyrgyz')]:
    s = stats[lang]
    audit_lines.append(
        f"| {label} | {s['keys']} | {s['empty']} | {s['identical_nontrivial']} | {s['estimated_coverage_pct']}% |"
    )

audit_lines += [
    '',
    '## Critical issues discovered',
    '',
    '### Severity: Critical',
    '1. Order details show raw Arabic `halhText` from Firestore.',
    '2. Status strings stored as Arabic human text instead of codes.',
    '3. FF entry `6bdi3tuo` = "Looking for a teacher".',
    '4. Corrupted FF glyphs in some map category strings.',
    '5. `checkout_order_status_pending` was English in ar/ru/ky.',
    '6. Notification localizer silently falls back to English.',
    '7. FF `getText` / `getVariableText` silently fall back to English.',
    '8. Extra languages (fr, …) exposed in picker.',
    '9. Cairo-only fonts risk missing Kyrgyz/Cyrillic glyphs.',
    '10. Legacy "Ara Watan" brand strings.',
    '',
    '### Severity: High',
    '- Hardcoded Arabic UI in map/places/schedule/support.',
    '- Dual translation systems diverge.',
    '- Phrase keys require ARB sanitization map.',
    '- Driver app writes Arabic `halh_text` constants.',
    '',
    f'## Hardcoded Text(...) candidates: **{len(hardcoded_patterns)}**',
    '',
]
for path, s in hardcoded_patterns[:40]:
    audit_lines.append(f'- `{path}`: `{s}`')

audit_lines += [
    '',
    '## Kyrgyz character presence',
    '',
    '```json',
    json.dumps(ky_chars, ensure_ascii=False, indent=2),
    '```',
    '',
    '## Next steps',
    '',
    '1. `l10n.yaml` + gen-l10n',
    '2. Restrict locales to ar/en/ru/ky',
    '3. Status/payment/error localizers',
    '4. Replace raw `halhText` UI',
    '5. Fonts + tools + tests + reports',
    '',
]
(DOCS_AUDIT / 'touri_localization_audit.md').write_text(
    '\n'.join(audit_lines), encoding='utf-8'
)
(ROOT / 'docs' / 'localization').mkdir(parents=True, exist_ok=True)
(ROOT / 'docs' / 'localization' / 'english_copy_keys.json').write_text(
    json.dumps(english_copies, ensure_ascii=False, indent=2) + '\n',
    encoding='utf-8',
)
print('Audit written')
print(json.dumps(stats, ensure_ascii=False, indent=2))
print('Hardcoded candidates:', len(hardcoded_patterns))
