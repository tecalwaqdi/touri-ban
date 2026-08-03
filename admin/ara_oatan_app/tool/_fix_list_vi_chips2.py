# -*- coding: utf-8 -*-
from pathlib import Path
import re

p = Path("lib/app/list_vi/list_vi_widget.dart")
t = p.read_text(encoding="utf-8")

ff_to_tr = {
    "0gjhqz6e": "landmark_cat_all",
    "1k6b2ubh": "landmark_cat_entertainment",
    "kmon2zgt": "landmark_cat_tourism",
    "tnfmb52e": "landmark_cat_cafe",
    "5p4hgnha": "landmark_cat_tourist_places",
    "f6lkp6ha": "landmark_cat_markets",
    "ek6uzd9t": "landmark_cat_desert",
    "icj3jzeb": "landmark_cat_sea",
    "gpd0piir": "landmark_cat_hotels",
    "6jn5bghr": "landmark_cat_restaurants",
}

# Broader pattern: ChipData( ... getText('KEY' /*..*/), Icons.xxx)
pattern = re.compile(
    r"ChipData\(\s*"
    r"FFLocalizations\.of\(context\)\s*\n\s*\.getText\(\s*\n\s*"
    r"'([^']+)'\s*/\*[^*]*\*/\s*,\s*\n\s*\)\s*,\s*\n\s*"
    r"(Icons\s*\n\s*\.[A-Za-z0-9_]+)\s*\)",
    re.MULTILINE,
)

matches = list(pattern.finditer(t))
print("matches", len(matches))
for m in matches[:3]:
    print("---")
    print(m.group(0)[:120])
    print("key", m.group(1), "icon", m.group(2).replace("\n", "").replace(" ", ""))


def repl(m: re.Match) -> str:
    key = m.group(1)
    icon = re.sub(r"\s+", "", m.group(2))
    tr = ff_to_tr.get(key)
    if not tr:
        return m.group(0)
    return f"ChipData('{tr}'.tr(), {icon})"


new_t, n = pattern.subn(repl, t)
p.write_text(new_t, encoding="utf-8")
print("replaced", n)
print("remaining 0gjhqz6e", new_t.count("'0gjhqz6e'"))
