# TOURi TAXI — ADMIN I18N FINAL INTEGRATION

BASE MAIN:
`0d5d6c00357a294473efb58b5aa4d6943c09946c`

I18N SOURCE:
`e111dd00dacbcd7ea35876afccdb104bccf8b4f0` (+ follow-up `74c2933` locale/font fill)

FINAL FIX COMMIT:
`5bf16a4dbe7d30af6d0a3468c33283569e77a6db`

BRANCH:
`recovery/admin-i18n-final-integration`

PREVIEW:
https://tutorial-multi-language-70gx4j--admin-i18n-final-v75ynfxv.web.app/admin/

================================
INTEGRATION METHOD
================================

Clean branch from `origin/main` @ `0d5d6c0` (not merge-main-into-old-i18n).

Cherry-picked:
1. `e111dd0` catalog A→Z repair (manual resolve of `ui_catalog.dart`)
2. `74c2933` KY/FR/PT FF fills + Cairo Safari aliases + `resolveUiTr`

Then commits:
- `900b997` drop KY→RU normal fallback + driver terminology
- `5bf16a4` repair lookup aliases / Filters key / validator

I18N FILES SAFE:
catalogs, FF `internationalization.dart`, status localization, tools/validator,
finance label wrappers, docs under `docs/admin_i18n/`, runtime locale tests

FILES CONFLICTING WITH NEW MAIN:
`admin/Admi/lib/l10n/ui_catalog.dart` (manual merge)
`admin/Admi/lib/admin/admin_a_l_lhg_z/admin_bookings_table.dart` (auto-merged; main kept)

FILES REQUIRING MANUAL MERGE:
`ui_catalog.dart` only (agent Filters + سائق terminology preserved)

Agent runtime / Rules / createPanelUser / sidebar map:
UNCHANGED vs main (diff empty for Rules + lock)

================================
ROOT CAUSES
================================

KY FALLBACK:
FlutterFlow `kTranslationsMap` login/nav keys lacked `ky`; `getText` used
`locale.toString()` and KY→RU resilience. Fixed by filling `ky` entries,
resolving by `languageCode`, and removing KY→RU as a normal path.

FR FALLBACK:
Same — missing `fr` entries in FF maps → EN. Fixed by filling `fr` + languageCode.

PT FALLBACK:
Same — missing `pt` entries → EN. Fixed by filling `pt` + languageCode.
Variant observed in FF strings: **pt-BR leaning** (e.g. “Conecte-se”, “Digite seu e-mail…”).

SAFARI TOFU:
Preview/build font family case mismatch (`cairo` vs `Cairo`) + missing
`@font-face` aliases. Fixed via dual family registration in `pubspec.yaml`
and `web/index.html` `@font-face` (from `74c2933`). Automated WebKit auth
DOM scrape could not prove glyphs (Flutter canvas); Safari.app opened to preview.

OLD FLUTTER TEST FAILURES:
Class: I18N_RUNTIME + TEST_HARNESS  
Root: `uiTr` without FFLocalizations + missing KY/FR/PT FF keys + lookup gaps.  
Fixed via `resolveUiTr` / null-safe `Localizations.of` + catalog/lookup repair.  
Current gate suites: PASS (no remaining “known six”).

================================
LANGUAGES
================================

AR:
PASS (runtime tests + catalog); Safari visual auth: NOT FULLY PROVEN in automation

EN:
PASS

RU:
PASS (terminology Водитель/Водители applied)

KY:
PASS (runtime getText + resolveUiTr ≠ RU)

FR:
PASS (runtime ≠ EN; Chauffeur terminology)

UR:
PASS (runtime)

PT:
PASS (runtime ≠ EN; pt-BR lean)

================================
FALLBACK
================================

KY->RU:
0 (normal path removed; EN only if key truly absent)

FR->EN:
0 on filled login/representative keys (runtime tests)

PT->EN:
0 on filled login/representative keys (runtime tests)

WRONG LANGUAGE:
0 on tested resolveUiTr / FF login keys

================================
SAFARI
================================

AR LOGIN:
NOT FULLY PROVEN (automation); source font fix landed; Safari.app opened

AR AUTH:
NOT FULLY PROVEN (WebKit stuck on shell loader text len=23)

UR LOGIN:
NOT FULLY PROVEN

UR AUTH:
NOT FULLY PROVEN

TOFU:
0 in automated scrape (no U+FFFD); human Safari glyph check still required

================================
AUTHENTICATED UI
================================

SUPER ADMIN:
PARTIAL (token mint OK; Flutter shell did not expose body text in WebKit probe)

ACCOUNTANT:
NOT RUN in browser this pass

COUNTRY AGENT:
NOT RUN in browser this pass (unit/security gates PASS)

SIDEBAR:
PASS (unit: frozen route map tests)

TABLES:
NOT FULLY PROVEN (browser)

BOOKINGS:
PASS (unit/runtime policy); browser PARTIAL

LANDMARKS:
PASS (unit); browser PARTIAL

FINANCE:
PASS (unit finance label tests); browser PARTIAL

SETTINGS:
NOT FULLY PROVEN

TECHNICAL IDS:
NOT FULLY PROVEN this pass

================================
VIEWPORTS
================================

1440:
NOT RUN

1280:
NOT RUN

1024:
NOT RUN

768:
NOT RUN

================================
TESTS
================================

FLUTTER ANALYZE:
PASS (infos only)

FLUTTER TEST:
PASS (agent runtime, shell rules, accountant RBAC, i18n runtime, validator,
booking/finance adapters touched by i18n)

TRANSLATION VALIDATOR:
PASS (1845-class coverage; MISSING/EMPTY/AR_IN_EN/UITR_MISSING_LOOKUP = 0)

RUNTIME LOCALE TEST:
PASS

NEW FAILURES:
0

================================
SECURITY
================================

F03:
PASS

F07:
PASS

C3:
PASS (prior assignment suite on baseline; Rules untouched)

CREATE SECURITY:
PASS (lock tests; Rules/Functions unchanged vs main)

CROSS COUNTRY:
0

ACCOUNTANT WRITES:
0

RULES:
UNCHANGED

FUNCTIONS:
UNCHANGED

PAYMENT API:
UNCHANGED

================================
DEPLOYMENT
================================

MAIN MERGED:
NO

PRODUCTION:
NO

RULES:
UNCHANGED

FUNCTIONS:
UNCHANGED

PAYMENT API:
UNCHANGED

PREVIEW CHANNEL:
`admin-i18n-final`
URL: https://tutorial-multi-language-70gx4j--admin-i18n-final-v75ynfxv.web.app/admin/
SHA: `5bf16a4dbe7d30af6d0a3468c33283569e77a6db`

================================
FINAL
================================

ADMIN_I18N_FINAL:
NEEDS_FIXES

READY_TO_MERGE_MAIN:
NO

READY_FOR_RENDER_RELEASE:
NO

BLOCKERS FOR HUMAN_PASS:
1. Authenticated Safari/Chromium visual QA across ar/en/ru/ky/fr/ur/pt routes
2. Confirm Arabic/Urdu glyphs (tofu) on real Safari.app authenticated screens
3. Viewport matrix 1440/1280/1024/768
4. Country Agent authenticated regression on preview
5. Technical IDs + money RTL visual checks

STOP.
