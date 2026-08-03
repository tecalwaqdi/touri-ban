#!/usr/bin/env python3
"""Restore closing brackets for admin pages that kept the legacy wrapper."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "admin"

LEGACY_TAIL = re.compile(
    r"(\]\.divide\(SizedBox\(height: 24\.0\)\),)\s*"
    r"\),\s*"
    r"\),\s*"
    r"\),\s*"
    r"\);\s*"
    r"\},\s*"
    r"\);\s*"
    r"\}\s*"
    r"\}",
    re.MULTILINE,
)

LEGACY_REPLACEMENT = (
    r"\1\n"
    r"                          ),\n"
    r"                        ),\n"
    r"                      ),\n"
    r"                    ),\n"
    r"                  ),\n"
    r"                ),\n"
    r"        );\n"
    r"      },\n"
    r"    );\n"
    r"  }\n"
    r"}"
)

MODERN_OPEN = re.compile(
    r"child: Align\(\s*"
    r"alignment: AlignmentDirectional\(0\.0, -1\.0\),\s*"
    r"child: Container\(\s*"
    r"width: double\.infinity,\s*"
    r"constraints: BoxConstraints\(\s*"
    r"maxWidth: 1370\.0,\s*"
    r"\),\s*"
    r"decoration: BoxDecoration\(\),\s*"
    r"child: Padding\(\s*"
    r"padding:\s*"
    r"EdgeInsetsDirectional\.fromSTEB\(24\.0, 0\.0, 24\.0, 0\.0\),\s*"
    r"child: SingleChildScrollView\(\s*"
    r"primary: false,\s*"
    r"child: Column\(\s*"
    r"mainAxisSize: MainAxisSize\.min,\s*"
    r"children: \[",
    re.MULTILINE,
)


def process_file(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if "AdminLayoutWidget" not in text:
        return

    if "child: AdminPageBody(" in text:
        return

    if MODERN_OPEN.search(text):
        fixed = LEGACY_TAIL.sub(LEGACY_REPLACEMENT, text, count=1)
        if fixed != text:
            path.write_text(fixed, encoding="utf-8")
            print(f"Restored legacy closings: {path.name}")


def main() -> None:
    for path in sorted(ROOT.rglob("*_widget.dart")):
        process_file(path)


if __name__ == "__main__":
    main()
