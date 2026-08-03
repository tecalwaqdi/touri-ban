"""Merge driver UI keys into assets/langs/*.json"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANG_DIR = ROOT / "assets/langs"
KEYS = json.loads((Path(__file__).parent / "driver_ui_keys.json").read_text(encoding="utf-8"))

LANG_FILES = {
    "en": "en.json",
    "ar": "ar.json",
    "tr": "tr.json",
    "ru": "ru.json",
    "fr": "fr.json",
    "id": "id.json",
    "ur": "ur.json",
    "az": "az.json",
    "ka": "ka.json",
    "ky": "ky.json",
    "zh-Hans": "zh-Hans.json",
}


def main() -> None:
    for lang, filename in LANG_FILES.items():
        path = LANG_DIR / filename
        if not path.exists():
            print(f"skip missing {filename}")
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        added = 0
        for en_key, translations in KEYS.items():
            if lang == "en":
                value = en_key
            else:
                value = translations.get(lang, en_key)
            if data.get(en_key) != value:
                data[en_key] = value
                added += 1
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"{filename}: updated {added} keys")


if __name__ == "__main__":
    main()
