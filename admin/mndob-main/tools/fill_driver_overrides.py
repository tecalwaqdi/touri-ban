"""Fill driver override files from tr template + client/mndob lang JSON."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT.parent / "ara_oatan_app"
LANG_DIR = ROOT / "assets/langs"
OVERRIDES = Path(__file__).resolve().parent / "driver_overrides"
TEMPLATE = OVERRIDES / "tr.json"

LANGS = ["fr", "ru", "ur", "id", "az", "zh-Hans", "ka", "ky"]

ARABIC_RE = re.compile(r"[\u0600-\u06FF]")


def load_json(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    return {k: v for k, v in data.items() if isinstance(v, str)}


def pick_translation(key: str, en_val: str, *sources: dict[str, str]) -> str | None:
    for src in sources:
        val = src.get(key, "")
        if not val or val == key or val == en_val:
            continue
        if ARABIC_RE.search(key) and not ARABIC_RE.search(val):
            continue
        return val
    return None


def main() -> None:
    template = load_json(TEMPLATE)
    en = load_json(LANG_DIR / "en.json")
    keys = sorted(set(template.keys()) | set(load_json(OVERRIDES / "ru.json").keys()))

    for lang in LANGS:
        override_path = OVERRIDES / f"{lang}.json"
        existing = load_json(override_path)
        mndob = load_json(LANG_DIR / f"{lang}.json")
        client = load_json(CLIENT / "assets/langs" / f"{lang}.json")
        ru = load_json(OVERRIDES / "ru.json") if lang != "ru" else {}

        out: dict[str, str] = {}
        for key in keys:
            en_val = en.get(key, key)
            if key in existing and existing[key] not in ("", key):
                out[key] = existing[key]
                continue
            translated = pick_translation(
                key,
                en_val,
                mndob,
                client,
                existing,
                ru if lang in ("ka", "ky", "id", "ur", "az", "zh-Hans") else {},
            )
            if translated:
                out[key] = translated

        override_path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"{lang}: {len(out)}/{len(keys)} keys")


if __name__ == "__main__":
    main()
