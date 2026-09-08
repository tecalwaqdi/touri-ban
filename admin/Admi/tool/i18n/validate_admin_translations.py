#!/usr/bin/env python3
"""Validate admin translation parity across ar/en/ru/ky/fr/ur/pt."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib"
LOCALES = ["ar", "en", "ru", "ky", "fr", "ur", "pt"]
AR_RE = re.compile(r"[\u0600-\u06FF]")

MAP_FILES = [
    LIB / "flutter_flow" / "internationalization.dart",
    LIB / "l10n" / "admin_translations.dart",
    LIB / "l10n" / "enterprise_translations.dart",
    LIB / "l10n" / "nav_translations.dart",
    LIB / "l10n" / "ui_catalog.dart",
]


def parse_maps(path: Path) -> dict[str, dict[str, str]]:
    text = path.read_text(encoding="utf-8")
    entries: dict[str, dict[str, str]] = {}
    patterns = [
        # Catalog / admin maps (2-space key indent)
        "\n  '((?:\\\\'|[^'])+)': \\{\n((?:    .*\n)*?)  \\},",
        # Compact FlutterFlow hash keys
        "'([A-Za-z0-9_]+)':\\s*\\{([^{}]*?)\\}",
    ]
    for pat in patterns:
        for m in re.finditer(pat, text):
            key = m.group(1).replace("\\'", "'")
            body = m.group(2)
            if "'en':" not in body and '"en":' not in body:
                continue
            locs: dict[str, str] = {}
            for loc in LOCALES + ["zh_Hans", "tr", "az", "ka"]:
                mm = re.search(rf"'{re.escape(loc)}':\s*'((?:\\'|[^'])*)'", body)
                if not mm:
                    mm = re.search(
                        rf"'{re.escape(loc)}':\s*\"((?:\\\"|[^\"])*)\"", body
                    )
                if mm:
                    locs[loc] = (
                        mm.group(1)
                        .replace("\\'", "'")
                        .replace('\\"', '"')
                        .replace("\\$", "$")
                    )
            if not locs:
                continue
            # Skip intentional empty placeholders (all target locales blank).
            if all(not (locs.get(loc) or "").strip() for loc in LOCALES if loc in locs):
                continue
            entries[key] = locs
    return entries



def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    total_keys = 0
    missing = {loc: 0 for loc in LOCALES}
    empty = {loc: 0 for loc in LOCALES}
    ar_in_en = 0
    ar_in_ltr = {loc: 0 for loc in ["en", "ru", "ky", "fr", "pt"]}

    for path in MAP_FILES:
        if not path.exists():
            errors.append(f"missing map file: {path}")
            continue
        entries = parse_maps(path)
        total_keys += len(entries)
        for key, locs in entries.items():
            for loc in LOCALES:
                if loc not in locs:
                    missing[loc] += 1
                    errors.append(f"{path.name}:{key}: missing {loc}")
                    continue
                val = locs[loc]
                if not val.strip():
                    empty[loc] += 1
                    errors.append(f"{path.name}:{key}: empty {loc}")
            en = locs.get("en", "")
            if AR_RE.search(en):
                ar_in_en += 1
                errors.append(f"{path.name}:{key}: Arabic inside EN: {en[:80]!r}")
            for loc in ar_in_ltr:
                v = locs.get(loc, "")
                # Allow currency examples etc via whitelist later
                if AR_RE.search(v) and loc != "en":
                    # ky/fr/pt/ru must not be Arabic fallback
                    ar = locs.get("ar", "")
                    if ar and v == ar:
                        ar_in_ltr[loc] += 1
                        errors.append(
                            f"{path.name}:{key}: {loc} identical to Arabic fallback"
                        )

    # uiTr coverage: every literal should be in lookup
    catalog = (LIB / "l10n" / "ui_catalog.dart").read_text(encoding="utf-8")
    lookup = set(
        m.group(1).replace("\\'", "'").replace("\\$", "$").replace("\\\\", "\\")
        for m in re.finditer(
            r"'((?:\\'|[^'])*)'\s*:\s*'ui_[A-Za-z0-9_]+'",
            catalog[catalog.find("kArabicUiLookup") :],
        )
    )
    uit_pat = re.compile(r"uiTr\(\s*context\s*,\s*'((?:\\'|[^'])*)'")
    missing_lookup = set()
    for p in LIB.rglob("*.dart"):
        if p.name == "ui_catalog.dart":
            continue
        t = p.read_text(encoding="utf-8", errors="ignore")
        for m in uit_pat.finditer(t):
            lit = m.group(1).replace("\\'", "'")
            if lit and lit not in lookup:
                missing_lookup.add(lit)
    if missing_lookup:
        for lit in sorted(missing_lookup)[:50]:
            errors.append(f"uiTr literal missing from catalog lookup: {lit!r}")
        if len(missing_lookup) > 50:
            errors.append(f"... and {len(missing_lookup) - 50} more missing uiTr literals")

    print("TOTAL_PARSED_KEYS", total_keys)
    print("MISSING", missing)
    print("EMPTY", empty)
    print("AR_IN_EN", ar_in_en)
    print("AR_FALLBACK_IN_LTR", ar_in_ltr)
    print("UITR_MISSING_LOOKUP", len(missing_lookup))
    print("ERRORS", len(errors))
    for e in errors[:80]:
        print(" -", e)
    if len(errors) > 80:
        print(f" - ... {len(errors) - 80} more")

    # Soft warnings only for suspect identical-to-en in fr/pt
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
