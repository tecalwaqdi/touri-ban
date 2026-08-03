"""Translate driver-only i18n keys still in English using Google Translate."""
from __future__ import annotations

import json
import re
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANG_DIR = ROOT / "assets/langs"
INTL = ROOT / "lib/flutter_flow/internationalization.dart"

LANG_TARGETS = {
    "tr": "tr",
    "ru": "ru",
    "fr": "fr",
    "ur": "ur",
    "id": "id",
    "az": "az",
    "ka": "ka",
    "ky": "ky",
    "zh-Hans": "zh-CN",
}

SKIP_RE = re.compile(
    r"^(\s|[\$0-9\.,:/\-+%@#]|user@|SA0{5,}|\+966|\d+\.\d+\s*mi|\d+\s*mins?|$840)",
    re.IGNORECASE,
)


def load_driver_keys() -> set[str]:
    text = INTL.read_text(encoding="utf-8")
    return {
        m.group(1).replace("\\'", "'")
        for m in re.finditer(r"'en': '((?:\\'|[^'])*)'", text)
        if m.group(1).strip()
    }


def should_skip(text: str) -> bool:
    t = text.strip()
    if len(t) <= 1:
        return True
    if t.isdigit():
        return True
    if SKIP_RE.match(t):
        return True
    if re.fullmatch(r"[\d\s\.,:\-APM]+", t):
        return True
    return False


def main() -> None:
    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        raise SystemExit("Run: pip install deep-translator")

    driver_keys = load_driver_keys()
    en_data = json.loads((LANG_DIR / "en.json").read_text(encoding="utf-8"))

    for file_stem, google_lang in LANG_TARGETS.items():
        lang_path = LANG_DIR / f"{file_stem}.json"
        data = json.loads(lang_path.read_text(encoding="utf-8"))
        translator = GoogleTranslator(source="en", target=google_lang)

        pending = [
            k
            for k in driver_keys
            if k in data and data.get(k) == k and not should_skip(k)
        ]
        print(f"{file_stem}: translating {len(pending)} strings…")

        translated = 0
        for i, key in enumerate(pending, 1):
            try:
                value = translator.translate(key)
                if value and value.strip() and value.strip() != key:
                    data[key] = value.strip()
                    translated += 1
            except Exception as exc:
                print(f"  skip {key[:40]!r}: {exc}")
            if i % 25 == 0:
                time.sleep(0.5)
                print(f"  progress {i}/{len(pending)}")

        lang_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"{file_stem}: done ({translated} updated)\n")
        time.sleep(1)


if __name__ == "__main__":
    main()
