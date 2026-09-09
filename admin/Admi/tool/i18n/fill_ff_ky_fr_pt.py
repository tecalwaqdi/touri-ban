#!/usr/bin/env python3
"""Fill missing ky/fr/pt in FlutterFlow kTranslationsMap using cache + parallel GT."""

from __future__ import annotations

import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path(__file__).resolve().parents[2]
FF = ROOT / "lib" / "flutter_flow" / "internationalization.dart"
CACHE = Path(__file__).resolve().parent / "translate_cache.json"
LOCALES = ("ky", "fr", "pt")
POISON = re.compile(r"Error 500|Server Error|That.s an error|Please try again later", re.I)
WORKERS = 8


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")


def esc(s: str) -> str:
    return (
        (s or "")
        .replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", "\\n")
    )


def unesc(s: str) -> str:
    return (
        s.replace("\\'", "'")
        .replace('\\"', '"')
        .replace("\\$", "$")
        .replace("\\n", "\n")
        .replace("\\\\", "\\")
    )


def translate_one(text: str, target: str) -> str:
    text = (text or "").strip()
    if not text:
        return text
    for attempt in range(4):
        try:
            out = GoogleTranslator(source="auto", target=target).translate(text)
            out = (out or "").strip()
            if out and not POISON.search(out):
                return out
        except Exception as exc:  # noqa: BLE001
            print(f"  retry {target}: {exc}", flush=True)
            time.sleep(1.0 * (attempt + 1))
    return text


def main() -> None:
    text = FF.read_text(encoding="utf-8")
    cache = load_cache()

    entry_re = re.compile(
        r"\n    '((?:\\'|[^'])+)': \{\n((?:      .*\n)*?)    \},"
    )
    jobs: list[tuple[str, str, str]] = []  # (cache_key, src, loc)
    plan: list[tuple[str, str, str, str]] = []  # key, loc, src, body_marker

    entries = list(entry_re.finditer(text))
    print(f"ff_entries={len(entries)}", flush=True)

    needed: dict[tuple[str, str], str] = {}  # (src,loc) -> placeholder

    for m in entries:
        key = m.group(1)
        body = m.group(2)
        en_m = re.search(r"'en':\s*'((?:\\'|[^'])*)'", body)
        if not en_m:
            en_m = re.search(r"'en':\s*\"((?:\\\"|[^\"])*)\"", body)
        if not en_m:
            continue
        en = unesc(en_m.group(1))
        ru_m = re.search(r"'ru':\s*'((?:\\'|[^'])*)'", body)
        ru = unesc(ru_m.group(1)) if ru_m else ""
        for loc in LOCALES:
            has = re.search(rf"'{loc}':\s*'((?:\\'|[^'])*)'", body)
            if has and has.group(1).strip() and not POISON.search(has.group(1)):
                continue
            src = ru if (loc == "ky" and ru.strip()) else en
            ck = f"auto|{loc}|{src}"
            if ck in cache and cache[ck] and not POISON.search(cache[ck]):
                continue
            needed[(src, loc)] = ck

    print(f"unique_translations_needed={len(needed)}", flush=True)

    # Resolve from cache / network
    to_fetch = [(src, loc, ck) for (src, loc), ck in needed.items()]
    done = 0
    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futs = {
            pool.submit(translate_one, src, loc): (src, loc, ck)
            for src, loc, ck in to_fetch
        }
        for fut in as_completed(futs):
            src, loc, ck = futs[fut]
            out = fut.result()
            cache[ck] = out
            done += 1
            if done % 25 == 0 or done == len(futs):
                print(f"translated {done}/{len(futs)}", flush=True)
                save_cache(cache)

    save_cache(cache)

    changed = 0

    def repl_entry(m: re.Match) -> str:
        nonlocal changed
        key = m.group(1)
        body = m.group(2)
        en_m = re.search(r"'en':\s*'((?:\\'|[^'])*)'", body)
        if not en_m:
            en_m = re.search(r"'en':\s*\"((?:\\\"|[^\"])*)\"", body)
        if not en_m:
            return m.group(0)
        en = unesc(en_m.group(1))
        ru_m = re.search(r"'ru':\s*'((?:\\'|[^'])*)'", body)
        ru = unesc(ru_m.group(1)) if ru_m else ""
        new_body = body
        for loc in LOCALES:
            has = re.search(rf"'{loc}':\s*('(?:\\'|[^'])*'|\"(?:\\\"|[^\"])*\")", new_body)
            if has:
                raw = has.group(1)
                val = raw[1:-1]
                if val.strip() and not POISON.search(val):
                    continue
            src = ru if (loc == "ky" and ru.strip()) else en
            ck = f"auto|{loc}|{src}"
            translated = cache.get(ck) or src
            if not str(translated).strip():
                translated = en
            line = f"      '{loc}': '{esc(translated)}',\n"
            if has:
                new_body = re.sub(
                    rf"'{loc}':\s*(?:'(?:\\'|[^'])*'|\"(?:\\\"|[^\"])*\"),?\n",
                    line,
                    new_body,
                    count=1,
                )
            else:
                new_body = re.sub(
                    r"('en':\s*(?:'(?:\\'|[^'])*'|\"(?:\\\"|[^\"])*\"),?\n)",
                    r"\1" + line,
                    new_body,
                    count=1,
                )
            changed += 1
        return f"    '{key}': {{\n{new_body}    }},"

    text2 = entry_re.sub(repl_entry, text)
    FF.write_text(text2, encoding="utf-8")
    save_cache(cache)
    print(f"changed_locale_slots={changed}", flush=True)


if __name__ == "__main__":
    main()
