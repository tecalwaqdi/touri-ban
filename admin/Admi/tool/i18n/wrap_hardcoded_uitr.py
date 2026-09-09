#!/usr/bin/env python3
"""Safely wrap hardcoded Arabic UI string literals with uiTr(context, ...)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "lib"
AR = r"[\u0600-\u06FF]"

FIELD = (
    r"title|subtitle|label|hint|hintText|labelText|helperText|errorText|"
    r"tooltip|message|emptyMessage|loadingMessage|buttonLabel|confirmLabel|"
    r"cancelLabel|semanticLabel"
)


def transform(content: str) -> tuple[str, int]:
    changes = 0

    def skip_uitr(prefix: str) -> bool:
        return "uiTr(" in prefix[-24:]

    # Text('عربي') / Text("عربي")
    def text_sub(m: re.Match) -> str:
        nonlocal changes
        before = content[max(0, m.start() - 24) : m.start()]
        if skip_uitr(before):
            return m.group(0)
        changes += 1
        return f"{m.group(1)}uiTr(context, {m.group(2)}){m.group(3)}"

    content2 = re.sub(
        rf"(Text\(\s*)('(?:\\'|[^'])*{AR}(?:\\'|[^'])*')(\s*(?:,|\)))",
        text_sub,
        content,
    )

    def field_sub(m: re.Match) -> str:
        nonlocal changes
        before = content2[max(0, m.start() - 24) : m.start()]
        if skip_uitr(before):
            return m.group(0)
        changes += 1
        return f"{m.group(1)}uiTr(context, {m.group(2)})"

    content3 = re.sub(
        rf"(\b(?:{FIELD})\s*:\s*)('(?:\\'|[^'])*{AR}(?:\\'|[^'])*')",
        field_sub,
        content2,
    )

    if changes == 0:
        return content, 0

    if "ui_catalog.dart" not in content3:
        lines = content3.splitlines(True)
        idx = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                idx = i + 1
        lines.insert(idx, "import '/l10n/ui_catalog.dart';\n")
        content3 = "".join(lines)

    return content3, changes


def main() -> None:
    total = 0
    files = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if path.name in {"ui_catalog.dart", "admin_status_localization.dart"}:
            continue
        original = path.read_text(encoding="utf-8")
        updated, n = transform(original)
        if n:
            path.write_text(updated, encoding="utf-8")
            files += 1
            total += n
            print(f"{n:4d} {path.relative_to(ROOT)}")
    print(f"TOTAL wraps={total} files={files}")


if __name__ == "__main__":
    main()
