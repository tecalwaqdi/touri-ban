#!/usr/bin/env python3
"""Faster concurrent translator; resumes from translated_master.json / cache."""

from __future__ import annotations

import json
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from deep_translator import GoogleTranslator

HERE = Path(__file__).resolve().parent
MASTER_IN = HERE / "translated_master.json"
if not MASTER_IN.exists():
    MASTER_IN = HERE / "master_strings.json"
OUT = HERE / "translated_master.json"
CACHE = HERE / "translate_cache.json"

AR_RE = re.compile(r"[\u0600-\u06FF]")

GLOSSARY_AR_EN = {
    "المصالحة المالية": "Financial reconciliation",
    "المصالحة": "Reconciliation",
    "التسوية": "Settlement",
    "التسويات": "Settlements",
    "حركة الأموال": "Money movement",
    "تحصيل النقد": "Cash collection",
    "عمولة المنصة": "Platform fee",
    "حصة الوكيل": "Agent share",
    "صافي السائق": "Driver net",
    "التقارير المحاسبية": "Accounting reports",
    "سجل التدقيق المالي": "Finance audit log",
    "مالية الوكلاء": "Agent finance",
    "الوكيل": "Agent",
    "الوكلاء": "Agents",
    "السائق": "Driver",
    "السائقين": "Drivers",
    "السائقون": "Drivers",
    "المندوب": "Driver",
    "المناديب": "Drivers",
    "المحاسب": "Accountant",
    "لوحة التحكم": "Dashboard",
    "وضع تجريبي": "Demo mode",
    "المتبقي": "Outstanding",
    "المدفوع": "Paid",
    "غير مدفوع": "Unpaid",
    "تحتاج مراجعة": "Needs review",
    "بيانات مالية ناقصة": "Incomplete financial data",
}

GLOSSARY_EN = {
    "Financial reconciliation": {
        "ru": "Финансовая сверка",
        "ky": "Финансылык салыштыруу",
        "fr": "Rapprochement financier",
        "ur": "مالیاتی مصالحت",
        "pt": "Conciliação financeira",
    },
    "Money movement": {
        "ru": "Движение средств",
        "ky": "Акча кыймылы",
        "fr": "Mouvements de fonds",
        "ur": "رقم کی نقل و حرکت",
        "pt": "Movimentação de fundos",
    },
    "Cash collection": {
        "ru": "Инкассация наличных",
        "ky": "Накталай жыйноо",
        "fr": "Encaissement cash",
        "ur": "نقدی وصولی",
        "pt": "Cobrança em dinheiro",
    },
    "Settlement": {
        "ru": "Расчёт",
        "ky": "Эсептешүү",
        "fr": "Règlement",
        "ur": "تصفیہ",
        "pt": "Liquidação",
    },
    "Settlements": {
        "ru": "Расчёты",
        "ky": "Эсептешүүлөр",
        "fr": "Règlements",
        "ur": "تصفیے",
        "pt": "Liquidações",
    },
    "Agent": {"ru": "Агент", "ky": "Агент", "fr": "Agent", "ur": "ایجنٹ", "pt": "Agente"},
    "Driver": {
        "ru": "Водитель",
        "ky": "Айдоочу",
        "fr": "Chauffeur",
        "ur": "ڈرائیور",
        "pt": "Motorista",
    },
    "Demo mode": {
        "ru": "Демо-режим",
        "ky": "Демо режим",
        "fr": "Mode démo",
        "ur": "ڈیمو موڈ",
        "pt": "Modo demonstração",
    },
    "Outstanding": {
        "ru": "К оплате",
        "ky": "Төлөнө элек",
        "fr": "Restant dû",
        "ur": "باقی",
        "pt": "Em aberto",
    },
    "Needs review": {
        "ru": "Требует проверки",
        "ky": "Текшерүү керек",
        "fr": "À revoir",
        "ur": "جائزے کی ضرورت",
        "pt": "Precisa de revisão",
    },
}


def load_json(path: Path, default):
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return default


def save_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def translate_raw(text: str, target: str) -> str:
    text = (text or "").strip()
    if not text:
        return text
    if not re.search(r"[\w\u0600-\u06FF]", text, re.UNICODE):
        return text
    last = None
    for attempt in range(4):
        try:
            return (GoogleTranslator(source="auto", target=target).translate(text) or text).strip()
        except Exception as exc:
            last = exc
            time.sleep(0.8 * (attempt + 1))
    raise RuntimeError(f"{target}: {last}")


def needs_work(item: dict) -> bool:
    if item.get("status") == "translated" and not item.get("needs_quality"):
        # still fix arabic-in-en
        if AR_RE.search(item.get("en") or ""):
            return True
        return False
    return True


def locale_bad(item: dict, loc: str, en: str, ar: str) -> bool:
    v = (item.get(loc) or "").strip()
    if not v:
        return True
    if en and v == en:
        return True
    if ar and v == ar:
        return True
    if AR_RE.search(v) and loc not in ("ur",):  # ur uses Arabic script but different language; allow
        # Urdu uses Arabic script — don't treat as bad solely for Arabic letters.
        # Detect identical-to-Arabic separately above.
        pass
    if loc == "ur" and ar and v == ar:
        return True
    # mixed garbage markers from prior catalog
    if any(x in v for x in (" new ", " description")) and en and v != en:
        return True
    return False


def main() -> None:
    master = load_json(MASTER_IN, [])
    cache = load_json(CACHE, {})
    work_idx = [i for i, it in enumerate(master) if needs_work(it)]
    print(f"resume work={len(work_idx)} total={len(master)} cache={len(cache)}", flush=True)

    def cached(text: str, target: str) -> str:
        key = f"auto|{target}|{text}"
        if key in cache:
            return cache[key]
        val = translate_raw(text, target)
        cache[key] = val
        return val

    done = 0
    for i in work_idx:
        item = master[i]
        ar = (item.get("source_ar") or item.get("ar") or "").strip()
        en = (item.get("en") or "").strip()
        if not en or AR_RE.search(en):
            en = GLOSSARY_AR_EN.get(ar) or cached(ar or en, "en")
        item["en"] = en
        item["ar"] = ar or item.get("ar") or en
        item["source_ar"] = ar or item.get("source_ar") or item["ar"]

        # Parallel locale fill
        targets = []
        for loc in ["ru", "ky", "fr", "ur", "pt"]:
            if en in GLOSSARY_EN and loc in GLOSSARY_EN[en]:
                item[loc] = GLOSSARY_EN[en][loc]
            elif locale_bad(item, loc, en, ar) or item.get("needs_quality"):
                targets.append(loc)
            # else keep existing

        if targets:
            with ThreadPoolExecutor(max_workers=5) as ex:
                futs = {ex.submit(cached, en if en else ar, loc): loc for loc in targets}
                for fut in as_completed(futs):
                    loc = futs[fut]
                    try:
                        item[loc] = fut.result()
                    except Exception as exc:
                        print(f"WARN {item['key']} {loc}: {exc}", flush=True)
                        item[loc] = item.get(loc) or en

        item["needs_quality"] = False
        item["status"] = "translated"
        done += 1
        if done % 20 == 0:
            save_json(CACHE, cache)
            save_json(OUT, master)
            print(f"progress {done}/{len(work_idx)}", flush=True)

    save_json(CACHE, cache)
    save_json(OUT, master)
    print(f"done {done}/{len(work_idx)} -> {OUT}", flush=True)


if __name__ == "__main__":
    main()
