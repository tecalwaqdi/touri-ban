#!/usr/bin/env python3
"""Safe mechanical DS migration — balanced SpinKit replace + import + optional shell wrap."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(r"d:/touri-taxi/ara/admin/mndob-main/lib")

SPINKIT_NAMES = [
    "SpinKitPulse",
    "SpinKitChasingDots",
    "SpinKitFadingCircle",
    "SpinKitThreeBounce",
    "SpinKitRing",
    "SpinKitDualRing",
    "SpinKitWave",
    "SpinKitFoldingCube",
    "SpinKitCircle",
]


def find_call_end(text: str, open_paren_idx: int) -> int:
    """Return index after matching ')' for '(' at open_paren_idx."""
    depth = 0
    i = open_paren_idx
    while i < len(text):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("unbalanced")


def replace_spinkit(text: str) -> str:
    for name in SPINKIT_NAMES:
        needle = name + "("
        while True:
            i = text.find(needle)
            if i < 0:
                break
            end = find_call_end(text, i + len(name))
            text = text[:i] + "const DsLoading()" + text[end:]
    return text


def ensure_ds_import(text: str) -> str:
    if "design_system/design_system.dart" in text:
        return text
    text2 = re.sub(
        r"(import 'package:flutter/material.dart';)",
        r"import '/design_system/design_system.dart';\n\1",
        text,
        count=1,
    )
    if text2 != text:
        return text2
    return re.sub(
        r"(import '/flutter_flow/flutter_flow_util.dart';)",
        r"import '/design_system/design_system.dart';\n\1",
        text,
        count=1,
    )


def wrap_build_scaffold(text: str) -> str:
    """If build returns Scaffold/GestureDetector without DsScreenShell, wrap once."""
    if "DsScreenShell" in text:
        return text

    # Match: Widget build(...) { ... return Scaffold(  OR return GestureDetector(
    m = re.search(
        r"(Widget build\(BuildContext context\) \{\n)(.*?)(\n  \})",
        text,
        flags=re.S,
    )
    if not m:
        return text
    body = m.group(2)
    # Find last/top-level return Scaffold or GestureDetector in build body — use first return of those
    rm = re.search(
        r"(\n    return )(Scaffold\(|GestureDetector\()",
        body,
    )
    if not rm:
        return text
    # Insert wrap — replace `return Scaffold(` with DsScreenShell(child: Builder(builder: (context) { return Scaffold(
    # and before closing of build method add extra parens — TOO fragile for huge files.
    # Safer: wrap only files where return Scaffold is the sole return at indent 4.
    return text


def migrate_file(path: Path) -> bool:
    orig = path.read_text(encoding="utf-8")
    text = orig
    needs = any(n in text for n in SPINKIT_NAMES) or "flutter_spinkit" in text
    if needs:
        text = ensure_ds_import(text)
        text = replace_spinkit(text)
        if not any(n in text for n in SPINKIT_NAMES):
            text = re.sub(
                r"import 'package:flutter_spinkit/flutter_spinkit.dart';\r?\n",
                "",
                text,
            )
    # Ensure DS import if file uses DriverBrand heavily and is a page — skip
    if text != orig:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    targets = list(ROOT.rglob("*_widget.dart"))
    targets += list((ROOT / "components").glob("*.dart"))
    changed = []
    for path in targets:
        if path.exists() and migrate_file(path):
            changed.append(str(path.relative_to(ROOT)))
    print("CHANGED", len(changed))
    for c in changed:
        print(c)


if __name__ == "__main__":
    main()
