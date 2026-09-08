#!/usr/bin/env python3
"""Fill same-as-EN gaps in admin/nav/enterprise translation maps using Google auto."""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path(__file__).resolve().parent / "translate_cache.json"
FILES = [
    ROOT / "lib" / "l10n" / "admin_translations.dart",
    ROOT / "lib" / "l10n" / "nav_translations.dart",
    ROOT / "lib" / "l10n" / "enterprise_translations.dart",
]
LOCALES = ["ru", "ky", "fr", "ur", "pt"]
AR_RE = re.compile(r"[\u0600-\u06FF]")


def load_cache():
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(c):
    CACHE.write_text(json.dumps(c, ensure_ascii=False, indent=2), encoding="utf-8")


def tr(cache, text, target):
    key = f"auto|{target}|{text}"
    if key in cache:
        return cache[key]
    for attempt in range(4):
        try:
            out = GoogleTranslator(source="auto", target=target).translate(text)
            out = (out or text).strip()
            cache[key] = out
            return out
        except Exception:
            time.sleep(1.0 * (attempt + 1))
    cache[key] = text
    return text


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def patch_file(path: Path, cache: dict) -> int:
    text = path.read_text(encoding="utf-8")
    changed = 0

    def repl_entry(m):
        nonlocal changed
        key = m.group(1)
        body = m.group(2)
        locs = {}
        for loc in ["en", "ar"] + LOCALES:
            mm = re.search(rf"'{loc}':\s*'((?:\\'|[^'])*)'", body)
            locs[loc] = mm.group(1).replace("\\'", "'") if mm else None
        en = locs.get("en") or ""
        if not en or AR_RE.search(en):
            return m.group(0)
        new_body = body
        for loc in LOCALES:
            cur = locs.get(loc)
            if cur is None:
                continue
            bad = (not cur.strip()) or cur == en or (locs.get("ar") and cur == locs["ar"])
            if not bad:
                continue
            translated = tr(cache, en, loc)
            # replace first occurrence of this locale line inside body
            new_body2, n = re.subn(
                rf"('{loc}':\s*')((?:\\'|[^'])*)(')",
                rf"\g<1>{esc(translated)}\3",
                new_body,
                count=1,
            )
            if n:
                new_body = new_body2
                changed += 1
        return f"  '{key}': {{\n{new_body}  }},"

    text2 = re.sub(
        r"\n  '((?:\\'|[^'])+)': \{\n((?:    .*\n)*?)  \},",
        repl_entry,
        text,
    )
    if text2 != text:
        path.write_text(text2, encoding="utf-8")
    return changed


def main():
    cache = load_cache()
    total = 0
    for f in FILES:
        n = patch_file(f, cache)
        print(f"{f.name}: changed {n}")
        total += n
        save_cache(cache)
    print("TOTAL", total)


if __name__ == "__main__":
    main()
