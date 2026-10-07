#!/usr/bin/env python3
"""Merge *_done.json translation maps into app locale JSON files."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path('/Users/meeting/touri-ban/admin')
WORK = ROOT / '_loc_work'
PH = re.compile(r'\{([a-zA-Z0-9_]+)\}')


def placeholders(s: str) -> set[str]:
    return set(PH.findall(s))


def apply_one(app: str, lang: str) -> tuple[int, int]:
    todo_path = WORK / f'{app}__{lang}__todo.json'
    done_path = WORK / f'{app}__{lang}__done.json'
    if not done_path.exists():
        print(f'MISSING {done_path.name}')
        return 0, -1
    todo = json.load(open(todo_path, encoding='utf-8'))
    done = json.load(open(done_path, encoding='utf-8'))
    locale_path = ROOT / app / 'assets' / 'langs' / f'{lang}.json'
    locale = json.load(open(locale_path, encoding='utf-8'))

    missing = sorted(set(todo) - set(done))
    extra = sorted(set(done) - set(todo))
    mism = []
    applied = 0
    for k, en_val in todo.items():
        if k not in done:
            continue
        tr = done[k]
        if not isinstance(tr, str) or not tr.strip():
            mism.append(k)
            continue
        if placeholders(en_val) != placeholders(tr):
            mism.append(k)
            continue
        locale[k] = tr
        applied += 1

    with open(locale_path, 'w', encoding='utf-8') as f:
        json.dump(locale, f, ensure_ascii=False, indent=2)
        f.write('\n')

    print(
        f'{app}/{lang}: applied={applied} missing={len(missing)} '
        f'extra={len(extra)} ph_mism={len(mism)}'
    )
    if missing[:5]:
        print('  missing sample', missing[:5])
    if mism[:5]:
        print('  ph_mism sample', mism[:5])
    return applied, len(mism) + len(missing)


def main() -> int:
    bad = 0
    for app in ['ara_oatan_app', 'mndob-main']:
        for lang in ['pt', 'fr', 'ur']:
            _, err = apply_one(app, lang)
            if err:
                bad += err
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
