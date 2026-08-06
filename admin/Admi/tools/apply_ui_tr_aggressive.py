#!/usr/bin/env python3
"""Aggressively wrap Arabic UI string literals with uiTr(context, ...)."""
from __future__ import annotations

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1] / "lib"
EN_MAP = json.loads(
    (ROOT.parent / "tools" / "ui_en_map.json").read_text(encoding="utf-8")
)
# Prefer catalog lookup keys; fall back to en_map
STRINGS = {k for k in EN_MAP if re.search(r"[\u0600-\u06FF]", k) and len(k) <= 160}

SKIP_DIRS = {"l10n", "flutter_flow", "backend"}
SKIP_FILES = {
    "internationalization.dart",
    "admin_booking_status_label.dart",  # canonical Arabic maps
    "admin_content_locale.dart",
    "toury_i18n_text.dart",
    "admin_i18n_translate_service.dart",
    "app_state.dart",
}

# Named UI fields
FIELD_NAMES = (
    r"title|subtitle|label|labelText|hintText|helperText|helpText|placeholder|"
    r"feature|emptyMessage|emptyTitle|searchHint|sectionTitle|message|"
    r"successMessage|errorMessage|confirmMessage|totalLabel|tooltip|"
    r"semanticsLabel|cancelText|confirmText|barrierLabel|semanticLabel"
)

AR_STR = r"'((?:\\'|[^'])*[\u0600-\u06FF](?:\\'|[^'])*)'"


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def already_wrapped(before: str) -> bool:
    tail = before[-80:] if len(before) > 80 else before
    return bool(
        re.search(
            r"(?:uiTr|appTr|appTrFormat|getText)\s*\(\s*(?:context\s*,\s*)?$",
            tail,
        )
    )


def should_skip_line(line: str) -> bool:
    stripped = line.strip()
    if stripped.startswith("//") or stripped.startswith("import "):
        return True
    if "'ar':" in line or '"ar":' in line:
        return True
    # equality / map keys used as machine labels
    if re.search(r"(==|!=)\s*" + AR_STR, line):
        return True
    if re.search(r"case\s+" + AR_STR, line):
        return True
    return False


def wrap_literal(s: str) -> str:
    return f"uiTr(context, '{esc(s)}')"


def replace_file(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    orig = text
    lines = text.splitlines(keepends=True)
    out: list[str] = []

    for line in lines:
        if should_skip_line(line) or "uiTr(" in line and line.count("'") <= 2:
            # still may have unwrapped extras; be careful
            pass

        if should_skip_line(line):
            out.append(line)
            continue

        def repl_text(m: re.Match) -> str:
            const_kw = m.group(1) or ""
            raw = m.group(2).replace("\\'", "'")
            if raw not in STRINGS:
                return m.group(0)
            # drop const — uiTr is not const
            return f"Text({wrap_literal(raw)})"

        def repl_field(m: re.Match) -> str:
            field = m.group(1)
            raw = m.group(2).replace("\\'", "'")
            if raw not in STRINGS:
                return m.group(0)
            return f"{field}: {wrap_literal(raw)}"

        def repl_return(m: re.Match) -> str:
            raw = m.group(1).replace("\\'", "'")
            if raw not in STRINGS:
                return m.group(0)
            return f"return {wrap_literal(raw)}"

        def repl_throw(m: re.Match) -> str:
            raw = m.group(1).replace("\\'", "'")
            if raw not in STRINGS:
                return m.group(0)
            return f"throw Exception({wrap_literal(raw)})"

        def repl_feedback(m: re.Match) -> str:
            prefix = m.group(1)
            raw = m.group(2).replace("\\'", "'")
            if raw not in STRINGS:
                return m.group(0)
            return f"{prefix}{wrap_literal(raw)}"

        def repl_assign(m: re.Match) -> str:
            # var = 'عربي' or _x = 'عربي'
            left = m.group(1)
            raw = m.group(2).replace("\\'", "'")
            if raw not in STRINGS:
                return m.group(0)
            if already_wrapped(left):
                return m.group(0)
            return f"{left}{wrap_literal(raw)}"

        new = line
        if not should_skip_line(new):
            new = re.sub(
                r"(const\s+)?Text\(\s*" + AR_STR + r"\s*\)",
                repl_text,
                new,
            )
            new = re.sub(
                rf"({FIELD_NAMES}):\s*{AR_STR}",
                repl_field,
                new,
            )
            new = re.sub(r"return\s+" + AR_STR, repl_return, new)
            new = re.sub(
                r"throw\s+Exception\(\s*" + AR_STR + r"\s*\)",
                repl_throw,
                new,
            )
            new = re.sub(
                r"(AdminCrudFeedback\.\w+\(\s*context\s*,\s*)" + AR_STR,
                repl_feedback,
                new,
            )
            new = re.sub(
                r"(SnackBar\(\s*content:\s*Text\(\s*)" + AR_STR,
                lambda m: (
                    f"{m.group(1)}{wrap_literal(m.group(2).replace(chr(92)+chr(39), chr(39)))}"
                    if m.group(2).replace("\\'", "'") in STRINGS
                    else m.group(0)
                ),
                new,
            )
            # Simple assignments of pure Arabic UI labels
            new = re.sub(
                r"([A-Za-z_][\w\.]*\s*=\s*)" + AR_STR,
                repl_assign,
                new,
            )
            # Ternary branches: ? 'عربي' : 'عربي'
            def repl_tern(m: re.Match) -> str:
                op = m.group(1)
                raw = m.group(2).replace("\\'", "'")
                if raw not in STRINGS:
                    return m.group(0)
                return f"{op}{wrap_literal(raw)}"

            new = re.sub(r"(\?\s*|:\s*)" + AR_STR, repl_tern, new)

        out.append(new)

    text = "".join(out)
    if text == orig:
        return False

    if "uiTr(" in text and "flutter_flow_util.dart" not in text:
        # add import after first import
        parts = text.splitlines(keepends=True)
        for i, line in enumerate(parts):
            if line.startswith("import "):
                parts.insert(i + 1, "import '/flutter_flow/flutter_flow_util.dart';\n")
                break
        text = "".join(parts)
        # dedupe
        seen = False
        cleaned = []
        for line in text.splitlines(keepends=True):
            if "flutter_flow_util.dart" in line:
                if seen:
                    continue
                seen = True
            cleaned.append(line)
        text = "".join(cleaned)

    path.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    count = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if path.name in SKIP_FILES:
            continue
        if any(p in path.parts for p in SKIP_DIRS):
            continue
        if path.name.endswith("_model.dart"):
            continue
        if replace_file(path):
            count += 1
            print("updated", path.relative_to(ROOT.parent))
    print("files", count)


if __name__ == "__main__":
    main()
