"""Replace hardcoded Arabic UI literals with uiTr(context, ...)."""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1] / 'lib'
EN_MAP = json.loads(
    (ROOT.parent / 'tools' / 'ui_en_map.json').read_text(encoding='utf-8')
)
STRINGS = set(EN_MAP.keys())

skip_dirs = {'l10n', 'flutter_flow'}
skip_files = {'internationalization.dart'}

pat = re.compile(r"(const\s+)?Text\(\s*'((?:\\'|[^'])*)'\s*\)")
pat2 = re.compile(
    r"(title|subtitle|label|labelText|hintText|placeholder|feature|"
    r"emptyMessage|searchHint|sectionTitle|message):\s*'((?:\\'|[^'])*)'"
)
pat3 = re.compile(r"child:\s*const\s+Text\('((?:\\'|[^'])*)'\)")


def needs_import(text: str) -> bool:
    return 'uiTr(' in text and 'flutter_flow_util.dart' not in text


def add_import(text: str) -> str:
    if 'flutter_flow_util.dart' in text:
        return text
    for i, line in enumerate(text.splitlines(keepends=True)):
        if line.startswith('import '):
            return ''.join(text.splitlines(keepends=True)[: i + 1]) + (
                "import '/flutter_flow/flutter_flow_util.dart';\n"
            ) + ''.join(text.splitlines(keepends=True)[i + 1 :])
    return "import '/flutter_flow/flutter_flow_util.dart';\n" + text


def replace_in_file(path: pathlib.Path) -> bool:
    text = path.read_text(encoding='utf-8')
    orig = text

    def sub_text(m):
        const_kw = m.group(1) or ''
        s = m.group(2).replace("\\'", "'")
        if s not in STRINGS:
            return m.group(0)
        if const_kw:
            return f"Text(uiTr(context, '{s.replace(chr(39), chr(92)+chr(39))}'))"
        return f"Text(uiTr(context, '{s.replace(chr(39), chr(92)+chr(39))}'))"

    def sub_field(m):
        field = m.group(1)
        s = m.group(2).replace("\\'", "'")
        if s not in STRINGS:
            return m.group(0)
        esc = s.replace("'", "\\'")
        return f"{field}: uiTr(context, '{esc}')"

    text = pat.sub(sub_text, text)
    text = pat2.sub(sub_field, text)
    text = pat3.sub(
        lambda m: (
            f"child: Text(uiTr(context, '{m.group(1).replace(chr(39), chr(92)+chr(39))}'))"
            if m.group(1) in STRINGS
            else m.group(0)
        ),
        text,
    )

    if text != orig:
        if needs_import(text):
            text = add_import(text)
        path.write_text(text, encoding='utf-8')
        return True
    return False


count = 0
for path in ROOT.rglob('*.dart'):
    if path.name in skip_files:
        continue
    if any(p in path.parts for p in skip_dirs):
        continue
    if 'backend' in path.parts and path.name not in (
        'admin_login_flow.dart',
        'admin_user_creation.dart',
        'admin_super_admin_gate.dart',
    ):
        continue
    if replace_in_file(path):
        count += 1
        print('updated', path.relative_to(ROOT.parent))

print('files', count)
