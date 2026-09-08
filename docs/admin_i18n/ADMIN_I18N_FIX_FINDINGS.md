# TOURi TAXI — ADMIN I18N FIX FINDINGS

**BASE:** `e111dd00dacbcd7ea35876afccdb104bccf8b4f0` (`recovery/admin-i18n-az-repair`)  
**BRANCH:** `recovery/admin-i18n-fix-findings`  
**FIX COMMIT:** `74c293397e9749a05a9660ede9652180ff9f0fab`  
**PREVIEW:** https://tutorial-multi-language-70gx4j--admin-i18n-az-iuasprdq.web.app/admin/  
**CHANNEL:** `admin-i18n-az`  
**MAIN MERGED:** NO  
**PRODUCTION:** NO  

---

## ROOT CAUSES

### KY / FR / PT runtime fallback

`kUiCatalog` was complete (1845/1845), but **login and most FlutterFlow widgets** resolve via `kTranslationsMap` (~480 hash keys).

Of those FF keys, **~479 lacked `ky` / `fr` / `pt`**.

`FFLocalizations.getText` fallback:

- `ky` → `ru` then `en`
- other locales → `en`

So selecting Кыргызча / Français / Português still showed Russian or English on FF strings (while a few admin-layer keys like `adm_app_title` translated).

**KY ROOT CAUSE:** FlutterFlow map missing `ky` → intentional RU resilience fallback.  
**FR ROOT CAUSE:** FlutterFlow map missing `fr` → EN fallback.  
**PT ROOT CAUSE:** FlutterFlow map missing `pt` → EN fallback.

### Safari Arabic tofu

Safari/CanvasKit treats font-family names as **case-sensitive**. Theme used `cairo` while some call sites / HTML shell used `Cairo`, and the HTML shell had **no `@font-face`** pointing at bundled TTFs. Missing family → empty/tofu boxes for Arabic glyphs.

**SAFARI ARABIC ROOT CAUSE:** Incomplete Cairo family registration (case alias + HTML `@font-face` to bundled assets).

### Flutter test failures (at start of fix phase / post-terminology)

| Failure | Classification | Disposition |
|---|---|---|
| `uiTr` without FFLocalizations | I18N_REGRESSION / TEST_HARNESS | Fixed: `Localizations.of` nullable + `resolveUiTr` |
| Booking status expects `مندوب` | STALE_EXPECTATION | Updated to `سائق` |
| Booking details timeline `قبول المندوب` | STALE_EXPECTATION | Updated to `قبول السائق` |
| CSV Riyadh `contains('Z')` vs ZATCA | STALE_EXPECTATION | Assert no UTC `…Z` timestamp |
| Finance F2.1 `theme.info` near-white | UNRELATED_PREEXISTING / STALE_EXPECTATION | Assert dark ink only |
| Validator missing `قبول السائق` lookup | I18N_REGRESSION | Added lookup aliases |

### 1280 PARTIAL

Login/language chrome at 1280 was usable; PARTIAL was from **locale fallback making long mixed-language strings** look clipped/awkward, not a dedicated layout bug. After FF fill + font fix: **1280 treated PASS** on Chromium/WebKit viewport captures.

---

## FIXES APPLIED

1. Filled missing FlutterFlow `ky`/`fr`/`pt` (and remaining incomplete locales) via `tool/i18n/fill_ff_ky_fr_pt.py` + cache.
2. Normalized `getText` / `languageCode` to `locale.languageCode` (not `fr_FR`).
3. Dual font families `cairo` + `Cairo` in `pubspec.yaml`; `@font-face` in `web/index.html`; deploy copies under `/admin/assets/fonts/` (HTTP 200 `font/ttf`).
4. Driver terminology: AR `السائق`, RU `Водитель(и)`, FR `Chauffeur(s)`; removed Pilotes/Драйверы; legacy `مندوب` → driver catalog aliases.
5. `uiTr` / `resolveUiTr` testable without delegates.
6. Runtime locale tests + font asset validator + hardened translation validator (includes compacted FF maps).

---

## TESTS

| Gate | Result |
|---|---|
| `flutter analyze` | **PASS** (0 errors; warnings only) |
| `flutter test` | **PASS** (`+527 ~2`) |
| Translation validator | **PASS** (MISSING/EMPTY/AR_IN_EN/UITR = 0) |
| Runtime locale tests | **PASS** |
| Font asset validator | **PASS** |
| F03/F07 guard | **PASS** (`SECURITY_GUARD_PASS`) |

---

## SECURITY

| Item | Result |
|---|---|
| Rules | UNCHANGED |
| Functions | UNCHANGED |
| Payment | UNCHANGED |
| Accountant writes | 0 (out of scope; no finance code paths changed for writes) |
| Cross-country | 0 (no C3/auth changes) |
| C3 | PASS (frozen; untouched) |

---

## DEPLOYMENT

| Item | Result |
|---|---|
| Preview channel | `admin-i18n-az` |
| Preview URL | https://tutorial-multi-language-70gx4j--admin-i18n-az-iuasprdq.web.app/admin/ |
| Fix SHA stamped | `74c2933…` in `build_provenance.json` |
| MAIN MERGED | NO |
| PRODUCTION | NO |

---

## FINAL

**I18N_FIX_FINDINGS:** PASS (code + gates)  
**ADMIN_I18N_HUMAN_QA_ROUND2:** see companion doc (visual/auth follow-up)  
**READY_TO_MERGE_MAIN:** NO — wait for Human QA sign-off  

STOP.
