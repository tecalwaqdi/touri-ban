#!/usr/bin/env python3
"""Mechanical UI migration: FlutterFlowTheme/SpinKit -> Design System tokens."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

COLOR_MAP = {
    "primaryBackground": "scaffold",
    "secondaryBackground": "surface",
    "primaryText": "textPrimary",
    "secondaryText": "textSecondary",
    "primary": "primary",
    "secondary": "primaryStrong",
    "tertiary": "primaryStrong",
    "alternate": "border",
    "error": "error",
    "success": "success",
    "warning": "warning",
    "info": "info",
    "accent1": "primarySoft",
    "accent2": "primaryMuted",
    "accent3": "warning",
    "accent4": "surfaceElevated",
}

TYPE_ROLES = [
    "displayLarge",
    "displayMedium",
    "displaySmall",
    "headlineLarge",
    "headlineMedium",
    "headlineSmall",
    "titleLarge",
    "titleMedium",
    "titleSmall",
    "bodyLarge",
    "bodyMedium",
    "bodySmall",
    "labelLarge",
    "labelMedium",
    "labelSmall",
]


def migrate(text: str) -> str:
    if "design_system/design_system.dart" not in text and (
        "FlutterFlowTheme.of" in text or "SpinKit" in text
    ):
        text2 = re.sub(
            r"(import 'package:flutter/material.dart';)",
            r"import '/design_system/design_system.dart';\n\1",
            text,
            count=1,
        )
        if text2 == text:
            text2 = re.sub(
                r"(import '/flutter_flow/flutter_flow_util.dart';)",
                r"import '/design_system/design_system.dart';\n\1",
                text,
                count=1,
            )
        text = text2

    text = re.sub(
        r"import 'package:flutter_spinkit/flutter_spinkit.dart';\r?\n",
        "",
        text,
    )

    for role in TYPE_ROLES:
        pat = (
            rf"FlutterFlowTheme\.of\(context\)\.{role}\.override\(\s*"
            rf"fontFamily:\s*FlutterFlowTheme\.of\(context\)\.{role}Family,\s*"
            rf"letterSpacing:\s*0\.0,\s*"
            rf"useGoogleFonts:\s*!FlutterFlowTheme\.of\(context\)\.{role}IsCustom,\s*"
            rf"\)"
        )
        text = re.sub(pat, f"DsTypography.of(context).{role}", text)

    for ff, ds in sorted(COLOR_MAP.items(), key=lambda x: -len(x[0])):
        text = text.replace(
            f"FlutterFlowTheme.of(context).{ff}",
            f"DsColors.of(context).{ds}",
        )

    for role in TYPE_ROLES:
        text = text.replace(
            f"FlutterFlowTheme.of(context).{role}",
            f"DsTypography.of(context).{role}",
        )
        text = text.replace(
            f"FlutterFlowTheme.of(context).{role}Family",
            "'cairo'",
        )
        text = text.replace(
            f"FlutterFlowTheme.of(context).{role}IsCustom",
            "true",
        )

    text = re.sub(r"SpinKit\w+\([^;]*?\)", "const DsLoading()", text, flags=re.S)
    return text


def main() -> None:
    paths = list(ROOT.rglob("*_widget.dart"))
    paths += list((ROOT / "components").glob("*.dart"))
    paths += list((ROOT / "core").glob("driver_*.dart"))
    paths += list((ROOT / "backend").rglob("*.dart"))
    paths += [ROOT / "flutter_flow" / "nav" / "nav.dart"]
    paths += [ROOT / "flutter_flow" / "upload_data.dart"]

    changed: list[str] = []
    for path in paths:
        if not path.exists() or not path.is_file():
            continue
        orig = path.read_text(encoding="utf-8")
        if "FlutterFlowTheme.of" not in orig and "SpinKit" not in orig and "flutter_spinkit" not in orig:
            continue
        # Skip generated models — only touch UI/chrome files
        if path.name.endswith("_model.dart"):
            continue
        new = migrate(orig)
        if new != orig:
            path.write_text(new, encoding="utf-8")
            changed.append(str(path.relative_to(ROOT)))

    print(f"CHANGED {len(changed)}")
    for c in changed:
        print(c)


if __name__ == "__main__":
    main()
