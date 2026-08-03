"""Remove const from widgets that use uiTr(context, ...)."""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1] / 'lib'

for path in root.rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    if 'uiTr(' not in text:
        continue
    orig = text
    # const SnackBar( ... uiTr
    text = re.sub(r'\bconst\s+SnackBar\(', 'SnackBar(', text)
    text = re.sub(r'\bconst\s+Text\(uiTr\(', 'Text(uiTr(', text)
    text = re.sub(
        r'\bconst\s+InputDecoration\(',
        'InputDecoration(',
        text,
    )
    text = re.sub(
        r'\bconst\s+AdminEditScaffold\(',
        'AdminEditScaffold(',
        text,
    )
    text = re.sub(
        r'\bconst\s+AdminContentCard\(',
        'AdminContentCard(',
        text,
    )
    if text != orig:
        path.write_text(text, encoding='utf-8')
        print('fixed', path.relative_to(root.parent))
