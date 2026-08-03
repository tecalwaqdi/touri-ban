"""Generate lib/l10n/ui_catalog.dart from Arabic strings + English map."""
import hashlib
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
STRINGS_FILE = ROOT / 'tools' / 'arabic_ui_strings.txt'
EN_MAP_FILE = ROOT / 'tools' / 'ui_en_map.json'
OUT = ROOT / 'lib' / 'l10n' / 'ui_catalog.dart'


def slug(s: str) -> str:
    return 'ui_' + hashlib.md5(s.encode('utf-8')).hexdigest()[:10]


def main():
    lines = [
        l.strip()
        for l in STRINGS_FILE.read_text(encoding='utf-8').splitlines()
        if l.strip()
    ]
    en_map = json.loads(EN_MAP_FILE.read_text(encoding='utf-8'))

    catalog = {}
    lookup = {}
    for ar in lines:
        key = slug(ar)
        en = en_map.get(ar, ar).replace("'", "\\'")
        esc_ar = ar.replace("'", "\\'")
        catalog[key] = {
            'en': en,
            'ar': esc_ar,
            'zh_Hans': en,
            'tr': en,
            'ur': en,
            'ru': en,
            'az': en,
            'ka': en,
        }
        lookup[ar] = key

    parts = [
        "import 'package:flutter/material.dart';",
        "import '/flutter_flow/internationalization.dart';",
        '',
        'const kUiCatalog = <String, Map<String, String>>{',
    ]
    for key, langs in sorted(catalog.items()):
        parts.append(f"  '{key}': {{")
        for lang, val in langs.items():
            parts.append(f"    '{lang}': '{val}',")
        parts.append('  },')
    parts.append('};')
    parts.append('')
    parts.append('const kArabicUiLookup = <String, String>{')
    for ar, key in sorted(lookup.items(), key=lambda x: x[0]):
        esc = ar.replace("'", "\\'")
        parts.append(f"  '{esc}': '{key}',")
    parts.append('};')
    parts.append('')
    parts.append('String uiTr(BuildContext context, String arabic) {')
    parts.append('  final key = kArabicUiLookup[arabic];')
    parts.append('  if (key != null) {')
    parts.append('    final text = FFLocalizations.of(context).getText(key);')
    parts.append('    if (text.isNotEmpty) return text;')
    parts.append('  }')
    parts.append('  return arabic;')
    parts.append('}')
    parts.append('')

    OUT.write_text('\n'.join(parts), encoding='utf-8')
    missing = [ar for ar in lines if ar not in en_map]
    print(f'Wrote {len(lines)} entries, missing EN: {len(missing)}')


if __name__ == '__main__':
    main()
