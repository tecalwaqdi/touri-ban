#!/usr/bin/env python3
"""Repair poisoned Error-500 translation values in translated_master.json."""

from __future__ import annotations

import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from deep_translator import GoogleTranslator, MyMemoryTranslator

HERE = Path(__file__).resolve().parent
MASTER = HERE / "translated_master.json"
CACHE = HERE / "translate_cache.json"

POISON = re.compile(
    r"Error 500|Server Error|That’s an error|That's an error|Please try again later",
    re.I,
)

MM_TARGETS = {
    "en": ("ar-SA", "en-US"),
    "fr": ("en-US", "fr-FR"),
    "ru": ("en-US", "ru-RU"),
    "pt": ("en-US", "pt-BR"),
    "ur": ("en-US", "ur-PK"),
    "ky": ("en-US", "ky-KG"),
}


def load(path: Path, default):
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else default


def save(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def is_poison(val: str | None) -> bool:
    return bool(POISON.search(val or ""))


def translate(cache: dict, text: str, target: str, from_ar: bool = False) -> str:
    text = (text or "").strip()
    if not text:
        return text
    key = f"fix|{target}|{text}"
    if key in cache and cache[key] and not is_poison(cache[key]):
        return cache[key]
    # Google first
    for attempt in range(3):
        try:
            out = GoogleTranslator(source="auto", target=target).translate(text)
            out = (out or "").strip()
            if out and not is_poison(out):
                cache[key] = out
                return out
        except Exception:
            time.sleep(1.2 * (attempt + 1))
    # MyMemory fallback
    try:
        if from_ar and target == "en":
            src, tgt = "ar-SA", "en-US"
            out = MyMemoryTranslator(source=src, target=tgt).translate(text)
        else:
            src, tgt = MM_TARGETS.get(target, ("en-US", "en-US"))
            # for non-en, text should be English
            out = MyMemoryTranslator(source=src, target=tgt).translate(text)
        out = (out or "").strip()
        if out and not is_poison(out):
            cache[key] = out
            return out
    except Exception as exc:
        print(f"MM FAIL {target}: {exc}", flush=True)
    return text


def main() -> None:
    master = load(MASTER, [])
    cache = load(CACHE, {})
    # scrub poison from cache
    cache = {k: v for k, v in cache.items() if not is_poison(v) and not is_poison(k)}

    poisoned_idx = [
        i
        for i, x in enumerate(master)
        if any(is_poison(x.get(loc)) for loc in ["en", "ru", "ky", "fr", "ur", "pt"])
    ]
    print(f"poisoned={len(poisoned_idx)} cache={len(cache)}", flush=True)

    for n, i in enumerate(poisoned_idx, 1):
        x = master[i]
        ar = (x.get("source_ar") or x.get("ar") or "").strip()
        en = x.get("en") or ""
        if is_poison(en) or not en.strip():
            en = translate(cache, ar, "en", from_ar=True) if ar else en
        x["en"] = en
        x["ar"] = ar or x.get("ar") or en

        need = [loc for loc in ["ru", "ky", "fr", "ur", "pt"] if is_poison(x.get(loc)) or not (x.get(loc) or "").strip()]
        if need:
            with ThreadPoolExecutor(max_workers=2) as ex:
                futs = {ex.submit(translate, cache, en, loc): loc for loc in need}
                for fut in as_completed(futs):
                    loc = futs[fut]
                    val = fut.result()
                    if val and not is_poison(val):
                        x[loc] = val
                    else:
                        # last resort keep EN rather than poison
                        x[loc] = en

        if n % 15 == 0 or n == len(poisoned_idx):
            save(CACHE, cache)
            save(MASTER, master)
            left = sum(
                1
                for y in master
                if any(is_poison(y.get(loc)) for loc in ["en", "ru", "ky", "fr", "ur", "pt"])
            )
            print(f"progress {n}/{len(poisoned_idx)} poison_left={left}", flush=True)
        time.sleep(0.25)

    left = sum(
        1
        for y in master
        if any(is_poison(y.get(loc)) for loc in ["en", "ru", "ky", "fr", "ur", "pt"])
    )
    print(f"DONE poison_left={left}", flush=True)


if __name__ == "__main__":
    main()
