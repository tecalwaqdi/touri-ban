#!/usr/bin/env python3
"""Apply AdminUi styling helpers across admin widget files."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "admin"

CARD_PATTERNS = [
    # With border (8 or 12 radius).
    re.compile(
        r"decoration: BoxDecoration\(\s*"
        r"color: FlutterFlowTheme\.of\(context\)\s*"
        r"\.secondaryBackground,\s*"
        r"borderRadius:\s*BorderRadius\.circular\((?:12|8)\.0\),\s*"
        r"border: Border\.all\(\s*"
        r"color: FlutterFlowTheme\.of\(context\)\.alternate,\s*"
        r"width: 1\.0,\s*"
        r"\),\s*"
        r"\),",
        re.MULTILINE,
    ),
    # Without border (multiline FlutterFlow style).
    re.compile(
        r"decoration: BoxDecoration\(\s*"
        r"color: FlutterFlowTheme\.of\(context\)\s*"
        r"\.secondaryBackground,\s*"
        r"borderRadius:\s*"
        r"BorderRadius\.circular\(12\.0\),\s*"
        r"\),",
        re.MULTILINE,
    ),
]


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    if "admin_layout_widget.dart" not in text:
        return False

    text = re.sub(
        r"import '/components/menu2_widget\.dart';\n",
        "",
        text,
    )

    for pattern in CARD_PATTERNS:
        text = pattern.sub("decoration: AdminUi.cardDecoration(context),", text)

    if "AdminUi." in text and "admin_ui.dart" not in text:
        text = text.replace(
            "import '/components/admin_layout_widget.dart';\n",
            "import '/components/admin_layout_widget.dart';\n"
            "import '/components/admin_ui.dart';\n",
        )

    if "admin_ui.dart" in text and "AdminUi." not in text:
        text = re.sub(
            r"import '/components/admin_ui\.dart';\n",
            "",
            text,
        )

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed = []
    for path in sorted(ROOT.rglob("*_widget.dart")):
        if process_file(path):
            changed.append(path.relative_to(ROOT.parent.parent))
    print(f"Updated {len(changed)} files:")
    for p in changed:
        print(f"  - {p}")


if __name__ == "__main__":
    main()
