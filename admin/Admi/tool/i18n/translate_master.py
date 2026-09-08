#!/usr/bin/env python3
"""Batch-translate admin UI master strings with glossary overlays."""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path(__file__).resolve().parents[3]  # admin/Admi
HERE = Path(__file__).resolve().parent
MASTER = HERE / "master_strings.json"
OUT = HERE / "translated_master.json"
CACHE = HERE / "translate_cache.json"

AR_RE = re.compile(r"[\u0600-\u06FF]")
SUPPORTED = ["en", "ru", "ky", "fr", "ur", "pt"]

# Canonical term overlays (applied to EN first, then propagated via phrase replace).
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

GLOSSARY_EN_PHRASE = {
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
    "Agent": {
        "ru": "Агент",
        "ky": "Агент",
        "fr": "Agent",
        "ur": "ایجنٹ",
        "pt": "Agente",
    },
    "Driver": {
        "ru": "Водитель",
        "ky": "Айдоочу",
        "fr": "Chauffeur",
        "ur": "ڈرائیور",
        "pt": "Motorista",
    },
    "Platform fee": {
        "ru": "Комиссия платформы",
        "ky": "Платформа комиссиясы",
        "fr": "Commission plateforme",
        "ur": "پلیٹ فارم فیس",
        "pt": "Taxa da plataforma",
    },
    "Agent share": {
        "ru": "Доля агента",
        "ky": "Агенттин үлүшү",
        "fr": "Part de l'agent",
        "ur": "ایجنٹ کا حصہ",
        "pt": "Participação do agente",
    },
    "Driver net": {
        "ru": "Чистыми водителю",
        "ky": "Айдоочунун тазасы",
        "fr": "Net chauffeur",
        "ur": "ڈرائیور کی خالص رقم",
        "pt": "Líquido do motorista",
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


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")


def cache_get(cache: dict, src: str, text: str, target: str) -> str | None:
    return cache.get(f"{src}|{target}|{text}")


def cache_set(cache: dict, src: str, text: str, target: str, value: str) -> None:
    cache[f"{src}|{target}|{text}"] = value


def translate_one(cache: dict, text: str, source: str, target: str) -> str:
    text = (text or "").strip()
    if not text:
        return text
    if source == target:
        return text
    hit = cache_get(cache, source, text, target)
    if hit is not None:
        return hit
    # Tiny / punctuation-only
    if not re.search(r"[\w\u0600-\u06FF]", text, re.UNICODE):
        cache_set(cache, source, text, target, text)
        return text
    # Google often rejects explicit ar→* for this environment; auto works.
    sources_to_try = ["auto", source]
    for attempt in range(6):
        src = sources_to_try[attempt % len(sources_to_try)]
        try:
            out = GoogleTranslator(source=src, target=target).translate(text)
            out = (out or "").strip() or text
            cache_set(cache, source, text, target, out)
            return out
        except Exception as exc:
            time.sleep(1.2 * (attempt + 1))
            if attempt == 5:
                print(f"WARN translate fail {source}->{target}: {exc!r} text={text[:60]!r}", flush=True)
    cache_set(cache, source, text, target, text)
    return text


def normalize_en_from_ar(ar: str, en: str) -> str:
    ar = (ar or "").strip()
    en = (en or "").strip()
    if ar in GLOSSARY_AR_EN:
        return GLOSSARY_AR_EN[ar]
    if en and not AR_RE.search(en):
        # Prefer glossary substring replacements for known Arabic leftovers already EN
        return en
    if ar in GLOSSARY_AR_EN:
        return GLOSSARY_AR_EN[ar]
    return en


def apply_phrase_glossary(en: str, loc: str, machine: str) -> str:
    if en in GLOSSARY_EN_PHRASE and loc in GLOSSARY_EN_PHRASE[en]:
        return GLOSSARY_EN_PHRASE[en][loc]
    # Exact phrase replace inside longer strings
    out = machine
    for phrase, locs in GLOSSARY_EN_PHRASE.items():
        if phrase in en and loc in locs:
            # If machine already differs, only force when whole string equals phrase
            if en.strip() == phrase:
                return locs[loc]
    return out


def needs_work(item: dict) -> bool:
    if item.get("status") == "missing":
        return True
    if item.get("needs_quality"):
        return True
    en = item.get("en") or ""
    if AR_RE.search(en):
        return True
    return False


def main() -> None:
    master = json.loads(MASTER.read_text(encoding="utf-8"))
    cache = load_cache()
    done = 0
    total = sum(1 for x in master if needs_work(x))
    print(f"translating {total} of {len(master)}", flush=True)

    for item in master:
        if not needs_work(item):
            continue
        ar = (item.get("source_ar") or item.get("ar") or "").strip()
        en = (item.get("en") or "").strip()

        if not en or AR_RE.search(en):
            if ar in GLOSSARY_AR_EN:
                en = GLOSSARY_AR_EN[ar]
            else:
                en = translate_one(cache, ar or en, "ar", "en")
        en = normalize_en_from_ar(ar, en)
        item["en"] = en
        item["ar"] = ar or item.get("ar") or en

        for loc in ["ru", "ky", "fr", "ur", "pt"]:
            existing = (item.get(loc) or "").strip()
            # Re-translate if empty, equals EN, equals AR, contains Arabic, or mixed garbage
            bad = (
                not existing
                or existing == en
                or (ar and existing == ar)
                or AR_RE.search(existing)
                or (
                    loc in ("pt", "fr", "ur", "ky", "ru")
                    and en
                    and any(
                        w in existing
                        for w in (" new ", " description", " driver", "Driver", "Balance")
                    )
                    and existing != en
                )
            )
            if not bad and not item.get("needs_quality"):
                continue
            if en in GLOSSARY_EN_PHRASE and loc in GLOSSARY_EN_PHRASE[en]:
                item[loc] = GLOSSARY_EN_PHRASE[en][loc]
            else:
                machine = translate_one(cache, en if en else ar, "en" if en else "ar", loc)
                item[loc] = apply_phrase_glossary(en, loc, machine)

        item["needs_quality"] = False
        item["status"] = "translated"
        done += 1
        if done % 25 == 0:
            save_cache(cache)
            OUT.write_text(json.dumps(master, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"progress {done}/{total}", flush=True)

    save_cache(cache)
    OUT.write_text(json.dumps(master, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"done {done}/{total} -> {OUT}", flush=True)


if __name__ == "__main__":
    main()
