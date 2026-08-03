"""Extract single-line Arabic UI string literals from Dart widgets."""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1] / 'lib'
skip = {
    'internationalization.dart',
    'admin_translations.dart',
    'nav_translations.dart',
    'ui_catalog.dart',
    'admin_production_seed_data.dart',
    'admin_production_landmark_seed.dart',
    'admin_demo_seed.dart',
}

UI_HINTS = (
    'Text(',
    'title:',
    'subtitle:',
    'label:',
    'labelText:',
    'hintText:',
    'placeholder:',
    'message:',
    'feature:',
    'emptyMessage:',
    'searchHint:',
    'sectionTitle:',
    'SnackBar',
    'AlertDialog',
    'AdminContentCard',
    'AdminPrimaryButton',
    'AdminTextField',
    'InputDecoration',
    'validator:',
    'child: Text',
)

pat = re.compile(r"['\"]([^'\"]*[\u0600-\u06FF][^'\"]*)['\"]")
found = set()

for path in root.rglob('*.dart'):
    if path.name in skip or 'l10n' in path.parts:
        continue
    if 'backend' in path.parts:
        if path.name not in (
            'admin_login_flow.dart',
            'admin_user_creation.dart',
            'admin_super_admin_gate.dart',
        ):
            continue
    for line in path.read_text(encoding='utf-8').splitlines():
        if not any(h in line for h in UI_HINTS):
            continue
        if 'uiTr(' in line or 'appTr(' in line or 'getText(' in line:
            continue
        for m in pat.finditer(line):
            s = m.group(1).strip()
            if 1 < len(s) <= 120 and '$' not in s:
                found.add(s)

out = root.parent / 'tools' / 'arabic_ui_strings.txt'
out.write_text('\n'.join(sorted(found, key=len)), encoding='utf-8')
print(len(found))
