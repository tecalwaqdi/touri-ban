#!/usr/bin/env python3
"""Regenerate ui_catalog.dart from translated_master.json."""

from __future__ import annotations

import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
MASTER = HERE / "translated_master.json"
OUT = HERE.parents[1] / "lib" / "l10n" / "ui_catalog.dart"

LOCALES = [
    "en",
    "pt",
    "fr",
    "ar",
    "zh_Hans",
    "tr",
    "ur",
    "ru",
    "ky",
    "az",
    "ka",
]


def esc(s: str) -> str:
    return (
        (s or "")
        .replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", "\\n")
        .replace("\r", "")
    )


def main() -> None:
    items = json.loads(MASTER.read_text(encoding="utf-8"))
    # Deduplicate by key, prefer translated/non-empty
    by_key = {}
    for it in items:
        key = it["key"]
        by_key[key] = it

    # Also ensure lookup from source_ar
    lookup_pairs = []
    catalog_blocks = []
    for key in sorted(by_key.keys()):
        it = by_key[key]
        # Preserve exact source_ar (including trailing spaces) for uiTr lookup parity.
        ar = it.get("source_ar") or it.get("ar") or ""
        en = (it.get("en") or "").strip() or ar.strip() or ar
        vals = {
            "en": en,
            "pt": (it.get("pt") or en).strip() or en,
            "fr": (it.get("fr") or en).strip() or en,
            "ar": ar if ar.strip() else en,
            "zh_Hans": en,
            "tr": en,
            "ur": (it.get("ur") or en).strip() or en,
            "ru": (it.get("ru") or en).strip() or en,
            "ky": (it.get("ky") or en).strip() or en,
            "az": en,
            "ka": en,
        }
        lines = [f"  '{key}': {{"]
        for loc in LOCALES:
            lines.append(f"    '{loc}': '{esc(vals[loc])}',")
        lines.append("  },")
        catalog_blocks.append("\n".join(lines))
        if ar:
            lookup_pairs.append((ar, key))

    # Stable unique lookup (first wins for duplicate Arabic)
    seen = set()
    lookup_lines = []
    for ar, key in sorted(lookup_pairs, key=lambda x: x[0]):
        if ar in seen:
            continue
        seen.add(ar)
        lookup_lines.append(f"  '{esc(ar)}': '{key}',")

    dart = (
        "import 'package:flutter/material.dart';\n"
        "import '/flutter_flow/internationalization.dart';\n"
        "\n"
        "const kUiCatalog = <String, Map<String, String>>{\n"
        + "\n".join(catalog_blocks)
        + "\n};\n\n"
        "const kArabicUiLookup = <String, String>{\n"
        + "\n".join(lookup_lines)
        + "\n};\n\n"
        "String uiTr(BuildContext context, String arabic) {\n"
        "  final key = kArabicUiLookup[arabic];\n"
        "  if (key != null) {\n"
        "    final text = FFLocalizations.of(context).getText(key);\n"
        "    if (text.isNotEmpty) return text;\n"
        "  }\n"
        "  return arabic;\n"
        "}\n"
    )
    OUT.write_text(dart, encoding="utf-8")
    print(f"wrote {OUT} keys={len(by_key)} lookup={len(seen)}")


if __name__ == "__main__":
    main()
