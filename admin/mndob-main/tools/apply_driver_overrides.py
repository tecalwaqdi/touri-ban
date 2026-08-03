"""Apply offline driver UI translations to assets/langs/*.json"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANG_DIR = ROOT / "assets/langs"
OVERRIDES_DIR = Path(__file__).resolve().parent / "driver_overrides"

ARABIC_RE = re.compile(r"[\u0600-\u06FF]")
SKIP_EXACT = {
    "0", "12", "14", "4.8", "98%", "DD", "MM", "YYYY", "Button", "Page Title",
    "CFVFV", "Emily Rodriguez", "Michael Chen", "Michael Rodriguez",
    "123 Main Street", "185 Berry Street, San Francisco", "456 Market Avenue",
    "Golden Gate Bridge Viewpoint", "Beach Resort", "Booking #RT58291",
    "SA0000000000000000000000", "+9665XXXXXXXX", "example@email.com",
    "$112", "$187.50", "$225", "$24.50", "\\$112", "\\$187.50", "\\$225", "\\$24.50",
}


def load_driver_keys() -> set[str]:
    text = (ROOT / "lib/flutter_flow/internationalization.dart").read_text(encoding="utf-8")
    return {
        m.group(1).replace("\\'", "'")
        for m in re.finditer(r"'en': '((?:\\'|[^'])*)'", text)
        if m.group(1).strip()
    }


def should_apply(key: str, current: str, override: str, en_value: str) -> bool:
    if key in SKIP_EXACT:
        return False
    if ARABIC_RE.search(key):
        return False
    if not override.strip() or current == override:
        return False
    if current == key or current == en_value:
        return True
    return False


def main() -> None:
    driver_keys = load_driver_keys()
    en_data = json.loads((LANG_DIR / "en.json").read_text(encoding="utf-8"))
    for override_path in sorted(OVERRIDES_DIR.glob("*.json")):
        lang_stem = override_path.stem
        if lang_stem in ("en", "ar"):
            continue
        lang_path = LANG_DIR / f"{lang_stem}.json"
        if not lang_path.exists():
            print(f"skip missing {lang_path.name}")
            continue
        data = json.loads(lang_path.read_text(encoding="utf-8"))
        overrides = json.loads(override_path.read_text(encoding="utf-8"))
        applied = 0
        for key, value in overrides.items():
            if key not in data or not value.strip():
                continue
            en_value = en_data.get(key, key)
            if data[key] != value and (
                data[key] == key or data[key] == en_value or key in driver_keys
            ):
                data[key] = value
                applied += 1
        lang_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"{lang_stem}: applied {applied} overrides")


if __name__ == "__main__":
    main()
