#!/usr/bin/env python3
"""Static validation: Cairo font assets declared in pubspec exist and are buildable."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PUBSPEC = ROOT / "pubspec.yaml"
FONTS_DIR = ROOT / "assets" / "fonts"
INDEX = ROOT / "web" / "index.html"


def main() -> int:
    pub = PUBSPEC.read_text(encoding="utf-8")
    assets = re.findall(r"asset:\s*(assets/fonts/\S+\.ttf)", pub)
    missing = [a for a in assets if not (ROOT / a).exists()]
    families = re.findall(r"family:\s*'([^']+)'", pub)
    cairo_families = [f for f in families if f.lower() == "cairo"]
    index = INDEX.read_text(encoding="utf-8") if INDEX.exists() else ""
    face_urls = re.findall(r"url\('([^']+Cairo[^']+\.ttf)'\)", index)

    print(f"declared_font_assets={len(assets)}")
    print(f"cairo_families={cairo_families}")
    print(f"missing_assets={len(missing)}")
    for m in missing:
        print(f"MISSING {m}")
    print(f"index_font_face_urls={len(face_urls)}")
    bad_face = [u for u in face_urls if not (ROOT / "web" / u).exists() and not (ROOT / u).exists()]
    # Flutter web serves assets from build root; source path is assets/fonts under project.
    source_missing = []
    for u in face_urls:
        name = Path(u).name
        if not (FONTS_DIR / name).exists():
            source_missing.append(u)
    print(f"index_face_source_missing={len(source_missing)}")
    for m in source_missing:
        print(f"MISSING_FACE {m}")

    ok = (
        len(missing) == 0
        and "cairo" in [f.lower() for f in cairo_families]
        and "Cairo" in cairo_families
        and len(source_missing) == 0
        and len(face_urls) >= 2
    )
    print("FONT_ASSET_TEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
