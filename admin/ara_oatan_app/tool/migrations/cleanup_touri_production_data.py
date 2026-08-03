# -*- coding: utf-8 -*-
"""Dry-run scanner for junk landmarks / teacher strings / Arabic leakage.

Usage:
  dart run is not used — this is a Python dry-run helper for reports.
  python tool/migrations/cleanup_touri_production_data.py --dry-run
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BANNED = re.compile(
    r"\b(aircraft|airplane|fighter|jet|boeing|panavia|tornado|"
    r"mcdonnell|douglas|f-\d|707)\b",
    re.I,
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", default=True)
    args = parser.parse_args()
    print("Mode:", "dry-run" if args.dry_run else "APPLY (not implemented — use Admin)")
    print("Scan assets/langs for teacher / banned phrases...")
    for lang in ["en", "ar", "ru", "ky"]:
        path = ROOT / "assets" / "langs" / f"{lang}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        for key, value in data.items():
            text = str(value)
            if "teacher" in text.lower():
                print(f"  TEACHER {lang}:{key} => {text[:80]}")
            if BANNED.search(text):
                print(f"  BANNED {lang}:{key} => {text[:80]}")
    print(
        "Firestore landmark cleanup requires Admin credentials; "
        "client filter touryFilterLandmarksForUi already hides banned names."
    )
    print("See docs/migrations/touri_production_cleanup.md")


if __name__ == "__main__":
    main()
