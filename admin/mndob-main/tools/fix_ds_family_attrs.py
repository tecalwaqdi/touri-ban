#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(r"d:/touri-taxi/ara/admin/mndob-main/lib")
ROLES = [
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


def main() -> None:
    fixed = 0
    for path in ROOT.rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        orig = text
        for role in ROLES:
            text = text.replace(
                f"DsTypography.of(context).{role}Family",
                "'cairo'",
            )
            text = text.replace(
                f"DsTypography.of(context).{role}IsCustom",
                "true",
            )
            text = text.replace(
                f"FlutterFlowTheme.of(context).{role}Family",
                "'cairo'",
            )
            text = text.replace(
                f"FlutterFlowTheme.of(context).{role}IsCustom",
                "true",
            )
        if text != orig:
            path.write_text(text, encoding="utf-8")
            fixed += 1
    print(f"fixed files {fixed}")


if __name__ == "__main__":
    main()
