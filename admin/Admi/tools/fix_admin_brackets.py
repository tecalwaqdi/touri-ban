#!/usr/bin/env python3
"""Fix extra closing paren left after padding script removed Row wrapper."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "admin"

FIX = re.compile(
    r"(\]\.divide\(SizedBox\(width: 16\.0\)\),)\s*"
    r"\),\s*"
    r"\),\s*"
    r"(Padding\()",
    re.MULTILINE,
)


def main() -> None:
    for path in ROOT.rglob("*_widget.dart"):
        text = path.read_text(encoding="utf-8")
        fixed = FIX.sub(r"\1\n                            ),\n                          \2", text)
        if fixed != text:
            path.write_text(fixed, encoding="utf-8")
            print(f"Fixed {path.name}")


if __name__ == "__main__":
    main()
