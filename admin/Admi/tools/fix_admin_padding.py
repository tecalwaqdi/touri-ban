#!/usr/bin/env python3
"""Remove redundant outer wrappers and fix double padding in admin pages."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "admin"

OPEN = re.compile(
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

CLOSE = re.compile(
    r"(\]\.divide\(SizedBox\(height: 24\.0\)\),)\s*"
    r"\),\s*"
    r"\),\s*"
    r"\),\s*"
    r"\),\s*"
    r"\),\s*"
    r"(\),\s*"
    r"\);)",
    re.MULTILINE,
)


def ensure_imports(text: str) -> str:
    if "admin_ui.dart" not in text and "AdminPageBody" in text:
        text = text.replace(
            "import '/components/admin_layout_widget.dart';\n",
            "import '/components/admin_layout_widget.dart';\n"
            "import '/components/admin_ui.dart';\n",
        )
    return text


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    if "AdminLayoutWidget" not in text:
        return False

    text = OPEN.sub(
        "child: AdminPageBody(\n"
        "          usePadding: false,\n"
        "          child: Column(\n"
        "            mainAxisSize: MainAxisSize.min,\n"
        "            crossAxisAlignment: CrossAxisAlignment.stretch,\n"
        "            children: [",
        text,
        count=1,
    )

    text = CLOSE.sub(r"\1\n          ),\n        ),\n      \2", text, count=1)

    # Remove common duplicate inner horizontal padding blocks.
    text = re.sub(
        r"Padding\(\s*"
        r"padding: EdgeInsetsDirectional\.fromSTEB\(\s*"
        r"24\.0, 0\.0, 24\.0, 0\.0\),\s*"
        r"child: Row\(",
        "Row(",
        text,
    )

    text = ensure_imports(text)

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed = []
    for path in sorted(ROOT.rglob("*_widget.dart")):
        if process_file(path):
            changed.append(path.name)
    print(f"Fixed padding in {len(changed)} files: {', '.join(changed)}")


if __name__ == "__main__":
    main()
